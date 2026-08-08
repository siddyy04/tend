import 'package:my_first_app/ai/inference/ai_inference_mutex.dart';
import 'package:my_first_app/ai/providers/embedding_provider.dart';
import 'package:my_first_app/ai/providers/gecko/gecko_constants.dart';
import 'package:my_first_app/ai/providers/gecko/gecko_inference_adapter.dart';

/// Production [EmbeddingProvider] backed by Gecko-110m-en.
///
/// Does not import `flutter_gemma_embeddings` — only [GeckoInferenceAdapter] may.
class GeckoEmbeddingProvider implements EmbeddingProvider {
  GeckoEmbeddingProvider({
    required GeckoInferenceAdapter adapter,
    required AiInferenceMutex mutex,
  })  : _adapter = adapter,
        _mutex = mutex;

  final GeckoInferenceAdapter _adapter;
  final AiInferenceMutex _mutex;

  bool get isAvailable => true;

  String get modelVersion => _adapter.modelVersion;

  int get dimension => GeckoConstants.dimension;

  /// Document embedding (index-time / post-persist / backfill).
  @override
  Future<List<double>> embed(String text) {
    return embedDocument(text);
  }

  Future<List<double>> embedDocument(String text) {
    return _mutex.withLock(AiInferencePriority.embedding, () {
      return _adapter.generateEmbedding(text, isQuery: false);
    });
  }

  /// Query embedding (search-time Tier 2).
  Future<List<double>> embedQuery(String text) {
    return _mutex.withLock(AiInferencePriority.embedding, () {
      return _adapter.generateEmbedding(text, isQuery: true);
    });
  }
}
