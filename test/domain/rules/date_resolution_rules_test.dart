import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/domain/rules/date_resolution_rules.dart';

void main() {
  final anchor = DateTime(2026, 8, 8); // Saturday

  group('resolveRelativeDate', () {
    test('today / yesterday / tomorrow', () {
      expect(
        resolveRelativeDate(rawPhrase: 'today', anchorDate: anchor),
        DateTime(2026, 8, 8),
      );
      expect(
        resolveRelativeDate(rawPhrase: 'yesterday', anchorDate: anchor),
        DateTime(2026, 8, 7),
      );
      expect(
        resolveRelativeDate(rawPhrase: 'tomorrow', anchorDate: anchor),
        DateTime(2026, 8, 9),
      );
    });

    test('next week / last week / next month', () {
      expect(
        resolveRelativeDate(rawPhrase: 'next week', anchorDate: anchor),
        DateTime(2026, 8, 15),
      );
      expect(
        resolveRelativeDate(rawPhrase: 'last week', anchorDate: anchor),
        DateTime(2026, 8, 1),
      );
      expect(
        resolveRelativeDate(rawPhrase: 'next month', anchorDate: anchor),
        DateTime(2026, 9, 8),
      );
    });

    test('next weekday is strictly after anchor', () {
      // Anchor is Saturday 2026-08-08 → next Monday = 2026-08-10
      expect(
        resolveRelativeDate(rawPhrase: 'next Monday', anchorDate: anchor),
        DateTime(2026, 8, 10),
      );
      // next Saturday from Saturday → +7
      expect(
        resolveRelativeDate(rawPhrase: 'next saturday', anchorDate: anchor),
        DateTime(2026, 8, 15),
      );
    });

    test('in N days / weeks / months', () {
      expect(
        resolveRelativeDate(rawPhrase: 'in 3 days', anchorDate: anchor),
        DateTime(2026, 8, 11),
      );
      expect(
        resolveRelativeDate(rawPhrase: 'in 2 weeks', anchorDate: anchor),
        DateTime(2026, 8, 22),
      );
      expect(
        resolveRelativeDate(rawPhrase: 'in 1 month', anchorDate: anchor),
        DateTime(2026, 9, 8),
      );
    });

    test('uses createdAt anchor, not wall clock (backfill safety)', () {
      final captured = DateTime(2026, 8, 5);
      expect(
        resolveRelativeDate(rawPhrase: 'yesterday', anchorDate: captured),
        DateTime(2026, 8, 4),
      );
    });

    test('unresolvable phrases return null', () {
      expect(
        resolveRelativeDate(rawPhrase: 'sometime soon', anchorDate: anchor),
        isNull,
      );
      expect(
        resolveRelativeDate(rawPhrase: 'March 2024', anchorDate: anchor),
        isNull,
      );
      expect(
        resolveRelativeDate(rawPhrase: '', anchorDate: anchor),
        isNull,
      );
    });

    test('normalizes punctuation and case', () {
      expect(
        resolveRelativeDate(rawPhrase: 'Next Week.', anchorDate: anchor),
        DateTime(2026, 8, 15),
      );
    });
  });
}
