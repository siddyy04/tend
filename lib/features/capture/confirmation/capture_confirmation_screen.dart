import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/app/app_routes.dart';
import 'package:my_first_app/core/analytics/capture_analytics.dart';
import 'package:my_first_app/features/capture/confirmation/capture_confirmation_args.dart';
import 'package:my_first_app/features/capture/confirmation/capture_confirmation_controller.dart';
import 'package:my_first_app/features/capture/confirmation/widgets/candidate_card.dart';
import 'package:my_first_app/features/capture/confirmation/widgets/capture_found_memories_banner.dart';
import 'package:my_first_app/features/capture/confirmation/widgets/clarification_note.dart';
import 'package:my_first_app/features/capture/confirmation/widgets/original_note_section.dart';
import 'package:my_first_app/features/circle/circle_providers.dart';

/// Single-candidate confirmation screen.
class CaptureConfirmationScreen extends ConsumerStatefulWidget {
  const CaptureConfirmationScreen({
    super.key,
    required this.args,
  });

  final CaptureConfirmationArgs args;

  @override
  ConsumerState<CaptureConfirmationScreen> createState() =>
      _CaptureConfirmationScreenState();
}

class _CaptureConfirmationScreenState
    extends ConsumerState<CaptureConfirmationScreen> {
  late final TextEditingController _eventTextController;
  late final TextEditingController _dateRawController;
  var _seeded = false;
  var _saving = false;

  CaptureDraftKey get _draftKey => CaptureDraftKey(
        index: 0,
        candidate: widget.args.candidate,
        sourceType: widget.args.sourceType,
        sourceRef: widget.args.sourceRef,
      );

  @override
  void initState() {
    super.initState();
    _eventTextController = TextEditingController();
    _dateRawController = TextEditingController();
  }

  @override
  void dispose() {
    _eventTextController.dispose();
    _dateRawController.dispose();
    super.dispose();
  }

  void _seedIfNeeded(CaptureConfirmationController form) {
    if (_seeded) return;
    _eventTextController.text = form.eventText;
    _dateRawController.text = form.dateValueRaw ?? '';
    _seeded = true;
  }

  Future<void> _onSave(CaptureConfirmationController form) async {
    if (_saving) return;
    setState(() => _saving = true);
    final analytics = ref.read(captureAnalyticsProvider);
    try {
      final personUuid = await form.save();
      if (!mounted) return;
      if (personUuid != null) {
        analytics.memoriesApproved(count: 1);
        if (form.wasEdited) {
          analytics.memoryEdited(fieldCount: form.editedFieldCount);
        }
        context.go(AppRoutes.personProfile(personUuid));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncForm =
        ref.watch(captureConfirmationControllerProvider(_draftKey));
    final people =
        ref.watch(allPeopleProvider).asData?.value ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review before saving'),
      ),
      body: asyncForm.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Preparing review…'),
              ],
            ),
          ),
        ),
        error: (error, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Something went wrong loading this review. Please go back and try again.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (_) {
          final form = ref.read(
            captureConfirmationControllerProvider(_draftKey).notifier,
          );
          _seedIfNeeded(form);

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const CaptureFoundMemoriesBanner(count: 1),
                const SizedBox(height: 14),
                Text(
                  'Check the details below, then save this memory to their profile.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (widget.args.clarificationNeeded.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  ClarificationNote(items: widget.args.clarificationNeeded),
                ],
                const SizedBox(height: 14),
                OriginalNoteSection(originalText: widget.args.originalText),
                const SizedBox(height: 18),
                CandidateCard(
                  controller: form,
                  people: people,
                  eventTextController: _eventTextController,
                  dateRawController: _dateRawController,
                ),
                if (form.saveError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Could not save this memory. Check the fields above and try again.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                Semantics(
                  button: true,
                  label: 'Save memory',
                  child: FilledButton(
                    onPressed: _saving ? null : () => _onSave(form),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save memory'),
                  ),
                ),
                const SizedBox(height: 8),
                Semantics(
                  button: true,
                  label: 'Cancel',
                  child: OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () {
                            ref
                                .read(captureAnalyticsProvider)
                                .memoriesRejected(count: 1);
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go(AppRoutes.circle);
                            }
                          },
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
