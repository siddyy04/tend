import 'package:flutter/material.dart';

/// Intentional extracting status for Typed / Voice / OCR / Share Continue.
class CaptureExtractingStatus extends StatelessWidget {
  const CaptureExtractingStatus({
    super.key,
    this.title = 'Finding memories…',
    this.subtitle = 'This stays on your device.',
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      liveRegion: true,
      label: '$title $subtitle',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact status used inside primary buttons while submitting.
class CaptureExtractingButtonChild extends StatelessWidget {
  const CaptureExtractingButtonChild({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Finding memories',
      child: const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}
