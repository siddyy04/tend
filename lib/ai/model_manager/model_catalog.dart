/// Tend-side identity for LiteRT-LM install.
///
/// Mapped to `flutter_gemma` [ModelType] only inside [LiteRtInferenceAdapter].
enum LiteRtModelKind {
  gemmaIt,
  gemma4,
  deepSeek,
  qwen,
  qwen3,
  llama,
  hammer,
  functionGemma,
  phi,
  general,
}

/// On-disk / install file format for a catalog artifact.
///
/// Mapped to `flutter_gemma` [ModelFileType] only inside [LiteRtInferenceAdapter].
enum LiteRtFileKind {
  task,
  binary,
  litertlm,
}

/// Preferred on-device accelerator hint for a catalog artifact.
enum LiteRtBackendPreference {
  /// Try GPU, then NPU/NNAPI-class accelerators, then CPU.
  gpuThenNpuThenCpu,
  cpuOnly,
}

/// Versioned on-device model artifact descriptor.
///
/// Capture, Confirmation, and [ExtractionProvider] never read this catalog.
/// Future model upgrades = add/swap specs here without changing those layers.
class ModelArtifactSpec {
  const ModelArtifactSpec({
    required this.versionId,
    required this.displayName,
    required this.fileName,
    required this.downloadUrl,
    required this.sha256,
    required this.modelKind,
    required this.fileKind,
    this.maxTokens = 4096,
    this.approximateDownloadBytes = 0,
    this.backendPreference = LiteRtBackendPreference.gpuThenNpuThenCpu,
    this.isOptionalUpgrade = false,
    this.shortLabel,
  });

  /// Stable identity for this artifact (e.g. `gemma4-e2b-it-v1`).
  final String versionId;

  /// Human-readable label for Settings / setup UI.
  final String displayName;

  /// Compact product label (e.g. "Recommended", "Best Quality").
  final String? shortLabel;

  /// On-disk filename under the models directory.
  final String fileName;

  /// Public HTTPS URL — must not require Hugging Face (or other hub) login.
  final String downloadUrl;

  /// Hex SHA-256 of the artifact. Empty skips hash verification (dev / manual).
  final String sha256;

  /// Which LiteRT model family to install (catalog concern, not Capture).
  final LiteRtModelKind modelKind;

  /// File format for install (`.litertlm` for Gemma 4 MVP).
  final LiteRtFileKind fileKind;

  /// Context window for [FlutterGemma.getActiveModel].
  final int maxTokens;

  /// Approximate download size for UI copy (0 = unknown).
  final int approximateDownloadBytes;

  /// Accelerator preference for this artifact.
  final LiteRtBackendPreference backendPreference;

  /// When true, not required for MVP — offered as an optional upgrade.
  final bool isOptionalUpgrade;

  bool get hasDownloadUrl => downloadUrl.trim().isNotEmpty;

  bool get hasChecksum => sha256.trim().isNotEmpty;

  String get downloadSizeLabel {
    if (approximateDownloadBytes <= 0) {
      return 'size unknown';
    }
    final gb = approximateDownloadBytes / (1024 * 1024 * 1024);
    return '~${gb.toStringAsFixed(1)} GB';
  }
}

/// Catalog of known extraction-model artifacts.
///
/// MVP [current] is Gemma 4 E2B (LiteRT-LM). Gemma 4 E4B is an optional
/// "Best Quality" upgrade for capable devices.
abstract final class ModelCatalog {
  static const String _e2bUrl =
      'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/'
      'gemma-4-E2B-it.litertlm';

  static const String _e4bUrl =
      'https://huggingface.co/litert-community/gemma-4-E4B-it-litert-lm/resolve/main/'
      'gemma-4-E4B-it.litertlm';

  /// Default / required MVP model (Recommended).
  static const ModelArtifactSpec gemma4_e2b = ModelArtifactSpec(
    versionId: 'gemma4-e2b-it-v1',
    displayName: 'Gemma 4 E2B IT',
    shortLabel: 'Recommended',
    fileName: 'gemma-4-E2B-it.litertlm',
    downloadUrl: _e2bUrl,
    sha256: '',
    modelKind: LiteRtModelKind.gemma4,
    fileKind: LiteRtFileKind.litertlm,
    maxTokens: 4096,
    // Measured X-Linked-Size from Hugging Face CDN.
    approximateDownloadBytes: 2588147712,
    backendPreference: LiteRtBackendPreference.gpuThenNpuThenCpu,
  );

  /// Optional Best Quality model for high-end devices.
  static const ModelArtifactSpec gemma4_e4b = ModelArtifactSpec(
    versionId: 'gemma4-e4b-it-v1',
    displayName: 'Gemma 4 E4B IT',
    shortLabel: 'Best Quality',
    fileName: 'gemma-4-E4B-it.litertlm',
    downloadUrl: _e4bUrl,
    sha256: '',
    modelKind: LiteRtModelKind.gemma4,
    fileKind: LiteRtFileKind.litertlm,
    maxTokens: 4096,
    approximateDownloadBytes: 3659530240,
    backendPreference: LiteRtBackendPreference.gpuThenNpuThenCpu,
    isOptionalUpgrade: true,
  );

  /// Active artifact the download manager should ensure is installed.
  static const ModelArtifactSpec current = gemma4_e2b;

  /// Known specs (required + optional upgrades).
  static const List<ModelArtifactSpec> all = [
    gemma4_e2b,
    gemma4_e4b,
  ];

  /// Optional upgrades (excludes [current]).
  static List<ModelArtifactSpec> get optionalUpgrades =>
      all.where((s) => s.isOptionalUpgrade).toList(growable: false);

  /// Look up a known spec by [versionId].
  static ModelArtifactSpec? findByVersionId(String versionId) {
    for (final spec in all) {
      if (spec.versionId == versionId) {
        return spec;
      }
    }
    return null;
  }
}

/// Subdirectory under app documents for model files.
const String kModelStorageRelativeDir = 'models';
