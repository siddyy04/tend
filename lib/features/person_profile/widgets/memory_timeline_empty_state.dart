import 'package:flutter/material.dart';

/// Empty timeline content for a person who has no active memories.
///
/// Occupies only the area below the person header — never replaces it.
class MemoryTimelineEmptyState extends StatelessWidget {
  const MemoryTimelineEmptyState({
    super.key,
    this.onAddMemory,
  });

  final VoidCallback? onAddMemory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notes_outlined,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No memories yet',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add something you want to remember about this person.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAddMemory != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAddMemory,
                icon: const Icon(Icons.add),
                label: const Text('Add memory'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
