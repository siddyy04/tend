import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/data/local/isar/collections/memory.dart';
import 'package:my_first_app/data/local/isar/collections/person.dart';
import 'package:my_first_app/data/local/isar/isar_provider.dart';
import 'package:my_first_app/domain/repositories/memory_repository.dart';
import 'package:my_first_app/features/circle/circle_providers.dart';

/// Exposes the Isar-backed [MemoryRepository].
final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  return IsarMemoryRepository(ref.watch(isarProvider));
});

/// Active person for a profile, derived from the watched people stream.
///
/// Returns null when the person is missing or soft-deleted.
final profilePersonProvider = Provider.family<AsyncValue<Person?>, String>((
  ref,
  personUuid,
) {
  final peopleAsync = ref.watch(allPeopleProvider);
  return peopleAsync.when(
    data: (people) {
      for (final person in people) {
        if (person.uuid == personUuid) {
          return AsyncData(person);
        }
      }
      return const AsyncData(null);
    },
    loading: () => const AsyncLoading(),
    error: AsyncError.new,
  );
});

/// Flat unsorted stream of active memories for [personUuid].
final personMemoriesProvider =
    StreamProvider.family<List<Memory>, String>((ref, personUuid) {
  return ref.watch(memoryRepositoryProvider).watchAllForPerson(personUuid);
});

/// Timeline for [personUuid]: [dateValue] descending, null dates older than any
/// explicit date, [Memory.createdAt] descending as the always-applied tie-breaker.
final personMemoryTimelineProvider =
    Provider.family<List<Memory>, String>((ref, personUuid) {
  final memories =
      ref.watch(personMemoriesProvider(personUuid)).asData?.value ??
          const <Memory>[];

  final sorted = List<Memory>.of(memories);
  sorted.sort(_compareMemoriesForTimeline);
  return sorted;
});

/// Write actions for Person Profile — widgets call these instead of the repo.
final personProfileActionsProvider = Provider<PersonProfileActions>((ref) {
  return PersonProfileActions(ref);
});

class PersonProfileActions {
  PersonProfileActions(this._ref);

  final Ref _ref;

  Future<void> softDeleteMemory(String uuid) {
    return _ref.read(memoryRepositoryProvider).softDelete(uuid);
  }
}

/// Reverse-chronological compare: dated memories before undated; newer first.
int _compareMemoriesForTimeline(Memory a, Memory b) {
  final aDate = a.dateValue;
  final bDate = b.dateValue;

  if (aDate != null && bDate != null) {
    final byDate = bDate.compareTo(aDate);
    if (byDate != 0) return byDate;
  } else if (aDate != null && bDate == null) {
    // Explicit date sorts before null (nulls are "older").
    return -1;
  } else if (aDate == null && bDate != null) {
    return 1;
  }

  return b.createdAt.compareTo(a.createdAt);
}
