/// Gecko-110m-en embedding constants (Phase 3.3 / ADR-013).
abstract final class GeckoConstants {
  /// Persisted on [Memory.embeddingModelVersion] when vectors are valid.
  static const String modelVersion = 'gecko-110m-en-seq256-v1';

  /// Fixed embedding dimension for Gecko_256_quant.
  static const int dimension = 768;

  /// SharedPreferences key for the tunable Tier 2 cosine threshold.
  static const String tier2ThresholdPrefsKey =
      'tend_semantic_tier2_cosine_threshold';

  /// Calibrated production default (Phase 3.4 on AIN065).
  ///
  /// Evidence: paraphrase scores ~0.73–0.79; negative max ~0.66.
  /// Midpoint → **0.70**. Provisional spike value was 0.75 (too high for city paraphrase).
  static const double provisionalTier2Threshold = 0.70;

  static const String modelFileName = 'Gecko_256_quant.tflite';
  static const String tokenizerFileName = 'sentencepiece.model';

  static const String modelDownloadUrl =
      'https://huggingface.co/litert-community/Gecko-110m-en/resolve/main/'
      'Gecko_256_quant.tflite';

  static const String tokenizerDownloadUrl =
      'https://huggingface.co/litert-community/Gecko-110m-en/resolve/main/'
      'sentencepiece.model';

  /// Approximate model bytes for UI copy (~114 MB).
  static const int approximateModelBytes = 114 * 1024 * 1024;
}
