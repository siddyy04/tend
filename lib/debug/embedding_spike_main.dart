import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_embeddings/flutter_gemma_embeddings.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:my_first_app/ai/model_manager/model_catalog.dart';
import 'package:my_first_app/debug/embedding_spike_cases.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Phase 3.2 embedding spike harness (SPRINT3_2.md).
///
/// Isolated debug entrypoint — never wired into production navigation.
///
/// ```
/// flutter run -t lib/debug/embedding_spike_main.dart -d <deviceId> --release
/// ```
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final report = StringBuffer();
  void log(String line) {
    debugPrint('[EmbeddingSpike] $line');
    report.writeln(line);
  }

  log('=== Phase 3.2 Embedding Spike ===');
  log('device_time=${DateTime.now().toIso8601String()}');
  log('reference_device=AIN065 (same tier as 2B.8 RC)');

  Object? fatal;
  try {
    // ----- Experiment 1: Gemma 4 E2B capability -----
    log('');
    log('--- Experiment 1: Gemma 4 E2B embedding capability ---');
    final exp1 = await _experiment1GemmaCapability(log);
    log('EXP1_RESULT=${exp1 ? "CAPABLE" : "NOT_CAPABLE"}');

    // ----- Option 2: Gecko (public, needsAuth=false) -----
    log('');
    log('--- Option 2: Gecko-110m-en via flutter_gemma_embeddings ---');
    log(
      'desk: EmbeddingGemma HF resolve returned 401 without token '
      '(gated — disqualified per ADR-010 / SPRINT3_2 §8).',
    );
    log(
      'desk: Gecko-110m-en resolve returns 302 public CDN '
      '(flutter_gemma example marks needsAuth=false).',
    );

    final gecko = await _experimentGeckoOption2(log);
    log('GECKO_RESULT=${gecko ? "RAN" : "FAILED_OR_SKIPPED"}');
  } catch (e, st) {
    fatal = e;
    log('FATAL: $e');
    log('$st');
  }

  log('');
  log('=== END SPIKE HARNESS ===');
  log('Write measured lines into SPRINT3_2_FINDINGS.md');

  await Future<void>.delayed(const Duration(seconds: 4));
  exit(fatal == null ? 0 : 1);
}

/// Returns true only if Gemma 4 InferenceModel can produce embeddings.
Future<bool> _experiment1GemmaCapability(void Function(String) log) async {
  final artifact = ModelCatalog.current;
  log('catalog_model=${artifact.displayName} file=${artifact.fileName}');

  // API-surface answer (authoritative for RQ1):
  log(
    'api: InferenceModel exposes createSession/createChat — '
    'NO generateEmbedding. EmbeddingModel is a separate type via '
    'FlutterGemma.getActiveEmbedder + flutter_gemma_embeddings + '
    'a dedicated .tflite embedder (EmbeddingGemma/Gecko), not Gemma 4 E2B.',
  );

  await FlutterGemma.initialize(
    inferenceEngines: const [LiteRtLmEngine()],
    // Intentionally NOT registering embedding backends for Exp 1.
  );

  try {
    await FlutterGemma.getActiveEmbedder();
    log('UNEXPECTED: getActiveEmbedder succeeded without embedding model');
    return true;
  } catch (e) {
    log('getActiveEmbedder_without_embedder=$e');
  }

  log(
    'conclusion: Gemma 4 E2B via current LiteRT-LM bridge cannot generate '
    'embeddings without a second dedicated embedding artifact.',
  );
  return false;
}

