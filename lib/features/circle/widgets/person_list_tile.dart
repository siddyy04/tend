import 'package:flutter/material.dart';
import 'package:my_first_app/data/local/isar/collections/person.dart';

/// A single person row on My Circle.
class PersonListTile extends StatelessWidget {
  const PersonListTile({
    super.key,
    required this.person,
    required this.onTap,
    required this.onDelete,
  });

  final Person person;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final subtitle = person.relationshipType?.trim();

    return ListTile(
      title: Text(person.name),
      subtitle: (subtitle != null && subtitle.isNotEmpty) ? Text(subtitle) : null,
      onTap: onTap,
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Delete',
        onPressed: onDelete,
      ),
    );
  }
}
