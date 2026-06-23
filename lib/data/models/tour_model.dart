import 'dart:math' as math;

import 'package:razak_travel/data/models/model_parsers.dart';

class TourModel {
  final String id;
  final Map<String, String> title;
  final Map<String, String> names;
  final String categoryId;
  final String destination;
  final String description;
  final Map<String, String> descriptionMap;
  final Map<String, String> descriptions;
  final Map<String, String> included;
  final Map<String, List<String>> includedItems;
  final Map<String, String> notIncluded;
  final Map<String, List<String>> placesToVisit;
  final Map<String, String> meetingPoint;
  final Map<String, String> pickupDetails;
  final Map<String, String> extraInfo;
  final Map<String, String> whatToBring;
  final Map<String, String> landmark;
  final Map<String, String> guidePhone;
  final Map<String, String> whatsapp;
  final Map<String, String> departureTime;
  final Map<String, String> returnTime;
  final String imageUrl;
  final List<String> images;
  final double? lat;
  final double? lng;
  final double price;
  final DateTime date;
  final int totalSeats;
  final int bookedSeats;
  final int reservedSeats;
  final int bookingCount;
  final int? remainingSeats;
  final DateTime? discountEndTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double rating;
  final List<String> reviewTexts;

  const TourModel({
    required this.id,
    this.title = const {},
    this.names = const {},
    required this.categoryId,
    required this.destination,
    this.description = '',
    this.descriptionMap = const {},
    this.descriptions = const {},
    this.included = const {},
    this.includedItems = const {},
    this.notIncluded = const {},
    this.placesToVisit = const {},
    this.meetingPoint = const {},
    this.pickupDetails = const {},
    this.extraInfo = const {},
    this.whatToBring = const {},
    this.landmark = const {},
    this.guidePhone = const {},
    this.whatsapp = const {},
    this.departureTime = const {},
    this.returnTime = const {},
    this.imageUrl = '',
    this.images = const [],
    this.lat,
    this.lng,
    required this.price,
    required this.date,
    required this.totalSeats,
    required this.bookedSeats,
    this.reservedSeats = 0,
    this.bookingCount = 0,
    this.remainingSeats,
    this.discountEndTime,
    this.createdAt,
    this.updatedAt,
    this.rating = 0,
    this.reviewTexts = const [],
  });

  int get availableSeats =>
      math.max(totalSeats - bookedSeats - reservedSeats, 0);
  int get seatsLeft => math.max(remainingSeats ?? availableSeats, 0);
  DateTime get resolvedDiscountEndTime => discountEndTime ?? date;
  List<String> get imageUrls => galleryImages;
  List<String> get galleryImages => _uniqueImageUrls([imageUrl, ...images]);
  String get primaryImage =>
      galleryImages.isNotEmpty ? galleryImages.first : '';
  String get name => localizedName('en');
  bool get hasImages => galleryImages.isNotEmpty;
  bool get hasCoordinates => lat != null && lng != null;
  double? get latitude => lat;
  double? get longitude => lng;
  String get shortDescription => summarizedDescription('en');
  List<String> get sampleReviewTexts => reviewTexts
      .map((text) => text.trim())
      .where((text) => text.isNotEmpty)
      .take(3)
      .toList(growable: false);

  Map<String, String> get resolvedTitle =>
      title.isNotEmpty ? title : names;
  Map<String, String> get resolvedDescriptionMap {
    if (descriptionMap.isNotEmpty) {
      return descriptionMap;
    }
    if (descriptions.isNotEmpty) {
      return descriptions;
    }
    if (description.trim().isNotEmpty) {
      return {'kg': description.trim()};
    }
    return const {};
  }

  String localizedName(String localeCode) {
    return localizedTextForLocale(resolvedTitle, localeCode);
  }

  String localizedDescription(String localeCode) {
    final localized = localizedTextForLocale(resolvedDescriptionMap, localeCode);
    if (localized.trim().isNotEmpty) {
      return localized;
    }

    return description.trim();
  }

  String localizedIncluded(String localeCode) {
    return localizedTextForLocale(included, localeCode);
  }

  String localizedNotIncluded(String localeCode) {
    return localizedTextForLocale(notIncluded, localeCode);
  }

  String localizedMeetingPoint(String localeCode) {
    return localizedTextForLocale(meetingPoint, localeCode);
  }

  String localizedPickupDetails(String localeCode) {
    return localizedTextForLocale(pickupDetails, localeCode);
  }

