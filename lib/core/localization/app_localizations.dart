import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;
  late final Map<String, String> _localizedValues;

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('ky'),
    Locale('kk'),
    Locale('tr'),
  ];

  static const List<String> supportedLocaleCodes = <String>[
    'en',
    'ru',
    'ky',
    'kk',
    'tr',
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(localizations != null, 'AppLocalizations not found in context.');
    return localizations!;
  }

  static Locale resolveLocale(Locale? locale) {
    final code = normalizeLanguageCode(locale?.languageCode);
    for (final supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == code) {
        return supportedLocale;
      }
    }
    return const Locale('en');
  }

  static String normalizeLanguageCode(String? code) {
    final normalized = (code ?? 'en').trim().toLowerCase();
    if (normalized == 'kg') {
      return 'ky';
    }
    if (normalized == 'kz') {
      return 'kk';
    }
    if (supportedLocaleCodes.contains(normalized)) {
      return normalized;
    }
    return 'en';
  }

  Future<void> load() async {
    final englishValues = await _loadJsonMap('en');
    final languageCode = normalizeLanguageCode(locale.languageCode);

    if (languageCode == 'en') {
      _localizedValues = englishValues;
      return;
    }

    final localizedValues = await _loadJsonMap(languageCode);
    _localizedValues = <String, String>{
      ...englishValues,
      ...localizedValues,
    };
  }

  String text(String key) {
    return _localizedValues[key] ?? key;
  }

  String translate(String key, {List<Object?> args = const []}) {
    var value = text(key);
    for (var index = 0; index < args.length; index++) {
      value = value.replaceAll('{$index}', '${args[index] ?? ''}');
    }
    return value;
  }

  String languageName(String localeCode) {
    const labelKeys = <String, String>{
      'en': 'language_english',
      'ru': 'language_russian',
      'ky': 'language_kyrgyz',
      'kk': 'language_kazakh',
      'tr': 'language_turkish',
    };

    final normalizedCode = normalizeLanguageCode(localeCode);
    final labelKey = labelKeys[normalizedCode];
    if (labelKey == null) {
      return normalizedCode;
    }
    return text(labelKey);
  }

  Future<Map<String, String>> _loadJsonMap(String languageCode) async {
    final assetLanguageCode = languageCode == 'ky' ? 'kg' : languageCode;
    final jsonString = await rootBundle.loadString(
      'assets/lang/$assetLanguageCode.json',
    );
    final dynamic decoded = json.decode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      return <String, String>{};
    }

    final values = <String, String>{};
    decoded.forEach((key, value) {
      values[key] = value.toString();
    });
    return values;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    final code = AppLocalizations.normalizeLanguageCode(locale.languageCode);
    return AppLocalizations.supportedLocaleCodes.contains(code);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(
      AppLocalizations.resolveLocale(locale),
    );
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}
