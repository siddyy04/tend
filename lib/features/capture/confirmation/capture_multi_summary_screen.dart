import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/app/app_routes.dart';
import 'package:my_first_app/features/capture/confirmation/capture_confirmation_args.dart';
import 'package:my_first_app/features/capture/confirmation/widgets/capture_found_memories_banner.dart';
import 'package:my_first_app/features/capture/confirmation/widgets/clarification_note.dart';
import 'package:my_first_app/features/capture/confirmation/widgets/original_note_section.dart';

/// Lightweight multi-memory summary before editable confirmation (Sprint 2B.2).
class CaptureMultiSummaryScreen extends StatefulWidget {
  const CaptureMultiSummaryScreen({
    super.key,
    required this.args,
  });

  final CaptureConfirmationArgs args;

  @override
  State<CaptureMultiSummaryScreen> createState() =>
      _CaptureMultiSummaryScreenState();
}

class _CaptureMultiSummaryScreenState extends State<CaptureMultiSummaryScreen> {
  var _navigating = false;

  Future<void> _onContinue() async {
    if (_navigating) return;
    setState(() => _navigating = true);
    await context.push(
      AppRoutes.captureConfirmMulti,
      extra: widget.args,
    );
    if (mounted) {
      setState(() => _navigating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
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
            CaptureFoundMemoriesBanner(count: count),
            const SizedBox(height: 16),
            Text(
              'We found $count memories',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Continue to review and edit each one before saving.',
              style: theme.textTheme.bodyMedium,
            ),
            if (args.clarificationNeeded.isNotEmpty) ...[
              const SizedBox(height: 14),
              ClarificationNote(items: args.clarificationNeeded),
            ],
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
            Semantics(
              button: true,
              label: 'Continue to review memories',
              child: FilledButton(
                onPressed: _navigating ? null : _onContinue,
                child: _navigating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continue'),
              ),
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
