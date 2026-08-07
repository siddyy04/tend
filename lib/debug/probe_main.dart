import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_first_app/ai/model_manager/model_catalog.dart';
import 'package:my_first_app/debug/gemma_runtime_probe.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Standalone entrypoint that runs the extraction grounding probe and exits.
///
/// Uses [ModelCatalog.current] (Gemma 4 E2B MVP default).
///
/// Usage:
/// ```
/// flutter run -t lib/debug/probe_main.dart -d <deviceId>
/// ```
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final artifact = ModelCatalog.current;
  debugPrint(
    '[ProbeMain] starting grounding probe for ${artifact.displayName}…',
  );

  final docs = await getApplicationDocumentsDirectory();
  final localPath = p.join(docs.path, 'models', artifact.fileName);
  final hasLocal = File(localPath).existsSync();
  debugPrint('[ProbeMain] local path=$localPath exists=$hasLocal');

  OfficialProbeReport? report;
  Object? error;
  try {
    report = await GemmaRuntimeProbe(
      modelFilePath: hasLocal ? localPath : null,
      allowNetworkDownload: true,
      suite: OfficialProbeSuite.extractionGrounding,
      artifact: artifact,
    ).run();
  } catch (e, st) {
    error = e;
    debugPrint('[ProbeMain] uncaught: $e\n$st');
  }

  final verdict = report == null
      ? 'INCONCLUSIVE (exception before report)'
      : 'GROUNDING: accepted=${report.acceptedCount} '
          'rejected=${report.rejectedCount} total=${report.cases.length} '
          'avgMs=${report.averageElapsedMs?.toStringAsFixed(0)} '
          'coldStartMs=${report.coldStartMs} '
          'warmAvgMs=${report.warmAvgMs} '
          'avgQuality=${report.averageExtractionQuality.toStringAsFixed(2)} '
          'peakRssMb=${report.peakRssBytes == null ? '?' : (report.peakRssBytes! / (1024 * 1024)).toStringAsFixed(1)} '
          'backend=${report.activeBackend ?? "?"} '
          'downloadGb=${report.downloadBytes == null ? '?' : (report.downloadBytes! / (1024 * 1024 * 1024)).toStringAsFixed(2)}';

  debugPrint('[ProbeMain] VERDICT: $verdict');
  if (report != null) {
    debugPrint(report.toString());
  }
  if (error != null) {
    debugPrint('[ProbeMain] error=$error');
  }

  runApp(
    MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Text(
                'Grounding probe finished.\n\n$verdict\n\n'
                '${report ?? error ?? ''}\n\n'
                'Exiting in 5s — check Debug Console / logcat.',
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await Future<void>.delayed(const Duration(seconds: 5));
  await SystemNavigator.pop();
  exit(report != null && report.acceptedCount > 0 ? 0 : 1);
}
