import 'package:flutter/material.dart';

/// Subtle success strip after extraction finds memories (Sprint 2B.7).
class CaptureFoundMemoriesBanner extends StatelessWidget {
  const CaptureFoundMemoriesBanner({
    super.key,
    required this.count,
  });

  final int count;

  String get _message {
    if (count <= 0) return 'Ready to review';
    if (count == 1) return 'Found 1 memory to review';
    return 'Found $count memories to review';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      liveRegion: true,
      label: _message,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 20,
                color: scheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
