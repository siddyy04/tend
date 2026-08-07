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

/// Mom completeness re-check after prompt refinement (Sprint 2B.1).
///
/// ```
/// flutter run -t lib/debug/mom_completeness_spike_main.dart -d <deviceId> --release
/// ```
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final artifact = ModelCatalog.current;
  debugPrint('[MomSpike] model=${artifact.displayName}');

  final docs = await getApplicationDocumentsDirectory();
  final localPath = p.join(docs.path, 'models', artifact.fileName);
  final hasLocal = File(localPath).existsSync();
  debugPrint('[MomSpike] path=$localPath exists=$hasLocal');

  const note =
      'Mom had spinal surgery 1.5 months back. '
      'Mom started physiotherapy last week. '
      'Mom has a follow-up scan next Thursday. '
      'Mom is recovering well at home.';
  const expected = 4;
  const orderHints = [
    'spinal surgery',
    'physiotherapy',
    'follow-up',
    'recovering',
  ];

  var passed = false;
  Object? error;
  try {
    await FlutterGemma.initialize(inferenceEngines: const [LiteRtLmEngine()]);
    if (hasLocal) {
      await FlutterGemma.installModel(
        modelType: ModelType.gemma4,
        fileType: ModelFileType.litertlm,
      ).fromFile(localPath).install();
    } else {
      await FlutterGemma.installModel(
        modelType: ModelType.gemma4,
        fileType: ModelFileType.litertlm,
      ).fromNetwork(artifact.downloadUrl).install();
    }

    InferenceModel? model;
    Object? last;
    for (final backend in const [
      PreferredBackend.gpu,
      PreferredBackend.npu,
      PreferredBackend.cpu,
    ]) {
      try {
        model = await FlutterGemma.getActiveModel(
          maxTokens: artifact.maxTokens,
          preferredBackend: backend,
        );
        debugPrint(
          '[MomSpike] backend=${model.activeBackend?.name ?? backend.name}',
        );
        break;
      } catch (e) {
        last = e;
        debugPrint('[MomSpike] backend ${backend.name} failed: $e');
      }
    }
    if (model == null) {
      throw StateError('model load failed: $last');
    }

    final bundle = const LiteRtPromptBuilder().build(
      text: note,
      knownPeople: const [],
    );
    final toolDef = bundle.tools.first;
    final tool = Tool(
      name: toolDef.name,
      description: toolDef.description,
      parameters: toolDef.parameters,
    );

    final sw = Stopwatch()..start();
    final chat = await model.createChat(
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
    try {
      await chat.addQueryChunk(
        Message.text(text: bundle.userPrompt, isUser: true),
      );
      final response = await chat.generateChatResponse();
      sw.stop();

      final calls = <FunctionCallResponse>[];
      if (response is FunctionCallResponse) {
        calls.add(response);
      } else if (response is ParallelFunctionCallResponse) {
        calls.addAll(response.calls);
      }

      final accepted = <({String person, String event, String quote})>[];
      for (final call in calls) {
        final args = Map<String, dynamic>.from(call.args);
        final person = '${args['personMentioned'] ?? ''}'.trim();
        final event = '${args['eventText'] ?? ''}'.trim();
        final quote = '${args['quoteEvidence'] ?? ''}'.trim();
        final dateRaw = '${args['dateValueRaw'] ?? ''}'.trim();
        final date = dateRaw.isEmpty || dateRaw.toLowerCase() == 'null'
            ? null
            : dateRaw;
        final category = validatedCategory('${args['category'] ?? ''}');
        if (person.isEmpty || event.isEmpty || category == null) {
          continue;
        }
        final reason = literalExtractionRejectionReason(
          note,
          personMentioned: person,
          eventText: event,
          quoteEvidence: quote,
          dateValueRaw: date,
        );
        if (reason != null) {
          debugPrint('[MomSpike] rejected: $reason event=$event');
          continue;
        }
        accepted.add((person: person, event: event, quote: quote));
      }

      final countOk = calls.length == expected && accepted.length == expected;
      final personOk =
          accepted.every((m) => m.person.toLowerCase() == 'mom');
      final hasRecovery = accepted.any(
        (m) => '${m.event} ${m.quote}'.toLowerCase().contains('recover'),
      );
      final hintHits = orderHints
          .where(
            (h) => accepted.any(
              (m) => '${m.event} ${m.quote}'.toLowerCase().contains(h),
            ),
          )
          .length;

      passed = countOk && personOk && hasRecovery && hintHits == expected;

      debugPrint('[MomSpike] type=${response.runtimeType}');
      if (response is TextResponse) {
        debugPrint('[MomSpike] TEXT_RESPONSE=${response.token}');
      }
      debugPrint(
        '[MomSpike] calls=${calls.length} accepted=${accepted.length} '
        'ms=${sw.elapsedMilliseconds}',
      );
      for (var i = 0; i < accepted.length; i++) {
        final m = accepted[i];
        debugPrint(
          '[MomSpike] #$i person=${m.person} event=${m.event}',
        );
      }
      debugPrint('[MomSpike] countOk=$countOk personOk=$personOk '
          'hasRecovery=$hasRecovery hintHits=$hintHits/$expected');
      debugPrint('[MomSpike] VERDICT: ${passed ? "PASS" : "FAIL"}');
    } finally {
      await chat.close();
    }
  } catch (e, st) {
    error = e;
    debugPrint('[MomSpike] uncaught: $e\n$st');
    debugPrint('[MomSpike] VERDICT: FAIL');
  }

  await Future<void>.delayed(const Duration(seconds: 3));
  exit(error == null && passed ? 0 : 1);
}
