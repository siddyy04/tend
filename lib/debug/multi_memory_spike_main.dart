import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:my_first_app/ai/model_manager/model_catalog.dart';
import 'package:my_first_app/domain/rules/extraction_validation_rules.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Sprint 2B.1 spike: compare parallel FC vs candidates[] on multi-fact notes.
///
/// Usage:
/// ```
/// flutter run -t lib/debug/multi_memory_spike_main.dart -d <deviceId> --release
/// ```
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final artifact = ModelCatalog.current;
  debugPrint('[MultiMemSpike] model=${artifact.displayName}');

  final docs = await getApplicationDocumentsDirectory();
  final localPath = p.join(docs.path, 'models', artifact.fileName);
  final hasLocal = File(localPath).existsSync();
  debugPrint('[MultiMemSpike] path=$localPath exists=$hasLocal');

  String? report;
  Object? error;
  try {
    report = await MultiMemoryFcSpike(
      modelFilePath: hasLocal ? localPath : null,
      artifact: artifact,
    ).run();
  } catch (e, st) {
    error = e;
    debugPrint('[MultiMemSpike] uncaught: $e\n$st');
  }

  debugPrint('[MultiMemSpike] ===== FINAL REPORT =====');
  debugPrint(report ?? 'no report');
  if (error != null) {
    debugPrint('[MultiMemSpike] error=$error');
  }

  // Keep process alive briefly so logcat flush completes.
  await Future<void>.delayed(const Duration(seconds: 3));
  exit(error == null ? 0 : 1);
}

class MultiMemoryFcSpike {
  MultiMemoryFcSpike({
    required this.artifact,
    this.modelFilePath,
  });

  final ModelArtifactSpec artifact;
  final String? modelFilePath;

  static const notes = <({String id, String text, int expected})>[
    (
      id: 'two_people',
      text:
          'Priya started a new job at Stripe last month. '
          'Rahul is flying to Goa next week.',
      expected: 2,
    ),
    (
      id: 'three_facts',
      text:
          'Mom had spinal surgery 1.5 months back. '
          'Dad retired from the bank in March 2024. '
          'Sarah loves hiking on weekends.',
      expected: 3,
    ),
    (
      id: 'four_facts',
      text:
          'John works at Google. '
          'Neha has been dealing with migraines since the baby was born. '
          'Arjun prefers oat milk in his coffee. '
          "Ravi's sister Ananya is moving to Berlin in September.",
      expected: 4,
    ),
    (
      id: 'single_control',
      text: 'Pooja likes tea.',
      expected: 1,
    ),
  ];

