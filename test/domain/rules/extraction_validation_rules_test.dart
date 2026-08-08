import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/ai/providers/extraction_provider.dart';
import 'package:my_first_app/core/constants/enums.dart';
import 'package:my_first_app/domain/rules/extraction_validation_rules.dart';

ExtractedMemoryCandidate _cand({
  required String quote,
  String? dateRaw,
  bool followUpSuggested = false,
  String? followUpNote,
}) {
  return ExtractedMemoryCandidate(
    personMentioned: 'Pooja',
    personMatchUuid: null,
    personMatchConfidence: 0,
    category: MemoryCategory.preferences,
    eventText: 'likes tea',
    quoteEvidence: quote,
    datePrecision: dateRaw == null ? DatePrecision.none : DatePrecision.relative,
    dateValueRaw: dateRaw,
    dateValue: null,
    importanceScore: 3,
    extractionConfidence: 1,
    followUpSuggested: followUpSuggested,
    followUpNote: followUpNote,
  );
}

void main() {
  const note = 'Pooja likes tea.';

  test('accepts case-insensitive contiguous quote', () {
    final c = _cand(quote: 'pooja likes tea.');
    expect(quoteAppearsVerbatimInSource(c, note), isTrue);
    expect(passesLiteralExtractionGuards(c, note), isTrue);
  });

  test('rejects fabricated quote', () {
    final c = _cand(quote: 'I love tea with friends at the weekend.');
    expect(quoteAppearsVerbatimInSource(c, note), isFalse);
    expect(passesLiteralExtractionGuards(c, note), isFalse);
  });

  test('rejects invented date phrase', () {
    final c = _cand(quote: 'Pooja likes tea.', dateRaw: 'last weekend');
    expect(datePhraseGroundedInSource(c, note), isFalse);
    expect(passesLiteralExtractionGuards(c, note), isFalse);
  });

  test('accepts date phrase present in note', () {
    const birthday = "Dad's birthday is on 15 August.";
    final c = const ExtractedMemoryCandidate(
      personMentioned: 'Dad',
      personMatchUuid: null,
      personMatchConfidence: 0,
      category: MemoryCategory.preferences,
      eventText: 'birthday',
      quoteEvidence: birthday,
      datePrecision: DatePrecision.relative,
      dateValueRaw: '15 August',
      dateValue: null,
      importanceScore: 3,
      extractionConfidence: 1,
      followUpSuggested: false,
      followUpNote: null,
    );
    expect(passesLiteralExtractionGuards(c, birthday), isTrue);
  });

  test('rejects invented follow-up', () {
    final c = _cand(quote: note, followUpSuggested: true, followUpNote: 'Ask about tea brands');
    expect(hasNoInventedFollowUp(c), isFalse);
    expect(passesLiteralExtractionGuards(c, note), isFalse);
  });

  test('validatedCategory accepts enum names case-insensitively', () {
    expect(validatedCategory('health'), MemoryCategory.health);
    expect(validatedCategory(' Career '), MemoryCategory.career);
    expect(validatedCategory('not-a-category'), isNull);
    expect(validatedCategory(''), isNull);
  });

  test('classifyDatePrecision: calendar phrases are explicit', () {
    expect(classifyDatePrecision('15 August'), DatePrecision.explicit);
    expect(classifyDatePrecision('March 2024'), DatePrecision.explicit);
    expect(classifyDatePrecision('2024-03-15'), DatePrecision.explicit);
  });

  test('classifyDatePrecision: relative phrases stay relative', () {
    expect(classifyDatePrecision('tomorrow'), DatePrecision.relative);
    expect(classifyDatePrecision('yesterday'), DatePrecision.relative);
    expect(classifyDatePrecision('next week'), DatePrecision.relative);
    expect(classifyDatePrecision('next Thursday'), DatePrecision.relative);
    expect(classifyDatePrecision('1.5 months back'), DatePrecision.relative);
    expect(classifyDatePrecision('in 3 months'), DatePrecision.relative);
  });

  test('classifyDatePrecision: empty is none', () {
    expect(classifyDatePrecision(null), DatePrecision.none);
    expect(classifyDatePrecision(''), DatePrecision.none);
  });

  test('resolveUniquePersonNameMatch is case-insensitive and unique-only', () {
    final people = [
      (uuid: 'u1', name: ' Priya '),
      (uuid: 'u2', name: 'Dad'),
      (uuid: 'u3', name: 'dad'),
    ];
    expect(resolveUniquePersonNameMatch(personMentioned: 'priya', knownPeople: people), (
      uuid: 'u1',
      confidence: 1.0,
    ));
    expect(
      resolveUniquePersonNameMatch(personMentioned: 'Dad', knownPeople: people).uuid,
      isNull,
      reason: 'Dad and dad collide case-insensitively',
    );
    expect(resolveUniquePersonNameMatch(personMentioned: 'Mom', knownPeople: people).uuid, isNull);
  });

  test('hasExactPersonNameMatch is trimmed case-insensitive', () {
    expect(
      hasExactPersonNameMatch(
        personMentioned: ' mom ',
        knownNames: ['Mom', 'Dad'],
      ),
      isTrue,
    );
    expect(
      hasExactPersonNameMatch(
        personMentioned: 'Priya',
        knownNames: ['Mom', 'Dad'],
      ),
      isFalse,
    );
    expect(
      hasExactPersonNameMatch(
        personMentioned: '  ',
        knownNames: ['Mom'],
      ),
      isFalse,
    );
  });

  test('countExactPersonNameMatches detects ambiguous duplicates', () {
    expect(
      countExactPersonNameMatches(
        personMentioned: 'John',
        knownNames: ['John', ' john ', 'Dad'],
      ),
      2,
    );
    expect(
      countExactPersonNameMatches(
        personMentioned: 'John',
        knownNames: ['John Smith', 'Dad'],
      ),
      0,
    );
  });

  group('ambiguousPersonClarifications', () {
    ExtractedMemoryCandidate mention(String name) {
      return ExtractedMemoryCandidate(
        personMentioned: name,
        personMatchUuid: null,
        personMatchConfidence: 0,
        category: MemoryCategory.preferences,
        eventText: 'event',
        quoteEvidence: '$name event',
        datePrecision: DatePrecision.none,
        dateValueRaw: null,
        dateValue: null,
        importanceScore: 3,
        extractionConfidence: 1,
        followUpSuggested: false,
        followUpNote: null,
      );
    }

    test('emits which-person note when multiple exact Circle matches', () {
      final notes = ambiguousPersonClarifications(
        candidates: [mention('John'), mention('Sarah')],
        knownNames: const ['John', 'john', 'Sarah'],
      );
      expect(notes, hasLength(1));
      expect(notes.single.reason, 'Which "John" did you mean?');
      expect(notes.single.rawSnippet, 'John');
    });

    test('emits nothing for unique or zero matches', () {
      final notes = ambiguousPersonClarifications(
        candidates: [mention('Pooja'), mention('Unknown')],
        knownNames: const ['Pooja', 'Mom'],
      );
      expect(notes, isEmpty);
    });

    test('dedupes repeated mentions of the same ambiguous name', () {
      final notes = ambiguousPersonClarifications(
        candidates: [mention('John'), mention('john')],
        knownNames: const ['John', 'JOHN'],
      );
      expect(notes, hasLength(1));
    });
  });
}
