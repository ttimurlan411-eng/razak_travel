import 'package:flutter/material.dart';
import 'package:razak_travel/data/models/booking_model.dart';
import 'package:razak_travel/data/models/category_model.dart';
import 'package:razak_travel/data/models/tour_model.dart';
import 'package:razak_travel/data/repositories/booking_repository.dart';
import 'package:razak_travel/data/repositories/tour_repository.dart';
import 'package:razak_travel/features/admin/add_tour_screen.dart';
import 'package:razak_travel/features/admin/widgets/admin_access_guard.dart';
import 'package:razak_travel/core/localization/app_localizations.dart';
import 'package:razak_travel/shared/widgets/app_card.dart';
import 'package:razak_travel/shared/widgets/app_empty_state.dart';
import 'package:razak_travel/shared/widgets/app_loader.dart';
import 'package:razak_travel/shared/widgets/app_network_image.dart';
import 'package:razak_travel/shared/widgets/language_switcher.dart';

class AdminTourListScreen extends StatefulWidget {
  const AdminTourListScreen({
    super.key,
    required this.category,
  });

  final CategoryModel category;

  @override
  State<AdminTourListScreen> createState() => _AdminTourListScreenState();
}

class _AdminTourListScreenState extends State<AdminTourListScreen> {
  final TourRepository _tourRepository = TourRepository();
  final TextEditingController _searchController = TextEditingController();
  List<TourModel> _tours = [];
  bool _isLoading = true;
  String? _error;
  final Set<String> _deletingTourIds = {};

  @override
  void initState() {
    super.initState();
    _loadTours();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(() => setState(() {}))
      ..dispose();
    super.dispose();
  }

  Future<void> _loadTours() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tours = await _tourRepository.getToursByCategory(
        widget.category.id,
      );
      if (!mounted) {
        return;
      }
      tours.sort((a, b) => a.date.compareTo(b.date));
      setState(() {
        _tours = tours;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;
    final categoryName = widget.category.localizedName(localeCode).trim();

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            categoryName.isEmpty
                ? l10n.translate('manage_tours')
                : categoryName,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadTours,
            ),
            const LanguageSwitcher(),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadTours,
          child: _buildBody(l10n, localeCode),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddTourScreen()),
            );
            _loadTours();
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, String localeCode) {
    if (_isLoading) {
      return const AppLoader();
    }

    if (_error != null) {
      return AppEmptyState(
        message: l10n.translate('error_generic'),
        icon: Icons.error_outline,
      );
    }

    final filteredTours = _filterTours(_tours);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText:
                  '${l10n.translate('tour_title')}, ${l10n.translate('destination')}',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: _searchController.clear,
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _tours.isEmpty
                ? AppEmptyState(
                    message: l10n.translate('no_tours_found'),
                    icon: Icons.card_travel_outlined,
                  )
                : filteredTours.isEmpty
                    ? AppEmptyState(
                        message: l10n.translate('no_tours_found'),
                        icon: Icons.search_off_outlined,
                      )
                    : ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: filteredTours.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final tour = filteredTours[index];
                          final localizedName = tour.localizedName(localeCode);
                          final localizedDescription =
                              tour.localizedDescription(localeCode);

                          return AppCard(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminTourDetailsScreen(
                                    category: widget.category,
                                    tour: tour,
                                  ),
                                ),
                              );
                            },
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _TourThumb(imageUrl: tour.primaryImage),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        localizedName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          if (tour.destination
                                              .trim()
                                              .isNotEmpty)
                                            _TourMetaPill(
                                              icon: Icons.location_on_outlined,
                                              label: tour.destination,
                                            ),
                                          _TourMetaPill(
                                            icon: Icons.event_outlined,
                                            label: tour.date
                                                .toIso8601String()
                                                .split('T')
                                                .first,
                                          ),
                                        ],
                                      ),
                                      if (localizedDescription.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          localizedDescription,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Text(
                                        '\$${tour.price.toStringAsFixed(2)}',
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${l10n.translate('booked_seats')}: ${tour.bookedSeats}/${tour.totalSeats}',
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    IconButton(
                                      onPressed: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                AddTourScreen(tour: tour),
                                          ),
                                        );
                                        _loadTours();
                                      },
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      onPressed:
                                          _deletingTourIds.contains(tour.id)
                                              ? null
                                              : () => _deleteTour(tour.id),
                                      icon: _deletingTourIds.contains(tour.id)
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(Icons.delete_outline),
                                    ),
                                    const SizedBox(height: 4),
                                    const Icon(Icons.chevron_right_rounded),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  List<TourModel> _filterTours(List<TourModel> tours) {
    return tours
        .where((tour) => tour.matchesSearchQuery(_searchController.text))
        .toList(growable: false);
  }

  Future<void> _deleteTour(String id) async {
    setState(() => _deletingTourIds.add(id));
    final l10n = AppLocalizations.of(context);

    try {
      await _tourRepository.deleteTour(id);
      if (!mounted) {
        return;
      }
      setState(() {
        _tours.removeWhere((t) => t.id == id);
        _deletingTourIds.remove(id);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _deletingTourIds.remove(id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error == 'tour_has_linked_bookings'
                ? l10n.translate('tour_has_linked_bookings')
                : l10n.translate('error_generic'),
          ),
        ),
      );
    }
  }
}

class AdminTourDetailsScreen extends StatefulWidget {
  const AdminTourDetailsScreen({
    super.key,
    required this.category,
    required this.tour,
  });

