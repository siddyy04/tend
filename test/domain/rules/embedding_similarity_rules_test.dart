import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/domain/rules/embedding_similarity_rules.dart';

void main() {
  group('cosineSimilarity', () {
    test('identical unit vectors → 1', () {
      expect(cosineSimilarity([1, 0, 0], [1, 0, 0]), closeTo(1, 1e-9));
    });

    test('orthogonal → 0', () {
      expect(cosineSimilarity([1, 0], [0, 1]), closeTo(0, 1e-9));
    });

    test('length mismatch → 0', () {
      expect(cosineSimilarity([1, 0], [1, 0, 0]), 0);
    });

    test('empty → 0', () {
      expect(cosineSimilarity([], []), 0);
    });
  });

  group('clearsTier2Threshold', () {
    test('at threshold passes', () {
      expect(clearsTier2Threshold(0.75, 0.75), isTrue);
    });
    test('below fails', () {
      expect(clearsTier2Threshold(0.74, 0.75), isFalse);
    });
  });

  group('isValidEmbedding', () {
    test('valid', () {
      expect(
        isValidEmbedding(
          embedding: List.filled(768, 0.1),
          embeddingModelVersion: 'v1',
          currentVersion: 'v1',
          expectedDimension: 768,
        ),
        isTrue,
      );
    });
    test('stale version', () {
      expect(
        isValidEmbedding(
          embedding: List.filled(768, 0.1),
          embeddingModelVersion: 'old',
          currentVersion: 'v1',
          expectedDimension: 768,
        ),
        isFalse,
      );
    });
    test('wrong dim', () {
      expect(
        isValidEmbedding(
          embedding: [1, 2, 3],
          embeddingModelVersion: 'v1',
          currentVersion: 'v1',
          expectedDimension: 768,
        ),
        isFalse,
      );
    });
  });
}
