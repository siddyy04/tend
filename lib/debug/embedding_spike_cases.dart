/// Fixed Phase 3.2 embedding-spike benchmark cases (SPRINT3_2.md §11).
///
/// Hand-authored synthetic set for directional go/no-go — not a full relevance
/// suite (that belongs to Phase 3.3/3.5). Reusable as a seed for later work.
library;

/// One memory document in the spike corpus.
class EmbeddingSpikeDocument {
  const EmbeddingSpikeDocument({
    required this.id,
    required this.eventText,
    this.category = '',
    this.personName = '',
  });

  final String id;
  final String eventText;
  final String category;
  final String personName;

  String get indexText {
    final parts = <String>[
      if (personName.isNotEmpty) personName,
      if (category.isNotEmpty) category,
      eventText,
    ];
    return parts.join(' · ');
  }
}

/// One query with expected top document id(s).
class EmbeddingSpikeQuery {
  const EmbeddingSpikeQuery({
    required this.id,
    required this.query,
    required this.expectedDocIds,
    required this.kind,
    this.notes = '',
  });

  final String id;
  final String query;

  /// Ordered preference: first id is the ideal top hit.
  final List<String> expectedDocIds;

  /// exact | paraphrase | category | negative
  final String kind;
  final String notes;
}

/// Synthetic corpus — short, structured, named-entity-heavy (Tend-shaped).
const embeddingSpikeCorpus = <EmbeddingSpikeDocument>[
  EmbeddingSpikeDocument(
    id: 'd_physio',
    personName: 'Mom',
    category: 'health',
    eventText: 'Mom started physiotherapy last week',
  ),
  EmbeddingSpikeDocument(
    id: 'd_openai',
    personName: 'Rahul',
    category: 'career',
    eventText: 'Rahul got selected by OpenAI',
  ),
  EmbeddingSpikeDocument(
    id: 'd_bangalore',
    personName: 'Priya',
    category: 'milestones',
    eventText: 'Priya moved to Bangalore in September',
  ),
  EmbeddingSpikeDocument(
    id: 'd_tea',
    personName: 'Rahul',
    category: 'preferences',
    eventText: 'Rahul likes tea',
  ),
  EmbeddingSpikeDocument(
    id: 'd_house',
    personName: 'Priya',
    category: 'goals',
    eventText: 'Priya is saving for a house',
  ),
  EmbeddingSpikeDocument(
    id: 'd_surgery',
    personName: 'Mom',
    category: 'health',
    eventText: 'Mom had spinal surgery 1.5 months back',
  ),
  EmbeddingSpikeDocument(
    id: 'd_cricket',
    personName: 'Rahul',
    category: 'hobbies',
    eventText: 'Rahul plays cricket on weekends',
  ),
];

/// Queries covering exact, paraphrase, category-ish, and negative cases.
const embeddingSpikeQueries = <EmbeddingSpikeQuery>[
  EmbeddingSpikeQuery(
    id: 'q_exact_openai',
    query: 'OpenAI',
    expectedDocIds: ['d_openai'],
    kind: 'exact',
    notes: 'Literal entity overlap — keyword search already wins this.',
  ),
  EmbeddingSpikeQuery(
    id: 'q_exact_physio',
    query: 'physiotherapy',
    expectedDocIds: ['d_physio'],
    kind: 'exact',
  ),
  EmbeddingSpikeQuery(
    id: 'q_paraphrase_job',
    query: 'Where did Rahul get a new job?',
    expectedDocIds: ['d_openai'],
    kind: 'paraphrase',
    notes: 'Little lexical overlap with "got selected by OpenAI".',
  ),
  EmbeddingSpikeQuery(
    id: 'q_paraphrase_rehab',
    query: 'Is Mom recovering with physical therapy?',
    expectedDocIds: ['d_physio', 'd_surgery'],
    kind: 'paraphrase',
    notes: 'Paraphrase of physiotherapy / surgery health cluster.',
  ),
  EmbeddingSpikeQuery(
    id: 'q_paraphrase_city',
    query: 'Who relocated to a new city?',
    expectedDocIds: ['d_bangalore'],
    kind: 'paraphrase',
  ),
  EmbeddingSpikeQuery(
    id: 'q_category_health',
    query: 'health updates about Mom',
    expectedDocIds: ['d_physio', 'd_surgery'],
    kind: 'category',
  ),
  EmbeddingSpikeQuery(
    id: 'q_negative_wedding',
    query: 'wedding anniversary plans',
    expectedDocIds: [],
    kind: 'negative',
    notes: 'No related memory — top hits should not look confidently relevant.',
  ),
];

/// Placeholder slots for anonymized real queries from on-device search log.
///
/// Filled at spike runtime if `search_query_log_v1` is readable; otherwise left
/// empty and documented as unknown in findings.
const embeddingSpikeRealQueryPlaceholders = <String>[
  // Intentionally empty in repo — populated only from device log during spike.
];
