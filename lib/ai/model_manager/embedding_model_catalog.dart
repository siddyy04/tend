import 'package:my_first_app/ai/providers/gecko/gecko_constants.dart';

/// Versioned on-device embedding artifact (sibling to [ModelArtifactSpec]).
///
/// Intentionally separate from LiteRT-LM catalog kinds — Gecko is `.tflite`.
class EmbeddingArtifactSpec {
  const EmbeddingArtifactSpec({
    required this.versionId,
    required this.displayName,
    required this.fileName,
    required this.downloadUrl,
    required this.sha256,
    this.approximateDownloadBytes = 0,
  });

  final String versionId;
  final String displayName;
  final String fileName;
  final String downloadUrl;

  /// Empty skips hash verification (public CDN; spike used presence checks).
  final String sha256;
  final int approximateDownloadBytes;

  bool get hasDownloadUrl => downloadUrl.trim().isNotEmpty;
  bool get hasChecksum => sha256.trim().isNotEmpty;

  String get downloadSizeLabel {
    if (approximateDownloadBytes <= 0) return 'size unknown';
    final mb = approximateDownloadBytes / (1024 * 1024);
    return '~${mb.toStringAsFixed(0)} MB';
  }
}

/// Catalog of embedding-model artifacts. MVP: Gecko-110m-en only.
abstract final class EmbeddingModelCatalog {
  static const EmbeddingArtifactSpec geckoModel = EmbeddingArtifactSpec(
    versionId: GeckoConstants.modelVersion,
    displayName: 'Gecko 110M (English)',
    fileName: GeckoConstants.modelFileName,
    downloadUrl: GeckoConstants.modelDownloadUrl,
    sha256: '', // presence check; public CDN artifact
    approximateDownloadBytes: GeckoConstants.approximateModelBytes,
  );

  static const EmbeddingArtifactSpec geckoTokenizer = EmbeddingArtifactSpec(
    versionId: '${GeckoConstants.modelVersion}-tokenizer',
    displayName: 'Gecko tokenizer',
    fileName: GeckoConstants.tokenizerFileName,
    downloadUrl: GeckoConstants.tokenizerDownloadUrl,
    sha256: '',
    approximateDownloadBytes: 800 * 1024,
  );

  static const EmbeddingArtifactSpec current = geckoModel;

  static const List<EmbeddingArtifactSpec> requiredFiles = [
    geckoModel,
    geckoTokenizer,
  ];
}
