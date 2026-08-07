import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:my_first_app/ai/model_manager/model_catalog.dart';
import 'package:my_first_app/domain/rules/extraction_validation_rules.dart';

/// One case result from [GemmaRuntimeProbe].
class OfficialProbeCaseResult {
  const OfficialProbeCaseResult({
    required this.id,
    required this.passed,
    required this.detail,
    this.responsePreview,
    this.error,
    this.elapsedMs,
    this.modelProducedCandidate,
    this.quoteGrounded,
    this.dateGrounded,
    this.decision,
    this.rejectionReason,
  });

  final String id;
  final bool passed;
  final String detail;
  final String? responsePreview;
  final String? error;
  final int? elapsedMs;

  /// Grounding debug fields (extraction suite).
  final bool? modelProducedCandidate;
  final bool? quoteGrounded;
  final bool? dateGrounded;
  final String? decision; // accepted | rejected
  final String? rejectionReason;

  @override
  String toString() {
    final status = passed ? 'PASS' : 'FAIL';
    final buf = StringBuffer(
      '[$status] $id (${elapsedMs ?? '?'}ms) $detail',
    );
    if (modelProducedCandidate != null) {
      buf.write(
        ' | modelCandidate=${_yn(modelProducedCandidate)} '
        'quoteGrounded=${_yn(quoteGrounded)} '
        'dateGrounded=${_yn(dateGrounded)} '
        'decision=$decision'
        '${rejectionReason == null ? '' : ' reason=$rejectionReason'}',
      );
    }
    if (responsePreview != null) {
      buf.write(' preview="$responsePreview"');
    }
    if (error != null) {
      buf.write(' error=$error');
    }
    return buf.toString();
  }

  static String _yn(bool? v) => v == null ? '?' : (v ? 'Yes' : 'No');
}

/// Full probe report with quality + performance metrics.
class OfficialProbeReport {
  const OfficialProbeReport({
    required this.modelPath,
    required this.cases,
    this.peakRssBytes,
    this.modelLabel,
    this.activeBackend,
    this.coldStartMs,
    this.warmAvgMs,
    this.downloadBytes,
  });

  final String modelPath;
  final List<OfficialProbeCaseResult> cases;
  final int? peakRssBytes;
  final String? modelLabel;
  final String? activeBackend;

  /// Install + first getActiveModel wall time (ms).
  final int? coldStartMs;

  /// Mean elapsed across grounding cases after the first (ms).
  final int? warmAvgMs;

  /// On-disk model file size (bytes), when known.
  final int? downloadBytes;

  bool get allPassed => cases.every((c) => c.passed);

  int get acceptedCount =>
      cases.where((c) => c.decision == 'accepted').length;

  int get rejectedCount =>
      cases.where((c) => c.decision == 'rejected').length;

  double? get averageElapsedMs {
    final timed = cases.where((c) => c.elapsedMs != null).toList();
    if (timed.isEmpty) {
      return null;
    }
    final sum = timed.fold<int>(0, (a, c) => a + c.elapsedMs!);
    return sum / timed.length;
  }

  /// Crude 0–1 score: accepted=1, produced-but-rejected with quote=0.4,
  /// produced-but-rejected=0.15, no candidate=0.
  double get averageExtractionQuality {
    if (cases.isEmpty) {
      return 0;
    }
    var sum = 0.0;
    for (final c in cases) {
      if (c.decision == 'accepted') {
        sum += 1.0;
      } else if (c.modelProducedCandidate == true && c.quoteGrounded == true) {
        sum += 0.4;
      } else if (c.modelProducedCandidate == true) {
        sum += 0.15;
      }
    }
    return sum / cases.length;
  }

