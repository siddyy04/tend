import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:my_first_app/ai/model_manager/model_catalog.dart';
import 'package:my_first_app/ai/providers/litert/litert_prompt_builder.dart';
import 'package:my_first_app/domain/rules/extraction_validation_rules.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Sprint 2B.1 follow-up: same-person multi-memory parallel FC validation.
///
/// Usage:
/// ```
/// flutter run -t lib/debug/same_person_multi_memory_spike_main.dart -d <deviceId> --release
/// ```
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final artifact = ModelCatalog.current;
  debugPrint('[SamePersonSpike] model=${artifact.displayName}');

  final docs = await getApplicationDocumentsDirectory();
  final localPath = p.join(docs.path, 'models', artifact.fileName);
  final hasLocal = File(localPath).existsSync();
  debugPrint('[SamePersonSpike] path=$localPath exists=$hasLocal');

  String? report;
  Object? error;
  var allPassed = false;
  try {
    final result = await SamePersonMultiMemorySpike(
      modelFilePath: hasLocal ? localPath : null,
      artifact: artifact,
    ).run();
    report = result.report;
    allPassed = result.allPassed;
  } catch (e, st) {
    error = e;
    debugPrint('[SamePersonSpike] uncaught: $e\n$st');
  }

  debugPrint('[SamePersonSpike] ===== FINAL REPORT =====');
  debugPrint(report ?? 'no report');
  debugPrint(
    '[SamePersonSpike] VERDICT: ${allPassed ? "PASS" : "FAIL"} '
    '(protocol lock ${allPassed ? "OK" : "NOT locked"})',
  );
  if (error != null) {
    debugPrint('[SamePersonSpike] error=$error');
  }

  await Future<void>.delayed(const Duration(seconds: 3));
  exit(error == null && allPassed ? 0 : 1);
}

class SamePersonMultiMemorySpike {
  SamePersonMultiMemorySpike({
    required this.artifact,
    this.modelFilePath,
  });

  final ModelArtifactSpec artifact;
  final String? modelFilePath;

  /// Notes with multiple independent memories about one person.
  static const cases = <_Case>[
    _Case(
      id: 'priya_career_move_pref_goal',
      expectedPerson: 'Priya',
      expectedCount: 4,
      orderHints: [
        'Stripe',
        'Berlin',
        'oat milk',
        'house',
      ],
      text:
          'Priya started a new job at Stripe last month. '
          'Priya is moving to Berlin in September. '
          'Priya prefers oat milk in her coffee. '
          'Priya is saving for a house.',
    ),
    _Case(
      id: 'mom_surgery_physio_followup_recovery',
      expectedPerson: 'Mom',
      expectedCount: 4,
      orderHints: [
        'spinal surgery',
        'physiotherapy',
        'follow-up',
        'recovering',
      ],
      text:
          'Mom had spinal surgery 1.5 months back. '
          'Mom started physiotherapy last week. '
          'Mom has a follow-up scan next Thursday. '
          'Mom is recovering well at home.',
    ),
    _Case(
      id: 'dad_two_facts_control',
      expectedPerson: 'Dad',
      expectedCount: 2,
      orderHints: [
        'retired',
        'walk',
      ],
      text:
          'Dad retired from the bank in March 2024. '
          'Dad still goes for a walk every morning.',
    ),
  ];

  Future<({String report, bool allPassed})> run() async {
    await FlutterGemma.initialize(inferenceEngines: const [LiteRtLmEngine()]);

    final path = modelFilePath;
    if (path != null && File(path).existsSync()) {
      debugPrint(
        '[SamePersonSpike] install fromFile bytes=${File(path).lengthSync()}',
      );
      await FlutterGemma.installModel(
        modelType: ModelType.gemma4,
        fileType: ModelFileType.litertlm,
      ).fromFile(path).install();
    } else {
      debugPrint('[SamePersonSpike] install fromNetwork ${artifact.downloadUrl}');
      await FlutterGemma.installModel(
        modelType: ModelType.gemma4,
        fileType: ModelFileType.litertlm,
      ).fromNetwork(artifact.downloadUrl).install();
    }

    final model = await _loadModel(artifact.maxTokens);
    final tool = _toSdkTool(LiteRtPromptBuilder().build(
      text: 'x',
      knownPeople: const [],
    ).tools.first);

    final buf = StringBuffer();
    buf.writeln('Same-person multi-memory spike — ${artifact.displayName}');
    buf.writeln('backend=${model.activeBackend?.name ?? "?"}');
    buf.writeln('protocol=parallel native FunctionCall (production prompt)');
    buf.writeln();

    var allPassed = true;
    for (final c in cases) {
      final outcome = await _runCase(model: model, tool: tool, c: c);
      buf.writeln(outcome.section);
      buf.writeln();
      if (!outcome.passed) {
        allPassed = false;
      }
    }

    buf.writeln(
      allPassed
          ? 'ALL_CASES_PASSED — safe to lock parallel FC as long-term protocol.'
          : 'SOME_CASES_FAILED — do not lock protocol yet; inspect failures.',
    );
    return (report: buf.toString(), allPassed: allPassed);
  }

