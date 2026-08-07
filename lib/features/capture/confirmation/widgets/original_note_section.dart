import 'package:flutter/material.dart';

/// Read-only, collapsed-by-default reference to the user's original capture text.
///
/// Not persisted — display only.
class OriginalNoteSection extends StatelessWidget {
  const OriginalNoteSection({
    super.key,
    required this.originalText,
  });

  final String originalText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      child: ExpansionTile(
        initiallyExpanded: false,
        title: Text(
          'Original Note',
          style: theme.textTheme.titleSmall,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SelectableText(
              originalText,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
