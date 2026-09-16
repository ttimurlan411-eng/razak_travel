import 'package:flutter/foundation.dart';
import 'package:razak_travel/data/models/category_model.dart';
import 'package:razak_travel/data/models/tour_model.dart';
import 'package:razak_travel/data/repositories/category_repository.dart';
import 'package:razak_travel/data/repositories/tour_repository.dart';

class CategoriesController extends ChangeNotifier {
  CategoriesController({
    CategoryRepository? repository,
    TourRepository? tourRepository,
  })  : _repository = repository ?? CategoryRepository(),
        _tourRepository = tourRepository ?? TourRepository();

  // ignore: unused_field
  final CategoryRepository _repository;
  final TourRepository _tourRepository;

  List<CategoryModel> categories = [];
  List<TourModel> _tours = [];
  bool isLoading = false;
  String errorKey = '';

  CategorySearchResults search(
    String query, {
    List<CategoryModel>? sourceCategories,
  }) {
    final availableCategories = sourceCategories ?? categories;
    final filteredTours = filterToursByQuery(
      categories: availableCategories,
      tours: _tours,
      query: query,
    );

    return CategorySearchResults(
      query: query,
      categories: filterCategoriesByQuery(
        categories: availableCategories,
        tours: filteredTours.isEmpty ? _tours : filteredTours,
        query: query,
      ),
      tours: filteredTours,
    );
  }

  List<CategoryModel> filterCategories(
    String query, {
    List<CategoryModel>? sourceCategories,
  }) {
    return search(query, sourceCategories: sourceCategories).categories;
  }

  List<TourModel> filterTours(
    String query, {
    List<CategoryModel>? sourceCategories,
  }) {
    return search(query, sourceCategories: sourceCategories).tours;
  }

  static List<TourModel> filterToursByQuery({
    required List<CategoryModel> categories,
    required List<TourModel> tours,
    required String query,
  }) {
    final normalizedQuery = TourModel.normalizeSearchText(query);
    if (normalizedQuery.isEmpty) {
      return const <TourModel>[];
    }

    final categoryById = {
      for (final category in categories) category.id: category,
    };

    return tours.where((tour) {
      final categoryNames =
          categoryById[tour.categoryId]?.names.values ?? const <String>[];

      return tour.matchesSearchQuery(
        normalizedQuery,
        categoryNames: categoryNames,
      );
    }).toList(growable: false);
  }

  static List<CategoryModel> filterCategoriesByQuery({
    required List<CategoryModel> categories,
    required List<TourModel> tours,
    required String query,
  }) {
    final normalizedQuery = TourModel.normalizeSearchText(query);
    if (normalizedQuery.isEmpty) {
      return categories;
    }

    final toursByCategoryId = <String, List<TourModel>>{};
    for (final tour in tours) {
      (toursByCategoryId[tour.categoryId] ??= <TourModel>[]).add(tour);
    }

    return categories.where((category) {
      final categoryNames = category.names.values
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false);

      if (_matchesSearchTerms(normalizedQuery, categoryNames)) {
        return true;
      }

      final relatedTours =
          toursByCategoryId[category.id] ?? const <TourModel>[];

      return relatedTours.any(
        (tour) => tour.matchesSearchQuery(
          normalizedQuery,
          categoryNames: categoryNames,
        ),
      );
    }).toList(growable: false);
  }

  static bool _matchesSearchTerms(
    String normalizedQuery,
    Iterable<String> values,
  ) {
    final searchableText = TourModel.normalizeSearchText(
      values.where((value) => value.trim().isNotEmpty).join(' '),
    );

    if (searchableText.isEmpty) {
      return false;
    }

    final searchTerms =
        normalizedQuery.split(' ').where((term) => term.isNotEmpty);

    return searchTerms.every(searchableText.contains);
  }

  Future<void> fetchCategories() async {
    isLoading = true;
    errorKey = '';
    notifyListeners();

    try {
      debugPrint('CategoriesController.fetchCategories: fetching...');
      categories = await _repository.getCategories();
      debugPrint(
        'CategoriesController.fetchCategories: fetched ${categories.length} categories',
      );
    } catch (e, s) {
      debugPrint('CategoriesController.fetchCategories ERROR: $e');
      debugPrintStack(stackTrace: s);
      errorKey = e.toString();
      categories = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTours() async {
    isLoading = true;
    errorKey = '';
    notifyListeners();

    try {
      debugPrint('CategoriesController.fetchTours: fetching...');
      _tours = await _tourRepository.getAllTours().catchError(
            (_) => <TourModel>[],
          );
      debugPrint(
        'CategoriesController.fetchTours: fetched ${_tours.length} tours',
      );
    } catch (e, s) {
      debugPrint('CategoriesController.fetchTours ERROR: $e');
      debugPrintStack(stackTrace: s);
      _tours = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

class CategorySearchResults {
  const CategorySearchResults({
    required this.query,
    required this.categories,
    required this.tours,
  });

  final String query;
  final List<CategoryModel> categories;
  final List<TourModel> tours;

  bool get hasQuery => TourModel.normalizeSearchText(query).isNotEmpty;
  bool get hasResults => categories.isNotEmpty || tours.isNotEmpty;
}
