import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/ai/inference/ai_inference_mutex.dart';
import 'package:my_first_app/ai/model_manager/device_capability_check.dart';
import 'package:my_first_app/ai/model_manager/embedding_model_manager.dart';
import 'package:my_first_app/ai/model_manager/model_download_manager.dart';
import 'package:my_first_app/ai/model_manager/model_manager_providers.dart';
import 'package:my_first_app/ai/providers/embedding/embedding_backfill_controller.dart';
import 'package:my_first_app/ai/providers/embedding/embedding_enqueue_hook.dart';
import 'package:my_first_app/ai/providers/embedding/embedding_queue_controller.dart';
import 'package:my_first_app/ai/providers/embedding/noop_embedding_provider.dart';
import 'package:my_first_app/ai/providers/embedding_provider.dart';
import 'package:my_first_app/ai/providers/extraction_provider.dart';
import 'package:my_first_app/ai/providers/gecko/gecko_constants.dart';
import 'package:my_first_app/ai/providers/gecko/gecko_embedding_provider.dart';
import 'package:my_first_app/ai/providers/gecko/gecko_inference_adapter.dart';
import 'package:my_first_app/ai/providers/litert/litert_extraction_provider.dart';
import 'package:my_first_app/ai/providers/litert/litert_inference_adapter.dart';
import 'package:my_first_app/ai/providers/litert/litert_prompt_builder.dart';
import 'package:my_first_app/ai/providers/manual/manual_fallback_provider.dart';
import 'package:my_first_app/ai/providers/ocr_provider.dart';
import 'package:my_first_app/ai/providers/platform/platform_ocr_provider.dart';
import 'package:my_first_app/ai/providers/platform/platform_transcription_provider.dart';
import 'package:my_first_app/ai/providers/search/hybrid_result_composer.dart';
import 'package:my_first_app/ai/providers/search/semantic_search_provider.dart';
import 'package:my_first_app/ai/providers/transcription_provider.dart';
import 'package:my_first_app/features/circle/circle_providers.dart';
import 'package:my_first_app/features/person_profile/person_profile_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared AI inference mutex (extraction > embedding).
final aiInferenceMutexProvider = Provider<AiInferenceMutex>((ref) {
  ref.keepAlive();
  return AiInferenceMutex();
});

/// Shared LiteRT inference adapter — model path comes from [ModelDownloadManager].
///
/// Kept alive so Capture rebuilds do not recreate the adapter and force a
/// native reinstall on every submit (that path aborted on retry).
final liteRtInferenceAdapterProvider = Provider<LiteRtInferenceAdapter>((ref) {
  ref.keepAlive();
  return LiteRtInferenceAdapter(
    modelManager: ref.watch(modelDownloadManagerProvider),
  );
});

/// LiteRT-backed extraction provider (active model from [ModelCatalog]).
final liteRtExtractionProvider = Provider<LiteRtExtractionProvider>((ref) {
  ref.keepAlive();
  return LiteRtExtractionProvider(
    adapter: ref.watch(liteRtInferenceAdapterProvider),
    promptBuilder: const LiteRtPromptBuilder(),
    inferenceMutex: ref.watch(aiInferenceMutexProvider),
    beforeInference: () {
      return ref.read(geckoInferenceAdapterProvider).releaseResident();
    },
  );
});

/// Resolves the active [ExtractionProvider].
///
/// Unsupported devices → [ManualFallbackProvider].
/// Supported devices → [LiteRtExtractionProvider] (model must be ready at call time).
/// Capture UI skips calling extract entirely on unsupported devices.
final activeExtractionProvider = Provider<ExtractionProvider>((ref) {
  final tierAsync = ref.watch(deviceAiTierProvider);
  final tier = tierAsync.asData?.value;
  if (tier == DeviceAiTier.unsupported) {
    return const ManualFallbackProvider();
  }
  return ref.watch(liteRtExtractionProvider);
});

/// Platform speech recognition — never routes through LiteRT / Gemma.
///
/// Concrete MVP implementation. Prefer [activeTranscriptionProvider] in UI so
/// a future long-form engine can replace this without Capture changes.
final platformTranscriptionProvider =
    Provider<PlatformTranscriptionProvider>((ref) {
  final provider = PlatformTranscriptionProvider();
  ref.onDispose(() {
    provider.cancelListening();
  });
  return provider;
});

/// Active [TranscriptionProvider] — the only transcription dependency Capture
/// / Voice should watch. Swap the returned implementation when a long-form
/// engine is selected after evaluation (see BACKLOG).
final activeTranscriptionProvider = Provider<TranscriptionProvider>((ref) {
  return ref.watch(platformTranscriptionProvider);
});

/// Platform OCR — never routes through LiteRT / Gemma.
final platformOCRProvider = Provider<PlatformOCRProvider>((ref) {
  final provider = PlatformOCRProvider();
  ref.onDispose(() {
    provider.close();
  });
  return provider;
});

/// Active [OCRProvider] — Capture / Photo UI should watch this only.
final activeOCRProvider = Provider<OCRProvider>((ref) {
  return ref.watch(platformOCRProvider);
});

