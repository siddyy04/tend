/// Process-wide hook for [FlutterGemma.initialize].
///
/// Set by [GeckoInferenceAdapter.installBootstrap] so LiteRT init can register
/// embedding backends without importing `flutter_gemma_embeddings`.
typedef TendGemmaBootstrap = Future<void> Function();

TendGemmaBootstrap? tendGemmaBootstrap;
