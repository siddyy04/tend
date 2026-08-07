/// Local text embedding interface.
///
/// Defined in Sprint 2A for architecture completeness.
/// No concrete implementation in Sprint 2A or 2B — embeddings stay out of scope.
abstract class EmbeddingProvider {
  Future<List<double>> embed(String text);
}
