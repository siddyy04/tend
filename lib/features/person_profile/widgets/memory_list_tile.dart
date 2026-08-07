import 'package:flutter/material.dart';
import 'package:my_first_app/core/constants/memory_category_labels.dart';
import 'package:my_first_app/data/local/isar/collections/memory.dart';

/// A single memory row on a person timeline.
class MemoryListTile extends StatelessWidget {
  const MemoryListTile({
    super.key,
    required this.memory,
    required this.onTap,
    required this.onDelete,
  });

  final Memory memory;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel =
        memory.dateValue != null ? _formatDate(memory.dateValue!) : 'No date';

    return ListTile(
      title: Text(
        memory.eventText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${memoryCategoryLabel(memory.category)} · $dateLabel',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: onTap,
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Delete',
        onPressed: onDelete,
      ),
    );
  }
}
