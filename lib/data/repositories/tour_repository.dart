import 'package:flutter/foundation.dart';
import 'package:razak_travel/core/services/admin_access_service.dart';
import 'package:razak_travel/core/services/supabase_service.dart';
import 'package:razak_travel/data/models/tour_model.dart';
import 'package:razak_travel/features/tours/models/tour_departure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class TourRepository {
  final SupabaseService _supabase = SupabaseService.instance;
  final _adminAccessService = AdminAccessService();

  Future<List<TourModel>> getToursByCategory(String categoryId) async {
    final toursData = await _supabase.queryEq(
      _supabase.tours,
      'category_id',
      categoryId,
    );
    final departuresByTourId = await _loadDeparturesByTourId();
    final bookingCounts = await _loadBookingCounts();

    return _mapTours(
      toursData,
      bookingCounts: bookingCounts,
      departuresByTourId: departuresByTourId,
    );
  }

  Future<List<TourModel>> getAllTours() async {
    final toursData = await _supabase.query(_supabase.tours);
    final departuresByTourId = await _loadDeparturesByTourId();
    final bookingCounts = await _loadBookingCounts();

    return _mapTours(
      toursData,
      bookingCounts: bookingCounts,
      departuresByTourId: departuresByTourId,
    );
  }

  Future<void> addTour(
    TourModel tour, {
    List<TourDeparture>? departures,
  }) async {
    await _adminAccessService.ensureAdminOrOwnerAccess();

    final normalizedDepartures = _normalizeDepartures(
      tour: tour,
      departures: departures,
      createFallbackWhenEmpty: true,
    );
    final summaryTour = _applyDepartureSummary(tour, normalizedDepartures);

    debugPrint('TOUR PAYLOAD: ${summaryTour.toJson()}');
    final user = Supabase.instance.client.auth.currentUser;
    debugPrint('INSERT USER: $user');
    debugPrint('INSERT USER ID: ${user?.id}');
    debugPrint('IS ANONYMOUS: ${user == null}');
    await _supabase.upsert(_supabase.tours, summaryTour.toJson());
    for (final departure in normalizedDepartures) {
      // ignore: avoid_print
      print('DEPARTURE ID: ${departure.id}');
      debugPrint('DEPARTURE PAYLOAD: ${departure.toJson()}');
      await _supabase.upsert(_supabase.departures, departure.toJson());
    }
  }

  Future<void> updateTour(
    TourModel tour, {
    List<TourDeparture>? departures,
  }) async {
    await _adminAccessService.ensureAdminOrOwnerAccess();

    if (departures == null) {
      if (tour.totalSeats < tour.bookedSeats + tour.reservedSeats) {
        throw 'invalid_total_seats';
      }
      debugPrint('TOUR PAYLOAD: ${tour.toJson()}');
      await _supabase.update(_supabase.tours, tour.toJson(), 'id', tour.id);
      return;
    }

    final normalizedDepartures = _normalizeDepartures(
      tour: tour,
      departures: departures,
      createFallbackWhenEmpty: false,
    );
    final existingData =
        await _supabase.queryEq(_supabase.departures, 'tour_id', tour.id);
    final existingDepartures =
        existingData.map((d) => TourDeparture.fromJson(d)).toList();
    final existingIds = existingDepartures.map((d) => d.id).toSet();
    final nextIds = normalizedDepartures.map((d) => d.id).toSet();
    final removedIds = existingIds.difference(nextIds);

    for (final departureId in removedIds) {
      await _ensureDepartureCanBeDeleted(tour.id, departureId);
      await _supabase.delete(_supabase.departures, 'id', departureId);
    }

    final summaryTour = _applyDepartureSummary(tour, normalizedDepartures);
    debugPrint('TOUR PAYLOAD: ${summaryTour.toJson()}');
    await _supabase.update(
      _supabase.tours,
      summaryTour.toJson(),
      'id',
      tour.id,
    );

    for (final departure in normalizedDepartures) {
      // ignore: avoid_print
      print('DEPARTURE ID: ${departure.id}');
      debugPrint('DEPARTURE PAYLOAD: ${departure.toJson()}');
      await _supabase.upsert(_supabase.departures, departure.toJson());
    }
  }

  Future<void> deleteTour(String id) async {
    await _adminAccessService.ensureAdminOrOwnerAccess();

    final linkedBookings = await _supabase.queryEq(
      _supabase.bookings,
      'tour_id',
      id,
      limit: 1,
    );

    if (linkedBookings.isNotEmpty) {
      throw 'tour_has_linked_bookings';
    }

    final departuresData =
        await _supabase.queryEq(_supabase.departures, 'tour_id', id);
    for (final dep in departuresData) {
      await _supabase.delete(_supabase.departures, 'id', dep['id']);
    }

    await _supabase.delete(_supabase.tours, 'id', id);
  }

  Future<List<TourDeparture>> getDeparturesForTour(String tourId) async {
    final normalizedTourId = tourId.trim();
    if (normalizedTourId.isEmpty) {
      return const <TourDeparture>[];
    }

    final data = await _supabase.queryEq(
      _supabase.departures,
      'tour_id',
      normalizedTourId,
      order: 'departure_date',
    );

    if (data.isNotEmpty) {
      return data.map((d) => TourDeparture.fromJson(d)).toList();
    }

    final tourData = await _supabase.querySingleEq(
      _supabase.tours,
      'id',
      normalizedTourId,
    );

    if (tourData == null) {
      return const <TourDeparture>[];
    }

    final tour = TourModel.fromJson(tourData);
    return <TourDeparture>[_legacyDepartureFromTour(tour)];
  }

  Future<Map<String, int>> _loadBookingCounts() async {
    final data = await _supabase.queryEq(
      _supabase.bookings,
      'status',
      'approved',
    );
    final counts = <String, int>{};

    for (final row in data) {
      final tourId = (row['tour_id'] ?? row['tourId'])?.toString().trim() ?? '';
      if (tourId.isEmpty) {
        continue;
      }
      counts.update(tourId, (value) => value + 1, ifAbsent: () => 1);
    }

    return counts;
  }

  Future<Map<String, List<TourDeparture>>> _loadDeparturesByTourId() async {
    final data = await _supabase.query(_supabase.departures);
    final departuresByTourId = <String, List<TourDeparture>>{};

    for (final row in data) {
      final departure = TourDeparture.fromJson(row);
      if (departure.tourId.isEmpty) {
        continue;
      }
      departuresByTourId
          .putIfAbsent(departure.tourId, () => <TourDeparture>[])
          .add(departure);
    }

    for (final departures in departuresByTourId.values) {
      departures.sort(_compareDepartures);
    }

    return departuresByTourId;
  }

  List<TourModel> _mapTours(
    List<Map<String, dynamic>> toursData, {
    required Map<String, int> bookingCounts,
    required Map<String, List<TourDeparture>> departuresByTourId,
  }) {
    final tours = toursData.map((json) => TourModel.fromJson(json)).map((tour) {
      final departures = departuresByTourId[tour.id];
      final summarizedTour = departures == null || departures.isEmpty
          ? tour
          : _applyDepartureSummary(tour, departures);
      return summarizedTour.copyWith(
        bookingCount: bookingCounts[tour.id] ?? 0,
      );
    }).toList(growable: false);

    tours.sort(_compareByPopularity);
    return tours;
  }

  List<TourDeparture> _normalizeDepartures({
    required TourModel tour,
    required List<TourDeparture>? departures,
    required bool createFallbackWhenEmpty,
  }) {
    final sourceDepartures = departures == null || departures.isEmpty
        ? (createFallbackWhenEmpty
            ? <TourDeparture>[_legacyDepartureFromTour(tour)]
            : const <TourDeparture>[])
        : departures;

    if (sourceDepartures.isEmpty) {
      throw 'tour_requires_departures';
    }

    final normalizedDepartures = <TourDeparture>[];
    for (final departure in sourceDepartures) {
      if (departure.price <= 0) {
        throw 'invalid_tour_data';
      }
      if (departure.totalSeats <= 0 ||
          departure.totalSeats < departure.bookedSeats) {
        throw 'invalid_total_seats';
      }
      if (departure.returnDate.isBefore(departure.departureDate)) {
        throw 'return_date_after_departure';
      }
      normalizedDepartures.add(
        departure.copyWith(
          id: departure.id.trim().isEmpty
              ? const Uuid().v4()
              : departure.id.trim(),
          tourId: departure.tourId.trim().isEmpty
              ? tour.id
              : departure.tourId.trim(),
        ),
      );
    }
    return _sortDepartures(normalizedDepartures);
  }

  TourModel _applyDepartureSummary(
    TourModel tour,
    List<TourDeparture> departures,
  ) {
    final summary = _buildDepartureSummary(departures);
    return tour.copyWith(
      price: summary.primaryDeparture.price,
      date: summary.primaryDeparture.departureDate,
      totalSeats: summary.totalSeats,
      bookedSeats: summary.bookedSeats,
      reservedSeats: 0,
      remainingSeats: summary.availableSeats,
      discountEndTime: summary.primaryDeparture.departureDate,
    );
  }

  _TourDepartureSummary _buildDepartureSummary(
    List<TourDeparture> departures,
  ) {
    final sorted = _sortDepartures(departures);
    final totalSeats = sorted.fold<int>(0, (sum, d) => sum + d.totalSeats);
    final bookedSeats = sorted.fold<int>(0, (sum, d) => sum + d.bookedSeats);
    final availableSeats =
        sorted.fold<int>(0, (sum, d) => sum + d.availableSeats);
    return _TourDepartureSummary(
      primaryDeparture: _selectPrimaryDeparture(sorted),
      totalSeats: totalSeats,
      bookedSeats: bookedSeats,
      availableSeats: availableSeats,
    );
  }

  TourDeparture _selectPrimaryDeparture(List<TourDeparture> departures) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    for (final d in departures) {
      if (!d.isSoldOut && !d.departureDate.isBefore(startOfToday)) {
        return d;
      }
    }
    for (final d in departures) {
      if (!d.isSoldOut) {
        return d;
      }
    }
    return departures.first;
  }

  Future<void> syncTourDepartureSummary(String tourId) async {
    final normalizedTourId = tourId.trim();
    if (normalizedTourId.isEmpty) {
      return;
    }

    final tourData = await _supabase.querySingleEq(
      _supabase.tours,
      'id',
      normalizedTourId,
    );
    if (tourData == null) {
      return;
    }

    final departures = await getDeparturesForTour(normalizedTourId);
    if (departures.isEmpty) {
      return;
    }

    final tour = TourModel.fromJson(tourData);
    final summaryTour = _applyDepartureSummary(tour, departures);

    await _supabase.update(
      _supabase.tours,
      summaryTour.toJson(),
      'id',
      normalizedTourId,
    );
  }

  Future<void> _ensureDepartureCanBeDeleted(
    String tourId,
    String departureId,
  ) async {
    final linked = await _supabase.queryEq(
      _supabase.bookings,
      'departure_id',
      departureId,
    );
    final hasActive = linked.any((b) {
      final status = b['status']?.toString().trim().toLowerCase() ?? '';
      return status != 'cancelled';
    });
    if (hasActive) {
      throw 'departure_has_linked_bookings';
    }
  }

  TourDeparture _legacyDepartureFromTour(TourModel tour) {
    final availableSeats =
        (tour.remainingSeats ?? tour.availableSeats).clamp(0, tour.totalSeats);
    final bookedSeats = tour.totalSeats - availableSeats;
    return TourDeparture(
      id: const Uuid().v4(),
      tourId: tour.id,
      departureDate: tour.date,
      returnDate: tour.date,
      totalSeats: tour.totalSeats,
      bookedSeats: bookedSeats,
      price: tour.price,
      status: TourDeparture.resolveStatusForSeats(availableSeats),
      meetingPointName: tour.meetingPoint,
      landmark: tour.landmark,
      pickupInstructions: tour.pickupDetails,
      latitude: tour.latitude,
      longitude: tour.longitude,
      guidePhone: tour.localizedGuidePhone('kg'),
      guideWhatsapp: tour.localizedWhatsapp('kg'),
    );
  }

  List<TourDeparture> _sortDepartures(List<TourDeparture> departures) {
    final sorted = List<TourDeparture>.from(departures);
    sorted.sort(_compareDepartures);
    return sorted;
  }

  static int _compareDepartures(TourDeparture left, TourDeparture right) {
    final dateCompare = left.departureDate.compareTo(right.departureDate);
    if (dateCompare != 0) {
      return dateCompare;
    }
    return left.id.compareTo(right.id);
  }

  static int _compareByPopularity(TourModel left, TourModel right) {
    final bookingCompare = right.bookingCount.compareTo(left.bookingCount);
    if (bookingCompare != 0) {
      return bookingCompare;
    }
    final dateCompare = left.date.compareTo(right.date);
    if (dateCompare != 0) {
      return dateCompare;
    }
    return left.id.compareTo(right.id);
  }
}

class _TourDepartureSummary {
  const _TourDepartureSummary({
    required this.primaryDeparture,
    required this.totalSeats,
    required this.bookedSeats,
    required this.availableSeats,
  });

  final TourDeparture primaryDeparture;
  final int totalSeats;
  final int bookedSeats;
  final int availableSeats;
}
