import 'package:razak_travel/data/models/model_parsers.dart';

class BookingModel {
  const BookingModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.tourId,
    required this.tourName,
    required this.categoryId,
    required this.categoryName,
    required this.price,
    required this.status,
    required this.createdAt,
    this.departureId = '',
    this.departureDate,
    this.seatCount = 1,
    this.pickupType = '',
    this.hotelName = '',
    this.userAddress = '',
    this.roomNumber = '',
    this.pickupNotes = '',
    this.phone = '',
    this.tourDate,
  });

  final String id;
  final String userId;
  final String userName;
  final String tourId;
  final String tourName;
  final String categoryId;
  final String categoryName;
  final double price;
  final String status;
  final DateTime createdAt;
  final String departureId;
  final DateTime? departureDate;
  final int seatCount;
  final String pickupType;
  final String hotelName;
  final String userAddress;
  final String roomNumber;
  final String pickupNotes;
  final String phone;
  final DateTime? tourDate;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isCancelled => status == 'cancelled';

  String get displayUserName {
    final name = userName.trim();
    if (name.isNotEmpty) return name;
    final p = phone.trim();
    if (p.isNotEmpty) return p;
    return 'Unknown';
  }

  String get clientName => displayUserName;
  String get pickupAddress => userAddress;
  DateTime? get selectedDate => departureDate;
  int get seats => seatCount;
  bool get paid => isApproved;
  double get amount => price;
  String get currency => 'usd';
  String get checkoutStatus => status;
  String get stripeCheckoutSessionId => '';
  String get stripePaymentIntentId => '';
  String get checkoutUrl => '';
  String get checkoutRequestId => '';
  DateTime? get updatedAt => null;
  DateTime? get paymentCompletedAt => null;

  BookingModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? tourId,
    String? tourName,
    String? categoryId,
    String? categoryName,
    double? price,
    String? status,
    DateTime? createdAt,
    String? departureId,
    DateTime? departureDate,
    int? seatCount,
    String? pickupType,
    String? hotelName,
    String? userAddress,
    String? roomNumber,
    String? pickupNotes,
    String? phone,
    DateTime? tourDate,
  }) {
    return BookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      tourId: tourId ?? this.tourId,
      tourName: tourName ?? this.tourName,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      price: price ?? this.price,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      departureId: departureId ?? this.departureId,
      departureDate: departureDate ?? this.departureDate,
      seatCount: seatCount ?? this.seatCount,
      pickupType: pickupType ?? this.pickupType,
      hotelName: hotelName ?? this.hotelName,
      userAddress: userAddress ?? this.userAddress,
      roomNumber: roomNumber ?? this.roomNumber,
      pickupNotes: pickupNotes ?? this.pickupNotes,
      phone: phone ?? this.phone,
      tourDate: tourDate ?? this.tourDate,
    );
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel.fromMap(json);
  }

  factory BookingModel.fromMap(Map<String, dynamic> json) {
    final normalizedStatus = _normalizeStatus(json['status']);

    return BookingModel(
      id: _readString(json, 'id'),
      userId:
          _readString(json, 'user_id', fallback: _readString(json, 'userId')),
      userName: _readString(
        json,
        'user_name',
        fallback: _readString(json, 'userName',
            fallback: _readString(json, 'customer_name', fallback: 'Unknown')),
      ),
      phone: _readString(json, 'phone'),
      tourId:
          _readString(json, 'tour_id', fallback: _readString(json, 'tourId')),
      tourName: _readString(json, 'tour_name',
          fallback: _readString(json, 'tourName')),
      categoryId: _readString(json, 'category_id',
          fallback: _readString(json, 'categoryId')),
      categoryName: _readString(json, 'category_name',
          fallback: _readString(json, 'categoryName')),
      price: parseDouble(json['price'], fallback: 0),
      status: normalizedStatus,
      createdAt: _parseCreatedAt(
        json['created_at'] ?? json['createdAt'],
      ),
      departureId: _readString(json, 'departure_id',
          fallback: _readString(json, 'departureId')),
      departureDate: parseNullableDateTime(
        json['departure_date'] ??
            json['departureDate'] ??
            json['tour_date'] ??
            json['tourDate'],
      ),
      tourDate: parseNullableDateTime(json['tour_date'] ?? json['tourDate']),
      seatCount: parseInt(
        json['seats'] ?? json['seat_count'] ?? json['seatCount'],
        fallback: 1,
      ),
      pickupType: _readString(json, 'pickup_type',
          fallback: _readString(json, 'pickupType')),
      hotelName: _readString(json, 'hotel_name',
          fallback: _readString(json, 'hotelName')),
      userAddress: _readString(json, 'user_address',
          fallback: _readString(json, 'userAddress')),
      roomNumber: _readString(json, 'room_number',
          fallback: _readString(json, 'roomNumber')),
      pickupNotes: _readString(json, 'pickup_notes',
          fallback: _readString(json, 'pickupNotes')),
    );
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'phone': phone,
      'tour_id': tourId,
      'tour_name': tourName,
      'category_id': categoryId,
      'category_name': categoryName,
      'price': price,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'departure_id': departureId,
      'departure_date': departureDate?.toIso8601String(),
      'tour_date': (tourDate ?? departureDate)?.toIso8601String(),
      'seats': seatCount,
      'seat_count': seatCount,
      'pickup_type': pickupType,
      'hotel_name': hotelName,
      'user_address': userAddress,
      'room_number': roomNumber,
      'pickup_notes': pickupNotes,
    };
  }

  static String _readString(
    Map<String, dynamic> json,
    String key, {
    String fallback = '',
  }) {
    final value = json[key]?.toString().trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  static String _normalizeStatus(dynamic value) {
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    switch (normalized) {
      case 'pending':
      case 'approved':
      case 'cancelled':
        return normalized;
      default:
        return 'pending';
    }
  }

  static DateTime _parseCreatedAt(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }

    if (value == null) {
      return DateTime.now();
    }

    return parseDateTime(value, fallback: DateTime.now());
  }
}
