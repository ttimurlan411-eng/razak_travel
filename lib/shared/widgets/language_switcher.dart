import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razak_travel/core/localization/app_localizations.dart';
import 'package:razak_travel/core/localization/locale_controller.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentLanguageCode =
        context.watch<LocaleController>().currentLocale.languageCode;

    return PopupMenuButton<String>(
      initialValue: currentLanguageCode,
      icon: const Icon(Icons.language),
      onSelected: (String languageCode) {
        context.read<LocaleController>().setLocale(languageCode);
      },
      itemBuilder: (BuildContext context) {
        return AppLocalizations.supportedLocaleCodes.map((String languageCode) {
          return PopupMenuItem<String>(
            value: languageCode,
            child: Text(l10n.languageName(languageCode)),
          );
        }).toList();
      },
    );
  }
}
