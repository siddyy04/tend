import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/ai/providers/search/search_provider.dart';
import 'package:my_first_app/core/constants/enums.dart';
import 'package:my_first_app/domain/rules/search_ranking_rules.dart';

MemorySearchDocument _doc({
  required String uuid,
  required String personUuid,
  required String personName,
  required String eventText,
  MemoryCategory category = MemoryCategory.preferences,
  String? dateValueRaw,
  DateTime? dateValue,
  String? quoteEvidence,
  DateTime? createdAt,
}) {
  return MemorySearchDocument(
    memoryUuid: uuid,
    personUuid: personUuid,
    personName: personName,
    eventText: eventText,
    category: category,
    datePrecision:
        dateValue != null ? DatePrecision.explicit : DatePrecision.none,
    dateValueRaw: dateValueRaw,
    dateValue: dateValue,
    quoteEvidence: quoteEvidence,
    createdAt: createdAt ?? DateTime.utc(2024, 1, 1),
  );
}

void main() {
  group('normalizeSearchQuery / tokenize', () {
    test('trims, lowercases, collapses whitespace', () {
      expect(normalizeSearchQuery('  Hello   WORLD  '), 'hello world');
    });

    test('tokenizes on punctuation', () {
      expect(
        tokenizeSearchQuery('mom, physiotherapy?'),
        ['mom', 'physiotherapy'],
      );
    });
  });

  group('ranking', () {
    test('exact phrase beats all-terms beats partial', () {
      final docs = [
        _doc(
          uuid: 'partial',
          personUuid: 'p1',
          personName: 'A',
          eventText: 'talked about physiotherapy yesterday',
          createdAt: DateTime.utc(2024, 6, 1),
        ),
        _doc(
          uuid: 'all',
          personUuid: 'p1',
          personName: 'A',
          eventText: 'mom did say things about physiotherapy after lunch',
          createdAt: DateTime.utc(2024, 6, 2),
        ),
        _doc(
          uuid: 'exact',
          personUuid: 'p1',
          personName: 'A',
          eventText: 'what did mom say about physiotherapy later',
          createdAt: DateTime.utc(2024, 6, 3),
        ),
      ];

      final ranked = rankMemoriesForQuery(
        documents: docs,
        rawQuery: 'mom say about physiotherapy',
      );

      expect(ranked.map((m) => m.document.memoryUuid).toList(), [
        'exact',
        'all',
        'partial',
      ]);
      expect(ranked[0].matchKind, MatchKind.exactPhrase);
      expect(ranked[1].matchKind, MatchKind.allTerms);
      expect(ranked[2].matchKind, MatchKind.partial);
    });

    test('eventText match beats category-only at same kind', () {
      final docs = [
        _doc(
          uuid: 'cat-only',
          personUuid: 'p1',
          personName: 'A',
          eventText: 'went for a walk',
          category: MemoryCategory.health,
          createdAt: DateTime.utc(2024, 7, 2),
        ),
        _doc(
          uuid: 'in-event',
          personUuid: 'p1',
          personName: 'A',
          eventText: 'health checkup went well',
          category: MemoryCategory.preferences,
          createdAt: DateTime.utc(2024, 7, 1),
        ),
      ];

      final ranked = rankMemoriesForQuery(
        documents: docs,
        rawQuery: 'health',
      );

      expect(ranked.first.document.memoryUuid, 'in-event');
      expect(ranked.first.matchedInEventText, isTrue);
      expect(ranked.last.matchedInEventText, isFalse);
    });

    test('recency tiebreak uses dateValue then createdAt', () {
      final docs = [
        _doc(
          uuid: 'older',
          personUuid: 'p1',
          personName: 'A',
          eventText: 'Bangalore trip planned',
          dateValue: DateTime.utc(2023, 1, 1),
          createdAt: DateTime.utc(2024, 1, 1),
        ),
        _doc(
          uuid: 'newer',
          personUuid: 'p1',
          personName: 'A',
          eventText: 'Bangalore trip booked',
          dateValue: DateTime.utc(2024, 5, 1),
          createdAt: DateTime.utc(2024, 1, 1),
        ),
      ];

      final ranked = rankMemoriesForQuery(
        documents: docs,
        rawQuery: 'bangalore',
      );

      expect(ranked.map((m) => m.document.memoryUuid).toList(), [
        'newer',
        'older',
      ]);
    });

    test('case insensitive matching', () {
      final docs = [
        _doc(
          uuid: 'm1',
          personUuid: 'p1',
          personName: 'Mom',
          eventText: 'PhysioTherapy appointment',
        ),
      ];
      final ranked = rankMemoriesForQuery(
        documents: docs,
        rawQuery: 'PHYSIOTHERAPY',
      );
      expect(ranked, hasLength(1));
      expect(ranked.single.matchKind, MatchKind.exactPhrase);
    });

    test('empty query returns no hits', () {
      final docs = [
        _doc(
          uuid: 'm1',
          personUuid: 'p1',
          personName: 'A',
          eventText: 'anything',
        ),
      ];
      expect(
        rankMemoriesForQuery(documents: docs, rawQuery: '   '),
        isEmpty,
      );
    });

    test('person name and date fields are searchable', () {
      final docs = [
        _doc(
          uuid: 'm1',
          personUuid: 'p1',
          personName: 'Rahul',
          eventText: 'called about work',
          dateValueRaw: 'next month',
          dateValue: DateTime.utc(2024, 8, 1),
        ),
      ];
      expect(
        rankMemoriesForQuery(documents: docs, rawQuery: 'rahul').single
            .document.memoryUuid,
        'm1',
      );
      expect(
        rankMemoriesForQuery(documents: docs, rawQuery: 'next month').single
            .document.memoryUuid,
        'm1',
      );
      expect(
        rankMemoriesForQuery(documents: docs, rawQuery: '2024-08-01').single
            .document.memoryUuid,
        'm1',
      );
    });

    test('stable uuid tiebreak', () {
      final t = DateTime.utc(2024, 1, 1);
      final docs = [
        _doc(
          uuid: 'b',
          personUuid: 'p1',
          personName: 'A',
          eventText: 'gift idea',
          createdAt: t,
        ),
        _doc(
          uuid: 'a',
          personUuid: 'p1',
          personName: 'A',
          eventText: 'gift idea',
          createdAt: t,
        ),
      ];
      final ranked = rankMemoriesForQuery(documents: docs, rawQuery: 'gift');
      expect(ranked.map((m) => m.document.memoryUuid).toList(), ['a', 'b']);
    });
  });
}