Future<bool> _experimentGeckoOption2(void Function(String) log) async {
  const modelUrl =
      'https://huggingface.co/litert-community/Gecko-110m-en/resolve/main/Gecko_256_quant.tflite';
  const tokenizerUrl =
      'https://huggingface.co/litert-community/Gecko-110m-en/resolve/main/sentencepiece.model';
  const modelFile = 'Gecko_256_quant.tflite';
  const tokFile = 'sentencepiece.model';

  await FlutterGemma.initialize(
    inferenceEngines: const [LiteRtLmEngine()],
    embeddingBackends: const [LiteRtEmbeddingBackend()],
  );

  final docs = await getApplicationDocumentsDirectory();
  final modelsDir = Directory(p.join(docs.path, 'models'));
  if (!modelsDir.existsSync()) {
    modelsDir.createSync(recursive: true);
  }
  final appModel = p.join(modelsDir.path, modelFile);
  final appTok = p.join(modelsDir.path, tokFile);
  const sdcardModel = '/sdcard/Download/tend_spike/Gecko_256_quant.tflite';
  const sdcardTok = '/sdcard/Download/tend_spike/sentencepiece.model';

  late final String localModel;
  late final String localTok;
  if (File(appModel).existsSync() && File(appTok).existsSync()) {
    localModel = appModel;
    localTok = appTok;
  } else if (File(sdcardModel).existsSync() && File(sdcardTok).existsSync()) {
    localModel = sdcardModel;
    localTok = sdcardTok;
  } else {
    localModel = appModel;
    localTok = appTok;
  }

  log('gecko_model_url=$modelUrl');
  log('gecko_local=$localModel exists=${File(localModel).existsSync()}');
  log('gecko_sdcard_exists=${File(sdcardModel).existsSync()}');

  try {
    var builder = FlutterGemma.installEmbedder();
    if (File(localModel).existsSync() && File(localTok).existsSync()) {
      log('gecko_install=fromFile');
      builder = builder
          .modelFromFile(localModel)
          .tokenizerFromFile(localTok);
    } else {
      log('gecko_install=fromNetwork (public, no token)');
      builder = builder
          .modelFromNetwork(modelUrl)
          .tokenizerFromNetwork(tokenizerUrl)
          .withModelProgress((pct) {
            if (pct % 20 == 0 || pct >= 99) {
              log('gecko_model_download=$pct%');
            }
          })
          .withTokenizerProgress((pct) {
            if (pct % 25 == 0 || pct >= 99) {
              log('gecko_tok_download=$pct%');
            }
          });
    }
    await builder.install();
  } catch (e, st) {
    log('gecko_install_failed=$e');
    log('$st');
    return false;
  }

  EmbeddingModel embedder;
  try {
    embedder = await FlutterGemma.getActiveEmbedder(
      preferredBackend: PreferredBackend.cpu,
    );
  } catch (e) {
    log('gecko_getActiveEmbedder_failed=$e');
    return false;
  }

  try {
    final dim = await embedder.getDimension();
    log('gecko_dimension=$dim');

    // Cold
    final coldSw = Stopwatch()..start();
    final coldVec = await embedder.generateEmbedding(
      embeddingSpikeCorpus.first.indexText,
      taskType: TaskType.retrievalDocument,
    );
    coldSw.stop();
    log(
      'gecko_cold_ms=${coldSw.elapsedMilliseconds} '
      'vec_len=${coldVec.length}',
    );

    // Warm average (N=8)
    const warmN = 8;
    final warmMs = <int>[];
    for (var i = 0; i < warmN; i++) {
      final text = embeddingSpikeCorpus[i % embeddingSpikeCorpus.length].indexText;
      final sw = Stopwatch()..start();
      await embedder.generateEmbedding(
        text,
        taskType: TaskType.retrievalDocument,
      );
      sw.stop();
      warmMs.add(sw.elapsedMilliseconds);
    }
    final warmAvg = warmMs.reduce((a, b) => a + b) / warmMs.length;
    log('gecko_warm_ms_list=$warmMs');
    log('gecko_warm_avg_ms=${warmAvg.toStringAsFixed(1)}');

    // Index corpus
    final docVectors = <String, List<double>>{};
    for (final doc in embeddingSpikeCorpus) {
      docVectors[doc.id] = await embedder.generateEmbedding(
        doc.indexText,
        taskType: TaskType.retrievalDocument,
      );
    }

    // Retrieval quality
    var paraphraseHits = 0;
    var paraphraseTotal = 0;
    var exactHits = 0;
    var exactTotal = 0;
    for (final q in embeddingSpikeQueries) {
      final qVec = await embedder.generateEmbedding(
        q.query,
        taskType: TaskType.retrievalQuery,
      );
      final ranked = docVectors.entries
          .map(
            (e) => (
              id: e.key,
              score: _cosine(qVec, e.value),
            ),
          )
          .toList()
        ..sort((a, b) => b.score.compareTo(a.score));

      final top = ranked.take(3).toList();
      final topIds = top.map((e) => e.id).toList();
      final hit = q.expectedDocIds.isEmpty
          ? true // negative: scored separately
          : q.expectedDocIds.any(topIds.contains);

      if (q.kind == 'paraphrase') {
        paraphraseTotal++;
        if (q.expectedDocIds.any((id) => topIds.isNotEmpty && topIds.first == id) ||
            q.expectedDocIds.any(topIds.contains)) {
          paraphraseHits++;
        }
      }
      if (q.kind == 'exact') {
        exactTotal++;
        if (q.expectedDocIds.any((id) => topIds.isNotEmpty && topIds.first == id)) {
          exactHits++;
        }
      }

      log(
        'quality q=${q.id} kind=${q.kind} '
        'top=${top.map((e) => '${e.id}:${e.score.toStringAsFixed(3)}').join(',')} '
        'expected=${q.expectedDocIds} hit=$hit',
      );
    }
    log(
      'quality_summary exact_top1=$exactHits/$exactTotal '
      'paraphrase_top3=$paraphraseHits/$paraphraseTotal',
    );

    // Backfill extrapolation
    final perItemMs = warmAvg;
    for (final n in const [50, 200, 500, 2000]) {
      final totalSec = (perItemMs * n) / 1000.0;
      log(
        'backfill_extrapolate n=$n per_item_ms=${perItemMs.toStringAsFixed(1)} '
        'total_s=${totalSec.toStringAsFixed(1)} '
        'total_min=${(totalSec / 60).toStringAsFixed(2)}',
      );
    }

    // Storage
    log(
      'storage_per_memory_768f32_bytes=${768 * 4} '
      'for_5000_memories_MB=${(5000 * 768 * 4) / (1024 * 1024)}',
    );
    log(
      'download_stack: Gemma4_E2B≈2.4GB + Gecko≈114MB '
      'cumulative≈2.5GB+',
    );

    return true;
  } finally {
    await embedder.close();
  }
}

double _cosine(List<double> a, List<double> b) {
  final n = math.min(a.length, b.length);
  var dot = 0.0;
  var na = 0.0;
  var nb = 0.0;
  for (var i = 0; i < n; i++) {
    dot += a[i] * b[i];
    na += a[i] * a[i];
    nb += b[i] * b[i];
  }
  if (na == 0 || nb == 0) return 0;
  return dot / (math.sqrt(na) * math.sqrt(nb));
}
