import 'package:flutter/material.dart';

/// Lightweight confidence cue when extraction is below threshold (2B.7).
///
/// Threshold logic is unchanged — this is visual polish only. No percentages.
class NeedsReviewChip extends StatelessWidget {
  const NeedsReviewChip({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      label: 'Needs review',
      child: Align(
        alignment: Alignment.centerLeft,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.tertiaryContainer.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 16,
                  color: scheme.onTertiaryContainer,
                ),
                const SizedBox(width: 6),
                Text(
                  'Needs review',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onTertiaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
