import 'package:flutter/material.dart';
import 'package:razak_travel/features/admin/admin_booking_screen.dart';
import 'package:razak_travel/features/admin/admin_management_screen.dart';
import 'package:razak_travel/features/admin/admin_notification_screen.dart';
import 'package:razak_travel/features/admin/category_list_screen.dart';
import 'package:razak_travel/features/admin/widgets/admin_access_guard.dart';
import 'package:razak_travel/shared/localization/app_localizations.dart';
import 'package:razak_travel/shared/widgets/app_button.dart';
import 'package:razak_travel/shared/widgets/language_switcher.dart';
import 'package:razak_travel/shared/widgets/theme_toggle_button.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.text('admin_dashboard')),
          actions: const [ThemeToggleButton(), LanguageSwitcher()],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppButton(
                text: l10n.text('manage_categories'),
                onPressed: () {
                  _openScreen(context, const AdminCategoryListScreen());
                },
              ),
              const SizedBox(height: 12),
              AppButton(
                text: l10n.text('manage_bookings'),
                onPressed: () {
                  _openScreen(context, const AdminBookingScreen());
                },
              ),
              const SizedBox(height: 12),
              AppButton(
                text: l10n.text('notifications'),
                onPressed: () {
                  _openScreen(context, const AdminNotificationScreen());
                },
              ),
              const SizedBox(height: 12),
              AppButton(
                text: l10n.text('admin_management'),
                onPressed: () {
                  _openScreen(context, const AdminManagementScreen());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}
