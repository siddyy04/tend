import 'package:my_first_app/ai/providers/embedding_provider.dart';

/// Null-object [EmbeddingProvider] when Gecko is unavailable.
///
/// The embedding queue must not call [embed] while this is active.
class NoOpEmbeddingProvider implements EmbeddingProvider {
  const NoOpEmbeddingProvider();

  bool get isAvailable => false;

  @override
  Future<List<double>> embed(String text) async {
    throw StateError(
      'NoOpEmbeddingProvider.embed called — Gecko embedder is not ready.',
    );
  }
}
