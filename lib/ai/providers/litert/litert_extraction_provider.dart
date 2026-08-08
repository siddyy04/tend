import 'package:flutter/foundation.dart';
import 'package:my_first_app/ai/providers/extraction_provider.dart';
import 'package:my_first_app/ai/providers/litert/litert_inference_adapter.dart';
import 'package:my_first_app/ai/providers/litert/litert_prompt_builder.dart';
import 'package:my_first_app/core/constants/extraction_defaults.dart';
import 'package:my_first_app/data/local/isar/collections/person.dart';
import 'package:my_first_app/domain/rules/extraction_validation_rules.dart';

/// Concrete [ExtractionProvider] backed by on-device LiteRT via the adapter.
///
/// Builds prompts, runs inference through [LiteRtInferenceAdapter], and maps
/// raw tool-call args into [ExtractionResult]. Does not import `flutter_gemma`.
/// Which model runs is decided by [ModelCatalog], not this class.
class LiteRtExtractionProvider implements ExtractionProvider {
  LiteRtExtractionProvider({
    required this.adapter,
    this.promptBuilder = const LiteRtPromptBuilder(),
  });

  final LiteRtInferenceAdapter adapter;
  final LiteRtPromptBuilder promptBuilder;

  /// Soft-failure / empty debug detail for Capture (debug builds only).
  ///
  /// Prefer [lastPipelineFailureReason] to decide Failed vs Empty UX.
  String? lastFailureReason;

  /// Set only for genuine pipeline failures (install/inference/exception).
  /// Mapping zero candidates or intentional zero tool calls are not failures.
  String? lastPipelineFailureReason;

  @override
  Future<ExtractionResult> extract({
    required String text,
    required List<Person> knownPeople,
  }) async {
    lastFailureReason = null;
    lastPipelineFailureReason = null;
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const ExtractionResult(candidates: []);
    }

