import 'dart:async';

import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:postgrest/postgrest.dart';
import 'package:razak_travel/core/services/media_upload_service.dart';
import 'package:razak_travel/data/models/category_model.dart';
import 'package:razak_travel/data/repositories/category_repository.dart';
import 'package:razak_travel/features/admin/widgets/admin_access_guard.dart';
import 'package:razak_travel/shared/localization/app_localizations.dart';
import 'package:razak_travel/shared/widgets/app_button.dart';
import 'package:razak_travel/shared/widgets/app_card.dart';
import 'package:razak_travel/shared/widgets/app_network_image.dart';
import 'package:razak_travel/shared/widgets/app_text_field.dart';
import 'package:razak_travel/shared/widgets/language_switcher.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({
    super.key,
    this.category,
  });

  final CategoryModel? category;

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen>
    with SingleTickerProviderStateMixin {
  final CategoryRepository _repository = CategoryRepository();
  final MediaUploadService _mediaUploadService = MediaUploadService();
  final Map<String, TextEditingController> _nameControllers = {};
  final Map<String, TextEditingController> _descriptionControllers = {};
  late final TextEditingController _imageController;
  late final TabController _tabController;
  late final List<String> _locales;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _locales = AppLocalizations.supportedLocaleCodes;
    for (final locale in _locales) {
      _nameControllers[locale] = TextEditingController(
        text: widget.category?.names[locale] ?? '',
      );
      _descriptionControllers[locale] = TextEditingController(
        text: widget.category?.descriptions[locale] ?? '',
      );
    }
    _imageController =
        TextEditingController(text: widget.category?.imageUrl ?? '');
    _tabController = TabController(length: _locales.length, vsync: this);
  }

  @override
  void dispose() {
    for (final controller in _nameControllers.values) {
      controller.dispose();
    }
    for (final controller in _descriptionControllers.values) {
      controller.dispose();
    }
    _imageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final previewTitle = _previewTitle;

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.category == null
                ? l10n.text('add_category')
                : l10n.text('edit_category'),
          ),
          actions: const [LanguageSwitcher()],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: _locales
                .map(
                  (locale) => Tab(text: l10n.languageName(locale)),
                )
                .toList(),
          ),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ImagePreview(
                          imageUrl: _imageController.text.trim(),
                          title: previewTitle,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _isSaving || _isUploadingImage
                                    ? null
                                    : _uploadImage,
                                icon: _isUploadingImage
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.upload_outlined),
                                label: Text(l10n.text('upload_image')),
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                controller: _imageController,
                                label: l10n.text('image_url'),
                                keyboardType: TextInputType.url,
                                maxLines: 2,
                                onChanged: (_) => setState(() {}),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 260,
                    child: TabBarView(
                      controller: _tabController,
                      children: _locales
                          .map(
                            (locale) => _LocalizedCategoryFields(
                              nameController: _nameControllers[locale]!,
                              descriptionController:
                                  _descriptionControllers[locale]!,
                              onNameChanged: (_) => setState(() {}),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    text: l10n.text('save'),
                    isLoading: _isSaving,
                    onPressed: _isSaving ? null : _saveCategory,
                  ),
                ],
              ),
            ),
            if (_isSaving || _isUploadingImage)
              Positioned.fill(
                child: Container(
                  color: const Color(0x4D000000),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCategory() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);

    final names = _collectTexts(_nameControllers);

    if (names.isEmpty) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.text('please_enter_category_name')),
          ),
        );
      return;
    }

    try {
      setState(() {
        _isSaving = true;
      });

      debugPrint('AddCategoryScreen._saveCategory: save started');

      final category = CategoryModel(
        id: widget.category?.id ?? '',
        names: names,
        image: _imageController.text.trim(),
        descriptions: _collectTexts(_descriptionControllers),
        createdAt: widget.category?.createdAt ?? DateTime.now(),
      );

      final payload = category.toJson();
      debugPrint('AddCategoryScreen._saveCategory: payload=$payload');
      debugPrint('CATEGORY INSERT PAYLOAD: $payload');

      if (widget.category == null) {
        debugPrint('AddCategoryScreen._saveCategory: calling addCategory');
        await _repository.addCategory(category).timeout(
              const Duration(seconds: 20),
            );
        debugPrint('AddCategoryScreen._saveCategory: addCategory OK');
      } else {
        debugPrint('AddCategoryScreen._saveCategory: calling updateCategory');
        await _repository.updateCategory(category).timeout(
              const Duration(seconds: 20),
            );
        debugPrint('AddCategoryScreen._saveCategory: updateCategory OK');
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(context);
    } catch (error, stackTrace) {
      debugPrint(
        'AddCategoryScreen._saveCategory ERROR at line 236: $error',
      );
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
        });
      }
    }
  }

  Future<void> _uploadImage() async {
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _isUploadingImage = true;
    });

    try {
      debugPrint('AddCategoryScreen: starting category image upload.');
      final url = await _mediaUploadService
          .pickAndUploadSingleImage(
            folder: 'categories',
          )
          .timeout(
            const Duration(minutes: 2),
          );

      if (url != null && mounted) {
        debugPrint('AddCategoryScreen: category image uploaded url="$url"');
        setState(() {
          _imageController.text = url;
        });
      }
    } catch (error, stackTrace) {
      debugPrint('AddCategoryScreen: category image upload failed: $error');
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
          _isUploadingImage = false;
        });
      }
    }
  }

  String get _previewTitle {
    for (final locale in _locales) {
      final value = _nameControllers[locale]?.text.trim() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }

    return '';
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

  String _resolveErrorMessage(Object error) {
    final l10n = AppLocalizations.of(context);

    if (error is String) {
      final translated = l10n.text(error);
      return translated == error ? error : translated;
    }

    final raw = error.toString().trim();
    if (error is TimeoutException) {
      return l10n.text('request_timed_out');
    }

    if (raw.startsWith('Bad state: ')) {
      return raw.substring('Bad state: '.length).trim();
    }

    final message = error is PostgrestException
        ? '${error.message} (${error.code})'
        : raw;

    return '$message. ${l10n.text('error_generic')}';
  }
}

class _LocalizedCategoryFields extends StatelessWidget {
  const _LocalizedCategoryFields({
    required this.nameController,
    required this.descriptionController,
    this.onNameChanged,
  });

  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final ValueChanged<String>? onNameChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: nameController,
          label: l10n.text('name'),
          onChanged: onNameChanged,
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: descriptionController,
          label: l10n.text('description'),
          maxLines: 6,
        ),
      ],
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({
    required this.imageUrl,
    required this.title,
  });

  final String imageUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final normalizedTitle = title.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppNetworkImage(
              imageUrl: imageUrl,
              placeholder: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.secondaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  Icons.photo_outlined,
                  size: 48,
                  color: colorScheme.primary,
                ),
              ),
              errorPlaceholder: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                ),
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 42,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x10000000),
                    Color(0x88000000),
                  ],
                ),
              ),
            ),
            if (normalizedTitle.isNotEmpty)
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: Text(
                  normalizedTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
