import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/app/app_routes.dart';
import 'package:my_first_app/features/capture/confirmation/capture_confirmation_args.dart';
import 'package:my_first_app/features/capture/confirmation/widgets/original_note_section.dart';

/// Lightweight multi-memory summary before editable confirmation (Sprint 2B.2).
///
/// No checkboxes — Continue opens the multi-card review screen.
class CaptureMultiSummaryScreen extends StatelessWidget {
  const CaptureMultiSummaryScreen({
    super.key,
    required this.args,
  });

  final CaptureConfirmationArgs args;

  @override
  Widget build(BuildContext context) {
    final count = args.candidates.length;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review before saving'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'We found $count memories',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Continue to review and edit each one before saving.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            OriginalNoteSection(originalText: args.originalText),
            const SizedBox(height: 20),
            for (var i = 0; i < args.candidates.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _SummaryLine(
                index: i + 1,
                person: args.candidates[i].personMentioned.trim().isEmpty
                    ? 'Someone'
                    : args.candidates[i].personMentioned.trim(),
                event: args.candidates[i].eventText.trim(),
              ),
            ],
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () {
                context.push(
                  AppRoutes.captureConfirmMulti,
                  extra: args,
                );
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.index,
    required this.person,
    required this.event,
  });

  final int index;
  final String person;
  final String event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$index.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: person,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: ' — $event',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
