import 'dart:async';

import 'package:flutter/material.dart';
import 'package:razak_travel/core/services/media_upload_service.dart';
import 'package:razak_travel/data/models/category_model.dart';
import 'package:razak_travel/data/models/model_parsers.dart';
import 'package:razak_travel/data/models/tour_model.dart';
import 'package:razak_travel/data/repositories/category_repository.dart';
import 'package:razak_travel/data/repositories/notification_repository.dart';
import 'package:razak_travel/data/repositories/tour_repository.dart';
import 'package:razak_travel/features/admin/widgets/admin_access_guard.dart';
import 'package:razak_travel/features/tours/models/tour_departure.dart';
import 'package:razak_travel/shared/localization/app_localizations.dart';
import 'package:razak_travel/shared/widgets/app_button.dart';
import 'package:razak_travel/shared/widgets/app_empty_state.dart';
import 'package:razak_travel/shared/widgets/app_loader.dart';
import 'package:razak_travel/shared/widgets/language_switcher.dart';
import 'package:uuid/uuid.dart';

class AddTourScreen extends StatefulWidget {
  const AddTourScreen({super.key, this.tour});

  final TourModel? tour;

  @override
  State<AddTourScreen> createState() => _AddTourScreenState();
}

class _AddTourScreenState extends State<AddTourScreen>
    with SingleTickerProviderStateMixin {
  final CategoryRepository _categoryRepository = CategoryRepository();
  final TourRepository _tourRepository = TourRepository();
  final MediaUploadService _mediaUploadService = MediaUploadService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final Future<List<CategoryModel>> _categoriesFuture;
  final Map<String, TextEditingController> _nameControllers = {};
  final Map<String, TextEditingController> _descriptionControllers = {};
  final Map<String, TextEditingController> _includedControllers = {};
  final Map<String, TextEditingController> _placesControllers = {};
  final Map<String, TextEditingController> _whatToBringControllers = {};
  final Map<String, TextEditingController> _extraInfoControllers = {};
  final Map<String, TextEditingController> _departureTimeControllers = {};
  final Map<String, TextEditingController> _returnTimeTextControllers = {};
  final Map<String, TextEditingController> _meetingPointControllers = {};
  final Map<String, TextEditingController> _meetingAddressControllers = {};
  final Map<String, TextEditingController> _landmarkControllers = {};
  final Map<String, TextEditingController> _pickupInstructionsControllers = {};
  late final TextEditingController _destinationController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _galleryImagesController;
  late final TextEditingController _priceController;
  late final TextEditingController _dateController;
  late final TextEditingController _returnDateController;
  late final TextEditingController _totalSeatsController;
  late final TextEditingController _departureGoogleMapsUrlController;
  late final TextEditingController _departureLatitudeController;
  late final TextEditingController _departureLongitudeController;
  final Map<String, TextEditingController> _guidePhoneControllers = {};
  final Map<String, TextEditingController> _guideWhatsappControllers = {};
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final TabController _tabController;
  late final List<String> _locales;
  final List<_DepartureFormData> _additionalDepartureForms = [];
  List<String> _imageUrls = [];
  int _currentLocaleIndex = 0;
  String _selectedCategoryId = '';
  late final String _primaryDepartureId;
  String _primaryPickupType = TourDeparturePickupType.meetingPoint;
  int _primaryBookedSeats = 0;
  bool isLoading = false;
  bool _isSaving = false;
  bool _isLoadingDepartures = false;
  bool _isUploadingImages = false;
  bool _isSyncingImageControllers = false;
  bool _showTranslations = false;
  // ignore: unused_field, prefer_final_fields
  bool _submitted = false;
  final NotificationRepository _notificationRepository =
      NotificationRepository();

  String get imageUrl => _imageUrlController.text.trim();
  String get _primaryPreviewImageUrl {
    if (imageUrl.isNotEmpty) {
      return imageUrl;
    }

    if (_imageUrls.isNotEmpty) {
      return _imageUrls.first;
    }

    return '';
  }

  @override
  void initState() {
    super.initState();
    _locales = kTourTranslationLocales;
    _categoriesFuture = _categoryRepository.getCategories().timeout(
          const Duration(seconds: 20),
        );
    for (final locale in _locales) {
      _nameControllers[locale] = TextEditingController(
        text: widget.tour?.title[locale] ??
            widget.tour?.names[locale] ??
            '',
      );
      _descriptionControllers[locale] = TextEditingController(
        text: widget.tour?.descriptionMap[locale] ??
            widget.tour?.descriptions[locale] ??
            (locale == 'kg' ? widget.tour?.description ?? '' : ''),
      );
      _includedControllers[locale] = TextEditingController(
        text: widget.tour?.included[locale] ??
            widget.tour?.includedItems[locale]?.join('\n') ??
            '',
      );
      _placesControllers[locale] = TextEditingController(
        text: widget.tour?.notIncluded[locale] ??
            widget.tour?.placesToVisit[locale]?.join('\n') ??
            '',
      );
      _whatToBringControllers[locale] = TextEditingController(
        text: widget.tour?.whatToBring[locale] ?? '',
      );
      _extraInfoControllers[locale] = TextEditingController(
        text: widget.tour?.extraInfo[locale] ?? '',
      );
      _departureTimeControllers[locale] = TextEditingController(
        text: widget.tour?.departureTime[locale] ?? '',
      );
      _returnTimeTextControllers[locale] = TextEditingController(
        text: widget.tour?.returnTime[locale] ?? '',
      );
      _meetingPointControllers[locale] = TextEditingController();
      _meetingAddressControllers[locale] = TextEditingController();
      _landmarkControllers[locale] = TextEditingController();
      _pickupInstructionsControllers[locale] = TextEditingController();
      _guidePhoneControllers[locale] = TextEditingController(
        text: widget.tour?.guidePhone[locale] ?? '',
      );
      _guideWhatsappControllers[locale] = TextEditingController(
        text: widget.tour?.whatsapp[locale] ?? '',
      );
    }
    _destinationController = TextEditingController(
      text: widget.tour?.destination ?? '',
    );
    _imageUrlController = TextEditingController(
      text: widget.tour?.imageUrl.isNotEmpty == true
          ? widget.tour!.imageUrl
          : widget.tour?.primaryImage ?? '',
    );
    _galleryImagesController = TextEditingController(
      text: widget.tour == null
          ? ''
          : widget.tour!.galleryImages.skip(1).join('\n'),
    );
    _priceController = TextEditingController(
      text: widget.tour == null ? '' : widget.tour!.price.toString(),
    );
    _dateController = TextEditingController(
      text: widget.tour == null
          ? ''
          : widget.tour!.date.toIso8601String().split('T').first,
    );
    _returnDateController = TextEditingController(
      text: widget.tour == null
          ? ''
          : widget.tour!.date.toIso8601String().split('T').first,
    );
    _totalSeatsController = TextEditingController(
      text: widget.tour == null ? '' : widget.tour!.totalSeats.toString(),
    );
    _departureGoogleMapsUrlController = TextEditingController();
    _departureLatitudeController = TextEditingController();
    _departureLongitudeController = TextEditingController();
    _latitudeController = TextEditingController(
      text: widget.tour?.latitude?.toString() ?? '',
    );
    _longitudeController = TextEditingController(
      text: widget.tour?.longitude?.toString() ?? '',
    );
    _selectedCategoryId = widget.tour?.categoryId ?? '';
    _primaryDepartureId = widget.tour == null
        ? const Uuid().v4()
        : (widget.tour?.id ?? const Uuid().v4());
    _primaryBookedSeats = widget.tour?.bookedSeats ?? 0;
    _tabController = TabController(length: _locales.length, vsync: this);
    _tabController.addListener(_handleTabChanged);
    _imageUrls = _uniqueImageUrls([
      _imageUrlController.text,
      ..._parseLines(_galleryImagesController.text),
    ]);
    _imageUrlController.addListener(_syncImageStateFromControllers);
    _galleryImagesController.addListener(_syncImageStateFromControllers);
    if (widget.tour != null) {
      _isLoadingDepartures = true;
      _loadExistingDepartures();
    }
  }

  @override
  void dispose() {
    for (final controller in _nameControllers.values) {
      controller.dispose();
    }
    for (final controller in _descriptionControllers.values) {
      controller.dispose();
    }
    for (final controller in _includedControllers.values) {
      controller.dispose();
    }
    for (final controller in _placesControllers.values) {
      controller.dispose();
    }
    for (final controller in _whatToBringControllers.values) {
      controller.dispose();
    }
    for (final controller in _extraInfoControllers.values) {
      controller.dispose();
    }
    for (final controller in _departureTimeControllers.values) {
      controller.dispose();
    }
    for (final controller in _returnTimeTextControllers.values) {
      controller.dispose();
    }
    for (final controller in _meetingPointControllers.values) {
      controller.dispose();
    }
    for (final controller in _meetingAddressControllers.values) {
      controller.dispose();
    }
    for (final controller in _landmarkControllers.values) {
      controller.dispose();
    }
    for (final controller in _pickupInstructionsControllers.values) {
      controller.dispose();
    }
    for (final controller in _guidePhoneControllers.values) {
      controller.dispose();
    }
    for (final controller in _guideWhatsappControllers.values) {
      controller.dispose();
    }
    _destinationController.dispose();
    _imageUrlController.removeListener(_syncImageStateFromControllers);
    _galleryImagesController.removeListener(_syncImageStateFromControllers);
    _imageUrlController.dispose();
    _galleryImagesController.dispose();
    _priceController.dispose();
    _dateController.dispose();
    _returnDateController.dispose();
    _totalSeatsController.dispose();
    _departureGoogleMapsUrlController.dispose();
    _departureLatitudeController.dispose();
    _departureLongitudeController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    for (final departureForm in _additionalDepartureForms) {
      departureForm.dispose();
    }
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    if (!mounted || _tabController.indexIsChanging) {
      return;
    }

    setState(() {
      _currentLocaleIndex = _tabController.index;
    });
  }

  Future<void> _selectDateForController(TextEditingController controller) async {
    final initialDate = DateTime.tryParse(controller.text) ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (pickedDate != null) {
      setState(() {
        controller.text = pickedDate.toIso8601String().split('T').first;
      });
    }
  }

  Future<void> _loadExistingDepartures() async {
    if (widget.tour == null) {
      return;
    }

    try {
      final departures = await _tourRepository.getDeparturesForTour(
        widget.tour!.id,
      );
      if (!mounted || departures.isEmpty) {
        return;
      }

      for (final departureForm in _additionalDepartureForms) {
        departureForm.dispose();
      }

      final primaryDeparture = departures.first;
      _primaryDepartureId = primaryDeparture.id;
      _primaryBookedSeats = primaryDeparture.bookedSeats;
      _priceController.text = primaryDeparture.price.toString();
      _dateController.text =
          primaryDeparture.departureDate.toIso8601String().split('T').first;
      _returnDateController.text =
          primaryDeparture.returnDate.toIso8601String().split('T').first;
      _totalSeatsController.text = primaryDeparture.totalSeats.toString();
      _primaryPickupType = primaryDeparture.pickupType;
      _setLocalizedControllerTexts(
        _meetingPointControllers,
        primaryDeparture.meetingPointName,
      );
      _setLocalizedControllerTexts(
        _meetingAddressControllers,
        primaryDeparture.meetingAddress,
      );
      _setLocalizedControllerTexts(
        _landmarkControllers,
        primaryDeparture.landmark,
      );
      _setLocalizedControllerTexts(
        _pickupInstructionsControllers,
        primaryDeparture.pickupInstructions,
      );
      _setSingleValueAsPrimaryLocale(
        _guidePhoneControllers,
        primaryDeparture.guidePhone,
      );
      _setSingleValueAsPrimaryLocale(
        _guideWhatsappControllers,
        primaryDeparture.guideWhatsapp,
      );
      _departureGoogleMapsUrlController.text = primaryDeparture.googleMapsUrl;
      _departureLatitudeController.text =
          primaryDeparture.latitude?.toString() ?? '';
      _departureLongitudeController.text =
          primaryDeparture.longitude?.toString() ?? '';
      _additionalDepartureForms
        ..clear()
        ..addAll(
          departures.skip(1).map(_DepartureFormData.fromDeparture),
        );

      setState(() {});
    } catch (_) {
      if (!mounted) {
        return;
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDepartures = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.tour == null
                ? l10n.translate('add_tour')
                : l10n.translate('edit_tour'),
          ),
          actions: const [LanguageSwitcher()],
          bottom: _showTranslations
              ? TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: _locales
                      .map(
                        (locale) => Tab(text: l10n.languageName(locale)),
                      )
                      .toList(),
                )
              : null,
        ),
        body: SafeArea(
          child: FutureBuilder<List<CategoryModel>>(
          future: _categoriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoader();
            }

            if (snapshot.hasError) {
              return AppEmptyState(
                message: l10n.translate('error_generic'),
                icon: Icons.error_outline,
              );
            }

            final categories = snapshot.data ?? <CategoryModel>[];

            if (categories.isNotEmpty &&
                !categories.any(
              (category) => category.id == _selectedCategoryId,
            )) {
              _selectedCategoryId = categories.first.id;
            }

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.disabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (categories.isNotEmpty) ...[
                          DropdownButtonFormField<String>(
                            initialValue: _selectedCategoryId.isEmpty
                                ? null
                                : _selectedCategoryId,
                            items: categories
                                .map(
                                  (category) => DropdownMenuItem<String>(
                                    value: category.id,
                                    child: Text(
                                      category.localizedName(
                                        Localizations.localeOf(context)
                                            .languageCode,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategoryId = value ?? '';
                              });
                            },
                            decoration: InputDecoration(
                              labelText: l10n.translate('category'),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextFormField(
                          controller: _nameControllers['kg']!,
                          decoration: InputDecoration(
                            labelText: l10n.translate('tour_title'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.translate('tour_image'),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _imageUrlController,
                              keyboardType: TextInputType.url,
                              decoration: InputDecoration(
                                labelText: l10n.translate('image_url'),
                                hintText: l10n.translate('tour_image_url_hint'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed:
                                  isLoading || _isSaving || _isUploadingImages
                                      ? null
                                      : pickAndUploadImage,
                              icon: _isUploadingImages
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.upload_outlined),
                              label: Text(l10n.translate('upload_image')),
                            ),
                            if (_isUploadingImages) ...[
                              const SizedBox(height: 12),
                              const LinearProgressIndicator(),
                            ],
                            if (_imageUrls.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _TourImagePreview(
                                imageUrl: _primaryPreviewImageUrl,
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed:
                                    isLoading || _isSaving || _isUploadingImages
                                        ? null
                                        : () {
                                            setState(() {
                                              _setImageUrls(
                                                _imageUrls.skip(1).toList(),
                                              );
                                            });
                                          },
                                icon: const Icon(Icons.delete_sweep_outlined),
                                label: Text(_clearPrimaryImageLabel(context)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.translate('price'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: const EdgeInsets.only(bottom: 4),
                          initiallyExpanded: widget.tour != null,
                          title: Text(
                            l10n.translate('additional_info'),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          children: [
                            TextFormField(
                              controller: _destinationController,
                              decoration: InputDecoration(
                                labelText: l10n.translate('destination'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _galleryImagesController,
                              keyboardType: TextInputType.multiline,
                              minLines: 3,
                              maxLines: 5,
                              decoration: InputDecoration(
                                labelText:
                                    l10n.translate('tour_gallery_images'),
                                hintText: l10n.translate('image_urls_hint'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _TourGalleryPreview(
                              imageUrls: _imageUrls,
                              onRemoveImage: (index) {
                                setState(() {
                                  final nextImages = List<String>.from(_imageUrls)
                                    ..removeAt(index);
                                  _setImageUrls(nextImages);
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: isLoading ||
                                          _isSaving ||
                                          _isUploadingImages
                                      ? null
                                      : _uploadGalleryImages,
                                  icon: _isUploadingImages
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.collections_outlined,
                                        ),
                                  label:
                                      Text(l10n.translate('upload_images')),
                                ),
                                if (_imageUrls.isNotEmpty)
                                  OutlinedButton.icon(
                                    onPressed: isLoading ||
                                            _isSaving ||
                                            _isUploadingImages
                                        ? null
                                        : () {
                                            setState(() {
                                              _setImageUrls(const []);
                                            });
                                          },
                                    icon: const Icon(
                                      Icons.delete_sweep_outlined,
                                    ),
                                    label:
                                        Text(l10n.translate('clear_gallery')),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.translate('departure_dates'),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _dateController,
                              readOnly: true,
                              onTap: () =>
                                  _selectDateForController(_dateController),
                              decoration: InputDecoration(
                                labelText: l10n.translate('date'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _returnDateController,
                              readOnly: true,
                              onTap: () => _selectDateForController(
                                _returnDateController,
                              ),
                              decoration: InputDecoration(
                                labelText: l10n.translate('return_date'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _totalSeatsController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: l10n.translate('total_seats'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _DeparturePickupFields(
                              pickupType: _primaryPickupType,
                              onPickupTypeChanged: (value) {
                                setState(() {
                                  _primaryPickupType = value;
                                });
                              },
                              meetingPointController:
                                  _meetingPointControllers[
                                      _locales[_currentLocaleIndex]]!,
                              meetingAddressController:
                                  _meetingAddressControllers[
                                      _locales[_currentLocaleIndex]]!,
                              landmarkController:
                                  _landmarkControllers[
                                      _locales[_currentLocaleIndex]]!,
                              pickupInstructionsController:
                                  _pickupInstructionsControllers[
                                      _locales[_currentLocaleIndex]]!,
                              googleMapsUrlController:
                                  _departureGoogleMapsUrlController,
                              latitudeController:
                                  _departureLatitudeController,
                              longitudeController:
                                  _departureLongitudeController,
                              guidePhoneController:
                                  _guidePhoneControllers[
                                      _locales[_currentLocaleIndex]]!,
                              guideWhatsappController:
                                  _guideWhatsappControllers[
                                      _locales[_currentLocaleIndex]]!,
                            ),
                            const SizedBox(height: 12),
                            ..._additionalDepartureForms.map(
                              (departureForm) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _DepartureEditorCard(
                                  title:
                                      l10n.translate('additional_departure'),
                                  departureForm: departureForm,
                                  localeCode: _locales[_currentLocaleIndex],
                                  onPickupTypeChanged: (value) {
                                    setState(() {
                                      departureForm.pickupType = value;
                                    });
                                  },
                                  onSelectDepartureDate: () =>
                                      _selectDateForController(
                                    departureForm.departureDateController,
                                  ),
                                  onSelectReturnDate: () =>
                                      _selectDateForController(
                                    departureForm.returnDateController,
                                  ),
                                  onRemove: () {
                                    setState(() {
                                      departureForm.dispose();
                                      _additionalDepartureForms.remove(
                                        departureForm,
                                      );
                                    });
                                  },
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _isSaving || _isUploadingImages
                                  ? null
                                  : () {
                                      setState(() {
                                        _additionalDepartureForms.add(
                                          _DepartureFormData.create(),
                                        );
                                      });
                                    },
                              icon: const Icon(Icons.add_outlined),
                              label: Text(l10n.translate('add_departure')),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _latitudeController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                      signed: true,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: l10n.translate('latitude'),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _longitudeController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                      signed: true,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: l10n.translate('longitude'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _showTranslations = !_showTranslations;
                                  if (!_showTranslations) {
                                    _tabController.index = 0;
                                    _currentLocaleIndex = 0;
                                  }
                                });
                              },
                              icon: Icon(
                                _showTranslations
                                    ? Icons.translate_outlined
                                    : Icons.edit_note_outlined,
                              ),
                              label: Text(
                                l10n.translate(
                                  _showTranslations
                                      ? 'hide_translations'
                                      : 'edit_translations',
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _LocalizedTourFields(
                              localeCode: _locales[_currentLocaleIndex],
                              showTitleField: _showTranslations,
                              showExtendedFields: _showTranslations,
                              nameController: _nameControllers[
                                  _locales[_currentLocaleIndex]]!,
                              descriptionController:
                                  _descriptionControllers[
                                      _locales[_currentLocaleIndex]]!,
                              includedController: _includedControllers[
                                  _locales[_currentLocaleIndex]]!,
                              notIncludedController: _placesControllers[
                                  _locales[_currentLocaleIndex]]!,
                              whatToBringController:
                                  _whatToBringControllers[
                                      _locales[_currentLocaleIndex]]!,
                              extraInfoController:
                                  _extraInfoControllers[
                                      _locales[_currentLocaleIndex]]!,
                              departureTimeController:
                                  _departureTimeControllers[
                                      _locales[_currentLocaleIndex]]!,
                              returnTimeController:
                                  _returnTimeTextControllers[
                                      _locales[_currentLocaleIndex]]!,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        AppButton(
                          text: l10n.translate('save'),
                          isLoading: _isSaving,
                          onPressed: _isSaving || _isUploadingImages
                              ? null
                              : () async {
                                  // ignore: avoid_print
                                  print("SAVE PRESSED");
                                  await _saveTour();
                                },
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isSaving ||
                    isLoading ||
                    _isUploadingImages ||
                    _isLoadingDepartures)
                  Positioned.fill(
                    child: Container(
                      color: const Color(0x4D000000),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
              ],
            );
          },
          ),
        ),
      ),
    );
  }

  Future<void> _saveTour() async {
    // ignore: avoid_print
    print("START SAVE");
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    FocusScope.of(context).unfocus();
    final name = _nameControllers['kg']?.text.trim() ?? '';
    if (name.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).text('please_enter_tour_name'),
          ),
        ),
      );
      return;
    }

    final parsedPrice = double.tryParse(_priceController.text.trim());
    if (parsedPrice == null || parsedPrice <= 0) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(_greaterThanZeroMessage(context, 'price')),
        ),
      );
      return;
    }

    final names = _collectTextsWithEmpty(_nameControllers);
    final tourId =
    widget.tour?.id ??
      const Uuid().v4();    final departures = _buildDepartures(tourId, parsedPrice);
    final primaryDeparture = departures.first;
    final totalSeats = departures.fold<int>(
      0,
      (sum, departure) => sum + departure.totalSeats,
    );
    final bookedSeats = departures.fold<int>(
      0,
      (sum, departure) => sum + departure.bookedSeats,
    );
    final availableSeats = departures.fold<int>(
      0,
      (sum, departure) => sum + departure.availableSeats,
    );

    final tour = TourModel(
      id: tourId,
      title: names,
      names: names,
      categoryId: _selectedCategoryId,
      destination: _destinationController.text.trim(),
      description: _primaryDescriptionText,
      descriptionMap: _collectTextsWithEmpty(_descriptionControllers),
      descriptions: _collectTextsWithEmpty(_descriptionControllers),
      included: _collectTextsWithEmpty(_includedControllers),
      includedItems: _collectLists(_includedControllers),
      notIncluded: _collectTextsWithEmpty(_placesControllers),
      placesToVisit: _collectLists(_placesControllers),
      meetingPoint: _collectTextsWithEmpty(_meetingPointControllers),
      pickupDetails: _collectTextsWithEmpty(_pickupInstructionsControllers),
      extraInfo: _collectTextsWithEmpty(_extraInfoControllers),
      whatToBring: _collectTextsWithEmpty(_whatToBringControllers),
      landmark: _collectTextsWithEmpty(_landmarkControllers),
      guidePhone: _collectTextsWithEmpty(_guidePhoneControllers),
      whatsapp: _collectTextsWithEmpty(_guideWhatsappControllers),
      departureTime: _collectTextsWithEmpty(_departureTimeControllers),
      returnTime: _collectTextsWithEmpty(_returnTimeTextControllers),
      imageUrl: _primaryPreviewImageUrl,
      images: List<String>.from(_imageUrls),
      price: primaryDeparture.price,
      date: primaryDeparture.departureDate,
      totalSeats: totalSeats,
      lat: double.tryParse(_latitudeController.text.trim()),
      lng: double.tryParse(_longitudeController.text.trim()),
      bookedSeats: bookedSeats,
      reservedSeats: 0,
      remainingSeats: availableSeats,
      discountEndTime: primaryDeparture.departureDate,
      rating: widget.tour?.rating ?? 0,
      reviewTexts: widget.tour?.reviewTexts ?? const <String>[],
    );

    setState(() {
      _isSaving = true;
      isLoading = true;
    });

    try {
      // ignore: avoid_print
      print("SAVING TO FIRESTORE");
      if (widget.tour == null) {
        await _tourRepository.addTour(
          tour,
          departures: departures,
        ).timeout(
              const Duration(seconds: 20),
            );
      } else {
        await _tourRepository.updateTour(
          tour,
          departures: departures,
        ).timeout(
              const Duration(seconds: 20),
            );
        if (tour.price < widget.tour!.price) {
          try {
            await _notificationRepository.createNotification(
              title: 'Discount available',
              message: '${tour.localizedName('en')} now has a lower price.',
              type: 'discount',
              tourId: tour.id,
            );
          } catch (e, s) {
            debugPrint('Discount notification failed: $e');
            debugPrintStack(stackTrace: s);
          }
        }
      }
      // ignore: avoid_print
      print("DONE");

      if (!mounted) {
        return;
      }

      navigator.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              widget.tour == null
                  ? _successMessage(context)
                  : _updateSuccessMessage(context),
            ),
          ),
        );
    } catch (error, stackTrace) {
      debugPrint('REVIEW ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_resolveErrorMessage(error)),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          isLoading = false;
        });
      }
    }
  }

  List<TourDeparture> _buildDepartures(String tourId, double primaryPrice) {
    final primaryDepartureDate =
        DateTime.tryParse(_dateController.text.trim()) ?? DateTime.now();
    final parsedPrimaryReturnDate = DateTime.tryParse(
      _returnDateController.text.trim(),
    );
    final primaryReturnDate =
        parsedPrimaryReturnDate == null ||
            parsedPrimaryReturnDate.isBefore(primaryDepartureDate)
        ? primaryDepartureDate
        : parsedPrimaryReturnDate;
    final primaryTotalSeats = _normalizeTotalSeats(
      int.tryParse(_totalSeatsController.text.trim()),
      bookedSeats: _primaryBookedSeats,
    );
    final primaryCoordinates = _parseCoordinatePair(
      _departureLatitudeController,
      _departureLongitudeController,
    );
    final departures = <TourDeparture>[
      TourDeparture(
        id: _primaryDepartureId,
        tourId: tourId,
        departureDate: primaryDepartureDate,
        returnDate: primaryReturnDate,
        totalSeats: primaryTotalSeats,
        bookedSeats: _primaryBookedSeats,
        price: primaryPrice,
        status: TourDeparture.resolveStatusForSeats(
          primaryTotalSeats - _primaryBookedSeats,
        ),
        meetingPointName: _collectTexts(_meetingPointControllers),
        meetingAddress: _collectTexts(_meetingAddressControllers),
        landmark: _collectTexts(_landmarkControllers),
        pickupType: _primaryPickupType,
        pickupInstructions: _collectTexts(_pickupInstructionsControllers),
        googleMapsUrl: _departureGoogleMapsUrlController.text.trim(),
        latitude: primaryCoordinates.latitude,
        longitude: primaryCoordinates.longitude,
        guidePhone: _guidePhoneControllers['kg']?.text.trim() ?? '',
        guideWhatsapp: _guideWhatsappControllers['kg']?.text.trim() ?? '',
      ),
    ];

    departures.addAll(
      _additionalDepartureForms
          .where((departureForm) => _shouldSaveDeparture(departureForm))
          .map(
        (departureForm) {
          final coordinates = _parseCoordinatePair(
            departureForm.latitudeController,
            departureForm.longitudeController,
          );
          final departureDate =
              DateTime.tryParse(
                departureForm.departureDateController.text.trim(),
              ) ??
              primaryDepartureDate;
          final returnDate =
              DateTime.tryParse(
                departureForm.returnDateController.text.trim(),
              ) ??
              departureDate;
          final totalSeats = _normalizeTotalSeats(
            int.tryParse(departureForm.totalSeatsController.text.trim()),
            bookedSeats: departureForm.bookedSeats,
          );
          final price =
              double.tryParse(departureForm.priceController.text.trim()) ??
              primaryPrice;

          return TourDeparture(
            id: departureForm.id,
            tourId: tourId,
            departureDate: departureDate,
            returnDate: returnDate.isBefore(departureDate)
                ? departureDate
                : returnDate,
            totalSeats: totalSeats,
            bookedSeats: departureForm.bookedSeats,
            price: price > 0 ? price : primaryPrice,
            status: TourDeparture.resolveStatusForSeats(
              totalSeats - departureForm.bookedSeats,
            ),
            meetingPointName:
                _collectTexts(departureForm.meetingPointControllers),
            meetingAddress:
                _collectTexts(departureForm.meetingAddressControllers),
            landmark: _collectTexts(departureForm.landmarkControllers),
            pickupType: departureForm.pickupType,
            pickupInstructions:
                _collectTexts(departureForm.pickupInstructionsControllers),
            googleMapsUrl: departureForm.googleMapsUrlController.text.trim(),
            latitude: coordinates.latitude,
            longitude: coordinates.longitude,
            guidePhone: departureForm.guidePhoneController.text.trim(),
            guideWhatsapp: departureForm.guideWhatsappController.text.trim(),
          );
        },
      ),
    );

    departures.sort((left, right) {
      final dateCompare = left.departureDate.compareTo(right.departureDate);
      if (dateCompare != 0) {
        return dateCompare;
      }
      return left.id.compareTo(right.id);
    });

    return departures;
  }

  bool _shouldSaveDeparture(_DepartureFormData departureForm) {
    final price = double.tryParse(departureForm.priceController.text.trim());
    if (price != null && price > 0) {
      return true;
    }

    return departureForm.departureDateController.text.trim().isNotEmpty ||
        departureForm.returnDateController.text.trim().isNotEmpty ||
        departureForm.totalSeatsController.text.trim().isNotEmpty ||
        departureForm.googleMapsUrlController.text.trim().isNotEmpty ||
        departureForm.latitudeController.text.trim().isNotEmpty ||
        departureForm.longitudeController.text.trim().isNotEmpty ||
        departureForm.guidePhoneController.text.trim().isNotEmpty ||
        departureForm.guideWhatsappController.text.trim().isNotEmpty ||
        departureForm.meetingPointControllers.values.any(
          (controller) => controller.text.trim().isNotEmpty,
        ) ||
        departureForm.meetingAddressControllers.values.any(
          (controller) => controller.text.trim().isNotEmpty,
        ) ||
        departureForm.landmarkControllers.values.any(
          (controller) => controller.text.trim().isNotEmpty,
        ) ||
        departureForm.pickupInstructionsControllers.values.any(
          (controller) => controller.text.trim().isNotEmpty,
        );
  }

  int _normalizeTotalSeats(int? value, {required int bookedSeats}) {
    final fallback = bookedSeats > 0 ? bookedSeats : 1;
    if (value == null || value <= 0 || value < bookedSeats) {
      return fallback;
    }
    return value;
  }

  Future<void> pickAndUploadImage() async {
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _isUploadingImages = true;
      isLoading = true;
    });

    try {
      debugPrint('AddTourScreen: starting primary tour image upload.');
      final url = await _mediaUploadService.pickAndUploadImage().timeout(
            const Duration(minutes: 2),
          );

      if (url == null || !mounted) {
        return;
      }

      debugPrint('AddTourScreen: primary tour image uploaded url="$url"');
      setState(() {
        _setImageUrls([url, ..._imageUrls]);
      });
    } catch (error, stackTrace) {
      debugPrint('AddTourScreen: primary image upload failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_resolveErrorMessage(error)),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImages = false;
          isLoading = false;
        });
      }
    }
  }

  Future<void> _uploadGalleryImages() async {
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _isUploadingImages = true;
      isLoading = true;
    });

    try {
      debugPrint('AddTourScreen: starting gallery image upload.');
      final urls = await _mediaUploadService
          .pickAndUploadMultipleImages(
            folder: 'tours',
          )
          .timeout(
            const Duration(minutes: 2),
          );

      if (urls.isEmpty || !mounted) {
        return;
      }

      debugPrint('AddTourScreen: gallery upload completed urls="$urls"');
      setState(() {
        _addImageUrls(urls);
      });
    } catch (error, stackTrace) {
      debugPrint('AddTourScreen: gallery image upload failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_resolveErrorMessage(error)),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImages = false;
          isLoading = false;
        });
      }
    }
  }

  Map<String, String> _collectTexts(
    Map<String, TextEditingController> controllers,
  ) {
    final result = <String, String>{};
    for (final entry in controllers.entries) {
      final value = entry.value.text.trim();
      if (value.isNotEmpty) {
        result[entry.key] = value;
      }
    }
    return result;
  }

  Map<String, String> _collectTextsWithEmpty(
    Map<String, TextEditingController> controllers,
  ) {
    final values = <String, String>{};
    for (final locale in _locales) {
      values[locale] = controllers[locale]?.text.trim() ?? '';
    }
    return values;
  }

  void _setLocalizedControllerTexts(
    Map<String, TextEditingController> controllers,
    Map<String, String> values,
  ) {
    for (final entry in controllers.entries) {
      entry.value.text = values[entry.key] ?? values['kg'] ?? values['ky'] ?? '';
    }
  }

  void _setSingleValueAsPrimaryLocale(
    Map<String, TextEditingController> controllers,
    String value,
  ) {
    final normalized = value.trim();
    for (final entry in controllers.entries) {
      entry.value.text = entry.key == 'kg' ? normalized : '';
    }
  }

  Map<String, List<String>> _collectLists(
    Map<String, TextEditingController> controllers,
  ) {
    final result = <String, List<String>>{};
    for (final entry in controllers.entries) {
      final values = _parseLines(entry.value.text);
      if (values.isNotEmpty) {
        result[entry.key] = values;
      }
    }
    return result;
  }

  String get _primaryDescriptionText {
    final kyrgyzDescription = _descriptionControllers['kg']?.text.trim() ?? '';
    if (kyrgyzDescription.isNotEmpty) {
      return kyrgyzDescription;
    }

    for (final controller in _descriptionControllers.values) {
      final description = controller.text.trim();
      if (description.isNotEmpty) {
        return description;
      }
    }

    return '';
  }

  void _syncImageStateFromControllers() {
    if (_isSyncingImageControllers) {
      return;
    }

    final nextImageUrls = _uniqueImageUrls([
      _imageUrlController.text,
      ..._parseLines(_galleryImagesController.text),
    ]);

    if (_areSameUrls(_imageUrls, nextImageUrls)) {
      return;
    }

    setState(() {
      _imageUrls = nextImageUrls;
    });
  }

  void _setImageUrls(List<String> imageUrls) {
    final normalizedUrls = _uniqueImageUrls(imageUrls);
    _imageUrls = normalizedUrls;

    _isSyncingImageControllers = true;
    _imageUrlController.text =
        normalizedUrls.isNotEmpty ? normalizedUrls.first : '';
    _galleryImagesController.text = normalizedUrls.skip(1).join('\n');
    _isSyncingImageControllers = false;
  }

  void _addImageUrls(Iterable<String> imageUrls) {
    _setImageUrls([
      ..._imageUrls,
      ...imageUrls,
    ]);
  }

  bool _areSameUrls(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }

    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }

    return true;
  }

  List<String> _uniqueImageUrls(Iterable<String> imageUrls) {
    final uniqueUrls = <String>[];
    for (final imageUrl in imageUrls) {
      final normalizedUrl = imageUrl.trim();
      if (normalizedUrl.isEmpty || uniqueUrls.contains(normalizedUrl)) {
        continue;
      }
      uniqueUrls.add(normalizedUrl);
    }

    return uniqueUrls;
  }

  List<String> _parseLines(String value) {
    return value
        .split(RegExp(r'[\n,]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  ({double? latitude, double? longitude}) _parseCoordinatePair(
    TextEditingController latitudeController,
    TextEditingController longitudeController,
  ) {
    final latitude = double.tryParse(latitudeController.text.trim());
    final longitude = double.tryParse(longitudeController.text.trim());

    if (latitude == null || longitude == null) {
      return (latitude: null, longitude: null);
    }

    return (latitude: latitude, longitude: longitude);
  }

  // ignore: unused_element
  String _requiredFieldMessage(BuildContext context, String fieldKey) {
    final l10n = AppLocalizations.of(context);
    final field = l10n.translate(fieldKey);
    switch (l10n.locale.languageCode) {
      case 'ru':
        return '$field обязательно';
      case 'ky':
        return '$field милдеттүү';
      default:
        return '$field is required';
    }
  }

  // ignore: unused_element
  String _invalidNumberMessage(BuildContext context, String fieldKey) {
    final l10n = AppLocalizations.of(context);
    final field = l10n.translate(fieldKey);
    switch (l10n.locale.languageCode) {
      case 'ru':
        return '$field должно быть числом';
      case 'ky':
        return '$field сан болушу керек';
      default:
        return '$field must be a number';
    }
  }

  String _greaterThanZeroMessage(BuildContext context, String fieldKey) {
    final l10n = AppLocalizations.of(context);
    final field = l10n.translate(fieldKey);
    switch (l10n.locale.languageCode) {
      case 'ru':
        return '$field должно быть больше 0';
      case 'ky':
        return '$field 0дон чоң болушу керек';
      default:
        return '$field must be greater than 0';
    }
  }

  // ignore: unused_element
  String _invalidDateMessage(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final field = l10n.translate('date');
    switch (l10n.locale.languageCode) {
      case 'ru':
        return 'Введите корректное значение для $field';
      case 'ky':
        return '$field туура форматта болушу керек';
      default:
        return 'Enter a valid $field';
    }
  }

  String _successMessage(BuildContext context) {
    switch (AppLocalizations.of(context).locale.languageCode) {
      case 'ru':
        return 'Тур успешно сохранен';
      case 'ky':
        return 'Тур ийгиликтүү сакталды';
      default:
        return AppLocalizations.of(context).text('tour_saved_successfully');
    }
  }

  String _updateSuccessMessage(BuildContext context) {
    switch (AppLocalizations.of(context).locale.languageCode) {
      case 'ru':
        return 'Тур успешно обновлен';
      case 'ky':
        return 'Тур ийгиликтүү жаңыртылды';
      default:
        return AppLocalizations.of(context).text('tour_updated_successfully');
    }
  }

  String _clearPrimaryImageLabel(BuildContext context) {
    switch (AppLocalizations.of(context).locale.languageCode) {
      case 'ru':
        return 'Очистить главное фото';
      case 'ky':
        return 'Башкы сүрөттү тазалоо';
      default:
        return AppLocalizations.of(context).text('clear_main_image');
    }
  }

  String _resolveErrorMessage(Object error) {
    final l10n = AppLocalizations.of(context);

    if (error is String) {
      final translated = l10n.translate(error);
      return translated == error ? error : translated;
    }

    final raw = error.toString().trim();
    if (error is TimeoutException) {
      return l10n.text('request_timed_out');
    }

    if (raw.startsWith('Bad state: ')) {
      return raw.substring('Bad state: '.length).trim();
    }

    return l10n.translate('error_generic');
  }
}

class _DepartureEditorCard extends StatelessWidget {
  const _DepartureEditorCard({
    required this.title,
    required this.departureForm,
    required this.localeCode,
    required this.onPickupTypeChanged,
    required this.onSelectDepartureDate,
    required this.onSelectReturnDate,
    required this.onRemove,
  });

  final String title;
  final _DepartureFormData departureForm;
  final String localeCode;
  final ValueChanged<String> onPickupTypeChanged;
  final VoidCallback onSelectDepartureDate;
  final VoidCallback onSelectReturnDate;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            TextFormField(
              controller: departureForm.priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.translate('price'),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: departureForm.departureDateController,
              readOnly: true,
              onTap: onSelectDepartureDate,
              decoration: InputDecoration(
                labelText: l10n.translate('date'),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: departureForm.returnDateController,
              readOnly: true,
              onTap: onSelectReturnDate,
              decoration: InputDecoration(
                labelText: l10n.translate('return_date'),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: departureForm.totalSeatsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.translate('total_seats'),
              ),
            ),
            const SizedBox(height: 16),
            _DeparturePickupFields(
              pickupType: departureForm.pickupType,
              onPickupTypeChanged: onPickupTypeChanged,
              meetingPointController:
                  departureForm.meetingPointControllers[localeCode]!,
              meetingAddressController:
                  departureForm.meetingAddressControllers[localeCode]!,
              landmarkController:
                  departureForm.landmarkControllers[localeCode]!,
              pickupInstructionsController:
                  departureForm.pickupInstructionsControllers[localeCode]!,
              googleMapsUrlController: departureForm.googleMapsUrlController,
              latitudeController: departureForm.latitudeController,
              longitudeController: departureForm.longitudeController,
              guidePhoneController: departureForm.guidePhoneController,
              guideWhatsappController: departureForm.guideWhatsappController,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeparturePickupFields extends StatelessWidget {
  const _DeparturePickupFields({
    required this.pickupType,
    required this.onPickupTypeChanged,
    required this.meetingPointController,
    required this.meetingAddressController,
    required this.landmarkController,
    required this.pickupInstructionsController,
    required this.googleMapsUrlController,
    required this.latitudeController,
    required this.longitudeController,
    required this.guidePhoneController,
    required this.guideWhatsappController,
  });

  final String pickupType;
  final ValueChanged<String> onPickupTypeChanged;
  final TextEditingController meetingPointController;
  final TextEditingController meetingAddressController;
  final TextEditingController landmarkController;
  final TextEditingController pickupInstructionsController;
  final TextEditingController googleMapsUrlController;
  final TextEditingController latitudeController;
  final TextEditingController longitudeController;
  final TextEditingController guidePhoneController;
  final TextEditingController guideWhatsappController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('pickup_meeting'),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: TourDeparturePickupType.values.contains(pickupType)
              ? pickupType
              : TourDeparturePickupType.meetingPoint,
          items: TourDeparturePickupType.values
              .map(
                (type) => DropdownMenuItem<String>(
                  value: type,
                  child: Text(l10n.translate(type)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              onPickupTypeChanged(value);
            }
          },
          decoration: InputDecoration(
            labelText: l10n.translate('select_pickup_type'),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: meetingPointController,
          decoration: InputDecoration(
            labelText: l10n.translate('meeting_point_name'),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: meetingAddressController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: l10n.translate('pickup_address'),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: landmarkController,
          decoration: InputDecoration(
            labelText: l10n.translate('landmark'),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: pickupInstructionsController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: l10n.translate('pickup_instructions'),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: googleMapsUrlController,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: l10n.translate('google_maps_url'),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: latitudeController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.translate('latitude'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: longitudeController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.translate('longitude'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: guidePhoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: l10n.translate('guide_phone'),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: guideWhatsappController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: l10n.translate('guide_whatsapp'),
          ),
        ),
      ],
    );
  }
}

class _DepartureFormData {
  _DepartureFormData({
    required this.id,
    required this.bookedSeats,
    required this.priceController,
    required this.departureDateController,
    required this.returnDateController,
    required this.totalSeatsController,
    required this.meetingPointControllers,
    required this.meetingAddressControllers,
    required this.landmarkControllers,
    required this.pickupInstructionsControllers,
    required this.googleMapsUrlController,
    required this.latitudeController,
    required this.longitudeController,
    required this.guidePhoneController,
    required this.guideWhatsappController,
    this.pickupType = TourDeparturePickupType.meetingPoint,
  });

  factory _DepartureFormData.create() {
    return _DepartureFormData(
      id: const Uuid().v4(),
      bookedSeats: 0,
      priceController: TextEditingController(),
      departureDateController: TextEditingController(),
      returnDateController: TextEditingController(),
      totalSeatsController: TextEditingController(),
      meetingPointControllers: _localizedControllers(),
      meetingAddressControllers: _localizedControllers(),
      landmarkControllers: _localizedControllers(),
      pickupInstructionsControllers: _localizedControllers(),
      googleMapsUrlController: TextEditingController(),
      latitudeController: TextEditingController(),
      longitudeController: TextEditingController(),
      guidePhoneController: TextEditingController(),
      guideWhatsappController: TextEditingController(),
    );
  }

  factory _DepartureFormData.fromDeparture(TourDeparture departure) {
    return _DepartureFormData(
      id: departure.id,
      bookedSeats: departure.bookedSeats,
      priceController: TextEditingController(
        text: departure.price.toString(),
      ),
      departureDateController: TextEditingController(
        text: departure.departureDate.toIso8601String().split('T').first,
      ),
      returnDateController: TextEditingController(
        text: departure.returnDate.toIso8601String().split('T').first,
      ),
      totalSeatsController: TextEditingController(
        text: departure.totalSeats.toString(),
      ),
      meetingPointControllers: _localizedControllers(
        departure.meetingPointName,
      ),
      meetingAddressControllers: _localizedControllers(
        departure.meetingAddress,
      ),
      landmarkControllers: _localizedControllers(departure.landmark),
      pickupInstructionsControllers: _localizedControllers(
        departure.pickupInstructions,
      ),
      googleMapsUrlController: TextEditingController(
        text: departure.googleMapsUrl,
      ),
      latitudeController: TextEditingController(
        text: departure.latitude?.toString() ?? '',
      ),
      longitudeController: TextEditingController(
        text: departure.longitude?.toString() ?? '',
      ),
      guidePhoneController: TextEditingController(text: departure.guidePhone),
      guideWhatsappController: TextEditingController(
        text: departure.guideWhatsapp,
      ),
      pickupType: departure.pickupType,
    );
  }

  static Map<String, TextEditingController> _localizedControllers([
    Map<String, String> values = const {},
  ]) {
    return {
      for (final locale in kTourTranslationLocales)
        locale: TextEditingController(
          text: values[locale] ?? values['ky'] ?? values['kg'] ?? '',
        ),
    };
  }

  final String id;
  final int bookedSeats;
  String pickupType;
  final TextEditingController priceController;
  final TextEditingController departureDateController;
  final TextEditingController returnDateController;
  final TextEditingController totalSeatsController;
  final Map<String, TextEditingController> meetingPointControllers;
  final Map<String, TextEditingController> meetingAddressControllers;
  final Map<String, TextEditingController> landmarkControllers;
  final Map<String, TextEditingController> pickupInstructionsControllers;
  final TextEditingController googleMapsUrlController;
  final TextEditingController latitudeController;
  final TextEditingController longitudeController;
  final TextEditingController guidePhoneController;
  final TextEditingController guideWhatsappController;

  void dispose() {
    priceController.dispose();
    departureDateController.dispose();
    returnDateController.dispose();
    totalSeatsController.dispose();
    for (final controller in meetingPointControllers.values) {
      controller.dispose();
    }
    for (final controller in meetingAddressControllers.values) {
      controller.dispose();
    }
    for (final controller in landmarkControllers.values) {
      controller.dispose();
    }
    for (final controller in pickupInstructionsControllers.values) {
      controller.dispose();
    }
    googleMapsUrlController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    guidePhoneController.dispose();
    guideWhatsappController.dispose();
  }
}

class _LocalizedTourFields extends StatelessWidget {
  const _LocalizedTourFields({
    required this.localeCode,
    required this.showTitleField,
    required this.showExtendedFields,
    required this.nameController,
    required this.descriptionController,
    required this.includedController,
    required this.notIncludedController,
    required this.whatToBringController,
    required this.extraInfoController,
    required this.departureTimeController,
    required this.returnTimeController,
  });

  final String localeCode;
  final bool showTitleField;
  final bool showExtendedFields;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController includedController;
  final TextEditingController notIncludedController;
  final TextEditingController whatToBringController;
  final TextEditingController extraInfoController;
  final TextEditingController departureTimeController;
  final TextEditingController returnTimeController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          showExtendedFields
              ? l10n.languageName(localeCode)
              : l10n.translate('primary_language_kg'),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        if (showTitleField) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: nameController,
            decoration:
                InputDecoration(labelText: l10n.translate('tour_title')),
          ),
        ],
        const SizedBox(height: 12),
        TextFormField(
          controller: descriptionController,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: l10n.translate('description'),
            hintText: l10n.translate('tour_description_hint'),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: includedController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: l10n.translate('included_items'),
            hintText: l10n.translate('multiline_list_hint'),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: notIncludedController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: l10n.translate('not_included'),
            hintText: l10n.translate('multiline_list_hint'),
          ),
        ),
        if (showExtendedFields || localeCode == 'kg') ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: whatToBringController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.translate('what_to_bring'),
              hintText: l10n.translate('multiline_list_hint'),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: extraInfoController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: l10n.translate('extra_info'),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: departureTimeController,
            decoration: InputDecoration(
              labelText: l10n.translate('departure_time'),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: returnTimeController,
            decoration: InputDecoration(
              labelText: l10n.translate('return_time_label'),
            ),
          ),
        ],
      ],
    );
  }
}

class _TourImagePreview extends StatelessWidget {
  const _TourImagePreview({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final normalizedUrl = imageUrl.trim();

    return Container(
      height: 150,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: normalizedUrl.isEmpty
          ? Center(
              child: Icon(
                Icons.image_outlined,
                size: 40,
                color: colorScheme.primary,
              ),
            )
          : Image.network(
              normalizedUrl,
              fit: BoxFit.cover,
              cacheWidth: 1200,
              cacheHeight: 720,
              filterQuality: FilterQuality.low,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 40,
                    color: colorScheme.primary,
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }

                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                );
              },
            ),
    );
  }
}

class _TourGalleryPreview extends StatelessWidget {
  const _TourGalleryPreview({
    required this.imageUrls,
    this.onRemoveImage,
  });

  final List<String> imageUrls;
  final ValueChanged<int>? onRemoveImage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (imageUrls.isEmpty) {
      return Container(
        height: 110,
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.collections_outlined,
          size: 36,
          color: colorScheme.primary,
        ),
      );
    }

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final imageUrl = imageUrls[index];

          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 140,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    cacheWidth: 400,
                    cacheHeight: 400,
                    filterQuality: FilterQuality.low,
                    errorBuilder: (context, error, stackTrace) {
                      return ColoredBox(
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 36,
                          color: colorScheme.primary,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }

                      return ColoredBox(
                        color: colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (onRemoveImage != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () => onRemoveImage!(index),
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
