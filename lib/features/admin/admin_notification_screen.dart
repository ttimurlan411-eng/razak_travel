import 'package:flutter/material.dart';
import 'package:razak_travel/data/models/app_notification_model.dart';
import 'package:razak_travel/data/models/category_model.dart';
import 'package:razak_travel/data/models/tour_model.dart';
import 'package:razak_travel/data/repositories/category_repository.dart';
import 'package:razak_travel/data/repositories/notification_repository.dart';
import 'package:razak_travel/data/repositories/tour_repository.dart';
import 'package:razak_travel/features/admin/widgets/admin_access_guard.dart';
import 'package:razak_travel/core/localization/app_localizations.dart';
import 'package:razak_travel/shared/widgets/app_card.dart';
import 'package:razak_travel/shared/widgets/app_empty_state.dart';
import 'package:razak_travel/shared/widgets/app_loader.dart';
import 'package:razak_travel/shared/widgets/language_switcher.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  State<AdminNotificationScreen> createState() =>
      _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  final NotificationRepository _notificationRepository =
      NotificationRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();
  final TourRepository _tourRepository = TourRepository();

  List<CategoryModel> _categories = [];
  List<TourModel> _tours = [];
  List<AppNotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _loadingNotificationId;

  String? _selectedCategoryId;
  String? selectedTour;
  String? _selectedTourId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _categoryRepository.getCategories(),
        _tourRepository.getAllTours(),
        _notificationRepository.getNotifications(includeAll: true),
      ]);

      if (!mounted) {
        return;
      }

      final tours = (results[1] as List<TourModel>)
        ..sort(
          (left, right) => left.name.toLowerCase().compareTo(
                right.name.toLowerCase(),
              ),
        );

      setState(() {
        _categories = results[0] as List<CategoryModel>;
        _tours = tours;
        _notifications = results[2] as List<AppNotificationModel>;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleNotificationTap(
    BuildContext context,
    AppLocalizations l10n,
    AppNotificationModel notification,
  ) async {
    if (notification.read || _loadingNotificationId == notification.id) {
      return;
    }

    setState(() => _loadingNotificationId = notification.id);

    try {
      await _notificationRepository.markAsRead(notification.id);
      if (!mounted) return;
      setState(() {
        final i = _notifications.indexWhere((n) => n.id == notification.id);
        if (i != -1) {
          _notifications[i] = notification.copyWith(read: true);
        }
        _loadingNotificationId = null;
      });
    } catch (e, s) {
      debugPrint('REVIEW ERROR: $e');
      debugPrintStack(stackTrace: s);
      if (!mounted) return;
      setState(() => _loadingNotificationId = null);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.text('error_generic')),
        ),
      );
    }
  }

  List<TourModel> _filteredTours(List<TourModel> tours) {
    if (_selectedCategoryId == null) {
      return tours;
    }

    return tours
        .where((tour) => tour.categoryId == _selectedCategoryId)
        .toList(growable: false);
  }

  List<AppNotificationModel> _filteredNotifications(
    List<AppNotificationModel> notifications, {
    required List<TourModel> availableTours,
  }) {
    final selectedTourId = selectedTour?.trim() ?? '';
    if (selectedTourId.isEmpty) {
      return notifications;
    }

    final hasSelectedTour = availableTours.any(
      (tour) => tour.id.trim() == selectedTourId,
    );
    if (!hasSelectedTour) {
      return notifications;
    }

    return notifications
        .where((notification) => notification.tourId.trim() == selectedTourId)
        .toList(growable: false);
  }

  void _onCategoryChanged(
    String? value,
  ) {
    setState(() {
      _selectedCategoryId = value;

      final availableTourIds =
          _filteredTours(_tours).map((tour) => tour.id).toSet();
      if (selectedTour != null && !availableTourIds.contains(selectedTour)) {
        selectedTour = null;
      }
      if (_selectedTourId != null &&
          !availableTourIds.contains(_selectedTourId)) {
        _selectedTourId = null;
      }
    });
  }

  void _onTourChanged(String? value) {
    setState(() {
      selectedTour = value;
      _selectedTourId = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.text('notifications')),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
            ),
            const LanguageSwitcher(),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadData,
          child: _isLoading ? const AppLoader() : _buildBody(l10n, localeCode),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, String localeCode) {
    final tours = _filteredTours(_tours);
    final filteredNotifications = _filteredNotifications(
      _notifications,
      availableTours: tours,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        children: [
          _NotificationFiltersCard(
            l10n: l10n,
            localeCode: localeCode,
            categories: _categories,
            tours: tours,
            selectedCategoryId: _selectedCategoryId,
            selectedTourId: selectedTour,
            onCategoryChanged: _onCategoryChanged,
            onTourChanged: _onTourChanged,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _notifications.isEmpty
                ? AppEmptyState(
                    message: l10n.text('no_notifications_found'),
                    icon: Icons.notifications_none_outlined,
                  )
                : filteredNotifications.isEmpty
                    ? AppEmptyState(
                        message: l10n.text('no_notifications_found'),
                        icon: Icons.filter_alt_off_outlined,
                      )
                    : ListView.separated(
                        itemCount: filteredNotifications.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final notification = filteredNotifications[index];
                          return _AdminNotificationTile(
                            notification: notification,
                            onTap: () {
                              _handleNotificationTap(
                                context,
                                l10n,
                                notification,
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _NotificationFiltersCard extends StatelessWidget {
  const _NotificationFiltersCard({
    required this.l10n,
    required this.localeCode,
    required this.categories,
    required this.tours,
    required this.selectedCategoryId,
    required this.selectedTourId,
    required this.onCategoryChanged,
    required this.onTourChanged,
  });

  final AppLocalizations l10n;
  final String localeCode;
  final List<CategoryModel> categories;
  final List<TourModel> tours;
  final String? selectedCategoryId;
  final String? selectedTourId;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onTourChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasTours = tours.isNotEmpty;
    final categoryDropdown = DropdownButtonFormField<String>(
      initialValue: selectedCategoryId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.text('categories'),
        prefixIcon: const Icon(Icons.category_outlined),
      ),
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text(l10n.text('status_all')),
        ),
        ...categories.map(
          (category) => DropdownMenuItem<String>(
            value: category.id,
            child: Text(category.localizedName(localeCode)),
          ),
        ),
      ],
      onChanged: onCategoryChanged,
    );
    final tourDropdown = DropdownButtonFormField<String>(
      initialValue: selectedTourId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.text('tours'),
        prefixIcon: const Icon(Icons.map_outlined),
        filled: !hasTours,
        fillColor: hasTours ? null : colorScheme.surfaceContainerHighest,
      ),
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text(l10n.text('status_all')),
        ),
        ...tours.map(
          (tour) => DropdownMenuItem<String>(
            value: tour.id,
            child: Text(tour.localizedName(localeCode)),
          ),
        ),
      ],
      onChanged: hasTours ? onTourChanged : null,
    );

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 640;
          if (isWide) {
            return Row(
              children: [
                Expanded(child: categoryDropdown),
                const SizedBox(width: 12),
                Expanded(child: tourDropdown),
              ],
            );
          }

          return Column(
            children: [
              categoryDropdown,
              const SizedBox(height: 12),
              tourDropdown,
            ],
          );
        },
      ),
    );
  }
}