  final CategoryModel category;
  final TourModel tour;

  @override
  State<AdminTourDetailsScreen> createState() => _AdminTourDetailsScreenState();
}

class _AdminTourDetailsScreenState extends State<AdminTourDetailsScreen> {
  final BookingRepository _bookingRepository = BookingRepository();
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
    // ignore: avoid_print
    print('TOUR ID SCREEN: ${widget.tour.id}');
    setState(() => _isLoading = true);
    try {
      final localeCode = Localizations.localeOf(context).languageCode;
      final bookings = await _bookingRepository.getBookingsForTour(
        widget.tour.id,
        localeCode: localeCode,
      );
      // ignore: avoid_print
      print('BOOKINGS COUNT: ${bookings.length}');
      if (!mounted) {
        return;
      }
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (error) {
      // ignore: avoid_print
      print('LOAD BOOKINGS ERROR: $error');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;
    final categoryName = widget.category.localizedName(localeCode).trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tour.localizedName(localeCode)),
        actions: const [LanguageSwitcher()],
      ),
      body: RefreshIndicator(
        onRefresh: _loadBookings,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.tour.localizedName(localeCode),
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (categoryName.isNotEmpty)
                        _TourMetaPill(
                          icon: Icons.category_outlined,
                          label: categoryName,
                        ),
                      if (widget.tour.destination.trim().isNotEmpty)
                        _TourMetaPill(
                          icon: Icons.location_on_outlined,
                          label: widget.tour.destination,
                        ),
                      _TourMetaPill(
                        icon: Icons.attach_money_outlined,
                        label: '\$${widget.tour.price.toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.translate('bookings'),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const AppLoader()
            else if (_bookings.isEmpty)
              AppEmptyState(
                message: l10n.translate('no_bookings_found'),
                icon: Icons.receipt_long_outlined,
              )
            else
              ..._bookings.map(
                (booking) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BookingCard(
                    booking: booking,
                    loadingIds: _loadingBookingIds,
                    onApprove: booking.isPending
                        ? () async {
                            final bookingId = booking.id;
                            setState(() => _loadingBookingIds.add(bookingId));
                            try {
                              final updated = await _bookingRepository
                                  .approveBooking(bookingId);
                              if (!mounted) return;
                              setState(() {
                                final i = _bookings
                                    .indexWhere((b) => b.id == bookingId);
                                if (i != -1) {
                                  _bookings[i] = updated;
                                }
                                _loadingBookingIds.remove(bookingId);
                              });
                            } catch (error) {
                              if (!mounted) return;
                              setState(
                                  () => _loadingBookingIds.remove(bookingId));
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
                    onDelete: booking.isPending
                        ? () async {
                            final bookingId = booking.id;
                            setState(() => _loadingBookingIds.add(bookingId));
                            try {
                              await _bookingRepository.deleteBooking(bookingId);
                              if (!mounted) return;
                              setState(() {
                                _bookings.removeWhere((b) => b.id == bookingId);
                                _loadingBookingIds.remove(bookingId);
                              });
                            } catch (e, s) {
                              debugPrint('REVIEW ERROR: $e');
                              debugPrintStack(stackTrace: s);
                              if (!mounted) return;
                              setState(
                                  () => _loadingBookingIds.remove(bookingId));
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
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.loadingIds,
    this.onApprove,
    this.onDelete,
  });

  final BookingModel booking;
  final Set<String> loadingIds;
  final Future<void> Function()? onApprove;
  final Future<void> Function()? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final categoryName = booking.categoryName.trim();
    final tourName = booking.tourName.trim();
    final title = categoryName.isNotEmpty && tourName.isNotEmpty
        ? '$categoryName → $tourName'
        : (tourName.isNotEmpty ? tourName : categoryName);
    final displayDate = (booking.tourDate ?? booking.departureDate);
    final priceDisplay =
        booking.price > 0 ? '\$${booking.price.toStringAsFixed(2)}' : '';
    final dateFormat = MaterialLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
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
            _BookingInfoRow(
              label: 'Status',
              value: _statusLabel(l10n, booking.status),
            ),
            if (booking.pickupNotes.trim().isNotEmpty)
              _BookingInfoRow(
                label: 'Notes',
                value: booking.pickupNotes,
              ),
            const SizedBox(height: 12),
            if (booking.isPending)
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed:
                          onApprove == null || loadingIds.contains(booking.id)
                              ? null
                              : () async {
                                  await onApprove!();
                                },
                      child: loadingIds.contains(booking.id)
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          onDelete == null || loadingIds.contains(booking.id)
                              ? null
                              : () async {
                                  await onDelete!();
                                },
                      child: loadingIds.contains(booking.id)
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
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: booking.isApproved
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  booking.isApproved
                      ? l10n.translate('approved')
                      : l10n.translate('cancelled'),
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: booking.isApproved
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
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

class _TourMetaPill extends StatelessWidget {
  const _TourMetaPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _TourThumb extends StatelessWidget {
  const _TourThumb({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 82,
        height: 96,
        child: AppNetworkImage(
          imageUrl: imageUrl,
          placeholder: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
            ),
            child: Icon(
              Icons.photo_library_outlined,
              color: colorScheme.primary,
            ),
          ),
          errorPlaceholder: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
            ),
            child: Icon(
              Icons.broken_image_outlined,
              color: colorScheme.primary,
            ),
          ),
        ),
      ),
    );
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