  String localizedExtraInfo(String localeCode) {
    return localizedTextForLocale(extraInfo, localeCode);
  }

  String localizedWhatToBring(String localeCode) {
    return localizedTextForLocale(whatToBring, localeCode);
  }

  String localizedLandmark(String localeCode) {
    return localizedTextForLocale(landmark, localeCode);
  }

  String localizedGuidePhone(String localeCode) {
    return localizedTextForLocale(guidePhone, localeCode);
  }

  String localizedWhatsapp(String localeCode) {
    return localizedTextForLocale(whatsapp, localeCode);
  }

  String localizedDepartureTime(String localeCode) {
    return localizedTextForLocale(departureTime, localeCode);
  }

  String localizedReturnTime(String localeCode) {
    return localizedTextForLocale(returnTime, localeCode);
  }

  static String normalizeSearchText(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  bool matchesSearchQuery(
    String query, {
    Iterable<String> categoryNames = const [],
  }) {
    final normalizedQuery = normalizeSearchText(query);
    if (normalizedQuery.isEmpty) {
      return true;
    }

    final searchableText = normalizeSearchText(
      <String>[
        ...resolvedTitle.values,
        destination,
        ...categoryNames,
      ].where((value) => value.trim().isNotEmpty).join(' '),
    );

    if (searchableText.isEmpty) {
      return false;
    }

    final searchTerms =
        normalizedQuery.split(' ').where((term) => term.isNotEmpty);

    return searchTerms.every(searchableText.contains);
  }

  String summarizedDescription(
    String localeCode, {
    int maxLength = 140,
  }) {
    final value = localizedDescription(localeCode).trim();
    if (value.length <= maxLength) {
      return value;
    }
    return '${value.substring(0, maxLength).trimRight()}...';
  }

  List<String> localizedIncludedItems(String localeCode) {
    final localizedText = localizedIncluded(localeCode);
    if (localizedText.isNotEmpty) {
      return _splitMultilineText(localizedText);
    }
    return localizedListForLocale(includedItems, localeCode);
  }

  List<String> localizedPlacesToVisit(String localeCode) {
    final localizedText = localizedTextForLocale(notIncluded, localeCode);
    if (localizedText.isNotEmpty) {
      return _splitMultilineText(localizedText);
    }
    return localizedListForLocale(placesToVisit, localeCode);
  }

  List<String> localizedNotIncludedItems(String localeCode) {
    final localizedText = localizedNotIncluded(localeCode);
    return _splitMultilineText(localizedText);
  }

  List<String> localizedWhatToBringItems(String localeCode) {
    return _splitMultilineText(localizedWhatToBring(localeCode));
  }

  TourModel copyWith({
    String? id,
    Map<String, String>? title,
    Map<String, String>? names,
    String? categoryId,
    String? destination,
    String? description,
    Map<String, String>? descriptionMap,
    Map<String, String>? descriptions,
    Map<String, String>? included,
    Map<String, List<String>>? includedItems,
    Map<String, String>? notIncluded,
    Map<String, List<String>>? placesToVisit,
    Map<String, String>? meetingPoint,
    Map<String, String>? pickupDetails,
    Map<String, String>? extraInfo,
    Map<String, String>? whatToBring,
    Map<String, String>? landmark,
    Map<String, String>? guidePhone,
    Map<String, String>? whatsapp,
    Map<String, String>? departureTime,
    Map<String, String>? returnTime,
    String? imageUrl,
    List<String>? images,
    double? lat,
    double? lng,
    double? price,
    DateTime? date,
    int? totalSeats,
    int? bookedSeats,
    int? reservedSeats,
    int? bookingCount,
    int? remainingSeats,
    DateTime? discountEndTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? rating,
    List<String>? reviewTexts,
  }) {
    return TourModel(
      id: id ?? this.id,
      title: title ?? this.title,
      names: names ?? this.names,
      categoryId: categoryId ?? this.categoryId,
      destination: destination ?? this.destination,
      description: description ?? this.description,
      descriptionMap: descriptionMap ?? this.descriptionMap,
      descriptions: descriptions ?? this.descriptions,
      included: included ?? this.included,
      includedItems: includedItems ?? this.includedItems,
      notIncluded: notIncluded ?? this.notIncluded,
      placesToVisit: placesToVisit ?? this.placesToVisit,
      meetingPoint: meetingPoint ?? this.meetingPoint,
      pickupDetails: pickupDetails ?? this.pickupDetails,
      extraInfo: extraInfo ?? this.extraInfo,
      whatToBring: whatToBring ?? this.whatToBring,
      landmark: landmark ?? this.landmark,
      guidePhone: guidePhone ?? this.guidePhone,
      whatsapp: whatsapp ?? this.whatsapp,
      departureTime: departureTime ?? this.departureTime,
      returnTime: returnTime ?? this.returnTime,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      price: price ?? this.price,
      date: date ?? this.date,
      totalSeats: totalSeats ?? this.totalSeats,
      bookedSeats: bookedSeats ?? this.bookedSeats,
      reservedSeats: reservedSeats ?? this.reservedSeats,
      bookingCount: bookingCount ?? this.bookingCount,
      remainingSeats: remainingSeats ?? this.remainingSeats,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      discountEndTime: discountEndTime ?? this.discountEndTime,
      rating: rating ?? this.rating,
      reviewTexts: reviewTexts ?? this.reviewTexts,
    );
  }

  static List<String> _parseImageUrls(
    Map<String, dynamic> json, {
    String primaryImageUrl = '',
  }) {
    final imageUrls = <String>[];

    void addUrls(dynamic value) {
      for (final url in parseStringList(value)) {
        if (!imageUrls.contains(url)) {
          imageUrls.add(url);
        }
      }
    }

    addUrls(primaryImageUrl);
    for (final key in ['images', 'imageUrls', 'imageUrl', 'image']) {
      addUrls(json[key]);
    }

    return imageUrls;
  }

  static List<String> _uniqueImageUrls(Iterable<String> values) {
    final imageUrls = <String>[];
    for (final value in values) {
      final normalized = value.trim();
      if (normalized.isEmpty || imageUrls.contains(normalized)) {
        continue;
      }
      imageUrls.add(normalized);
    }

    return imageUrls;
  }

  static List<String> _splitMultilineText(String value) {
    return value
        .split(RegExp(r'[\n,]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static String _joinLocalizedListItems(
    Map<String, List<String>> values,
    String localeCode,
  ) {
    final items = localizedListForLocale(values, localeCode);
    return items.join('\n').trim();
  }

  // ignore: unused_element
  static Map<String, String> _localizedTextMapFromListMap(
    Map<String, List<String>> values,
  ) {
    final result = <String, String>{};
    for (final entry in values.entries) {
      final joined = entry.value
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .join('\n')
          .trim();
      if (joined.isNotEmpty) {
        result[normalizeTourLanguageCode(entry.key)] = joined;
      }
    }
    return result;
  }

  static Map<String, List<String>> _listMapFromLocalizedTextMap(
    Map<String, String> values,
  ) {
    final result = <String, List<String>>{};
    for (final entry in values.entries) {
      final items = _splitMultilineText(entry.value);
      if (items.isNotEmpty) {
        result[normalizeTourLanguageCode(entry.key)] = items;
      }
    }
    return result;
  }

  factory TourModel.fromJson(Map<String, dynamic> json) {
    final rawDescription = json['description'];
    final descriptionText = rawDescription is String
        ? rawDescription.trim()
        : json['descriptionText']?.toString().trim() ?? '';
    final imageUrl = json['image_url']?.toString() ?? json['imageUrl']?.toString() ?? '';
    final date = parseDateTime(json['date']);
    final totalSeats = parseInt(json['total_seats'] ?? json['totalSeats']);
    final bookedSeats = parseInt(json['booked_seats'] ?? json['bookedSeats']);
    final reservedSeats = parseInt(json['reserved_seats'] ?? json['reservedSeats']);
    final availableSeats =
        math.max(totalSeats - bookedSeats - reservedSeats, 0);

    final legacyIncludedItems = parseLocalizedStringListMap(json['includedItems']);
    final legacyPlacesToVisit =
        parseLocalizedStringListMap(json['placesToVisit']);
    final titleMap = parseLocalizedTextMap(
      json['title'] ?? json['names'],
      legacyValue: json['name']?.toString(),
    );
    final descriptionMap = parseLocalizedTextMap(
      rawDescription is Map ? rawDescription : json['descriptions'],
      legacyValue: descriptionText,
    );
    final includedMap = parseLocalizedTextMap(
      json['included'],
      legacyValue: _joinLocalizedListItems(legacyIncludedItems, 'kg'),
    );
    final notIncludedMap = parseLocalizedTextMap(
      json['notIncluded'],
      legacyValue: _joinLocalizedListItems(legacyPlacesToVisit, 'kg'),
    );

    return TourModel(
      id: json['id']?.toString() ?? '',
      title: titleMap,
      names: titleMap.isNotEmpty
          ? titleMap
          : parseLocalizedTextMap(
              json['names'],
              legacyValue: json['name']?.toString(),
            ),
      categoryId: json['category_id']?.toString() ?? json['categoryId']?.toString() ?? '',
      destination: json['destination']?.toString() ?? '',
      description: localizedTextForLocale(descriptionMap, 'kg'),
      descriptionMap: descriptionMap,
      descriptions: descriptionMap.isNotEmpty
          ? descriptionMap
          : parseLocalizedTextMap(
              json['descriptions'],
              legacyValue: descriptionText,
            ),
      included: includedMap,
      includedItems: legacyIncludedItems.isNotEmpty
          ? legacyIncludedItems
          : _listMapFromLocalizedTextMap(includedMap),
      notIncluded: notIncludedMap,
      placesToVisit: legacyPlacesToVisit.isNotEmpty
          ? legacyPlacesToVisit
          : _listMapFromLocalizedTextMap(notIncludedMap),
      meetingPoint: parseLocalizedTextMap(
        json['meetingPoint'],
        legacyValue: json['meetingPoint']?.toString(),
      ),
      pickupDetails: parseLocalizedTextMap(
        json['pickupDetails'],
        legacyValue: json['pickupDetails']?.toString(),
      ),
      extraInfo: parseLocalizedTextMap(
        json['extraInfo'],
        legacyValue: json['extraInfo']?.toString(),
      ),
      whatToBring: parseLocalizedTextMap(
        json['whatToBring'],
        legacyValue: json['whatToBring']?.toString(),
      ),
      landmark: parseLocalizedTextMap(
        json['landmark'],
        legacyValue: json['landmark']?.toString(),
      ),
      guidePhone: parseLocalizedTextMap(
        json['guidePhone'],
        legacyValue: json['guidePhone']?.toString(),
      ),
      whatsapp: parseLocalizedTextMap(
        json['whatsapp'],
        legacyValue: json['whatsapp']?.toString(),
      ),
      departureTime: parseLocalizedTextMap(
        json['departureTime'],
        legacyValue: json['departureTime']?.toString(),
      ),
      returnTime: parseLocalizedTextMap(
        json['returnTime'],
        legacyValue: json['returnTime']?.toString(),
      ),
      imageUrl: imageUrl,
      images: _parseImageUrls(
        json,
        primaryImageUrl: imageUrl,
      ),
      lat: parseNullableDouble(json['lat'] ?? json['latitude']),
      lng: parseNullableDouble(json['lng'] ?? json['longitude']),
      price: parseDouble(json['price']),
      date: date,
      totalSeats: totalSeats,
      bookedSeats: bookedSeats,
      reservedSeats: reservedSeats,
      bookingCount: parseInt(
        json['booking_count'] ?? json['bookingCount'],
      ),
      remainingSeats: json.containsKey('remainingSeats')
          ? parseInt(json['remainingSeats'])
          : availableSeats,
      createdAt: parseNullableDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: parseNullableDateTime(json['updated_at'] ?? json['updatedAt']),
      discountEndTime: json['discountEndTime'] == null
          ? date
          : parseDateTime(json['discountEndTime']),
      rating: parseDouble(json['rating']),
      reviewTexts: parseStringList(
        json['reviewTexts'] ?? json['reviews'] ?? json['reviewText'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    final resolvedTitle = completeLocalizedTextMap(
      // ignore: unnecessary_this
      this.title.isNotEmpty ? this.title : names,
    );
    final resolvedDescriptionMap = completeLocalizedTextMap(
      descriptionMap.isNotEmpty ? descriptionMap : descriptions,
      primaryLocale: description.trim(),
    );

    return {
      'id': id,
      'title': resolvedTitle,
      'category_id': categoryId,
      'description': localizedTextForLocale(
        resolvedDescriptionMap,
        'kg',
      ),
      'image_url': primaryImage,
      'price': price,
      'date': date.toIso8601String(),
      'total_seats': totalSeats,
      'booked_seats': bookedSeats,
      'reserved_seats': reservedSeats,
      'booking_count': bookingCount,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }
}
