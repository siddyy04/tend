import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/app/app_routes.dart';
import 'package:my_first_app/features/capture/confirmation/capture_confirmation_args.dart';
import 'package:my_first_app/features/capture/confirmation/capture_confirmation_controller.dart';
import 'package:my_first_app/features/capture/confirmation/widgets/candidate_card.dart';
import 'package:my_first_app/features/capture/confirmation/widgets/original_note_section.dart';
import 'package:my_first_app/features/circle/circle_providers.dart';

/// Single-candidate confirmation screen (Sprint 2A UX, unchanged for N=1).
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
    setState(() => _saving = true);
    try {
      final personUuid = await form.save();
      if (!mounted) return;
      if (personUuid != null) {
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (_) {
          final form = ref.read(
            captureConfirmationControllerProvider(_draftKey).notifier,
          );
          _seedIfNeeded(form);

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Check the details below, then save this memory to their profile.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                OriginalNoteSection(originalText: widget.args.originalText),
                const SizedBox(height: 16),
                CandidateCard(
                  controller: form,
                  people: people,
                  eventTextController: _eventTextController,
                  dateRawController: _dateRawController,
                ),
                if (form.saveError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    '${form.saveError}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : () => _onSave(form),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save memory'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
