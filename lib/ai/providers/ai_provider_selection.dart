import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/ai/model_manager/device_capability_check.dart';
import 'package:my_first_app/ai/model_manager/model_manager_providers.dart';
import 'package:my_first_app/ai/providers/extraction_provider.dart';
import 'package:my_first_app/ai/providers/litert/litert_extraction_provider.dart';
import 'package:my_first_app/ai/providers/litert/litert_inference_adapter.dart';
import 'package:my_first_app/ai/providers/litert/litert_prompt_builder.dart';
import 'package:my_first_app/ai/providers/manual/manual_fallback_provider.dart';

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
