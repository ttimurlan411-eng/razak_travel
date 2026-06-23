import 'dart:convert';

const List<String> kTourTranslationLocales = <String>[
  'kg',
  'ru',
  'en',
  'kk',
  'tr',
];

String normalizeTourLanguageCode(String? code) {
  final normalized = (code ?? '').trim().toLowerCase();
  switch (normalized) {
    case 'ky':
      return 'kg';
    case 'kz':
      return 'kk';
    default:
      return normalized.isEmpty ? 'kg' : normalized;
  }
}

Map<String, String> createEmptyLocalizedTextMap({
  String primaryLocale = 'kg',
  String primaryValue = '',
}) {
  final normalizedPrimaryLocale = normalizeTourLanguageCode(primaryLocale);
  return {
    for (final locale in kTourTranslationLocales)
      locale: locale == normalizedPrimaryLocale ? primaryValue.trim() : '',
  };
}

Map<String, String> completeLocalizedTextMap(
  Map<String, String> values, {
  String primaryLocale = 'kg',
}) {
  final completed = createEmptyLocalizedTextMap(primaryLocale: primaryLocale);
  for (final entry in values.entries) {
    completed[normalizeTourLanguageCode(entry.key)] = entry.value.trim();
  }
  return completed;
}

String formatDateOnly(DateTime value) {
  final normalized = DateTime(value.year, value.month, value.day);
  final year = normalized.year.toString().padLeft(4, '0');
  final month = normalized.month.toString().padLeft(2, '0');
  final day = normalized.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

DateTime parseDateTime(
  dynamic value, {
  DateTime? fallback,
}) {
  final fallbackValue = fallback ?? DateTime.fromMillisecondsSinceEpoch(0);

  if (value == null) {
    return fallbackValue;
  }

  if (value is DateTime) {
    return value;
  }

  if (value is String) {
    return DateTime.tryParse(value) ?? fallbackValue;
  }

  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }

  return fallbackValue;
}

double parseDouble(
  dynamic value, {
  double fallback = 0,
}) {
  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value) ?? fallback;
  }

  return fallback;
}

double? parseNullableDouble(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value);
  }

  return null;
}

DateTime? parseNullableDateTime(dynamic value) {
  if (value == null) {
    return null;
  }

  return parseDateTime(value);
}

bool parseBool(
  dynamic value, {
  bool fallback = false,
}) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') {
      return true;
    }

    if (normalized == 'false' || normalized == '0') {
      return false;
    }
  }

  return fallback;
}

int parseInt(
  dynamic value, {
  int fallback = 0,
}) {
  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }

  return fallback;
}

List<String> parseStringList(dynamic value) {
  if (value is Iterable) {
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  if (value is String) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return const [];
    }

    return normalized
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  return const [];
}

Map<String, String> parseLocalizedTextMap(
  dynamic value, {
  String? legacyValue,
}) {
  final result = <String, String>{};

  if (value is Map) {
    for (final entry in value.entries) {
      final key = normalizeTourLanguageCode(entry.key.toString());
      final text = entry.value?.toString().trim() ?? '';
      if (key.isNotEmpty && text.isNotEmpty) {
        result[key] = text;
      }
    }
  } else if (value is String && value.trim().isNotEmpty) {
    final trimmed = value.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          return parseLocalizedTextMap(decoded, legacyValue: legacyValue);
        }
      } catch (_) {}
    }
    result['kg'] = trimmed;
  }

  final legacy = legacyValue?.trim() ?? '';
  if (legacy.isNotEmpty) {
    result.putIfAbsent('kg', () => legacy);
  }

  return result;
}

Map<String, List<String>> parseLocalizedStringListMap(
  dynamic value, {
  List<String>? legacyValue,
}) {
  final result = <String, List<String>>{};

  if (value is Map) {
    for (final entry in value.entries) {
      final key = normalizeTourLanguageCode(entry.key.toString());
      final items = parseStringList(entry.value);
      if (key.isNotEmpty && items.isNotEmpty) {
        result[key] = items;
      }
    }
  } else {
    final items = parseStringList(value);
    if (items.isNotEmpty) {
      result['kg'] = items;
    }
  }

  final legacyItems = legacyValue ?? const <String>[];
  if (legacyItems.isNotEmpty) {
    result.putIfAbsent('kg', () => legacyItems);
  }

  return result;
}

String localizedTextForLocale(
  Map<String, String> values,
  String localeCode, {
  String fallbackLocale = 'kg',
}) {
  return getLocalized(values, localeCode, fallbackLocale: fallbackLocale);
}

String getLocalized(
  Map<String, String> values,
  String localeCode, {
  String fallbackLocale = 'kg',
}) {
  final normalizedCode = normalizeTourLanguageCode(localeCode);
  final normalizedFallbackLocale = normalizeTourLanguageCode(fallbackLocale);
  final normalizedValues = <String, String>{};

  for (final entry in values.entries) {
    final key = normalizeTourLanguageCode(entry.key);
    final text = entry.value.trim();
    if (key.isNotEmpty && text.isNotEmpty) {
      normalizedValues[key] = text;
    }
  }

  if (normalizedValues[normalizedCode]?.trim().isNotEmpty == true) {
    return normalizedValues[normalizedCode]!.trim();
  }

  if (normalizedValues[normalizedFallbackLocale]?.trim().isNotEmpty == true) {
    return normalizedValues[normalizedFallbackLocale]!.trim();
  }

  for (final locale in kTourTranslationLocales) {
    if (normalizedValues[locale]?.trim().isNotEmpty == true) {
      return normalizedValues[locale]!.trim();
    }
  }

  for (final value in normalizedValues.values) {
    final text = value.trim();
    if (text.isNotEmpty) {
      return text;
    }
  }

  return '';
}

List<String> localizedListForLocale(
  Map<String, List<String>> values,
  String localeCode, {
  String fallbackLocale = 'kg',
}) {
  final normalizedCode = normalizeTourLanguageCode(localeCode);
  final normalizedFallbackLocale = normalizeTourLanguageCode(fallbackLocale);
  final normalizedValues = <String, List<String>>{};

  for (final entry in values.entries) {
    final key = normalizeTourLanguageCode(entry.key);
    final items = entry.value
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (key.isNotEmpty && items.isNotEmpty) {
      normalizedValues[key] = items;
    }
  }

  if (normalizedValues[normalizedCode]?.isNotEmpty == true) {
    return normalizedValues[normalizedCode]!;
  }

  if (normalizedValues[normalizedFallbackLocale]?.isNotEmpty == true) {
    return normalizedValues[normalizedFallbackLocale]!;
  }

  for (final locale in kTourTranslationLocales) {
    if (normalizedValues[locale]?.isNotEmpty == true) {
      return normalizedValues[locale]!;
    }
  }

  for (final items in normalizedValues.values) {
    if (items.isNotEmpty) {
      return items;
    }
  }

  return const [];
}
