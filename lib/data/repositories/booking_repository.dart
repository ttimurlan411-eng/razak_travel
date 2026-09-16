import 'package:flutter/foundation.dart';
import 'package:razak_travel/core/services/supabase_service.dart';
import 'package:razak_travel/core/services/user_identity_service.dart';
import 'package:razak_travel/data/models/booking_model.dart';
import 'package:razak_travel/data/models/category_model.dart';
import 'package:razak_travel/data/models/tour_model.dart';
import 'package:razak_travel/data/repositories/notification_repository.dart';
import 'package:razak_travel/data/repositories/tour_repository.dart';
import 'package:razak_travel/features/tours/models/tour_departure.dart';

class BookingRepository {
  BookingRepository({
    UserIdentityService? userIdentityService,
  }) : _userIdentityService =
            userIdentityService ?? UserIdentityService.instance;

  final SupabaseService _supabase = SupabaseService.instance;
  final UserIdentityService _userIdentityService;
  final TourRepository _tourRepository = TourRepository();

  Future<List<BookingModel>> getAllBookings({
    String? localeCode,
  }) async {
    final data = await _supabase.query(
      _supabase.bookings,
      order: 'created_at',
      ascending: false,
    );
    final bookings = data.map((json) => BookingModel.fromJson(json)).toList();
    return _localizeBookings(bookings, localeCode);
  }

  Future<List<BookingModel>> getBookingsForUser(
    String userId, {
    String? localeCode,
  }) async {
    final currentUserId = userId.trim();
    if (currentUserId.isEmpty) {
      return const <BookingModel>[];
    }

    final data = await _supabase.queryEq(
      _supabase.bookings,
      'user_id',
      currentUserId,
      order: 'created_at',
      ascending: false,
    );
    final bookings = data.map((json) => BookingModel.fromJson(json)).toList();
    return _localizeBookings(bookings, localeCode);
  }

  Future<List<BookingModel>> getBookingsForTour(
    String tourId, {
    String? localeCode,
  }) async {
    final data = await _supabase.queryEq(
      _supabase.bookings,
      'tour_id',
      tourId,
      order: 'created_at',
      ascending: false,
    );
    final bookings = data.map((json) => BookingModel.fromJson(json)).toList();
    return _localizeBookings(bookings, localeCode);
  }

  Future<BookingModel?> getBookingById(
    String bookingId, {
    String? localeCode,
  }) async {
    final data = await _supabase.querySingleEq(
      _supabase.bookings,
      'id',
      bookingId,
    );
    if (data == null) {
      return null;
    }
    final booking = BookingModel.fromJson(data);
    final localized = await _localizeBookings([booking], localeCode);
    return localized.isEmpty ? null : localized.first;
  }

