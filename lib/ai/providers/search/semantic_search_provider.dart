import 'package:my_first_app/ai/providers/gecko/gecko_constants.dart';
import 'package:my_first_app/ai/providers/gecko/gecko_embedding_provider.dart';
import 'package:my_first_app/ai/providers/search/search_provider.dart';
import 'package:my_first_app/data/local/isar/collections/memory.dart';
import 'package:my_first_app/domain/repositories/memory_repository.dart';
import 'package:my_first_app/domain/repositories/person_repository.dart';
import 'package:my_first_app/domain/rules/embedding_similarity_rules.dart';
import 'package:my_first_app/domain/rules/search_ranking_rules.dart';

/// Tier 2 semantic search — cosine over version-valid embeddings only.
///
/// Does not modify or call [KeywordSearchProvider].
class SemanticSearchProvider {
  SemanticSearchProvider({
    required MemoryRepository memoryRepository,
    required PersonRepository personRepository,
    required GeckoEmbeddingProvider embeddingProvider,
    required double Function() thresholdReader,
  })  : _memories = memoryRepository,
        _people = personRepository,
        _embedder = embeddingProvider,
        _thresholdReader = thresholdReader;

  final MemoryRepository _memories;
  final PersonRepository _people;
  final GeckoEmbeddingProvider _embedder;
  final double Function() _thresholdReader;

  /// Returns semantic-only candidates (caller dedupes against Tier 1).
  ///
  /// On any failure returns an empty list (silent Tier-1-only degradation).
  Future<List<SearchHit>> search(SearchQuery query) async {
    final normalized = normalizeSearchQuery(query.text);
    if (normalized.isEmpty) return const [];

    try {
      final queryVec = await _embedder.embedQuery(normalized);
      if (queryVec.length != GeckoConstants.dimension) return const [];

      final memories = query.scope == SearchScope.person
          ? await _memories.getActiveMemoriesForPerson(query.personUuid!)
          : await _memories.getActiveMemories();

      final people = await _people.getActivePeople();
      final namesByUuid = <String, String>{
        for (final p in people) p.uuid: p.name,
      };

      final threshold = _thresholdReader();
      final scored = <({Memory memory, String personName, double score})>[];

      for (final memory in memories) {
        final personName = namesByUuid[memory.personUuid];
        if (personName == null) continue;
        if (!isValidEmbedding(
          embedding: memory.embedding,
          embeddingModelVersion: memory.embeddingModelVersion,
          currentVersion: GeckoConstants.modelVersion,
          expectedDimension: GeckoConstants.dimension,
        )) {
          continue;
        }
        final score = cosineSimilarity(queryVec, memory.embedding!);
        if (!clearsTier2Threshold(score, threshold)) continue;
        scored.add((memory: memory, personName: personName, score: score));
      }

      scored.sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        final aRecency = a.memory.dateValue ?? a.memory.createdAt;
        final bRecency = b.memory.dateValue ?? b.memory.createdAt;
        final byRecency = bRecency.compareTo(aRecency);
        if (byRecency != 0) return byRecency;
        return a.memory.uuid.compareTo(b.memory.uuid);
      });

      return [
        for (final row in scored) _toHit(row.memory, row.personName),
      ];
    } catch (_) {
      return const [];
    }
  }

  SearchHit _toHit(Memory memory, String personName) {
    final snippet = memory.eventText.trim().isEmpty
        ? memory.eventText
        : (memory.eventText.length <= 160
            ? memory.eventText
            : '${memory.eventText.substring(0, 157)}…');
    return SearchHit(
      memoryUuid: memory.uuid,
      personUuid: memory.personUuid,
      personName: personName,
      eventText: memory.eventText,
      snippet: snippet,
      category: memory.category,
      dateValue: memory.dateValue,
      dateValueRaw: memory.dateValueRaw,
      datePrecision: memory.datePrecision,
      // Semantic hits are not keyword-classified; use partial as a neutral kind.
      matchKind: MatchKind.partial,
      matchedInEventText: true,
    );
  }
}
