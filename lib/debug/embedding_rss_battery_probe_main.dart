import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_embeddings/flutter_gemma_embeddings.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Pre-flight RSS / warm-latency probe for Gecko (Phase 3.3 Section A).
///
/// Run:
/// `flutter run -t lib/debug/embedding_rss_battery_probe_main.dart -d <device>`
///
/// Logs warm embed latency. RSS is best-effort via `/proc/self/status` on
/// Android (VmRSS). Battery Exp 6 remains a soft manual observation.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  void log(String m) => debugPrint('[GeckoProbe] $m');

  await FlutterGemma.initialize(
    inferenceEngines: const [LiteRtLmEngine()],
    embeddingBackends: const [LiteRtEmbeddingBackend()],
  );

  final docs = await getApplicationDocumentsDirectory();
  final appModel = p.join(docs.path, 'models', 'Gecko_256_quant.tflite');
  final appTok = p.join(docs.path, 'models', 'sentencepiece.model');
  const sdModel = '/sdcard/Download/tend_spike/Gecko_256_quant.tflite';
  const sdTok = '/sdcard/Download/tend_spike/sentencepiece.model';

  late final String model;
  late final String tok;
  if (File(appModel).existsSync() && File(appTok).existsSync()) {
    model = appModel;
    tok = appTok;
  } else if (File(sdModel).existsSync() && File(sdTok).existsSync()) {
    model = sdModel;
    tok = sdTok;
  } else {
    log('MISSING_MODEL paths model=$appModel tok=$appTok');
    log('Also checked $sdModel — push files then re-run.');
    return;
  }

  log('rss_before_kb=${_vmRssKb()}');

  await FlutterGemma.installEmbedder()
      .modelFromFile(model)
      .tokenizerFromFile(tok)
      .install();
  final embedder = await FlutterGemma.getActiveEmbedder(
    preferredBackend: PreferredBackend.cpu,
  );

  log('rss_after_load_kb=${_vmRssKb()}');
  log('dim=${await embedder.getDimension()}');

  // Warm
  const n = 10;
  final ms = <int>[];
  for (var i = 0; i < n; i++) {
    final sw = Stopwatch()..start();
    await embedder.generateEmbedding(
      'Rahul got a job at OpenAI after the internship.',
      taskType: TaskType.retrievalDocument,
    );
    sw.stop();
    ms.add(sw.elapsedMilliseconds);
  }
  final avg = ms.reduce((a, b) => a + b) / ms.length;
  log('warm_ms_list=$ms');
  log('warm_avg_ms=${avg.toStringAsFixed(1)}');
  log('rss_after_warm_kb=${_vmRssKb()}');
  log('PROBE_DONE — record battery manually if desired (soft gate)');
}

int? _vmRssKb() {
  try {
    final status = File('/proc/self/status').readAsStringSync();
    final line = status.split('\n').firstWhere(
          (l) => l.startsWith('VmRSS:'),
          orElse: () => '',
        );
    if (line.isEmpty) return null;
    final parts = line.split(RegExp(r'\s+'));
    return int.tryParse(parts.length > 1 ? parts[1] : '');
  } catch (_) {
    return null;
  }
}

void debugPrint(String message) {
  // ignore: avoid_print
  print(message);
}