  Future<_CaseOutcome> _runCase({
    required InferenceModel model,
    required Tool tool,
    required _Case c,
  }) async {
    final promptBuilder = const LiteRtPromptBuilder();
    final bundle = promptBuilder.build(text: c.text, knownPeople: const []);
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
        tools: [tool],
        toolChoice: ToolChoice.auto,
        isThinking: false,
        modelType: ModelType.gemma4,
      );
      await chat.addQueryChunk(
        Message.text(text: bundle.userPrompt, isUser: true),
      );
      final response = await chat.generateChatResponse();
      sw.stop();

      final calls = <FunctionCallResponse>[];
      final responseType = response.runtimeType.toString();
      if (response is FunctionCallResponse) {
        calls.add(response);
      } else if (response is ParallelFunctionCallResponse) {
        calls.addAll(response.calls);
      }

      final accepted = <_AcceptedMem>[];
      final rejects = <String>[];
      for (var i = 0; i < calls.length; i++) {
        final call = calls[i];
        if (call.name != LiteRtPromptBuilder.extractMemoriesToolName) {
          rejects.add('call[$i] unexpected tool ${call.name}');
          continue;
        }
        final args = Map<String, dynamic>.from(call.args);
        // Parallel protocol must be flat — nested candidates[] is a fail for this spike.
        if (args.containsKey('candidates')) {
          rejects.add('call[$i] contains candidates[] (not parallel-flat)');
          continue;
        }
        final person = '${args['personMentioned'] ?? ''}'.trim();
        final event = '${args['eventText'] ?? ''}'.trim();
        final quote = '${args['quoteEvidence'] ?? ''}'.trim();
        final date = _nullable(args['dateValueRaw']);
        final category = validatedCategory('${args['category'] ?? ''}');
        if (person.isEmpty || event.isEmpty || category == null) {
          rejects.add('call[$i] schema incomplete');
          continue;
        }
        final reason = literalExtractionRejectionReason(
          c.text,
          personMentioned: person,
          eventText: event,
          quoteEvidence: quote,
          dateValueRaw: date,
        );
        if (reason != null) {
          rejects.add('call[$i] grounding: $reason');
          continue;
        }
        accepted.add(
          _AcceptedMem(
            index: i,
            person: person,
            event: event,
            quote: quote,
            category: category.name,
          ),
        );
      }

      final checks = <String, bool>{};
      checks['one_call_per_memory_count'] =
          calls.length == c.expectedCount && accepted.length == c.expectedCount;
      checks['all_same_expected_person'] = accepted.every(
        (m) => _personMatches(m.person, c.expectedPerson),
      );
      checks['order_preserved'] = _orderPreserved(c.text, accepted, c.orderHints);
      checks['no_merged_facts'] = _noMergedFacts(accepted, c.orderHints);
      checks['no_duplicates'] = _noDuplicates(accepted);

      final passed = checks.values.every((v) => v) && rejects.isEmpty;

      debugPrint(
        '[SamePersonSpike] ${c.id} type=$responseType calls=${calls.length} '
        'accepted=${accepted.length} ms=${sw.elapsedMilliseconds} '
        'passed=$passed',
      );
      for (final m in accepted) {
        debugPrint(
          '[SamePersonSpike]   [$c.id] #${m.index} person=${m.person} '
          'cat=${m.category} event=${m.event}',
        );
      }
      for (final e in checks.entries) {
        debugPrint('[SamePersonSpike]   check ${e.key}=${e.value}');
      }

      final section = StringBuffer()
        ..writeln(
          '--- ${c.id} expected=${c.expectedCount} person=${c.expectedPerson} ---',
        )
        ..writeln('note: ${c.text}')
        ..writeln(
          'result: type=$responseType rawCalls=${calls.length} '
          'accepted=${accepted.length} ms=${sw.elapsedMilliseconds}',
        );
      for (final m in accepted) {
        section.writeln(
          '  #${m.index} person="${m.person}" category=${m.category} '
          'event="${m.event}"',
        );
      }
      if (rejects.isNotEmpty) {
        section.writeln('  rejects: ${rejects.join(' | ')}');
      }
      for (final e in checks.entries) {
        section.writeln('  ${e.value ? "PASS" : "FAIL"} ${e.key}');
      }
      section.writeln('CASE: ${passed ? "PASS" : "FAIL"}');

