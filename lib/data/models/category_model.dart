import 'package:razak_travel/data/models/model_parsers.dart';

class CategoryModel {
  final String id;
  final Map<String, String> names;
  final String image;
  final Map<String, String> descriptions;
  final DateTime createdAt;

  const CategoryModel({
    required this.id,
    this.names = const {},
    required this.image,
    this.descriptions = const {},
    required this.createdAt,
  });

  String get name => localizedName('en');
  String get description => localizedDescription('en');
  String get imageUrl => image.trim();
  bool get hasImage => imageUrl.isNotEmpty;
  String get shortDescription => summarizedDescription('en');

  String localizedName(String localeCode) {
    return localizedTextForLocale(names, localeCode);
  }

  String localizedDescription(String localeCode) {
    return localizedTextForLocale(descriptions, localeCode);
  }

  String summarizedDescription(
    String localeCode, {
    int maxLength = 110,
  }) {
    final value = localizedDescription(localeCode).trim();
    if (value.length <= maxLength) {
      return value;
    }
    return '${value.substring(0, maxLength).trimRight()}...';
  }

  static String _parseImageUrl(Map<String, dynamic> json) {
    for (final key in ['image_url', 'imageUrl', 'image']) {
      final value = json[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }

    return '';
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      names: parseLocalizedTextMap(
        json['names'],
        legacyValue: json['name']?.toString(),
      ),
      image: _parseImageUrl(json),
      descriptions: parseLocalizedTextMap(
        json['descriptions'],
        legacyValue: json['description']?.toString(),
      ),
      createdAt: parseDateTime(
        json['created_at'] ?? json['createdAt'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'name': name,
      'descriptions': descriptions,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };

    if (id.isNotEmpty) {
      data['id'] = id;
    }

    return data;
  }
}