  @override
  String toString() {
    final buf = StringBuffer()
      ..writeln('=== Gemma 4 LiteRT-LM runtime probe ===')
      ..writeln('modelLabel=${modelLabel ?? '(n/a)'}')
      ..writeln('modelPath=$modelPath')
      ..writeln('activeBackend=${activeBackend ?? '?'}')
      ..writeln('allPassed=$allPassed')
      ..writeln(
        'accepted=$acceptedCount rejected=$rejectedCount '
        'total=${cases.length}',
      )
      ..writeln(
        'avgElapsedMs=${averageElapsedMs?.toStringAsFixed(0) ?? '?'} '
        'coldStartMs=${coldStartMs ?? '?'} '
        'warmAvgMs=${warmAvgMs ?? '?'} '
        'avgQuality=${averageExtractionQuality.toStringAsFixed(2)} '
        'peakRssMb=${peakRssBytes == null ? '?' : (peakRssBytes! / (1024 * 1024)).toStringAsFixed(1)} '
        'downloadGb=${downloadBytes == null ? '?' : (downloadBytes! / (1024 * 1024 * 1024)).toStringAsFixed(2)}',
      );
    for (final c in cases) {
      buf.writeln(c);
    }
    return buf.toString();
  }
}

/// Suite selection for [GemmaRuntimeProbe.run].
enum OfficialProbeSuite {
  /// Minimal ChatScreen-shaped smoke cases.
  officialSample,

  /// Eleven capture-style notes via Tend's [extract_memories] tool.
  extractionGrounding,
}

/// Gemma 4 LiteRT-LM probe: same 11-prompt grounding suite as the Qwen baseline.
///
/// Runtime: [LiteRtLmEngine], [ModelType.gemma4], [ModelFileType.litertlm].
/// Backends: GPU → NPU → CPU.
class GemmaRuntimeProbe {
  GemmaRuntimeProbe({
    this.modelFilePath,
    this.allowNetworkDownload = true,
    this.suite = OfficialProbeSuite.officialSample,
    this.artifact = ModelCatalog.current,
  });

  /// Absolute path to an already-downloaded catalog `.litertlm`, or null to
  /// force the [fromNetwork] install path using [artifact.downloadUrl].
  final String? modelFilePath;

  /// When the local file is missing, download like the official example.
  final bool allowNetworkDownload;

  /// Which case set to run.
  final OfficialProbeSuite suite;

  /// Catalog artifact under test (defaults to [ModelCatalog.current]).
  final ModelArtifactSpec artifact;

  String get officialDownloadUrl => artifact.downloadUrl;

  int _peakRssBytes = 0;
  String? _activeBackendName;
  int? _coldStartMs;
  int? _downloadBytes;

  void _sampleRss() {
    try {
      final rss = ProcessInfo.currentRss;
      if (rss > _peakRssBytes) {
        _peakRssBytes = rss;
      }
    } catch (_) {}
  }

