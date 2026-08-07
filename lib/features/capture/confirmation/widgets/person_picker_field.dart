import 'package:flutter/material.dart';
import 'package:my_first_app/data/local/isar/collections/person.dart';
import 'package:my_first_app/domain/rules/extraction_validation_rules.dart';

/// Person selector for capture confirmation.
///
/// - Unique exact match: auto-selected upstream; Create Person hidden.
/// - Zero exact matches: optional Create Person action.
/// - Multiple exact matches: no auto-select, no Create Person, inline nudge.
class PersonPickerField extends StatelessWidget {
  const PersonPickerField({
    super.key,
    required this.people,
    required this.selectedPersonUuid,
    required this.onChanged,
    this.personMentioned,
    this.onCreatePerson,
    this.errorText,
  });

  final List<Person> people;
  final String? selectedPersonUuid;
  final ValueChanged<String?> onChanged;
  final String? personMentioned;
  final VoidCallback? onCreatePerson;
  final String? errorText;

  int get _exactMatchCount {
    final mentioned = personMentioned?.trim() ?? '';
    if (mentioned.isEmpty) return 0;
    return countExactPersonNameMatches(
      personMentioned: mentioned,
      knownNames: people.map((p) => p.name),
    );
  }

  bool get _showCreateAction {
    final mentioned = personMentioned?.trim() ?? '';
    if (mentioned.isEmpty || onCreatePerson == null) {
      return false;
    }
    // Only when nobody in Circle matches — never when names collide.
    return _exactMatchCount == 0;
  }

  bool get _showAmbiguousMatchMessage => _exactMatchCount > 1;

  @override
  Widget build(BuildContext context) {
    final mentioned = personMentioned?.trim() ?? '';
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use — value is the stable API in this Flutter pin
          value: selectedPersonUuid,
          decoration: InputDecoration(
            labelText: 'Person',
            errorText: errorText,
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final person in people)
              DropdownMenuItem(
                value: person.uuid,
                child: Text(person.name),
              ),
          ],
          onChanged: people.isEmpty ? null : onChanged,
        ),
        if (mentioned.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Mentioned as: $mentioned',
            style: theme.textTheme.bodySmall,
          ),
        ],
        if (_showAmbiguousMatchMessage) ...[
          const SizedBox(height: 8),
          Text(
            'Multiple people named "$mentioned" were found. '
            'Please choose the correct person.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (_showCreateAction) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onCreatePerson,
              icon: const Icon(Icons.person_add_outlined),
              label: Text('Create "$mentioned"'),
            ),
          ),
        ],
      ],
    );
  }
}
