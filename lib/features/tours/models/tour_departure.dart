import 'dart:math' as math;

import 'package:razak_travel/data/models/model_parsers.dart';

abstract final class TourDepartureStatus {
  static const String available = 'available';
  static const String limited = 'limited';
  static const String soldOut = 'sold_out';
}

abstract final class TourDeparturePickupType {
  static const String meetingPoint = 'meeting_point';
  static const String hotelPickup = 'hotel_pickup';
  static const String airportPickup = 'airport_pickup';
  static const String doorToDoor = 'door_to_door';

  static const List<String> values = <String>[
    meetingPoint,
    hotelPickup,
    airportPickup,
    doorToDoor,
  ];
}

class TourDeparture {
  const TourDeparture({
    required this.id,
    required this.tourId,
    required this.departureDate,
    required this.returnDate,
    required this.totalSeats,
    required this.bookedSeats,
    required this.price,
    required this.status,
    this.meetingPointName = const {},
    this.meetingAddress = const {},
    this.landmark = const {},
    this.pickupType = TourDeparturePickupType.meetingPoint,
    this.pickupInstructions = const {},
    this.googleMapsUrl = '',
    this.latitude,
    this.longitude,
    this.guidePhone = '',
    this.guideWhatsapp = '',
  });

  final String id;
  final String tourId;
  final DateTime departureDate;
  final DateTime returnDate;
  final int totalSeats;
  final int bookedSeats;
  final double price;
  final String status;
  final Map<String, String> meetingPointName;
  final Map<String, String> meetingAddress;
  final Map<String, String> landmark;
  final String pickupType;
  final Map<String, String> pickupInstructions;
  final String googleMapsUrl;
  final double? latitude;
  final double? longitude;
  final String guidePhone;
  final String guideWhatsapp;

  int get availableSeats => math.max(totalSeats - bookedSeats, 0);
  bool get isLimited => status == TourDepartureStatus.limited;
  bool get isSoldOut => status == TourDepartureStatus.soldOut;
  bool get hasCoordinates => latitude != null && longitude != null;
  bool get hasGuideContact =>
      guidePhone.trim().isNotEmpty || guideWhatsapp.trim().isNotEmpty;
  bool get hasPickupDetails =>
      meetingPointName.values.any((value) => value.trim().isNotEmpty) ||
      meetingAddress.values.any((value) => value.trim().isNotEmpty) ||
      landmark.values.any((value) => value.trim().isNotEmpty) ||
      pickupInstructions.values.any((value) => value.trim().isNotEmpty) ||
      googleMapsUrl.trim().isNotEmpty ||
      hasCoordinates ||
      hasGuideContact;
  String get resolvedGoogleMapsUrl {
    final directUrl = googleMapsUrl.trim();
    if (directUrl.isNotEmpty) {
      return directUrl;
    }

    if (hasCoordinates) {
      return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    }

    return '';
  }

  String localizedMeetingPointName(String localeCode) {
    return localizedTextForLocale(meetingPointName, localeCode);
  }

  String localizedMeetingAddress(String localeCode) {
    return localizedTextForLocale(meetingAddress, localeCode);
  }

  String localizedLandmark(String localeCode) {
    return localizedTextForLocale(landmark, localeCode);
  }

  String localizedPickupInstructions(String localeCode) {
    return localizedTextForLocale(pickupInstructions, localeCode);
  }

  TourDeparture copyWith({
    String? id,
    String? tourId,
    DateTime? departureDate,
    DateTime? returnDate,
    int? totalSeats,
    int? bookedSeats,
    double? price,
    String? status,
    Map<String, String>? meetingPointName,
    Map<String, String>? meetingAddress,
    Map<String, String>? landmark,
    String? pickupType,
    Map<String, String>? pickupInstructions,
    String? googleMapsUrl,
    double? latitude,
    double? longitude,
    bool clearLatitude = false,
    bool clearLongitude = false,
    String? guidePhone,
    String? guideWhatsapp,
  }) {
    final resolvedTotalSeats = totalSeats ?? this.totalSeats;
    final resolvedBookedSeats = bookedSeats ?? this.bookedSeats;
    final resolvedAvailableSeats =
        math.max(resolvedTotalSeats - resolvedBookedSeats, 0);

    return TourDeparture(
      id: id ?? this.id,
      tourId: tourId ?? this.tourId,
      departureDate: departureDate ?? this.departureDate,
      returnDate: returnDate ?? this.returnDate,
      totalSeats: resolvedTotalSeats,
      bookedSeats: resolvedBookedSeats,
      price: price ?? this.price,
      status: _normalizeStatus(
        status,
        availableSeats: resolvedAvailableSeats,
      ),
      meetingPointName: meetingPointName ?? this.meetingPointName,
      meetingAddress: meetingAddress ?? this.meetingAddress,
      landmark: landmark ?? this.landmark,
      pickupType: _normalizePickupType(pickupType ?? this.pickupType),
      pickupInstructions: pickupInstructions ?? this.pickupInstructions,
      googleMapsUrl: googleMapsUrl ?? this.googleMapsUrl,
      latitude: clearLatitude ? null : latitude ?? this.latitude,
      longitude: clearLongitude ? null : longitude ?? this.longitude,
      guidePhone: guidePhone ?? this.guidePhone,
      guideWhatsapp: guideWhatsapp ?? this.guideWhatsapp,
    );
  }

