import 'package:flutter/material.dart';

/// Shared empty-state copy when extraction finds no grounded memories.
///
/// Used by Typed, Voice, OCR, and (later) Share — not an error.
abstract final class CaptureEmptyMemoriesCopy {
  static const headline = 'No memories were found in this text.';

  static const explanation =
      'Tend saves information about people, relationships, events, promises, '
      'preferences and other meaningful life memories.';

  static const examples = <String>[
    'Mom had spinal surgery last month.',
    'Sarah loves hiking.',
    'John started working at Google.',
  ];
}

/// Friendly empty panel + actions shared across capture ingress screens.
///
/// Technical mapping/grounding diagnostics must never appear here — use
/// `debugPrint` in CaptureController / LiteRtExtractionProvider instead.
class CaptureEmptyMemoriesPanel extends StatelessWidget {
  const CaptureEmptyMemoriesPanel({
    super.key,
    required this.onEditText,
    required this.onEnterManually,
    this.enabled = true,
  });

  /// Dismisses the empty panel so the user can revise the current text.
  final VoidCallback onEditText;
  final VoidCallback onEnterManually;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          CaptureEmptyMemoriesCopy.headline,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          CaptureEmptyMemoriesCopy.explanation,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Text('Examples:', style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        for (final example in CaptureEmptyMemoriesCopy.examples)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 2),
            child: Text('• $example', style: theme.textTheme.bodyMedium),
          ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: enabled ? onEditText : null,
          child: const Text('Edit text'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: enabled ? onEnterManually : null,
          child: const Text('Enter manually'),
        ),
      ],
    );
  }
}
