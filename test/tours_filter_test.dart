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
  required double price,
  int bookingCount = 0,
}) {
  return TourModel(
    id: id,
    names: {'en': name},
    categoryId: categoryId,
    destination: destination,
    price: price,
    date: DateTime.utc(2026, 6, 12),
    totalSeats: 12,
    bookedSeats: 2,
    bookingCount: bookingCount,
  );
}

List<TourModel> filterToursByCriteria({
  required List<TourModel> tours,
  required Map<String, CategoryModel> categoryById,
  required String searchQuery,
  String? selectedCategoryId,
  double? minPrice,
  double? maxPrice,
}) {
  final categories = categoryById.values.toList(growable: false);
  final normalizedQuery = TourModel.normalizeSearchText(searchQuery);

  final filtered = tours.where((tour) {
    if (selectedCategoryId != null &&
        selectedCategoryId.isNotEmpty &&
        tour.categoryId != selectedCategoryId) {
      return false;
    }
    if (minPrice != null && tour.price < minPrice) {
      return false;
    }
    if (maxPrice != null && tour.price > maxPrice) {
      return false;
    }
    if (normalizedQuery.isEmpty) {
      return true;
    }

    final matches = CategoriesController.filterToursByQuery(
      categories: categories,
      tours: [tour],
      query: normalizedQuery,
    );
    return matches.isNotEmpty;
  }).toList(growable: false);

  filtered.sort((left, right) {
    final bookingCompare = right.bookingCount.compareTo(left.bookingCount);
    if (bookingCompare != 0) {
      return bookingCompare;
    }

    final dateCompare = left.date.compareTo(right.date);
    if (dateCompare != 0) {
      return dateCompare;
    }

    return left.id.compareTo(right.id);
  });

  return filtered;
}

void main() {
  group('filterToursByCriteria', () {
    final categoryById = {
      'mountains': buildCategory(
        id: 'mountains',
        name: 'Mountain Adventures',
      ),
      'beach': buildCategory(
        id: 'beach',
        name: 'Beach Holidays',
      ),
    };

    final tours = [
      buildTour(
        id: 'tour-1',
        categoryId: 'mountains',
        name: 'Alpine Escape',
        destination: 'Bishkek',
        price: 120,
      ),
      buildTour(
        id: 'tour-2',
        categoryId: 'beach',
        name: 'Sunny Coast',
        destination: 'Antalya',
        price: 240,
      ),
      buildTour(
        id: 'tour-3',
        categoryId: 'beach',
        name: 'Golden Bay',
        destination: 'Bodrum',
        price: 420,
      ),
    ];

    test('filters tours by inclusive price range', () {
      final result = filterToursByCriteria(
        tours: tours,
        categoryById: categoryById,
        searchQuery: '',
        minPrice: 120,
        maxPrice: 240,
      );

      expect(result.map((tour) => tour.id), ['tour-1', 'tour-2']);
    });

    test('keeps existing search and category filters working with price range', () {
      final result = filterToursByCriteria(
        tours: tours,
        categoryById: categoryById,
        searchQuery: 'beach antalya',
        selectedCategoryId: 'beach',
        minPrice: 200,
        maxPrice: 260,
      );

      expect(result.map((tour) => tour.id), ['tour-2']);
    });

    test('excludes tours outside the selected budget even if search matches', () {
      final result = filterToursByCriteria(
        tours: tours,
        categoryById: categoryById,
        searchQuery: 'golden',
        minPrice: 100,
        maxPrice: 300,
      );

      expect(result, isEmpty);
    });

    test('sorts filtered tours by popularity before date', () {
      final result = filterToursByCriteria(
        tours: [
          buildTour(
            id: 'tour-1',
            categoryId: 'beach',
            name: 'Sunny Coast',
            destination: 'Antalya',
            price: 240,
            bookingCount: 2,
          ),
          buildTour(
            id: 'tour-2',
            categoryId: 'beach',
            name: 'Golden Bay',
            destination: 'Bodrum',
            price: 240,
            bookingCount: 5,
          ),
          buildTour(
            id: 'tour-3',
            categoryId: 'mountains',
            name: 'Alpine Escape',
            destination: 'Bishkek',
            price: 120,
            bookingCount: 1,
          ),
        ],
        categoryById: categoryById,
        searchQuery: '',
        minPrice: 100,
        maxPrice: 300,
      );

      expect(result.map((tour) => tour.id), ['tour-2', 'tour-1', 'tour-3']);
    });
  });
}