class _AdminNotificationTile extends StatelessWidget {
  const _AdminNotificationTile({
    required this.notification,
    required this.onTap,
  });

  final AppNotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUnread = !notification.read;
    final backgroundColor = isUnread
        // ignore: deprecated_member_use
        ? colorScheme.primaryContainer.withOpacity(0.4)
        : colorScheme.surface;
    final borderColor = isUnread
        // ignore: deprecated_member_use
        ? colorScheme.primary.withOpacity(0.35)
        : colorScheme.outlineVariant;
    final icon = switch (notification.type) {
      'payment' => Icons.payments_outlined,
      'booking' => Icons.receipt_long_outlined,
      _ => Icons.notifications_none_outlined,
    };
    final timestamp = _formatTimestamp(context, notification.timestamp);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        leading: CircleAvatar(
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.primary,
          child: Icon(icon),
        ),
        title: Text(
          notification.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: isUnread ? FontWeight.w800 : FontWeight.w400,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (notification.message.isNotEmpty)
                Text(
                  notification.message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                    fontWeight: isUnread ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              if (timestamp.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (isUnread) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Icon(
                      Icons.schedule_outlined,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        timestamp,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(BuildContext context, DateTime? value) {
    if (value == null) {
      return '';
    }

    final localDateTime = value.toLocal();
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatMediumDate(localDateTime);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(localDateTime),
    );
    return '$date, $time';
  }
}