      return _CaseOutcome(passed: passed, section: section.toString());
    } catch (e) {
      sw.stop();
      debugPrint('[SamePersonSpike] ${c.id} EXCEPTION: $e');
      return _CaseOutcome(
        passed: false,
        section: '--- ${c.id} ---\nEXCEPTION: $e\nCASE: FAIL',
      );
    } finally {
      try {
        await chat?.close();
      } catch (_) {}
    }
  }

  bool _personMatches(String actual, String expected) {
    return actual.toLowerCase() == expected.toLowerCase();
  }

  /// Order preserved: each successive accepted memory's hint appears later in
  /// the note than the previous (by first index of hint in source / event+quote).
  bool _orderPreserved(
    String note,
    List<_AcceptedMem> accepted,
    List<String> orderHints,
  ) {
    if (accepted.length != orderHints.length) {
      return false;
    }
    var lastPos = -1;
    for (var i = 0; i < accepted.length; i++) {
      final hint = orderHints[i].toLowerCase();
      final hay =
          '${accepted[i].event} ${accepted[i].quote}'.toLowerCase();
      if (!hay.contains(hint) && !note.toLowerCase().contains(hint)) {
        return false;
      }
      // Position of this fact in the original note (prefer quote, else event).
      final posQuote = note.toLowerCase().indexOf(accepted[i].quote.toLowerCase());
      final posHint = note.toLowerCase().indexOf(hint);
      final pos = posQuote >= 0 ? posQuote : posHint;
      if (pos < 0 || pos < lastPos) {
        return false;
      }
      lastPos = pos;
    }
    return true;
  }

  /// No merge: each accepted memory should cover exactly one order hint,
  /// and not contain two different hints from the set.
  bool _noMergedFacts(List<_AcceptedMem> accepted, List<String> orderHints) {
    if (accepted.length != orderHints.length) {
      return false;
    }
    for (final mem in accepted) {
      final hay = '${mem.event} ${mem.quote}'.toLowerCase();
      final hits = orderHints
          .where((h) => hay.contains(h.toLowerCase()))
          .length;
      if (hits != 1) {
        return false;
      }
    }
    // Each hint claimed by exactly one memory.
    for (final hint in orderHints) {
      final owners = accepted
          .where(
            (m) => '${m.event} ${m.quote}'
                .toLowerCase()
                .contains(hint.toLowerCase()),
          )
          .length;
      if (owners != 1) {
        return false;
      }
    }
    return true;
  }

  bool _noDuplicates(List<_AcceptedMem> accepted) {
    final keys = <String>{};
    for (final m in accepted) {
      final key =
          '${m.person.toLowerCase()}|${m.event.toLowerCase()}|${m.quote.toLowerCase()}';
      if (!keys.add(key)) {
        return false;
      }
    }
    // Also reject near-duplicates: same quoteEvidence.
    final quotes = accepted.map((m) => m.quote.toLowerCase()).toSet();
    return quotes.length == accepted.length;
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
          '[SamePersonSpike] loaded backend=${model.activeBackend?.name ?? backend.name}',
        );
        return model;
      } catch (e) {
        last = e;
        debugPrint('[SamePersonSpike] backend ${backend.name} failed: $e');
      }
    }
    throw StateError('model load failed: $last');
  }

  Tool _toSdkTool(LiteRtToolDefinition definition) {
    return Tool(
      name: definition.name,
      description: definition.description,
      parameters: definition.parameters,
    );
  }

  String? _nullable(Object? value) {
    if (value == null) return null;
    final t = '$value'.trim();
    if (t.isEmpty || t.toLowerCase() == 'null') return null;
    return t;
  }
}

class _Case {
  const _Case({
    required this.id,
    required this.text,
    required this.expectedPerson,
    required this.expectedCount,
    required this.orderHints,
  });

  final String id;
  final String text;
  final String expectedPerson;
  final int expectedCount;
  final List<String> orderHints;
}

class _AcceptedMem {
  const _AcceptedMem({
    required this.index,
    required this.person,
    required this.event,
    required this.quote,
    required this.category,
  });

  final int index;
  final String person;
  final String event;
  final String quote;
  final String category;
}

class _CaseOutcome {
  const _CaseOutcome({required this.passed, required this.section});

  final bool passed;
  final String section;
}