  Future<BookingModel> createPendingBooking({
    required TourModel tour,
    required TourDeparture departure,
    required int seatCount,
    required String localeCode,
    required String userName,
    String hotelName = '',
    String userAddress = '',
    String roomNumber = '',
    String pickupNotes = '',
  }) async {
    final userId = (await _userIdentityService.getUserId()).trim();
    final bookingId = 'bok_${DateTime.now().microsecondsSinceEpoch}';
    final categoryData = await _supabase.querySingleEq(
      _supabase.categories,
      'id',
      tour.categoryId,
    );
    final category =
        categoryData != null ? CategoryModel.fromJson(categoryData) : null;
    final categoryName =
        category?.localizedName(localeCode).trim().isNotEmpty == true
            ? category!.localizedName(localeCode)
            : category?.name ?? '';
    final normalizedUserName =
        userName.trim().isEmpty ? 'Unknown' : userName.trim();
    final normalizedSeatCount = seatCount <= 0 ? 1 : seatCount;
    final requiresTransferDetails =
        departure.pickupType == TourDeparturePickupType.doorToDoor;
    final normalizedHotelName = requiresTransferDetails ? hotelName.trim() : '';
    final normalizedUserAddress =
        requiresTransferDetails ? userAddress.trim() : '';
    final normalizedRoomNumber =
        requiresTransferDetails ? roomNumber.trim() : '';
    final normalizedPickupNotes =
        requiresTransferDetails ? pickupNotes.trim() : '';

    final currentDepartureData = await _supabase.querySingleEq(
      _supabase.departures,
      'id',
      departure.id,
    );
    final currentDeparture = currentDepartureData != null
        ? TourDeparture.fromJson(currentDepartureData)
        : departure.copyWith(tourId: tour.id);

    if (currentDeparture.availableSeats < normalizedSeatCount) {
      throw 'not_enough_seats_available';
    }

    final nextDeparture = currentDeparture.copyWith(
      bookedSeats: currentDeparture.bookedSeats + normalizedSeatCount,
    );
    final shouldNotifyLowSeats =
        nextDeparture.availableSeats > 0 && nextDeparture.availableSeats <= 5;

    debugPrint('DEPARTURE PAYLOAD: ${nextDeparture.toJson()}');
    await _supabase.update(
      _supabase.departures,
      nextDeparture.toJson(),
      'id',
      nextDeparture.id,
    );

    final now = DateTime.now().toIso8601String();
    await _supabase.insert(_supabase.bookings, {
      'id': bookingId,
      'user_id': userId,
      'user_name': normalizedUserName,
      'tour_id': tour.id,
      'tour_name': tour.localizedName(localeCode),
      'category_id': tour.categoryId,
      'category_name': categoryName,
      'price': nextDeparture.price,
      'departure_id': nextDeparture.id,
      'departure_date': nextDeparture.departureDate.toIso8601String(),
      'tour_date': nextDeparture.departureDate.toIso8601String(),
      'pickup_type': nextDeparture.pickupType,
      'hotel_name': normalizedHotelName,
      'user_address': normalizedUserAddress,
      'room_number': normalizedRoomNumber,
      'pickup_notes': normalizedPickupNotes,
      'seats': normalizedSeatCount,
      'seat_count': normalizedSeatCount,
      'status': 'pending',
      'created_at': now,
    });

    await _tourRepository.syncTourDepartureSummary(tour.id);

    if (shouldNotifyLowSeats) {
      try {
        final notificationRepo = NotificationRepository();
        await notificationRepo.createNotification(
          title: 'Only few seats left',
          message: tour.localizedName('en').trim().isEmpty
              ? 'Only few seats left'
              : 'Only few seats left for ${tour.localizedName('en')}.',
          type: 'low_seats',
          tourId: tour.id,
        );
      } catch (e, s) {
        debugPrint('Low seats notification failed: $e');
        debugPrintStack(stackTrace: s);
      }
    }

    final createdBooking =
        await getBookingById(bookingId, localeCode: localeCode);

    if (createdBooking == null) {
      throw 'error_generic';
    }

    return createdBooking;
  }

  Future<void> cancelBooking(String bookingId) async {
    final bookingData =
        await _supabase.querySingleEq(_supabase.bookings, 'id', bookingId);
    if (bookingData == null) {
      throw 'error_generic';
    }

    final booking = BookingModel.fromJson(bookingData);
    if (!booking.isPending) {
      return;
    }

    if (booking.departureId.trim().isNotEmpty &&
        booking.tourId.trim().isNotEmpty) {
      final departureData = await _supabase.querySingleEq(
        _supabase.departures,
        'id',
        booking.departureId,
      );
      if (departureData != null) {
        final currentDeparture = TourDeparture.fromJson(departureData);
        final nextDeparture = currentDeparture.copyWith(
          bookedSeats: currentDeparture.bookedSeats - booking.seats,
        );
        debugPrint('DEPARTURE PAYLOAD: ${nextDeparture.toJson()}');
        await _supabase.update(
          _supabase.departures,
          nextDeparture.toJson(),
          'id',
          nextDeparture.id,
        );
        await _tourRepository.syncTourDepartureSummary(booking.tourId);
      }
    }

    await _supabase.update(
      _supabase.bookings,
      {'status': 'cancelled'},
      'id',
      bookingId,
    );
  }

