import 'dart:math' as math;

/// Cosine similarity between two equal-length vectors.
///
/// Returns 0 if either vector is empty, lengths differ, or either has
/// near-zero magnitude.
double cosineSimilarity(List<double> a, List<double> b) {
  if (a.isEmpty || b.isEmpty || a.length != b.length) return 0;
  var dot = 0.0;
  var normA = 0.0;
  var normB = 0.0;
  for (var i = 0; i < a.length; i++) {
    final av = a[i];
    final bv = b[i];
    dot += av * bv;
    normA += av * av;
    normB += bv * bv;
  }
  if (normA <= 0 || normB <= 0) return 0;
  return dot / (math.sqrt(normA) * math.sqrt(normB));
}

/// True when [score] clears the Tier 2 absolute cosine threshold.
bool clearsTier2Threshold(double score, double threshold) {
  return score >= threshold;
}

/// Whether an embedding is usable for the active model version.
bool isValidEmbedding({
  required List<double>? embedding,
  required String? embeddingModelVersion,
  required String currentVersion,
  required int expectedDimension,
}) {
  if (embedding == null || embeddingModelVersion == null) return false;
  if (embeddingModelVersion != currentVersion) return false;
  return embedding.length == expectedDimension;
}