  static const _categories = [
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

  static final Tool flatTool = Tool(
    name: 'extract_memories',
    description:
        'Extract one independent memory fact from the note. '
        'Call this tool once per independent memory. '
        'quoteEvidence must be an exact substring of the note. '
        'Pick exactly one category from the allowed enum list.',
    parameters: {
      'type': 'object',
      'properties': {
        'personMentioned': {
          'type': 'string',
          'description': 'Person name exactly as written. Empty if none.',
        },
        'eventText': {
          'type': 'string',
          'description':
              'Complete primary clause including the subject. '
              'Use only words from the note.',
        },
        'quoteEvidence': {
          'type': 'string',
          'description': 'Exact contiguous substring from the note.',
        },
        'dateValueRaw': {
          'type': 'string',
          'description':
              'Verbatim temporal phrase from the note, or empty string.',
        },
        'category': {
          'type': 'string',
          'description': 'Exactly one of: ${_categories.join(', ')}.',
          'enum': _categories,
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

  static final Tool arrayTool = Tool(
    name: 'extract_memories',
    description:
        'Extract all independent memory facts from the note into candidates. '
        'Return one candidate object per independent memory. '
        'quoteEvidence must be an exact substring of the note. '
        'Pick exactly one category per candidate from the allowed enum list.',
    parameters: {
      'type': 'object',
      'properties': {
        'candidates': {
          'type': 'array',
          'description':
              'One entry per independent memory fact in the note. '
              'Do not merge unrelated facts.',
          'items': {
            'type': 'object',
            'properties': {
              'personMentioned': {
                'type': 'string',
                'description':
                    'Person name exactly as written. Empty if none.',
              },
              'eventText': {
                'type': 'string',
                'description':
                    'Complete primary clause including the subject. '
                    'Use only words from the note.',
              },
              'quoteEvidence': {
                'type': 'string',
                'description': 'Exact contiguous substring from the note.',
              },
              'dateValueRaw': {
                'type': 'string',
                'description':
                    'Verbatim temporal phrase from the note, or empty string.',
              },
              'category': {
                'type': 'string',
                'description': 'Exactly one of: ${_categories.join(', ')}.',
                'enum': _categories,
              },
            },
            'required': [
              'personMentioned',
              'eventText',
              'quoteEvidence',
              'category',
            ],
          },
        },
      },
      'required': ['candidates'],
    },
  );

  Future<String> run() async {
    await FlutterGemma.initialize(inferenceEngines: const [LiteRtLmEngine()]);

    final path = modelFilePath;
    if (path != null && File(path).existsSync()) {
      debugPrint('[MultiMemSpike] install fromFile bytes=${File(path).lengthSync()}');
      await FlutterGemma.installModel(
        modelType: ModelType.gemma4,
        fileType: ModelFileType.litertlm,
      ).fromFile(path).install();
    } else {
      debugPrint('[MultiMemSpike] install fromNetwork ${artifact.downloadUrl}');
      await FlutterGemma.installModel(
        modelType: ModelType.gemma4,
        fileType: ModelFileType.litertlm,
      ).fromNetwork(artifact.downloadUrl).install();
    }

    final model = await _loadModel(artifact.maxTokens);
    final buf = StringBuffer();
    buf.writeln('Multi-memory FC spike — ${artifact.displayName}');
    buf.writeln('backend=${model.activeBackend?.name ?? "?"}');
    buf.writeln();

    for (final note in notes) {
      buf.writeln('--- ${note.id} expected=${note.expected} ---');
      buf.writeln('note: ${note.text}');

      final parallel = await _runApproach(
        model: model,
        approach: 'parallel',
        note: note.text,
        tools: [flatTool],
        userPrompt: _parallelPrompt(note.text),
      );
      buf.writeln(parallel.summary);

      final array = await _runApproach(
        model: model,
        approach: 'candidates_array',
        note: note.text,
        tools: [arrayTool],
        userPrompt: _arrayPrompt(note.text),
      );
      buf.writeln(array.summary);
      buf.writeln();
    }

    buf.writeln('RECOMMENDATION_HINT:');
    buf.writeln(
      'Prefer the approach with higher accepted_count vs expected, '
      'stable single_control=1, and lower failure/protocol rates. '
      'If scores are close, prefer parallel for flat-schema isolation.',
    );
    return buf.toString();
  }

  String _parallelPrompt(String note) {
    return 'Extract every independent memory fact from the note. '
        'Call extract_memories once per independent memory '
        '(for example, two people or two unrelated facts → two calls). '
        'Do not invent details. quoteEvidence must be copied exactly. '
        'eventText must be the complete primary clause including the subject. '
        'If a temporal phrase appears, copy it verbatim into dateValueRaw. '
        'Set category to exactly one of: ${_categories.join(', ')}.\n\n'
        'Note: $note';
  }

  String _arrayPrompt(String note) {
    return 'Extract every independent memory fact from the note. '
        'Return them all in candidates[] — one object per independent memory '
        '(for example, two people or two unrelated facts → two candidates). '
        'Do not invent details. quoteEvidence must be copied exactly. '
        'eventText must be the complete primary clause including the subject. '
        'If a temporal phrase appears, copy it verbatim into dateValueRaw. '
        'Set category to exactly one of: ${_categories.join(', ')}.\n\n'
        'Note: $note';
  }

  Future<InferenceModel> _loadModel(int maxTokens) async {
    Object? last;
    for (final backend in const [
      PreferredBackend.gpu,
      PreferredBackend.npu,
      PreferredBackend.cpu,
    ]) {
      try {
        final model = await FlutterGemma.getActiveModel(
          maxTokens: maxTokens,
          preferredBackend: backend,
        );
        debugPrint(
          '[MultiMemSpike] loaded backend=${model.activeBackend?.name ?? backend.name}',
        );
        return model;
      } catch (e) {
        last = e;
        debugPrint('[MultiMemSpike] backend ${backend.name} failed: $e');
      }
    }
    throw StateError('model load failed: $last');
  }

  Future<_ApproachResult> _runApproach({
    required InferenceModel model,
    required String approach,
    required String note,
    required List<Tool> tools,
    required String userPrompt,
  }) async {
    final sw = Stopwatch()..start();
    InferenceChat? chat;
    try {
      chat = await model.createChat(
        temperature: 1.0,
        randomSeed: 1,
        topK: 64,
        topP: 0.95,
        tokenBuffer: 256,
        supportsFunctionCalls: true,
        tools: tools,
        toolChoice: ToolChoice.auto,
        isThinking: false,
        modelType: ModelType.gemma4,
      );
      await chat.addQueryChunk(Message.text(text: userPrompt, isUser: true));
      final response = await chat.generateChatResponse();
      sw.stop();

      final rawCalls = <Map<String, dynamic>>[];
      final responseType = response.runtimeType.toString();
      if (response is FunctionCallResponse) {
        rawCalls.add(_asMap(response.args));
      } else if (response is ParallelFunctionCallResponse) {
        for (final c in response.calls) {
          rawCalls.add(_asMap(c.args));
        }
      }

      final candidateMaps = <Map<String, dynamic>>[];
      if (approach == 'candidates_array') {
        for (final call in rawCalls) {
          final list = call['candidates'];
          if (list is List) {
            for (final item in list) {
              if (item is Map) {
                candidateMaps.add(Map<String, dynamic>.from(item));
              }
            }
          } else if (call.containsKey('eventText')) {
            // Model ignored array schema and returned flat — still count.
            candidateMaps.add(call);
          }
        }
      } else {
        for (final call in rawCalls) {
          if (call.containsKey('candidates') && call['candidates'] is List) {
            for (final item in call['candidates'] as List) {
              if (item is Map) {
                candidateMaps.add(Map<String, dynamic>.from(item));
              }
            }
          } else {
            candidateMaps.add(call);
          }
        }
      }

      var accepted = 0;
      final rejections = <String>[];
      for (final raw in candidateMaps) {
        final person = '${raw['personMentioned'] ?? ''}'.trim();
        final event = '${raw['eventText'] ?? ''}'.trim();
        final quote = '${raw['quoteEvidence'] ?? ''}'.trim();
        final date = _nullable(raw['dateValueRaw']);
        final category = validatedCategory('${raw['category'] ?? ''}');
        if (person.isEmpty || event.isEmpty || category == null) {
          rejections.add('schema');
          continue;
        }
        final reason = literalExtractionRejectionReason(
          note,
          personMentioned: person,
          eventText: event,
          quoteEvidence: quote,
          dateValueRaw: date,
        );
        if (reason == null) {
          accepted++;
        } else {
          rejections.add(reason);
        }
      }

      final preview = response.toString();
      debugPrint(
        '[MultiMemSpike] $approach note="${note.substring(0, note.length > 40 ? 40 : note.length)}..." '
        'type=$responseType calls=${rawCalls.length} mapped=${candidateMaps.length} '
        'accepted=$accepted ms=${sw.elapsedMilliseconds}',
      );
      debugPrint('[MultiMemSpike] $approach preview=$preview');

      return _ApproachResult(
        approach: approach,
        responseType: responseType,
        rawCallCount: rawCalls.length,
        mappedCount: candidateMaps.length,
        acceptedCount: accepted,
        elapsedMs: sw.elapsedMilliseconds,
        rejectionSummary: rejections.isEmpty ? 'none' : rejections.join(','),
      );
    } catch (e) {
      sw.stop();
      debugPrint('[MultiMemSpike] $approach EXCEPTION: $e');
      return _ApproachResult(
        approach: approach,
        responseType: 'exception',
        rawCallCount: 0,
        mappedCount: 0,
        acceptedCount: 0,
        elapsedMs: sw.elapsedMilliseconds,
        rejectionSummary: '$e',
      );
    } finally {
      try {
        await chat?.close();
      } catch (_) {}
    }
  }

  Map<String, dynamic> _asMap(Map<String, dynamic> args) =>
      Map<String, dynamic>.from(args);

  String? _nullable(Object? value) {
    if (value == null) return null;
    final t = '$value'.trim();
    if (t.isEmpty || t.toLowerCase() == 'null') return null;
    return t;
  }
}

class _ApproachResult {
  const _ApproachResult({
    required this.approach,
    required this.responseType,
    required this.rawCallCount,
    required this.mappedCount,
    required this.acceptedCount,
    required this.elapsedMs,
    required this.rejectionSummary,
  });

  final String approach;
  final String responseType;
  final int rawCallCount;
  final int mappedCount;
  final int acceptedCount;
  final int elapsedMs;
  final String rejectionSummary;

  String get summary =>
      '  [$approach] type=$responseType rawCalls=$rawCallCount '
      'mapped=$mappedCount accepted=$acceptedCount '
      'ms=$elapsedMs rejects=$rejectionSummary';
}