  Future<BookingModel> approveBooking(String bookingId) async {
    // ignore: avoid_print
    print('APPROVE START');
    // ignore: avoid_print
    print('BOOKING ID: $bookingId');

    final bookingData =
        await _supabase.querySingleEq(_supabase.bookings, 'id', bookingId);
    if (bookingData == null) {
      // ignore: avoid_print
      print('APPROVE ERROR: booking not found');
      throw 'error_generic';
    }

    final booking = BookingModel.fromJson(bookingData);
    if (!booking.isPending) {
      // ignore: avoid_print
      print('APPROVE ERROR: booking is not pending, status=${booking.status}');
      throw 'error_generic';
    }

    final response = await _supabase.update(
      _supabase.bookings,
      {'status': 'approved'},
      'id',
      bookingId,
    );
    // ignore: avoid_print
    print('SUPABASE RESPONSE: $response');

    if (response.isEmpty) {
      // ignore: avoid_print
      print('APPROVE ERROR: update returned empty response');
      throw 'error_generic';
    }

    final updatedBooking = BookingModel.fromJson(response.first);

    try {
      final notificationRepo = NotificationRepository();
      await notificationRepo.createNotification(
        title: 'Your tour is confirmed',
        message: booking.tourName.isEmpty
            ? 'Your tour is confirmed'
            : 'Your booking for ${booking.tourName} is confirmed.',
        type: 'booking_approved',
        tourId: booking.tourId,
        targetUserId: booking.userId,
      );
    } catch (e, s) {
      debugPrint('Approval notification failed: $e');
      debugPrintStack(stackTrace: s);
    }

    // ignore: avoid_print
    print('APPROVE SUCCESS');
    return updatedBooking;
  }

  Future<void> deleteBooking(String bookingId) async {
    final bookingData =
        await _supabase.querySingleEq(_supabase.bookings, 'id', bookingId);
    if (bookingData == null) {
      return;
    }

    final booking = BookingModel.fromJson(bookingData);

    if (!booking.isCancelled &&
        booking.departureId.trim().isNotEmpty &&
        booking.tourId.trim().isNotEmpty) {
      final departureData = await _supabase.querySingleEq(
        _supabase.departures,
        'id',
        booking.departureId,
      );
      if (departureData != null) {
        final currentDeparture = TourDeparture.fromJson(departureData);
        final nextDeparture = currentDeparture.copyWith(
          bookedSeats: currentDeparture.bookedSeats - booking.seats,
        );
        debugPrint('DEPARTURE PAYLOAD: ${nextDeparture.toJson()}');
        await _supabase.update(
          _supabase.departures,
          nextDeparture.toJson(),
          'id',
          nextDeparture.id,
        );
        await _tourRepository.syncTourDepartureSummary(booking.tourId);
      }
    }

    await _supabase.delete(_supabase.bookings, 'id', bookingId);
  }

  Future<List<BookingModel>> _localizeBookings(
    List<BookingModel> bookings,
    String? localeCode,
  ) async {
    final normalizedLocale = localeCode?.trim().toLowerCase() ?? '';
    if (bookings.isEmpty || normalizedLocale.isEmpty) {
      return bookings;
    }

    final toursById = await _loadToursById(
      bookings.map((b) => b.tourId),
    );
    final categoriesById = await _loadCategoriesById(
      bookings.map((b) => b.categoryId),
    );

    return bookings.map((booking) {
      final tour = toursById[booking.tourId];
      final category = categoriesById[booking.categoryId];
      final localizedTourName =
          tour?.localizedName(normalizedLocale).trim() ?? '';
      final localizedCategoryName =
          category?.localizedName(normalizedLocale).trim() ?? '';
      final resolvedPrice =
          booking.price > 0 ? booking.price : (tour?.price ?? booking.price);

      return booking.copyWith(
        tourName:
            localizedTourName.isNotEmpty ? localizedTourName : booking.tourName,
        categoryName: localizedCategoryName.isNotEmpty
            ? localizedCategoryName
            : booking.categoryName,
        price: resolvedPrice,
      );
    }).toList(growable: false);
  }

  Future<Map<String, TourModel>> _loadToursById(Iterable<String> ids) async {
    final uniqueIds =
        ids.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet();
    final result = <String, TourModel>{};

    for (final id in uniqueIds) {
      final data = await _supabase.querySingleEq(_supabase.tours, 'id', id);
      if (data != null) {
        result[id] = TourModel.fromJson(data);
      }
    }

    return result;
  }

  Future<Map<String, CategoryModel>> _loadCategoriesById(
    Iterable<String> ids,
  ) async {
    final uniqueIds =
        ids.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet();
    final result = <String, CategoryModel>{};

    for (final id in uniqueIds) {
      final data =
          await _supabase.querySingleEq(_supabase.categories, 'id', id);
      if (data != null) {
        result[id] = CategoryModel.fromJson(data);
      }
    }

    return result;
  }
}
