import 'package:flutter/material.dart';
import 'package:my_first_app/core/constants/circle_tier_labels.dart';
import 'package:my_first_app/core/constants/enums.dart';
import 'package:my_first_app/data/local/isar/collections/person.dart';
import 'package:my_first_app/features/circle/widgets/person_list_tile.dart';

/// One non-empty [CircleTier] section on My Circle.
class PersonTierSection extends StatelessWidget {
  const PersonTierSection({
    super.key,
    required this.tier,
    required this.people,
    required this.onPersonTap,
    required this.onPersonDelete,
  });

  final CircleTier tier;
  final List<Person> people;
  final ValueChanged<Person> onPersonTap;
  final ValueChanged<Person> onPersonDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            circleTierLabel(tier),
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        for (final person in people)
          PersonListTile(
            person: person,
            onTap: () => onPersonTap(person),
            onDelete: () => onPersonDelete(person),
          ),
      ],
    );
  }
}
