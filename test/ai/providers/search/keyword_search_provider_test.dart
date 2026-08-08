import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/ai/providers/search/keyword_search_provider.dart';
import 'package:my_first_app/ai/providers/search/search_provider.dart';
import 'package:my_first_app/core/constants/enums.dart';
import 'package:my_first_app/data/local/isar/collections/memory.dart';
import 'package:my_first_app/data/local/isar/collections/person.dart';
import 'package:my_first_app/domain/repositories/memory_repository.dart';
import 'package:my_first_app/domain/repositories/person_repository.dart';

class _FakeMemoryRepository implements MemoryRepository {
  _FakeMemoryRepository(this.memories);

  final List<Memory> memories;

  @override
  Future<List<Memory>> getActiveMemories() async {
    return memories.where((m) => m.deletedAt == null).toList();
  }

  @override
  Future<List<Memory>> getActiveMemoriesForPerson(String personUuid) async {
    return memories
        .where((m) => m.deletedAt == null && m.personUuid == personUuid)
        .toList();
  }

  @override
  Stream<List<Memory>> watchAllForPerson(String personUuid) {
    return Stream.value(
      memories
          .where((m) => m.deletedAt == null && m.personUuid == personUuid)
          .toList(),
    );
  }

  @override
  Future<Memory?> getByUuid(String uuid) async {
    for (final m in memories) {
      if (m.uuid == uuid && m.deletedAt == null) return m;
    }
    return null;
  }

  @override
  Future<void> create(Memory memory) async {}

  @override
  Future<void> update(Memory memory) async {}

  @override
  Future<void> softDelete(String uuid) async {}
}

class _FakePersonRepository implements PersonRepository {
  _FakePersonRepository(this.people);

  final List<Person> people;

  @override
  Future<List<Person>> getActivePeople() async {
    return people.where((p) => p.deletedAt == null).toList();
  }

  @override
  Stream<List<Person>> watchActivePeople() {
    return Stream.value(people.where((p) => p.deletedAt == null).toList());
  }

  @override
  Future<Person?> getByUuid(String uuid) async {
    for (final p in people) {
      if (p.uuid == uuid && p.deletedAt == null) return p;
    }
    return null;
  }

  @override
  Future<void> create(Person person) async {}

  @override
  Future<void> update(Person person) async {}

  @override
  Future<void> softDelete(String uuid) async {}
}

Person _person(String uuid, String name, {bool deleted = false}) {
  return Person()
    ..uuid = uuid
    ..name = name
    ..relationshipType = 'friend'
    ..circleTier = CircleTier.friends
    ..createdAt = DateTime.utc(2024, 1, 1)
    ..updatedAt = DateTime.utc(2024, 1, 1)
    ..syncStatus = SyncStatus.synced
    ..deletedAt = deleted ? DateTime.utc(2024, 2, 1) : null;
}

Memory _memory({
  required String uuid,
  required String personUuid,
  required String eventText,
  MemoryCategory category = MemoryCategory.preferences,
  bool deleted = false,
  DateTime? createdAt,
}) {
  return Memory()
    ..uuid = uuid
    ..personUuid = personUuid
    ..category = category
    ..eventText = eventText
    ..datePrecision = DatePrecision.none
    ..importanceScore = 3
    ..sensitivityFlag = SensitivityLevel.low
    ..sourceType = SourceType.text
    ..needsUserConfirmation = false
    ..createdAt = createdAt ?? DateTime.utc(2024, 1, 1)
    ..updatedAt = createdAt ?? DateTime.utc(2024, 1, 1)
    ..syncStatus = SyncStatus.synced
    ..deletedAt = deleted ? DateTime.utc(2024, 2, 1) : null;
}

void main() {
  late KeywordSearchProvider provider;

  setUp(() {
    final people = [
      _person('pa', 'Alice'),
      _person('pb', 'Bob'),
      _person('pd', 'Deleted Dana', deleted: true),
    ];
    final memories = [
      _memory(
        uuid: 'ma',
        personUuid: 'pa',
        eventText: 'Alice loves Bangalore weather',
        createdAt: DateTime.utc(2024, 3, 1),
      ),
      _memory(
        uuid: 'mb',
        personUuid: 'pb',
        eventText: 'Bob mentioned Bangalore housing',
        createdAt: DateTime.utc(2024, 4, 1),
      ),
      _memory(
        uuid: 'md',
        personUuid: 'pa',
        eventText: 'Alice secret Bangalore note',
        deleted: true,
      ),
      _memory(
        uuid: 'mx',
        personUuid: 'pd',
        eventText: 'Dana Bangalore orphan',
      ),
    ];
    provider = KeywordSearchProvider(
      memoryRepository: _FakeMemoryRepository(memories),
      personRepository: _FakePersonRepository(people),
    );
  });

  test('person-scoped search never leaks another person', () async {
    final hits = await provider.search(
      const SearchQuery(
        text: 'Bangalore',
        scope: SearchScope.person,
        personUuid: 'pa',
      ),
    );
    expect(hits, hasLength(1));
    expect(hits.single.memoryUuid, 'ma');
    expect(hits.single.personUuid, 'pa');
  });

  test('global search attaches correct person names', () async {
    final hits = await provider.search(
      const SearchQuery(text: 'Bangalore', scope: SearchScope.global),
    );
    expect(hits.map((h) => h.memoryUuid).toSet(), {'ma', 'mb'});
    final byId = {for (final h in hits) h.memoryUuid: h};
    expect(byId['ma']!.personName, 'Alice');
    expect(byId['mb']!.personName, 'Bob');
  });

  test('soft-deleted memories are excluded', () async {
    final hits = await provider.search(
      const SearchQuery(text: 'secret', scope: SearchScope.global),
    );
    expect(hits, isEmpty);
  });

  test('memories for soft-deleted people are skipped', () async {
    final hits = await provider.search(
      const SearchQuery(text: 'orphan', scope: SearchScope.global),
    );
    expect(hits, isEmpty);
  });

  test('ranking prefers newer among equal keyword matches', () async {
    final hits = await provider.search(
      const SearchQuery(text: 'Bangalore', scope: SearchScope.global),
    );
    expect(hits.first.memoryUuid, 'mb'); // newer createdAt
  });

  test('empty query returns empty list', () async {
    final hits = await provider.search(
      const SearchQuery(text: '  ', scope: SearchScope.global),
    );
    expect(hits, isEmpty);
  });
}
