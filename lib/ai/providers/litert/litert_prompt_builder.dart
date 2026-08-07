import 'package:my_first_app/data/local/isar/collections/person.dart';

/// Vendor-neutral tool definition for extraction function calling.
///
/// Converted to `flutter_gemma` [Tool] only inside [LiteRtInferenceAdapter]
/// when tools are enabled.
class LiteRtToolDefinition {
  const LiteRtToolDefinition({
    required this.name,
    required this.description,
    required this.parameters,
  });

  final String name;
  final String description;

  /// JSON-Schema-shaped map for the tool parameters object.
  final Map<String, dynamic> parameters;
}

/// Prompt + tool bundle produced for one extraction call.
class LiteRtPromptBundle {
  const LiteRtPromptBundle({
    required this.systemInstruction,
    required this.userPrompt,
    required this.tools,
  });

  final String systemInstruction;
  final String userPrompt;
  final List<LiteRtToolDefinition> tools;
}

/// Builds extraction prompts — no inference.
///
/// Schema: person, event, verbatim quote, optional date phrase, and a
/// [MemoryCategory] enum name. Importance / follow-up / confidence stay
/// app-owned; invalid categories are rejected at mapping time.
///
/// Architectural contract (ADR-012): one native FunctionCall maps to one
/// [ExtractedMemoryCandidate]. Prompt refinements may improve completeness
/// but must not bundle multiple memories into a single call.
class LiteRtPromptBuilder {
  const LiteRtPromptBuilder();

  static const String extractMemoriesToolName = 'extract_memories';

  static const List<String> categoryEnumNames = [
    'family',
    'career',
    'health',
    'education',
    'travel',
    'finance',
    'goals',
    'hobbies',
    'preferences',
    'promises',
    'milestones',
  ];

  /// Builds the system instruction, user prompt, and tool list for [text].
  LiteRtPromptBundle build({
    required String text,
    required List<Person> knownPeople,
  }) {
    return LiteRtPromptBundle(
      // Not passed into createChat for Gemma 4 (SDK tools prompt is native).
      systemInstruction: '',
      userPrompt: _buildUserPrompt(text: text, knownPeople: knownPeople),
      tools: const [_extractMemoriesTool],
    );
  }

  static const LiteRtToolDefinition _extractMemoriesTool = LiteRtToolDefinition(
    name: extractMemoriesToolName,
    description:
        'Extract one stable, independently useful memory fact from the note. '
        'Call this tool once per such memory — including status, progress, '
        'and recovery updates when they provide lasting relationship context. '
        'If the note does not contain at least one explicit, stable memory or '
        'relationship fact, do not call this tool at all. '
        'Never invent a memory simply to satisfy the tool. '
        'Zero calls is a valid outcome. '
        'Do not invent, infer, or complete missing details. '
        'quoteEvidence must be an exact substring of the note. '
        'If the note contains any explicit or relative temporal phrase, '
        'copy that phrase verbatim into dateValueRaw. '
        'Pick exactly one category from the allowed enum list.',
    parameters: {
      'type': 'object',
      'properties': {
        'personMentioned': {
          'type': 'string',
          'description':
              'Person name exactly as written in the note. Empty if none.',
        },
        'eventText': {
          'type': 'string',
          'description':
              'Complete primary clause from the note, including the subject '
              '(e.g. "John works at Google" not "works at Google"). '
              'Use only words from the note; do not invent.',
        },
        'quoteEvidence': {
          'type': 'string',
          'description':
              'Exact contiguous substring copied from the note that supports '
              'the memory. Must match the note character-for-character.',
        },
        'dateValueRaw': {
          'type': 'string',
          'description':
              'When the note contains any explicit or relative temporal '
              'phrase (e.g. "yesterday", "next week", "Sunday", '
              '"March 2024", "1.5 months back", "15 August"), copy that '
              'phrase verbatim into this field. Do not normalize, infer, or '
              'calculate dates. Empty string only if no temporal phrase '
              'appears.',
        },
        'category': {
          'type': 'string',
          'description':
              'Exactly one allowed category name for this memory. '
              'Must be one of: family, career, health, education, travel, '
              'finance, goals, hobbies, preferences, promises, milestones. '
              'Disambiguation examples: '
              '"saving for a house" → goals; '
              '"saving money in a bank account" → finance; '
              '"moved to another city/country" → milestones; '
              '"visited another city/country" → travel.',
          'enum': categoryEnumNames,
        },
      },
      'required': [
        'personMentioned',
        'eventText',
        'quoteEvidence',
        'category',
      ],
    },
  );

  String _buildUserPrompt({
    required String text,
    required List<Person> knownPeople,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(
      'Extract every stable, independently useful memory that is literally '
      'written. Call extract_memories once per such memory '
      '(same person with several facts → several tool calls; never merge them). '
      'If the note does not contain at least one explicit, stable memory or '
      'relationship fact, produce no function calls. '
      'Never invent a memory simply to satisfy the tool. '
      'Returning zero memories is acceptable and preferred over fabrication '
      '(e.g. a bare name like "Emily" or a lone word like "Yesterday" is not enough). '
      'Do not skip status, progress, or recovery facts when they provide '
      'meaningful long-term relationship context '
      '(e.g. recovering well, started physiotherapy, doing better). '
      'When you do extract, use the extract_memories tool — never answer with '
      'free text or JSON. '
      'Do not invent follow-ups, importance, or missing facts. '
      'quoteEvidence must be copied exactly from the note. '
      'eventText must be the complete primary clause including the subject '
      '(not a verb fragment). '
      'If the note contains any explicit or relative temporal phrase '
      '(e.g. yesterday, next week, Sunday, March 2024, 1.5 months back), '
      'always copy that phrase verbatim into dateValueRaw. '
      'Do not normalize, infer, or calculate dates — copy the text exactly '
      'as it appears. '
      'Set category to exactly one of: '
      '${categoryEnumNames.join(', ')}. '
      'Category disambiguation examples (choose the closer meaning): '
      '"saving for a house" → goals; '
      '"saving money in a bank account" → finance; '
      '"moved to another city/country" → milestones; '
      '"visited another city/country" → travel.',
    );
    buffer.writeln();
    buffer.writeln(
      'Completeness: if one person has several stable facts in the Note, '
      'emit several extract_memories tool calls (never merge). '
      'Include recovery/progress/status updates when present in the Note. '
      'If there is no explicit fact, emit zero calls — do not fabricate. '
      'quoteEvidence and eventText must use only words from the Note below — '
      'never from this instruction text.',
    );
    buffer.writeln(
      'Example pattern: a career fact and a preference about the same person '
      '→ two tool calls. A surgery fact and a recovering-well fact about the '
      'same person → two tool calls (do not drop recovering-well).',
    );
    buffer.writeln();
    if (knownPeople.isNotEmpty) {
      buffer.writeln('Known people:');
      final limit = knownPeople.length < 8 ? knownPeople.length : 8;
      for (var i = 0; i < limit; i++) {
        buffer.writeln('- ${knownPeople[i].name}');
      }
      buffer.writeln();
    }
    buffer.writeln('Note: ${text.trim()}');
    return buffer.toString();
  }
}
