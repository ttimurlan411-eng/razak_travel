import 'package:flutter/material.dart';
import 'package:razak_travel/data/models/category_model.dart';
import 'package:razak_travel/data/repositories/category_repository.dart';
import 'package:razak_travel/features/admin/admin_tour_list_screen.dart';
import 'package:razak_travel/features/admin/add_category_screen.dart';
import 'package:razak_travel/features/admin/widgets/admin_access_guard.dart';
import 'package:razak_travel/shared/localization/app_localizations.dart';
import 'package:razak_travel/shared/widgets/app_card.dart';
import 'package:razak_travel/shared/widgets/app_empty_state.dart';
import 'package:razak_travel/shared/widgets/app_loader.dart';
import 'package:razak_travel/shared/widgets/app_network_image.dart';
import 'package:razak_travel/shared/widgets/language_switcher.dart';

class AdminCategoryListScreen extends StatefulWidget {
  const AdminCategoryListScreen({super.key});

  @override
  State<AdminCategoryListScreen> createState() =>
      _AdminCategoryListScreenState();
}

class _AdminCategoryListScreenState extends State<AdminCategoryListScreen> {
  final CategoryRepository _repository = CategoryRepository();
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  String? _error;
  String? _deletingCategoryId;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final categories = await _repository.getCategories();
      if (!mounted) {
        return;
      }
      setState(() {
        _categories = categories;
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

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.text('manage_categories')),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadCategories,
            ),
            const LanguageSwitcher(),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadCategories,
          child: _buildBody(l10n, localeCode),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddCategoryScreen()),
            );
            _loadCategories();
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
        message: l10n.text('error_generic'),
        icon: Icons.error_outline,
      );
    }

    if (_categories.isEmpty) {
      return AppEmptyState(
        message: l10n.text('no_categories_found'),
        icon: Icons.dashboard_outlined,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemBuilder: (context, index) {
        final category = _categories[index];
        final localizedName = category.localizedName(localeCode);
        final localizedDescription =
            category.localizedDescription(localeCode);
        return AppCard(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminTourListScreen(category: category),
              ),
            );
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CategoryImage(imageUrl: category.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizedName,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (localizedDescription.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        localizedDescription,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (category.hasImage) ...[
                      const SizedBox(height: 6),
                      Text(
                        category.imageUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
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
                              AddCategoryScreen(category: category),
                        ),
                      );
                      _loadCategories();
                    },
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    onPressed: _deletingCategoryId == category.id
                        ? null
                        : () => _deleteCategory(category.id),
                    icon: _deletingCategoryId == category.id
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
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
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemCount: _categories.length,
    );
  }

  Future<void> _deleteCategory(String id) async {
    setState(() => _deletingCategoryId = id);
    final l10n = AppLocalizations.of(context);

    try {
      await _repository.deleteCategory(id);
      if (!mounted) {
        return;
      }
      setState(() {
        _categories.removeWhere((c) => c.id == id);
        _deletingCategoryId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.text('category_deleted'))),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _deletingCategoryId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error == 'category_has_linked_tours'
                ? l10n.text('category_has_linked_tours')
                : l10n.text('category_delete_failed'),
          ),
        ),
      );
    }
  }
}

class _CategoryImage extends StatelessWidget {
  const _CategoryImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 72,
        width: 72,
        child: AppNetworkImage(
          imageUrl: imageUrl,
          placeholder: ColoredBox(
            color: colorScheme.primaryContainer,
            child: Icon(
              Icons.image_outlined,
              color: colorScheme.primary,
            ),
          ),
          errorPlaceholder: ColoredBox(
            color: colorScheme.primaryContainer,
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