  factory TourDeparture.fromJson(Map<String, dynamic> json) {
    final totalSeats = parseInt(json['total_seats'] ?? json['totalSeats']);
    final bookedSeats =
        json.containsKey('booked_seats') || json.containsKey('bookedSeats')
            ? parseInt(json['booked_seats'] ?? json['bookedSeats'])
            : math.max(
                totalSeats -
                    parseInt(json['available_seats'] ?? json['availableSeats']),
                0);
    final availableSeats = math.max(totalSeats - bookedSeats, 0);
    final departureDate =
        parseDateTime(json['departure_date'] ?? json['departureDate']);

    return TourDeparture(
      id: json['id']?.toString() ?? '',
      tourId: json['tour_id']?.toString() ?? json['tourId']?.toString() ?? '',
      departureDate: departureDate,
      returnDate: (json['return_date'] ?? json['returnDate']) == null
          ? departureDate
          : parseDateTime(json['return_date'] ?? json['returnDate']),
      totalSeats: totalSeats,
      bookedSeats: bookedSeats,
      price: parseDouble(json['price']),
      status: _normalizeStatus(
        json['status']?.toString(),
        availableSeats: availableSeats,
      ),
      meetingPointName: parseLocalizedTextMap(
          json['meeting_point_name'] ?? json['meetingPointName']),
      meetingAddress: parseLocalizedTextMap(
          json['meeting_address'] ?? json['meetingAddress']),
      landmark: parseLocalizedTextMap(json['landmark']),
      pickupType: _normalizePickupType(
          json['pickup_type']?.toString() ?? json['pickupType']?.toString()),
      pickupInstructions: parseLocalizedTextMap(
          json['pickup_instructions'] ?? json['pickupInstructions']),
      googleMapsUrl: (json['google_maps_url'] ?? json['googleMapsUrl'])
              ?.toString()
              .trim() ??
          '',
      latitude: parseNullableDouble(json['latitude'] ?? json['lat']),
      longitude: parseNullableDouble(json['longitude'] ?? json['lng']),
      guidePhone:
          (json['guide_phone'] ?? json['guidePhone'])?.toString().trim() ?? '',
      guideWhatsapp: (json['guide_whatsapp'] ?? json['guideWhatsapp'])
              ?.toString()
              .trim() ??
          '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tour_id': tourId,
      'departure_date': departureDate.toIso8601String(),
      'return_date': returnDate.toIso8601String(),
      'total_seats': totalSeats,
      'booked_seats': bookedSeats,
      'price': price,
      'status': _normalizeStatus(
        status,
        availableSeats: availableSeats,
      ),
      'meeting_point_name': meetingPointName,
      'meeting_address': meetingAddress,
      'landmark': landmark,
      'pickup_type': _normalizePickupType(pickupType),
      'pickup_instructions': pickupInstructions,
      'google_maps_url': googleMapsUrl.trim(),
      'latitude': latitude,
      'longitude': longitude,
      'guide_phone': guidePhone.trim(),
      'guide_whatsapp': guideWhatsapp.trim(),
    };
  }

  static String resolveStatusForSeats(int availableSeats) {
    if (availableSeats <= 0) {
      return TourDepartureStatus.soldOut;
    }

    if (availableSeats <= 5) {
      return TourDepartureStatus.limited;
    }

    return TourDepartureStatus.available;
  }

  static String _normalizeStatus(
    String? value, {
    required int availableSeats,
  }) {
    switch (value) {
      case TourDepartureStatus.available:
      case TourDepartureStatus.limited:
      case TourDepartureStatus.soldOut:
        return resolveStatusForSeats(availableSeats);
      default:
        return resolveStatusForSeats(availableSeats);
    }
  }

  static String _normalizePickupType(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';
    if (TourDeparturePickupType.values.contains(normalized)) {
      return normalized;
    }
    return TourDeparturePickupType.meetingPoint;
  }
}
