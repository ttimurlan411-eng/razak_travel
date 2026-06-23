import 'package:flutter_test/flutter_test.dart';
import 'package:razak_travel/data/models/tour_model.dart';

TourModel buildTourFixture() {
  return TourModel(
    id: 'tour-1',
    names: const {
      'en': 'Alpine Escape',
      'ru': '\u0410\u043b\u044c\u043f\u0438\u0439\u0441\u043a\u0438\u0439 \u043e\u0442\u0434\u044b\u0445',
      'ky': '\u0422\u043e\u043e\u043b\u0443\u0443 \u044d\u0441 \u0430\u043b\u0443\u0443',
    },
    categoryId: 'mountains',
    destination: 'Bishkek',
    price: 149.99,
    date: DateTime.utc(2026, 6, 12),
    totalSeats: 18,
    bookedSeats: 5,
  );
}

void main() {
  group('TourModel.matchesSearchQuery', () {
    test('matches tour titles across languages without case sensitivity', () {
      final tour = buildTourFixture();

      expect(tour.matchesSearchQuery('ALPINE'), isTrue);
      expect(
        tour.matchesSearchQuery(
          '\u0430\u043b\u044c\u041f\u0418\u0419\u0421\u041a\u0418\u0419',
        ),
        isTrue,
      );
      expect(
        tour.matchesSearchQuery('\u042d\u0421 \u0410\u041b\u0423\u0423'),
        isTrue,
      );
    });

    test('matches city and category names with normalized spacing', () {
      final tour = buildTourFixture();
      const categoryNames = [
        'Mountain Adventures',
        '\u0413\u043e\u0440\u043d\u044b\u0435 \u043f\u0440\u0438\u043a\u043b\u044e\u0447\u0435\u043d\u0438\u044f',
        '\u0422\u043e\u043e\u043b\u0443\u0443 \u0441\u0430\u044f\u043a\u0430\u0442\u0442\u0430\u0440',
      ];

      expect(
        tour.matchesSearchQuery(
          '  bishkek   mountain  ',
          categoryNames: categoryNames,
        ),
        isTrue,
      );
      expect(
        tour.matchesSearchQuery(
          '\u0433\u043e\u0440\u043d\u044b\u0435',
          categoryNames: categoryNames,
        ),
        isTrue,
      );
      expect(
        tour.matchesSearchQuery(
          '\u0441\u0430\u044f\u043a\u0430\u0442\u0442\u0430\u0440',
          categoryNames: categoryNames,
        ),
        isTrue,
      );
    });

    test('returns false when no searchable field matches the query', () {
      final tour = buildTourFixture();

      expect(
        tour.matchesSearchQuery(
          'desert safari',
          categoryNames: const ['Mountain Adventures'],
        ),
        isFalse,
      );
    });
  });
}
