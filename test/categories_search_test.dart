import 'package:flutter_test/flutter_test.dart';
import 'package:razak_travel/data/models/category_model.dart';
import 'package:razak_travel/data/models/tour_model.dart';
import 'package:razak_travel/features/categories/categories_controller.dart';

CategoryModel buildCategory({
  required String id,
  required String name,
}) {
  return CategoryModel(
    id: id,
    names: {'en': name},
    image: '',
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

TourModel buildTour({
  required String id,
  required String categoryId,
  required String name,
  required String destination,
}) {
  return TourModel(
    id: id,
    names: {'en': name},
    categoryId: categoryId,
    destination: destination,
    price: 120,
    date: DateTime.utc(2026, 6, 12),
    totalSeats: 12,
    bookedSeats: 2,
  );
}

void main() {
  group('CategoriesController.filterCategoriesByQuery', () {
    final categories = [
      buildCategory(id: 'mountains', name: 'Mountain Adventures'),
      buildCategory(id: 'beach', name: 'Beach Holidays'),
    ];

    final tours = [
      buildTour(
        id: 'tour-1',
        categoryId: 'mountains',
        name: 'Alpine Escape',
        destination: 'Bishkek',
      ),
      buildTour(
        id: 'tour-2',
        categoryId: 'beach',
        name: 'Sunny Coast',
        destination: 'Antalya',
      ),
    ];

    test('matches category names directly without case sensitivity', () {
      final result = CategoriesController.filterCategoriesByQuery(
        categories: categories,
        tours: tours,
        query: 'MOUNTAIN',
      );

      expect(result.map((category) => category.id), ['mountains']);
    });

    test('keeps a category when a related tour name matches the query', () {
      final result = CategoriesController.filterCategoriesByQuery(
        categories: categories,
        tours: tours,
        query: 'alpine',
      );

      expect(result.map((category) => category.id), ['mountains']);
    });

    test('keeps a category when a related tour location matches the query', () {
      final result = CategoriesController.filterCategoriesByQuery(
        categories: categories,
        tours: tours,
        query: 'ANTALYA',
      );

      expect(result.map((category) => category.id), ['beach']);
    });

    test('matches combined category and related tour terms', () {
      final result = CategoriesController.filterCategoriesByQuery(
        categories: categories,
        tours: tours,
        query: 'beach antalya',
      );

      expect(result.map((category) => category.id), ['beach']);
    });

    test('returns an empty list when nothing matches', () {
      final result = CategoriesController.filterCategoriesByQuery(
        categories: categories,
        tours: tours,
        query: 'desert safari',
      );

      expect(result, isEmpty);
    });
  });
}
