import 'package:flutter/material.dart';
import 'package:razak_travel/data/models/booking_model.dart';
import 'package:razak_travel/data/repositories/booking_repository.dart';
import 'package:razak_travel/features/admin/widgets/admin_access_guard.dart';
import 'package:razak_travel/shared/localization/app_localizations.dart';
import 'package:razak_travel/shared/widgets/app_card.dart';
import 'package:razak_travel/shared/widgets/app_empty_state.dart';
import 'package:razak_travel/shared/widgets/app_loader.dart';
import 'package:razak_travel/shared/widgets/language_switcher.dart';
import 'package:razak_travel/shared/widgets/theme_toggle_button.dart';

class AdminBookingScreen extends StatefulWidget {
  const AdminBookingScreen({super.key});

  @override
  State<AdminBookingScreen> createState() => _AdminBookingScreenState();
}

class _AdminBookingScreenState extends State<AdminBookingScreen> {
  final BookingRepository _repository = BookingRepository();
  List<BookingModel> _bookings = [];
  bool _isLoading = true;
  final Set<String> _loadingBookingIds = {};
  bool _didInit = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      _didInit = true;
      _loadBookings();
    }
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final localeCode = Localizations.localeOf(context).languageCode;
      final bookings = await _repository.getAllBookings(
        localeCode: localeCode,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.translate('manage_bookings')),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadBookings,
            ),
            const ThemeToggleButton(),
            const LanguageSwitcher(),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadBookings,
          child: _buildBody(l10n),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const AppLoader();
    }

    if (_bookings.isEmpty) {
      return AppEmptyState(
        message: l10n.translate('no_bookings_found'),
        icon: Icons.receipt_long_outlined,
      );
    }

    final dateFormat = MaterialLocalizations.of(context);

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _bookings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final booking = _bookings[index];
        final categoryName = booking.categoryName.trim();
        final tourName = booking.tourName.trim();
        final title = categoryName.isNotEmpty && tourName.isNotEmpty
            ? '$categoryName → $tourName'
            : (tourName.isNotEmpty ? tourName : categoryName);
        final displayDate = (booking.tourDate ?? booking.departureDate);
        final priceDisplay = booking.price > 0
            ? '\$${booking.price.toStringAsFixed(2)}'
            : '';
        final statusLabel = _statusLabel(l10n, booking.status);

        return AppCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _BookingInfoRow(
                  label: 'Customer',
                  value: booking.displayUserName,
                ),
                if (booking.phone.trim().isNotEmpty)
                  _BookingInfoRow(label: 'Phone', value: booking.phone),
                _BookingInfoRow(label: 'Guests', value: '${booking.seatCount}'),
                if (displayDate != null)
                  _BookingInfoRow(
                    label: 'Date',
                    value: dateFormat.formatMediumDate(displayDate),
                  ),
                if (priceDisplay.isNotEmpty)
                  _BookingInfoRow(label: 'Price', value: priceDisplay),
                _BookingInfoRow(label: 'Status', value: statusLabel),
                if (booking.pickupNotes.trim().isNotEmpty)
                  _BookingInfoRow(
                    label: 'Notes',
                    value: booking.pickupNotes,
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: booking.isPending &&
                                !_loadingBookingIds.contains(booking.id)
                            ? () async {
                                final bookingId = booking.id;
                                setState(() =>
                                    _loadingBookingIds.add(bookingId));
                                try {
                                  final updated = await _repository
                                      .approveBooking(bookingId);
                                  if (!mounted) return;
                                  setState(() {
                                    final i = _bookings.indexWhere(
                                        (b) => b.id == bookingId);
                                    if (i != -1) {
                                      _bookings[i] = updated;
                                    }
                                    _loadingBookingIds.remove(bookingId);
                                  });
                                } catch (_) {
                                  if (!mounted) return;
                                  setState(() =>
                                      _loadingBookingIds.remove(bookingId));
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n.translate('error_generic'),
                                      ),
                                    ),
                                  );
                                }
                              }
                            : null,
                        child: _loadingBookingIds.contains(booking.id)
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l10n.translate('approve')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _loadingBookingIds.contains(booking.id)
                            ? null
                            : () async {
                                final bookingId = booking.id;
                                setState(() =>
                                    _loadingBookingIds.add(bookingId));
                                try {
                                  await _repository
                                      .deleteBooking(bookingId);
                                  if (!mounted) return;
                                  setState(() {
                                    _bookings.removeWhere(
                                        (b) => b.id == bookingId);
                                    _loadingBookingIds.remove(bookingId);
                                  });
                                } catch (_) {
                                  if (!mounted) return;
                                  setState(() =>
                                      _loadingBookingIds.remove(bookingId));
                                }
                              },
                        child: _loadingBookingIds.contains(booking.id)
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l10n.translate('delete')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _statusLabel(AppLocalizations l10n, String status) {
    switch (status) {
      case 'pending':
        return l10n.translate('pending');
      case 'approved':
        return l10n.translate('approved');
      case 'cancelled':
        return l10n.translate('cancelled');
      default:
        return status;
    }
  }
}

class _BookingInfoRow extends StatelessWidget {
  const _BookingInfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