  /// Same tool schema Tend uses for Capture extraction (literal-only).
  static const extractMemoriesTool = Tool(
    name: 'extract_memories',
    description:
        'Copy literal facts from the user note only. '
        'Do not invent, infer, or complete missing details. '
        'quoteEvidence must be an exact substring of the note. '
        'If the note contains any explicit or relative temporal phrase, '
        'copy that phrase verbatim into dateValueRaw.',
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
      },
      'required': [
        'personMentioned',
        'eventText',
        'quoteEvidence',
      ],
    },
  );

  /// Original five-note baseline (same set as Qwen 0.5B benchmark).
  static const originalFiveNotes = <String>[
    'Pooja likes tea.',
    'Mom had spinal surgery.',
    'John works at Google.',
    'Sarah loves hiking.',
    "Dad's birthday is on 15 August.",
  ];

  /// Realistic multi-sentence relationship notes.
  static const realisticNotes = <String>[
    'Caught up with Priya yesterday. She started a new job at Stripe last month '
        'and said the team is smaller than her last company.',
    'Mom had her spinal surgery 1.5 months back. The doctor wants a follow-up '
        'scan next week.',
    'Arjun prefers oat milk in his coffee. He mentioned it again when we met '
        'for brunch on Sunday.',
    "Ravi's sister Ananya is moving to Berlin in September for a research postdoc.",
    'Dad retired from the bank in March 2024. He still goes for a walk every morning.',
    'Neha has been dealing with migraines since the baby was born. She is seeing '
        'a neurologist next Thursday.',
  ];

  static const groundingNotes = <String>[
    ...originalFiveNotes,
    ...realisticNotes,
  ];

  static const exampleTools = <Tool>[
    Tool(
      name: 'change_background_color',
      description: 'Changes the app background color',
      parameters: {
        'type': 'object',
        'properties': {
          'color': {
            'type': 'string',
            'description':
                'The color name (red, green, blue, yellow, purple, orange)',
          },
        },
        'required': ['color'],
      },
    ),
    Tool(
      name: 'change_app_title',
      description: 'Changes the application title text in the AppBar',
      parameters: {
        'type': 'object',
        'properties': {
          'title': {
            'type': 'string',
            'description': 'The new title text to display',
          },
        },
        'required': ['title'],
      },
    ),
    Tool(
      name: 'show_alert',
      description: 'Shows an alert dialog with a custom message and title',
      parameters: {
        'type': 'object',
        'properties': {
          'title': {
            'type': 'string',
            'description': 'The title of the alert dialog',
          },
          'message': {
            'type': 'string',
            'description': 'The message content of the alert dialog',
          },
        },
        'required': ['title', 'message'],
      },
    ),
  ];

  Future<OfficialProbeReport> run() async {
    final cases = <OfficialProbeCaseResult>[];
    final pathLabel = modelFilePath ?? '(fromNetwork:${artifact.fileName})';
    _log('start path=$pathLabel artifact=${artifact.versionId}');
    _sampleRss();

    await FlutterGemma.initialize(inferenceEngines: const [LiteRtLmEngine()]);

    InferenceModel? model;
    try {
      final coldSw = Stopwatch()..start();
      final local = modelFilePath;
      final hasLocal =
          local != null && local.isNotEmpty && await File(local).exists();

      if (hasLocal) {
        _downloadBytes = await File(local).length();
        _log(
          'installModel fromFile (local cache) '
          'bytes=$_downloadBytes…',
        );
        await FlutterGemma.installModel(
          modelType: ModelType.gemma4,
          fileType: ModelFileType.litertlm,
        ).fromFile(local).install();
      } else if (allowNetworkDownload && artifact.hasDownloadUrl) {
        _log('installModel fromNetwork (${artifact.displayName})…');
        await FlutterGemma.installModel(
          modelType: ModelType.gemma4,
          fileType: ModelFileType.litertlm,
        ).fromNetwork(officialDownloadUrl).withProgress((percent) {
          if (percent % 5 == 0) {
            _log('download $percent%');
          }
        }).install();
        _downloadBytes = artifact.approximateDownloadBytes > 0
            ? artifact.approximateDownloadBytes
            : null;
      } else {
        cases.add(
          OfficialProbeCaseResult(
            id: 'preflight',
            passed: false,
            detail: 'model file missing and network download disabled',
            error: modelFilePath,
          ),
        );
        return OfficialProbeReport(
          modelPath: pathLabel,
          cases: cases,
          modelLabel: artifact.displayName,
          peakRssBytes: _peakRssBytes,
          downloadBytes: _downloadBytes,
        );
      }

      _sampleRss();
      model = await _loadWithBackendFallback(artifact.maxTokens);
      coldSw.stop();
      _coldStartMs = coldSw.elapsedMilliseconds;
      _sampleRss();
      _log(
        'coldStartMs=$_coldStartMs backend=$_activeBackendName '
        'maxTokens=${artifact.maxTokens}',
      );

      switch (suite) {
        case OfficialProbeSuite.officialSample:
          cases.add(
            await _runCase(
              id: 'A_plain_Pooja_no_tools',
              model: model,
              userText: 'Pooja',
              tools: const <Tool>[],
              supportsFunctionCalls: false,
            ),
          );
          cases.add(
            await _runCase(
              id: 'B_example_tools_Hi',
              model: model,
              userText: 'Hi',
              tools: exampleTools,
              supportsFunctionCalls: true,
            ),
          );
          cases.add(
            await _runCase(
              id: 'C_plain_likes_tea_no_tools',
              model: model,
              userText: 'Pooja likes tea.',
              tools: const <Tool>[],
              supportsFunctionCalls: false,
            ),
          );
        case OfficialProbeSuite.extractionGrounding:
          var index = 0;
          for (final note in originalFiveNotes) {
            index++;
            cases.add(
              await _runCase(
                id: 'O${index}_${_slug(note)}',
                model: model,
                sourceNote: note,
                userText: _literalUserPrompt(note),
                tools: const [extractMemoriesTool],
                supportsFunctionCalls: true,
                evaluateLiteralGrounding: true,
              ),
            );
          }
          for (final note in realisticNotes) {
            index++;
            cases.add(
              await _runCase(
                id: 'R${index - originalFiveNotes.length}_${_slug(note)}',
                model: model,
                sourceNote: note,
                userText: _literalUserPrompt(note),
                tools: const [extractMemoriesTool],
                supportsFunctionCalls: true,
                evaluateLiteralGrounding: true,
              ),
            );
          }
      }
    } catch (e, st) {
      _log('FATAL dart exception (process still alive): $e\n$st');
      cases.add(
        OfficialProbeCaseResult(
          id: 'setup_or_unhandled',
          passed: false,
          detail: 'Dart exception before/during probe',
          error: '$e',
        ),
      );
    } finally {
      try {
        await model?.close();
      } catch (_) {}
    }

    final timed = cases
        .where((c) => c.elapsedMs != null)
        .map((c) => c.elapsedMs!)
        .toList();
    int? warmAvg;
    if (timed.length > 1) {
      final warm = timed.sublist(1);
      warmAvg = (warm.reduce((a, b) => a + b) / warm.length).round();
    } else if (timed.length == 1) {
      warmAvg = timed.first;
    }

    final report = OfficialProbeReport(
      modelPath: pathLabel,
      cases: cases,
      modelLabel: artifact.displayName,
      peakRssBytes: _peakRssBytes > 0 ? _peakRssBytes : null,
      activeBackend: _activeBackendName,
      coldStartMs: _coldStartMs,
      warmAvgMs: warmAvg,
      downloadBytes: _downloadBytes,
    );
    _log(report.toString());
    return report;
  }

  Future<InferenceModel> _loadWithBackendFallback(int maxTokens) async {
    Object? lastError;
    for (final backend in const [
      PreferredBackend.gpu,
      PreferredBackend.npu,
      PreferredBackend.cpu,
    ]) {
      try {
        _log('getActiveModel maxTokens=$maxTokens prefer=${backend.name}');
        final model = await FlutterGemma.getActiveModel(
          maxTokens: maxTokens,
          preferredBackend: backend,
        );
        _activeBackendName = (model.activeBackend ?? backend).name;
        _log('loaded activeBackend=$_activeBackendName');
        return model;
      } catch (e) {
        lastError = e;
        _log('backend ${backend.name} failed: $e');
      }
    }
    throw StateError(
      'Failed to load model on GPU/NPU/CPU. Last error: $lastError',
    );
  }

  String _literalUserPrompt(String note) {
    return 'Extract only what is literally written. '
        'Do not guess category, importance, follow-ups, or missing facts. '
        'quoteEvidence must be copied exactly from the note. '
        'eventText must be the complete primary clause including the subject '
        '(not a verb fragment). '
        'If the note contains any explicit or relative temporal phrase '
        '(e.g. yesterday, next week, Sunday, March 2024, 1.5 months back), '
        'always copy that phrase verbatim into dateValueRaw. '
        'Do not normalize, infer, or calculate dates — copy the text exactly '
        'as it appears.\n\n'
        'Note: $note';
  }

  String _slug(String note) {
    return note
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  Future<OfficialProbeCaseResult> _runCase({
    required String id,
    required InferenceModel model,
    required String userText,
    required List<Tool> tools,
    required bool supportsFunctionCalls,
    String? sourceNote,
    bool evaluateLiteralGrounding = false,
  }) async {
    final sw = Stopwatch()..start();
    InferenceChat? chat;
    try {
      _log(
        'case $id: createChat supportsFC=$supportsFunctionCalls '
        'tools=${tools.length} text="${sourceNote ?? userText}"',
      );
      chat = await model.createChat(
        temperature: 1.0,
        randomSeed: 1,
        topK: 64,
        topP: 0.95,
        tokenBuffer: 256,
        supportsFunctionCalls: supportsFunctionCalls,
        tools: tools,
        toolChoice: ToolChoice.auto,
        isThinking: false,
        modelType: ModelType.gemma4,
      );

      await chat.addQueryChunk(
        Message.text(text: userText, isUser: true),
      );
      _log('case $id: generateChatResponse...');
      _sampleRss();
      final response = await chat.generateChatResponse();
      sw.stop();
      _sampleRss();

      final preview = switch (response) {
        TextResponse(:final token) => token,
        FunctionCallResponse(:final name, :final args) => '$name($args)',
        ParallelFunctionCallResponse(:final calls) =>
          '${calls.length} parallel calls: '
              '${calls.map((c) => '${c.name}(${c.args})').join(' | ')}',
        _ => response.toString(),
      };

      _log('case $id: done type=${response.runtimeType}');
      _log(
        'case $id: FULL_RESPONSE_START\n$preview\ncase $id: FULL_RESPONSE_END',
      );

      if (!evaluateLiteralGrounding || sourceNote == null) {
        final nonEmpty = preview.trim().isNotEmpty;
        return OfficialProbeCaseResult(
          id: id,
          passed: nonEmpty,
          detail: nonEmpty
              ? 'got ${response.runtimeType}'
              : 'empty ${response.runtimeType} (no abort, but no text)',
          responsePreview: preview.length > 2000
              ? '${preview.substring(0, 2000)}…'
              : preview,
          elapsedMs: sw.elapsedMilliseconds,
        );
      }

      final grounding = _evaluateLiteralGrounding(
        id: id,
        sourceNote: sourceNote,
        response: response,
        preview: preview,
      );
      return OfficialProbeCaseResult(
        id: id,
        passed: grounding.accepted,
        detail: grounding.detail,
        responsePreview: preview.length > 2000
            ? '${preview.substring(0, 2000)}…'
            : preview,
        elapsedMs: sw.elapsedMilliseconds,
        modelProducedCandidate: grounding.modelProducedCandidate,
        quoteGrounded: grounding.quoteGrounded,
        dateGrounded: grounding.dateGrounded,
        decision: grounding.accepted ? 'accepted' : 'rejected',
        rejectionReason: grounding.rejectionReason,
      );
    } catch (e, st) {
      sw.stop();
      _log('case $id: exception $e\n$st');
      return OfficialProbeCaseResult(
        id: id,
        passed: false,
        detail: 'Dart exception during generate',
        error: '$e',
        elapsedMs: sw.elapsedMilliseconds,
        modelProducedCandidate: false,
        quoteGrounded: false,
        dateGrounded: false,
        decision: 'rejected',
        rejectionReason: 'exception',
      );
    } finally {
      try {
        await chat?.close();
      } catch (_) {}
    }
  }

  ({
    bool modelProducedCandidate,
    bool quoteGrounded,
    bool dateGrounded,
    bool accepted,
    String? rejectionReason,
    String detail,
  }) _evaluateLiteralGrounding({
    required String id,
    required String sourceNote,
    required ModelResponse response,
    required String preview,
  }) {
    final args = _extractArgs(response);
    final produced = args != null;
    if (!produced) {
      final reason = preview.trim().isEmpty
          ? 'empty model response'
          : 'no parseable extract_memories candidate';
      _logGroundingDebug(
        id: id,
        note: sourceNote,
        produced: false,
        quoteGrounded: false,
        dateGrounded: false,
        accepted: false,
        reason: reason,
        args: null,
      );
      return (
        modelProducedCandidate: false,
        quoteGrounded: false,
        dateGrounded: false,
        accepted: false,
        rejectionReason: reason,
        detail: 'got ${response.runtimeType}; $reason',
      );
    }

    final person = '${args['personMentioned'] ?? ''}'.trim();
    final event = '${args['eventText'] ?? ''}'.trim();
    final quote = '${args['quoteEvidence'] ?? ''}'.trim();
    final dateRaw = () {
      final raw = '${args['dateValueRaw'] ?? ''}'.trim();
      if (raw.isEmpty || raw.toLowerCase() == 'null') {
        return null;
      }
      return raw;
    }();

    final quoteOk = textAppearsVerbatimInSource(sourceNote, quote);
    final dateOk = dateRaw == null ||
        textAppearsVerbatimInSource(sourceNote, dateRaw);
    final rejection = literalExtractionRejectionReason(
      sourceNote,
      personMentioned: person,
      eventText: event,
      quoteEvidence: quote,
      dateValueRaw: dateRaw,
    );
    final accepted = rejection == null;

    _logGroundingDebug(
      id: id,
      note: sourceNote,
      produced: true,
      quoteGrounded: quoteOk,
      dateGrounded: dateOk,
      accepted: accepted,
      reason: rejection,
      args: {
        'personMentioned': person,
        'eventText': event,
        'quoteEvidence': quote,
        'dateValueRaw': dateRaw,
      },
    );

    return (
      modelProducedCandidate: true,
      quoteGrounded: quoteOk,
      dateGrounded: dateOk,
      accepted: accepted,
      rejectionReason: rejection,
      detail: accepted
          ? 'got ${response.runtimeType}; accepted'
          : 'got ${response.runtimeType}; rejected ($rejection)',
    );
  }

  void _logGroundingDebug({
    required String id,
    required String note,
    required bool produced,
    required bool quoteGrounded,
    required bool dateGrounded,
    required bool accepted,
    required String? reason,
    required Map<String, Object?>? args,
  }) {
    _log('===== GROUNDING DEBUG [$id] =====');
    _log('note=$note');
    _log('Model produced a candidate: ${produced ? 'Yes' : 'No'}');
    _log('Quote grounded: ${quoteGrounded ? 'Yes' : 'No'}');
    _log('Date grounded: ${dateGrounded ? 'Yes' : 'No'}');
    _log('Candidate: ${accepted ? 'accepted' : 'rejected'}');
    if (!accepted) {
      _log('Exact rejection reason: ${reason ?? 'unknown'}');
    }
    if (args != null) {
      _log('args=$args');
    }
    _log('===== END GROUNDING DEBUG =====');
  }

  Map<String, dynamic>? _extractArgs(ModelResponse response) {
    if (response is FunctionCallResponse) {
      return _asStringKeyedMap(response.args);
    }
    if (response is ParallelFunctionCallResponse && response.calls.isNotEmpty) {
      return _asStringKeyedMap(response.calls.first.args);
    }
    if (response is TextResponse) {
      return _tryParseEnvelope(response.token);
    }
    return null;
  }

  Map<String, dynamic>? _tryParseEnvelope(String raw) {
    var text = raw.trim();
    if (text.isEmpty) {
      return null;
    }
    final wrappers = <RegExp>[
      RegExp(r'<tool_call>\s*([\s\S]*?)\s*</tool_call>', multiLine: true),
      RegExp(r'<tool_code>\s*([\s\S]*?)\s*</tool_code>', multiLine: true),
      RegExp(r'```(?:json|tool_code)?\s*([\s\S]*?)\s*```', multiLine: true),
    ];
    for (final re in wrappers) {
      final m = re.firstMatch(text);
      if (m != null) {
        text = m.group(1)!.trim();
        break;
      }
    }
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) {
      return null;
    }
    try {
      final decoded = jsonDecode(text.substring(start, end + 1));
      if (decoded is! Map) {
        return null;
      }
      final map = _asStringKeyedMap(decoded);
      if (map == null) {
        return null;
      }
      if (map.containsKey('personMentioned') || map.containsKey('eventText')) {
        return map;
      }
      final nested = map['parameters'] ?? map['args'] ?? map['arguments'];
      return _asStringKeyedMap(nested);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _asStringKeyedMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      try {
        return Map<String, dynamic>.from(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  void _log(String message) {
    debugPrint('[GemmaRuntimeProbe] $message');
  }
}
