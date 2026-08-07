import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/core/constants/enums.dart';
import 'package:my_first_app/data/local/isar/collections/person.dart';
import 'package:my_first_app/data/local/isar/isar_provider.dart';
import 'package:my_first_app/domain/repositories/person_repository.dart';

/// Exposes the Isar-backed [PersonRepository].
final personRepositoryProvider = Provider<PersonRepository>((ref) {
  return IsarPersonRepository(ref.watch(isarProvider));
});

/// Flat stream of active people — no grouping or sorting.
final allPeopleProvider = StreamProvider<List<Person>>((ref) {
  return ref.watch(personRepositoryProvider).watchActivePeople();
});

/// Groups [allPeopleProvider] by [CircleTier], sorted alphabetically by name
/// within each tier.
///
/// Always contains an entry for every [CircleTier] (empty list when none).
/// Filtering empty tiers for display is the screen's job, not this provider's.
final groupedPeopleProvider = Provider<Map<CircleTier, List<Person>>>((ref) {
  final people = ref.watch(allPeopleProvider).asData?.value ?? const <Person>[];

  final grouped = <CircleTier, List<Person>>{
    for (final tier in CircleTier.values) tier: <Person>[],
  };

  for (final person in people) {
    grouped[person.circleTier]!.add(person);
  }

  for (final tier in CircleTier.values) {
    grouped[tier]!.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
  }

  return grouped;
});

/// Write actions for My Circle — widgets call these instead of the repository.
final circleActionsProvider = Provider<CircleActions>((ref) {
  return CircleActions(ref);
});

class CircleActions {
  CircleActions(this._ref);

  final Ref _ref;

  Future<void> softDeletePerson(String uuid) {
    return _ref.read(personRepositoryProvider).softDelete(uuid);
  }
}