// --- Phase 3.3 embeddings ---

final geckoInferenceAdapterProvider = Provider<GeckoInferenceAdapter>((ref) {
  ref.keepAlive();
  GeckoInferenceAdapter.installBootstrap();
  return GeckoInferenceAdapter(
    modelManager: ref.watch(embeddingModelManagerProvider),
  );
});

final geckoEmbeddingProvider = Provider<GeckoEmbeddingProvider>((ref) {
  ref.keepAlive();
  return GeckoEmbeddingProvider(
    adapter: ref.watch(geckoInferenceAdapterProvider),
    mutex: ref.watch(aiInferenceMutexProvider),
  );
});

/// Resolves to Gecko when files+runtime are ready; otherwise NoOp.
///
/// Callers that need to activate Gecko should use [ensureGeckoEmbedderReady].
final activeEmbeddingProvider = Provider<EmbeddingProvider>((ref) {
  final status = ref.watch(geckoEmbedderStatusProvider).asData?.value;
  if (status == GeckoEmbedderStatus.runtimeReady ||
      status == GeckoEmbedderStatus.filesReady) {
    // filesReady still needs prepare(); provider methods call prepare().
    return ref.watch(geckoEmbeddingProvider);
  }
  return const NoOpEmbeddingProvider();
});

final geckoEmbedderStatusProvider =
    FutureProvider<GeckoEmbedderStatus>((ref) async {
  return ref.watch(embeddingModelManagerProvider).status();
});

/// Tier 2 cosine threshold (tunable via SharedPreferences).
final tier2CosineThresholdProvider = FutureProvider<double>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getDouble(GeckoConstants.tier2ThresholdPrefsKey) ??
      GeckoConstants.provisionalTier2Threshold;
});

final hybridResultComposerProvider = Provider<HybridResultComposer>((ref) {
  return const HybridResultComposer();
});

final semanticSearchProvider = Provider<SemanticSearchProvider?>((ref) {
  final embedding = ref.watch(activeEmbeddingProvider);
  if (embedding is! GeckoEmbeddingProvider) return null;
  final thresholdAsync = ref.watch(tier2CosineThresholdProvider);
  final threshold =
      thresholdAsync.asData?.value ?? GeckoConstants.provisionalTier2Threshold;
  return SemanticSearchProvider(
    memoryRepository: ref.watch(memoryRepositoryProvider),
    personRepository: ref.watch(personRepositoryProvider),
    embeddingProvider: embedding,
    thresholdReader: () => threshold,
  );
});

final embeddingQueueControllerProvider =
    Provider<EmbeddingQueueController>((ref) {
  ref.keepAlive();
  return EmbeddingQueueController(
    memoryRepository: ref.watch(memoryRepositoryProvider),
    embeddingProviderReader: () => ref.read(activeEmbeddingProvider),
  );
});

final embeddingEnqueueHookProvider = Provider<EmbeddingEnqueueHook>((ref) {
  return EmbeddingEnqueueHook(ref.watch(embeddingQueueControllerProvider));
});

final embeddingBackfillControllerProvider =
    Provider<EmbeddingBackfillController>((ref) {
  ref.keepAlive();
  final controller = EmbeddingBackfillController(
    memoryRepository: ref.watch(memoryRepositoryProvider),
    queue: ref.watch(embeddingQueueControllerProvider),
    embeddingProviderReader: () => ref.read(activeEmbeddingProvider),
  );
  controller.start();
  ref.onDispose(controller.stop);
  return controller;
});

/// Ensures Gecko files + runtime are ready. Returns false if declined/failed.
Future<bool> ensureGeckoEmbedderReady(Ref ref) async {
  final manager = ref.read(embeddingModelManagerProvider);
  final status = await manager.status();
  if (status == GeckoEmbedderStatus.declined) return false;
  try {
    final adapter = ref.read(geckoInferenceAdapterProvider);
    await adapter.prepare();
    ref.invalidate(geckoEmbedderStatusProvider);
    return true;
  } catch (_) {
    return false;
  }
}

/// Opportunistic Gecko download after primary model is ready (non-blocking).
///
/// Never blocks Capture. Respects explicit decline.
final geckoOpportunisticDownloadProvider = FutureProvider<void>((ref) async {
  final assist = await ref.watch(modelAssistStatusProvider.future);
  if (assist != ModelAssistStatus.modelReady) return;

  final manager = ref.read(embeddingModelManagerProvider);
  final status = await manager.status();
  if (status == GeckoEmbedderStatus.declined ||
      status == GeckoEmbedderStatus.runtimeReady) {
    return;
  }

  try {
    if (status == GeckoEmbedderStatus.notDownloaded) {
      await manager.ensureFilesDownloaded();
    }
    await ref.read(geckoInferenceAdapterProvider).prepare();
    ref.invalidate(geckoEmbedderStatusProvider);
  } catch (_) {
    // Silent — Settings offers retry; Tier 1 search remains available.
  }
});