    try {
      final bundle = promptBuilder.build(
        text: trimmed,
        knownPeople: knownPeople,
      );

      if (kDebugMode) {
        debugPrint(
          '[LiteRtExtractionProvider] prompt lengths '
          'system=${bundle.systemInstruction.length} '
          'user=${bundle.userPrompt.length} '
          'tools=${bundle.tools.length}',
        );
      }

      final rawCalls = await adapter.runFunctionCalls(
        systemInstruction: bundle.systemInstruction,
        userPrompt: bundle.userPrompt,
        tools: bundle.tools,
      );

      final branch = adapter.lastDiagnostics?.parserBranch;
      if (branch == 'exception' || branch == 'no_tools_provided') {
        lastPipelineFailureReason =
            adapter.lastDiagnostics?.toString() ?? branch;
        lastFailureReason = lastPipelineFailureReason;
        return const ExtractionResult(candidates: []);
      }

      if (rawCalls.isEmpty) {
        // Valid empty: model emitted no tool calls (or non-FC response with
        // nothing to map). Not a pipeline failure.
        lastFailureReason =
            adapter.lastDiagnostics?.toString() ?? 'no function calls';
        if (kDebugMode) {
          debugPrint(
            '[LiteRtExtractionProvider] no function-call response; '
            '$lastFailureReason',
          );
          final rawOut = adapter.lastFullRawResponse;
          debugPrint('[LiteRtExtractionProvider] ===== RAW MODEL OUTPUT =====');
          if (rawOut == null || rawOut.isEmpty) {
            debugPrint('(empty / not captured)');
          } else {
            const chunkSize = 700;
            for (var i = 0; i < rawOut.length; i += chunkSize) {
              final end =
                  i + chunkSize < rawOut.length ? i + chunkSize : rawOut.length;
              debugPrint(rawOut.substring(i, end));
            }
          }
          debugPrint('[LiteRtExtractionProvider] =============================');
          debugPrint(
            '[LiteRtExtractionProvider] ===== PARSER RESULT =====\n'
            '${adapter.lastParserResultSummary ?? "(none)"}\n'
            '=========================',
          );
        }
        return const ExtractionResult(candidates: []);
      }

      final knownUuids = {
        for (final person in knownPeople) person.uuid,
      };

      final candidates = <ExtractedMemoryCandidate>[];
      for (final raw in rawCalls) {
        if (raw.name != LiteRtPromptBuilder.extractMemoriesToolName) {
          if (kDebugMode) {
            debugPrint(
              '[LiteRtExtractionProvider] skipping unexpected tool: ${raw.name}',
            );
          }
          continue;
        }
        if (kDebugMode) {
          debugPrint(
            '[LiteRtExtractionProvider] raw args before mapping: ${raw.args}',
          );
        }
        candidates.addAll(
          _mapCandidates(raw.args, knownPeople, knownUuids, trimmed),
        );
      }

      if (kDebugMode) {
        debugPrint(
          '[LiteRtExtractionProvider] ===== VALIDATION / MAPPING =====',
        );
        debugPrint(
          'mapped ${candidates.length} candidate(s) from ${rawCalls.length} '
          'function call(s)',
        );
        for (final c in candidates) {
          debugPrint(
            'candidate person=${c.personMentioned} category=${c.category.name} '
            'event=${c.eventText} quote=${c.quoteEvidence} '
            'datePrecision=${c.datePrecision.name} '
            'importance=${c.importanceScore} '
            'extractConf=${c.extractionConfidence} '
            'grounding=${hasGroundingQuote(c)}',
          );
        }
        debugPrint('================================');
      }

      if (candidates.isEmpty) {
        // Model called the tool but nothing mapped — valid empty for UX;
        // keep detail for debug logs only (not CaptureSubmitFailed).
        lastFailureReason =
            'mapping produced 0 candidates from ${rawCalls.length} call(s); '
            'raw=${adapter.lastFullRawResponse}; '
            '${adapter.lastDiagnostics}';
        if (kDebugMode) {
          debugPrint('[LiteRtExtractionProvider] $lastFailureReason');
        }
      }

      return ExtractionResult(candidates: candidates);
    } catch (e, st) {
      final line = st.toString().split('\n').firstWhere(
            (l) => l.contains('litert_') || l.trim().startsWith('#0'),
            orElse: () => st.toString().split('\n').first,
          );
      lastPipelineFailureReason = 'extract threw at $line: $e';
      lastFailureReason = lastPipelineFailureReason;
      if (kDebugMode) {
        debugPrint('[LiteRtExtractionProvider] $lastFailureReason\n$st');
      }
      return const ExtractionResult(candidates: []);
    }
  }

  List<ExtractedMemoryCandidate> _mapCandidates(
    Map<String, dynamic> args,
    List<Person> knownPeople,
    Set<String> knownUuids,
    String sourceText,
  ) {
    try {
      final rawCandidates = args['candidates'];
      if (rawCandidates is List) {
        final mapped = <ExtractedMemoryCandidate>[];
        for (final item in rawCandidates) {
          if (item is! Map) {
            continue;
          }
          Map<String, dynamic> asMap;
          try {
            asMap = Map<String, dynamic>.from(item);
          } catch (e) {
            if (kDebugMode) {
              debugPrint(
                '[LiteRtExtractionProvider] candidate map coerce failed: $e',
              );
            }
            continue;
          }
          final candidate =
              _mapCandidate(asMap, knownPeople, knownUuids, sourceText);
          if (candidate != null) {
            mapped.add(candidate);
          } else if (kDebugMode) {
            debugPrint(
              '[LiteRtExtractionProvider] dropped candidate: $item',
            );
          }
        }
        return mapped;
      }

      if (args.containsKey('eventText') || args.containsKey('personMentioned')) {
        final single =
            _mapCandidate(args, knownPeople, knownUuids, sourceText);
        if (single != null) {
          return [single];
        }
        if (kDebugMode) {
          debugPrint(
            '[LiteRtExtractionProvider] dropped flat candidate: $args',
          );
        }
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          '[LiteRtExtractionProvider] _mapCandidates threw: $e\n$st',
        );
      }
    }

    return const [];
  }

  ExtractedMemoryCandidate? _mapCandidate(
    Map<String, dynamic> raw,
    List<Person> knownPeople,
    Set<String> knownUuids,
    String sourceText,
  ) {
    try {
      final personMentioned = '${raw['personMentioned'] ?? ''}'.trim();
      final eventText = '${raw['eventText'] ?? ''}'.trim();
      final quoteEvidence = '${raw['quoteEvidence'] ?? ''}'.trim();
      final dateValueRaw = _nullableString(raw['dateValueRaw']);
      final category = validatedCategory('${raw['category'] ?? ''}');

      if (personMentioned.isEmpty || eventText.isEmpty) {
        if (kDebugMode) {
          debugPrint(
            '[LiteRtExtractionProvider] missing person/event '
            'person="$personMentioned" event="$eventText"',
          );
        }
        return null;
      }

      if (category == null) {
        if (kDebugMode) {
          debugPrint(
            '[LiteRtExtractionProvider] rejected invalid/missing category '
            'raw="${raw['category']}"',
          );
        }
        return null;
      }

      // Hallucination guards — quote and optional date must be in the note.
      final rejection = literalExtractionRejectionReason(
        sourceText,
        personMentioned: personMentioned,
        eventText: eventText,
        quoteEvidence: quoteEvidence,
        dateValueRaw: dateValueRaw,
      );
      final quoteOk =
          textAppearsVerbatimInSource(sourceText, quoteEvidence);
      final dateOk = dateValueRaw == null ||
          textAppearsVerbatimInSource(sourceText, dateValueRaw);
      if (kDebugMode) {
        debugPrint('[LiteRtExtractionProvider] ===== GROUNDING DEBUG =====');
        debugPrint('Model produced a candidate: Yes');
        debugPrint('Quote grounded: ${quoteOk ? 'Yes' : 'No'}');
        debugPrint('Date grounded: ${dateOk ? 'Yes' : 'No'}');
        debugPrint('Category: ${category.name}');
        debugPrint(
          'Candidate: ${rejection == null ? 'accepted' : 'rejected'}',
        );
        if (rejection != null) {
          debugPrint('Exact rejection reason: $rejection');
        }
        debugPrint('================================');
      }
      if (rejection != null) {
        return null;
      }

      // Importance / follow-up / confidence remain app-owned (not model).
      if (kDebugMode &&
          (raw.containsKey('followUpSuggested') ||
              raw.containsKey('followUpNote') ||
              raw.containsKey('importanceScore') ||
              raw.containsKey('extractionConfidence'))) {
        debugPrint(
          '[LiteRtExtractionProvider] ignoring non-schema model fields in '
          '${raw.keys.toList()}',
        );
      }

      final nameMatch = resolveUniquePersonNameMatch(
        personMentioned: personMentioned,
        knownPeople: knownPeople.map(
          (p) => (uuid: p.uuid, name: p.name),
        ),
      );
      // Prefer Tend name match; accept model uuid only if it is a known person
      // and name matching did not already resolve uniquely.
      final personMatchUuid = nameMatch.uuid ??
          _resolvePersonMatchUuid(raw['personMatchUuid'], knownUuids);
      final personMatchConfidence = nameMatch.uuid != null
          ? nameMatch.confidence
          : (personMatchUuid != null ? 1.0 : 0.0);

      if (kDebugMode) {
        debugPrint(
          '[LiteRtExtractionProvider] person match '
          'mentioned="$personMentioned" '
          'uuid=${personMatchUuid ?? "(none)"} '
          'confidence=${personMatchConfidence.toStringAsFixed(2)}',
        );
      }

      final datePrecision = classifyDatePrecision(dateValueRaw);

      return ExtractedMemoryCandidate(
        personMentioned: personMentioned,
        personMatchUuid: personMatchUuid,
        personMatchConfidence: personMatchConfidence,
        category: category,
        eventText: eventText,
        quoteEvidence: quoteEvidence,
        datePrecision: datePrecision,
        // Keep the verbatim phrase for confirmation even when explicit
        // (absolute DateTime resolution is backlog / optional parse later).
        dateValueRaw: dateValueRaw,
        dateValue: null,
        importanceScore: kLiteralExtractionDefaultImportance,
        // High only because quote is verbatim-grounded by validation above.
        extractionConfidence: 1.0,
        followUpSuggested: false,
        followUpNote: null,
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          '[LiteRtExtractionProvider] _mapCandidate threw: $e\n$st',
        );
      }
      return null;
    }
  }

  String? _resolvePersonMatchUuid(Object? rawUuid, Set<String> knownUuids) {
    final uuid = _nullableString(rawUuid);
    if (uuid == null || !knownUuids.contains(uuid)) {
      return null;
    }
    return uuid;
  }

  String? _nullableString(Object? value) {
    if (value == null) {
      return null;
    }
    final text = '$value'.trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }
    return text;
  }
}
