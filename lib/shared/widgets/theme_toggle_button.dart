import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razak_travel/core/localization/app_localizations.dart';
import 'package:razak_travel/shared/theme/theme_controller.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final l10n = AppLocalizations.of(context);

    return IconButton(
      tooltip: l10n.text(
        themeController.isDarkMode ? 'light_mode' : 'dark_mode',
      ),
      onPressed: themeController.toggleTheme,
      icon: Icon(
        themeController.isDarkMode
            ? Icons.light_mode_outlined
            : Icons.dark_mode_outlined,
      ),
    );
  }
}
