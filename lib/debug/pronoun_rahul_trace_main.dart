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

/// One-shot pronoun QA trace for Capture Quality fix.
///
/// ```
/// flutter run -t lib/debug/pronoun_rahul_trace_main.dart -d <deviceId> --release
/// ```
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final artifact = ModelCatalog.current;
  debugPrint('[PronounTrace] model=${artifact.displayName}');

  final docs = await getApplicationDocumentsDirectory();
  final localPath = p.join(docs.path, 'models', artifact.fileName);
  final hasLocal = File(localPath).existsSync();
  debugPrint('[PronounTrace] path=$localPath exists=$hasLocal');

  const note = 'Met Rahul yesterday.\nHe got selected by OpenAI.';

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
          '[PronounTrace] backend=${model.activeBackend?.name ?? backend.name}',
        );
        break;
      } catch (e) {
        last = e;
        debugPrint('[PronounTrace] backend ${backend.name} failed: $e');
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

      debugPrint('[PronounTrace] ===== RAW TRACE =====');
      debugPrint('[PronounTrace] note=$note');
      debugPrint('[PronounTrace] responseType=${response.runtimeType}');
      if (response is TextResponse) {
        debugPrint('[PronounTrace] TEXT=${response.token}');
      }
      debugPrint(
        '[PronounTrace] functionCallCount=${calls.length} '
        'ms=${sw.elapsedMilliseconds}',
      );

      for (var i = 0; i < calls.length; i++) {
        final args = Map<String, dynamic>.from(calls[i].args);
        final person = '${args['personMentioned'] ?? ''}'.trim();
        final event = '${args['eventText'] ?? ''}'.trim();
        final quote = '${args['quoteEvidence'] ?? ''}'.trim();
        final dateRaw = '${args['dateValueRaw'] ?? ''}'.trim();
        final category = '${args['category'] ?? ''}'.trim();
        debugPrint(
          '[PronounTrace] FC#$i personMentioned="$person" '
          'category="$category" event="$event" quote="$quote" '
          'dateValueRaw="$dateRaw"',
        );

        final date = dateRaw.isEmpty || dateRaw.toLowerCase() == 'null'
            ? null
            : dateRaw;
        final reason = literalExtractionRejectionReason(
          note,
          personMentioned: person,
          eventText: event,
          quoteEvidence: quote,
          dateValueRaw: date,
        );
        debugPrint(
          '[PronounTrace] FC#$i grounding='
          '${reason == null ? "ACCEPT" : "REJECT:$reason"}',
        );
      }

      final verdict = switch (calls.length) {
        0 => 'ZERO_FUNCTION_CALLS',
        1 => 'ONE_FUNCTION_CALL',
        2 => 'TWO_FUNCTION_CALLS',
        _ => 'OTHER_COUNT_${calls.length}',
      };
      debugPrint('[PronounTrace] VERDICT=$verdict');
    } finally {
      await chat.close();
    }
  } catch (e, st) {
    error = e;
    debugPrint('[PronounTrace] uncaught: $e\n$st');
    debugPrint('[PronounTrace] VERDICT=ERROR');
  }

  await Future<void>.delayed(const Duration(seconds: 3));
  exit(error == null ? 0 : 1);
}
