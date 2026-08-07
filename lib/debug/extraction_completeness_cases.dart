/// Permanent extraction-completeness regression cases (ADR-012).
///
/// Twin of [EXTRACTION_COMPLETENESS_BENCHMARK.md]. Use when refining
/// [LiteRtPromptBuilder] prompts — do not change the one FunctionCall → one
/// memory contract to “fix” these cases.
library;

/// One completeness-benchmark note and its expected memory count / hints.
class ExtractionCompletenessCase {
  const ExtractionCompletenessCase({
    required this.id,
    required this.note,
    required this.expectedCount,
    this.expectedPerson = '',
    this.factHints = const [],
    this.description = '',
  });

  final String id;
  final String note;
  final int expectedCount;

  /// Canonical person name expected on each memory (after pronoun binding).
  /// Empty when [expectedCount] is 0 (insufficient-information cases).
  final String expectedPerson;

  /// Substrings that should each appear in exactly one accepted memory
  /// (event or quote), for coverage / anti-merge checks.
  final List<String> factHints;

  final String description;

  /// True when the note must yield zero native function calls.
  bool get expectsNoMemories => expectedCount == 0;
}

/// Multi-memory completeness (pronouns, compounds, relative dates).
const extractionCompletenessCases = <ExtractionCompletenessCase>[
  ExtractionCompletenessCase(
    id: 'c1_pronouns_compound',
    description:
        'Later sentences use She; second sentence holds two facts with and.',
    note:
        'Mom had spinal surgery. She started physiotherapy and is recovering well.',
    expectedCount: 3,
    expectedPerson: 'Mom',
    factHints: [
      'spinal surgery',
      'physiotherapy',
      'recovering',
    ],
  ),
  ExtractionCompletenessCase(
    id: 'c2_same_person_pronouns',
    description: 'Same person, four memories, pronoun subject each time.',
    note:
        'Priya joined Google. She moved to Bangalore. '
        'She loves her new team. She is saving for a house.',
    expectedCount: 4,
    expectedPerson: 'Priya',
    factHints: [
      'Google',
      'Bangalore',
      'new team',
      'saving for a house',
    ],
  ),
  ExtractionCompletenessCase(
    id: 'c3_compound_sentence',
    description: 'Two independent facts joined by and in one sentence.',
    note: 'Rahul likes tea and plays cricket.',
    expectedCount: 2,
    expectedPerson: 'Rahul',
    factHints: [
      'tea',
      'cricket',
    ],
  ),
  ExtractionCompletenessCase(
    id: 'c4_mixed_pronouns',
    description: 'He refers to Dad across sentences.',
    note: 'Dad retired last month. He now walks every morning.',
    expectedCount: 2,
    expectedPerson: 'Dad',
    factHints: [
      'retired',
      'walks',
    ],
  ),
  ExtractionCompletenessCase(
    id: 'c5_relative_dates_pronouns',
    description: 'Relative dates plus pronoun continuation.',
    note:
        'Mom has a follow-up next week. She started physiotherapy yesterday.',
    expectedCount: 2,
    expectedPerson: 'Mom',
    factHints: [
      'follow-up',
      'physiotherapy',
    ],
  ),
];

/// Insufficient-information notes: must yield zero native FunctionCalls.
const extractionInsufficientInformationCases = <ExtractionCompletenessCase>[
  ExtractionCompletenessCase(
    id: 'i1_emily',
    description: 'Bare name must not invent a biography.',
    note: 'Emily',
    expectedCount: 0,
  ),
  ExtractionCompletenessCase(
    id: 'i2_john',
    description: 'Bare name.',
    note: 'John',
    expectedCount: 0,
  ),
  ExtractionCompletenessCase(
    id: 'i3_mom',
    description: 'Bare kinship label without a fact.',
    note: 'Mom',
    expectedCount: 0,
  ),
  ExtractionCompletenessCase(
    id: 'i4_yesterday',
    description: 'Lone relative-date word without a fact.',
    note: 'Yesterday',
    expectedCount: 0,
  ),
  ExtractionCompletenessCase(
    id: 'i5_tea',
    description: 'Lone preference word without a person/fact clause.',
    note: 'Tea',
    expectedCount: 0,
  ),
  ExtractionCompletenessCase(
    id: 'i6_google',
    description: 'Lone entity word without a relationship fact.',
    note: 'Google',
    expectedCount: 0,
  ),
];

/// All completeness + insufficient-information cases for a full regression run.
const extractionQualityRegressionCases = <ExtractionCompletenessCase>[
  ...extractionCompletenessCases,
  ...extractionInsufficientInformationCases,
];
