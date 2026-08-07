import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/app/app_routes.dart';
import 'package:my_first_app/data/local/isar/collections/memory.dart';
import 'package:my_first_app/features/memory_form/memory_form_screen.dart';
import 'package:my_first_app/features/person_form/person_form_screen.dart';
import 'package:my_first_app/features/person_profile/person_profile_providers.dart';
import 'package:my_first_app/features/person_profile/widgets/memory_list_tile.dart';
import 'package:my_first_app/features/person_profile/widgets/memory_timeline_empty_state.dart';
import 'package:my_first_app/features/person_profile/widgets/person_profile_header.dart';

/// Person detail: read-only person header + memory timeline.
///
/// The header stays visible even when the timeline is empty.
class PersonProfileScreen extends ConsumerWidget {
  const PersonProfileScreen({
    super.key,
    required this.personUuid,
  });

  final String personUuid;

  Future<void> _confirmAndDeleteMemory(
    BuildContext context,
    WidgetRef ref,
    Memory memory,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete memory?'),
          content: const Text('Remove this memory from the timeline?'),
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
    await ref.read(personProfileActionsProvider).softDeleteMemory(memory.uuid);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personAsync = ref.watch(profilePersonProvider(personUuid));
    final memoriesAsync = ref.watch(personMemoriesProvider(personUuid));
    final timeline = ref.watch(personMemoryTimelineProvider(personUuid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Edit person',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.openEditPerson(personUuid),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.openCreateMemory(personUuid),
        tooltip: 'Add memory',
        child: const Icon(Icons.add),
      ),
      body: personAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(error.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (person) {
          if (person == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'This person is no longer in your circle.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PersonProfileHeader(person: person),
              const Divider(height: 1),
              Expanded(
                child: memoriesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(error.toString(), textAlign: TextAlign.center),
                    ),
                  ),
                  data: (memories) {
                    if (memories.isEmpty) {
                      return MemoryTimelineEmptyState(
                        onAddMemory: () => context.openCreateMemory(personUuid),
                      );
                    }

                    return ListView.builder(
                      itemCount: timeline.length,
                      itemBuilder: (context, index) {
                        final memory = timeline[index];
                        return MemoryListTile(
                          memory: memory,
                          onTap: () => context.openEditMemory(
                            personUuid,
                            memory.uuid,
                          ),
                          onDelete: () =>
                              _confirmAndDeleteMemory(context, ref, memory),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Navigation helper for person profile.
extension PersonProfileNavigation on BuildContext {
  void openPersonProfile(String personUuid) =>
      push(AppRoutes.personProfile(personUuid));
}
