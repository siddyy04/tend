import 'package:flutter/material.dart';
import 'package:my_first_app/ai/providers/extraction_provider.dart';

/// Passive, non-blocking clarification banner (Sprint 2B.7).
///
/// Never interactive — user resolves via existing confirmation controls.
class ClarificationNote extends StatelessWidget {
  const ClarificationNote({
    super.key,
    required this.items,
  });

  final List<ClarificationNeeded> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      container: true,
      label: 'Clarification needed',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.secondaryContainer.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.8),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: scheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Quick check',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: 6),
                Text(
                  items[i].reason,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSecondaryContainer,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                'Choose the right person below — this does not block saving.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSecondaryContainer.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
