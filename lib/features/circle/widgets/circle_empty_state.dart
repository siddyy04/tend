import 'package:flutter/material.dart';

/// Full-screen empty state when My Circle has no active people.
class CircleEmptyState extends StatelessWidget {
  const CircleEmptyState({
    super.key,
    this.onAddPerson,
  });

  /// Optional CTA — typically navigates to create-person.
  final VoidCallback? onAddPerson;

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
              Icons.people_outline,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Your circle is empty',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add someone you want to remember.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAddPerson != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAddPerson,
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Add person'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
