import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/core/constants/enums.dart';
import 'package:my_first_app/data/local/isar/collections/person.dart';
import 'package:my_first_app/features/auth/auth_controller.dart';
import 'package:my_first_app/features/circle/circle_providers.dart';
import 'package:my_first_app/features/circle/widgets/circle_empty_state.dart';
import 'package:my_first_app/features/circle/widgets/person_tier_section.dart';
import 'package:my_first_app/features/person_form/person_form_screen.dart';

/// My Circle — people grouped by [CircleTier], offline Isar-backed.
class CircleScreen extends ConsumerWidget {
  const CircleScreen({super.key});

  Future<void> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    Person person,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete person?'),
          content: Text('Remove ${person.name} from your circle?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await ref.read(circleActionsProvider).softDeletePerson(person.uuid);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peopleAsync = ref.watch(allPeopleProvider);
    final grouped = ref.watch(groupedPeopleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Circle'),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.openCreatePerson(),
        tooltip: 'Add person',
        child: const Icon(Icons.person_add_outlined),
      ),
      body: peopleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (people) {
          if (people.isEmpty) {
            return CircleEmptyState(
              onAddPerson: () => context.openCreatePerson(),
            );
          }

          // Only tiers that contain at least one person — fixed enum order.
          final sections = <Widget>[
            for (final tier in CircleTier.values)
              if (grouped[tier]!.isNotEmpty)
                PersonTierSection(
                  tier: tier,
                  people: grouped[tier]!,
                  onPersonTap: (person) => context.openEditPerson(person.uuid),
                  onPersonDelete: (person) =>
                      _confirmAndDelete(context, ref, person),
                ),
          ];

          return ListView(
            children: sections,
          );
        },
      ),
    );
  }
}
