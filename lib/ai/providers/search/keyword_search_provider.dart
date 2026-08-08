import 'package:my_first_app/ai/providers/search/search_provider.dart';
import 'package:my_first_app/data/local/isar/collections/memory.dart';
import 'package:my_first_app/domain/repositories/memory_repository.dart';
import 'package:my_first_app/domain/repositories/person_repository.dart';
import 'package:my_first_app/domain/rules/search_ranking_rules.dart';

/// Phase 3.1 concrete [SearchProvider]: keyword / substring ranking only.
///
/// Does not call embeddings, LiteRT, or network.
class KeywordSearchProvider implements SearchProvider {
  KeywordSearchProvider({
    required MemoryRepository memoryRepository,
    required PersonRepository personRepository,
  })  : _memories = memoryRepository,
        _people = personRepository;

  final MemoryRepository _memories;
  final PersonRepository _people;

  @override
  Future<List<SearchHit>> search(SearchQuery query) async {
    final normalized = normalizeSearchQuery(query.text);
    if (normalized.isEmpty) return const [];

    if (query.scope == SearchScope.person) {
      final personUuid = query.personUuid;
      if (personUuid == null || personUuid.isEmpty) {
        return const [];
      }
    }

    final memories = query.scope == SearchScope.person
        ? await _memories.getActiveMemoriesForPerson(query.personUuid!)
        : await _memories.getActiveMemories();

    final people = await _people.getActivePeople();
    final namesByUuid = <String, String>{
      for (final p in people) p.uuid: p.name,
    };

    final documents = <MemorySearchDocument>[];
    for (final memory in memories) {
      final personName = namesByUuid[memory.personUuid];
      if (personName == null) {
        // Soft-deleted / missing person — skip to avoid bad attribution.
        continue;
      }
      if (query.scope == SearchScope.person &&
          memory.personUuid != query.personUuid) {
        continue;
      }
      documents.add(_toDocument(memory, personName));
    }

    final scored = rankMemoriesForQuery(
      documents: documents,
      rawQuery: query.text,
    );
    return scored.map(searchHitFromScoredMatch).toList(growable: false);
  }

  MemorySearchDocument _toDocument(Memory memory, String personName) {
    return MemorySearchDocument(
      memoryUuid: memory.uuid,
      personUuid: memory.personUuid,
      personName: personName,
      eventText: memory.eventText,
      category: memory.category,
      datePrecision: memory.datePrecision,
      dateValueRaw: memory.dateValueRaw,
      dateValue: memory.dateValue,
      quoteEvidence: memory.quoteEvidence,
      createdAt: memory.createdAt,
    );
  }
}
