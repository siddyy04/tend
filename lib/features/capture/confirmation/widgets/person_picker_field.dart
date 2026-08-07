import 'package:flutter/material.dart';
import 'package:my_first_app/data/local/isar/collections/person.dart';

/// Person selector for capture confirmation — existing Circle people only.
class PersonPickerField extends StatelessWidget {
  const PersonPickerField({
    super.key,
    required this.people,
    required this.selectedPersonUuid,
    required this.onChanged,
    this.errorText,
  });

  final List<Person> people;
  final String? selectedPersonUuid;
  final ValueChanged<String?> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      // ignore: deprecated_member_use — value is the stable API in this Flutter pin
      value: selectedPersonUuid,
      decoration: InputDecoration(
        labelText: 'Person',
        errorText: errorText,
        border: const OutlineInputBorder(),
        helperText: 'Creating a new person from capture is not available yet.',
      ),
      items: [
        for (final person in people)
          DropdownMenuItem(
            value: person.uuid,
            child: Text(person.name),
          ),
      ],
      onChanged: people.isEmpty ? null : onChanged,
    );
  }
}
