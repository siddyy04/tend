import 'package:flutter/material.dart';
import 'package:my_first_app/core/constants/circle_tier_labels.dart';
import 'package:my_first_app/data/local/isar/collections/person.dart';

/// Read-only person summary at the top of [PersonProfileScreen].
///
/// Always rendered when a person is loaded — including when the timeline is empty.
class PersonProfileHeader extends StatelessWidget {
  const PersonProfileHeader({
    super.key,
    required this.person,
  });

  final Person person;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final relationship = person.relationshipType?.trim();

    return Material(
      color: theme.colorScheme.surface,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              person.name,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              circleTierLabel(person.circleTier),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            if (relationship != null && relationship.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                relationship,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
