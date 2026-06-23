import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:razak_travel/core/localization/app_localizations.dart';

class LocaleController extends ChangeNotifier {
  LocaleController();

  static const String _storageKey = 'selected_language_code';

  Locale _currentLocale = const Locale('en');

  Locale get currentLocale => _currentLocale;
  Locale get locale => _currentLocale;

  Future<void> loadLocale() async {
    final preferences = await SharedPreferences.getInstance();
    final storedCode = preferences.getString(_storageKey);
    _currentLocale = AppLocalizations.resolveLocale(Locale(storedCode ?? 'en'));
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    final resolvedLocale = AppLocalizations.resolveLocale(Locale(languageCode));
    if (_currentLocale == resolvedLocale) {
      return;
    }

    _currentLocale = resolvedLocale;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, _currentLocale.languageCode);
  }
}
