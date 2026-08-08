import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/ai/providers/extraction_provider.dart';
import 'package:my_first_app/core/constants/enums.dart';
import 'package:my_first_app/domain/rules/extraction_validation_rules.dart';

ExtractedMemoryCandidate _cand({
  required String person,
  required String event,
  String quote = '',
}) {
  return ExtractedMemoryCandidate(
    personMentioned: person,
    personMatchUuid: null,
    personMatchConfidence: 0,
    category: MemoryCategory.career,
    eventText: event,
    quoteEvidence: quote.isEmpty ? event : quote,
    datePrecision: DatePrecision.none,
    dateValueRaw: null,
    dateValue: null,
    importanceScore: 3,
    extractionConfidence: 1,
    followUpSuggested: false,
    followUpNote: null,
  );
}

void main() {
  group('isPronounPersonMention', () {
    test('detects personal pronouns', () {
      expect(isPronounPersonMention('He'), isTrue);
      expect(isPronounPersonMention('she'), isTrue);
      expect(isPronounPersonMention('THEY'), isTrue);
      expect(isPronounPersonMention('Rahul'), isFalse);
      expect(isPronounPersonMention('Mom'), isFalse);
    });
  });

  group('bindPronounPersonMentions', () {
    test('single-person pronouns bind to the explicit name', () {
      final bound = bindPronounPersonMentions(
        candidates: [
          _cand(person: 'Rahul', event: 'Met Rahul yesterday'),
          _cand(person: 'He', event: 'He got selected by OpenAI'),
        ],
        knownPeople: const [(uuid: 'u1', name: 'Rahul')],
      );
      expect(bound.map((c) => c.personMentioned).toList(), [
        'Rahul',
        'Rahul',
      ]);
      expect(bound[1].personMatchUuid, 'u1');
      expect(bound[1].personMatchConfidence, 1.0);
    });

    test('empty personMentioned binds when sole antecedent exists', () {
      final bound = bindPronounPersonMentions(
        candidates: [
          _cand(person: 'Mom', event: 'Mom had surgery'),
          _cand(person: '', event: 'She started physiotherapy'),
        ],
        knownPeople: const [(uuid: 'm1', name: 'Mom')],
      );
      expect(bound[1].personMentioned, 'Mom');
      expect(bound[1].personMatchUuid, 'm1');
    });

    test('ambiguous pronouns fail safe (two distinct people)', () {
      final bound = bindPronounPersonMentions(
        candidates: [
          _cand(person: 'Rahul', event: 'Rahul joined OpenAI'),
          _cand(person: 'Priya', event: 'Priya moved to Berlin'),
          _cand(person: 'He', event: 'He loves tea'),
        ],
        knownPeople: const [
          (uuid: 'r', name: 'Rahul'),
          (uuid: 'p', name: 'Priya'),
        ],
      );
      expect(bound[2].personMentioned, 'He');
      expect(bound[2].personMatchUuid, isNull);
    });

    test('multiple people with explicit names are unchanged', () {
      final bound = bindPronounPersonMentions(
        candidates: [
          _cand(person: 'Rahul', event: 'Rahul likes tea'),
          _cand(person: 'Priya', event: 'Priya plays cricket'),
        ],
        knownPeople: const [
          (uuid: 'r', name: 'Rahul'),
          (uuid: 'p', name: 'Priya'),
        ],
      );
      expect(bound.map((c) => c.personMentioned).toList(), [
        'Rahul',
        'Priya',
      ]);
    });

    test('mixed family: She binds to Mom when Mom is sole antecedent', () {
      final bound = bindPronounPersonMentions(
        candidates: [
          _cand(person: 'Mom', event: 'Mom had surgery'),
          _cand(person: 'She', event: 'She is recovering well'),
        ],
        knownPeople: const [(uuid: 'm', name: 'Mom')],
      );
      expect(bound[1].personMentioned, 'Mom');
    });

    test('mixed family with Dad then Mom: He does not bind (ambiguous)', () {
      final bound = bindPronounPersonMentions(
        candidates: [
          _cand(person: 'Dad', event: 'Dad retired last month'),
          _cand(person: 'Mom', event: 'Mom started physiotherapy'),
          _cand(person: 'He', event: 'He walks every morning'),
        ],
        knownPeople: const [
          (uuid: 'd', name: 'Dad'),
          (uuid: 'm', name: 'Mom'),
        ],
      );
      expect(bound[2].personMentioned, 'He');
    });

    test('repeated same person then pronoun still binds', () {
      final bound = bindPronounPersonMentions(
        candidates: [
          _cand(person: 'Priya', event: 'Priya joined Google'),
          _cand(person: 'Priya', event: 'Priya moved to Bangalore'),
          _cand(person: 'She', event: 'She loves her new team'),
        ],
        knownPeople: const [(uuid: 'p', name: 'Priya')],
      );
      expect(bound[2].personMentioned, 'Priya');
    });

    test('leading pronoun with no antecedent stays unresolved', () {
      final bound = bindPronounPersonMentions(
        candidates: [
          _cand(person: 'He', event: 'He got selected by OpenAI'),
        ],
        knownPeople: const [(uuid: 'r', name: 'Rahul')],
      );
      expect(bound.single.personMentioned, 'He');
    });
  });
}
