import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_embeddings/flutter_gemma_embeddings.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:my_first_app/ai/model_manager/embedding_model_manager.dart';
import 'package:my_first_app/ai/providers/gecko/gecko_constants.dart';
import 'package:my_first_app/ai/runtime/tend_gemma_bootstrap.dart';

/// Sole production import point for `flutter_gemma_embeddings` (Phase 3.3).
///
/// Mirrors [LiteRtInferenceAdapter]'s vendor boundary for the LLM stack.
class GeckoInferenceAdapter {
  GeckoInferenceAdapter({
    required EmbeddingModelManager modelManager,
  }) : _models = modelManager;

  final EmbeddingModelManager _models;
  EmbeddingModel? _embedder;
  var _installed = false;

  /// Registers a process-wide FlutterGemma bootstrap that includes embedding
  /// backends (safe to call more than once).
  static void installBootstrap() {
    tendGemmaBootstrap = () async {
      await FlutterGemma.initialize(
        inferenceEngines: const [LiteRtLmEngine()],
        embeddingBackends: const [LiteRtEmbeddingBackend()],
      );
    };
  }

  Future<void> _ensureRuntime() async {
    final bootstrap = tendGemmaBootstrap;
    if (bootstrap != null) {
      await bootstrap();
    } else {
      await FlutterGemma.initialize(
        inferenceEngines: const [LiteRtLmEngine()],
        embeddingBackends: const [LiteRtEmbeddingBackend()],
      );
    }
  }

  /// True when files exist and embedder has been installed this process
  /// (or marked ready in prefs from a prior session — still need install).
  Future<bool> isReady() async {
    if (_embedder != null) return true;
    return _models.areFilesOnDisk();
  }

  /// Downloads (if needed) and installs the embedder from local files.
  Future<void> prepare({
    void Function(double? fraction)? onDownloadProgress,
  }) async {
    await _ensureRuntime();

    if (!await _models.areFilesOnDisk()) {
      await _models.ensureFilesDownloaded(
        onProgress: (p) => onDownloadProgress?.call(p.fraction),
      );
    }

    final modelPath = await _models.modelPath();
    final tokPath = await _models.tokenizerPath();
    if (!File(modelPath).existsSync() || !File(tokPath).existsSync()) {
      throw StateError('Gecko model files missing after download.');
    }

    if (!_installed) {
      await FlutterGemma.installEmbedder()
          .modelFromFile(modelPath)
          .tokenizerFromFile(tokPath)
          .install();
      _installed = true;
      await _models.markRuntimeInstalled();
    }

    _embedder ??= await FlutterGemma.getActiveEmbedder(
      preferredBackend: PreferredBackend.cpu,
    );

    final dim = await _embedder!.getDimension();
    if (dim != GeckoConstants.dimension) {
      if (kDebugMode) {
        debugPrint(
          '[GeckoInferenceAdapter] unexpected dim=$dim '
          '(expected ${GeckoConstants.dimension})',
        );
      }
    }
  }

  Future<List<double>> generateEmbedding(
    String text, {
    required bool isQuery,
  }) async {
    await prepare();
    final embedder = _embedder;
    if (embedder == null) {
      throw StateError('Gecko embedder not prepared.');
    }
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Cannot embed empty text.');
    }
    return embedder.generateEmbedding(
      trimmed,
      taskType:
          isQuery ? TaskType.retrievalQuery : TaskType.retrievalDocument,
    );
  }

  /// Releases the resident embedder worker to free RAM before Gemma extraction.
  ///
  /// Does **not** uninstall catalog files or clear readiness prefs — the next
  /// [prepare] / [generateEmbedding] reloads via [FlutterGemma.getActiveEmbedder].
  /// Idempotent and safe when no embedder is loaded.
  Future<void> releaseResident() async {
    final embedder = _embedder;
    _embedder = null;
    if (embedder == null) return;
    try {
      await embedder.close();
      if (kDebugMode) {
        debugPrint('[GeckoInferenceAdapter] releaseResident=closed');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[GeckoInferenceAdapter] releaseResident failed: $e\n$st');
      }
    }
  }

  String get modelVersion => GeckoConstants.modelVersion;

  /// True when an [EmbeddingModel] instance is currently held in memory.
  bool get hasResidentEmbedder => _embedder != null;
}
