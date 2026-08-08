import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/app/app_routes.dart';
import 'package:my_first_app/data/local/isar/collections/person.dart';
import 'package:my_first_app/features/capture/confirmation/capture_confirmation_args.dart';
import 'package:my_first_app/features/capture/confirmation/capture_confirmation_controller.dart';
import 'package:my_first_app/features/capture/confirmation/widgets/candidate_card.dart';
import 'package:my_first_app/features/capture/confirmation/widgets/original_note_section.dart';
import 'package:my_first_app/features/circle/circle_providers.dart';

/// Multi-card confirmation: edit each memory, toggle save, save selection.
class CaptureMultiConfirmationScreen extends ConsumerStatefulWidget {
  const CaptureMultiConfirmationScreen({
    super.key,
    required this.args,
  });

  final CaptureConfirmationArgs args;

  @override
  ConsumerState<CaptureMultiConfirmationScreen> createState() =>
      _CaptureMultiConfirmationScreenState();
}

class _CaptureMultiConfirmationScreenState
    extends ConsumerState<CaptureMultiConfirmationScreen> {
  late final List<bool> _selected;
  late final List<TextEditingController> _eventControllers;
  late final List<TextEditingController> _dateRawControllers;
  late final List<bool> _seeded;
  var _saving = false;
  String? _batchError;

  @override
  void initState() {
    super.initState();
    final n = widget.args.candidates.length;
    _selected = List<bool>.filled(n, true);
    _eventControllers = List.generate(n, (_) => TextEditingController());
    _dateRawControllers = List.generate(n, (_) => TextEditingController());
    _seeded = List<bool>.filled(n, false);
  }

  @override
  void dispose() {
    for (final c in _eventControllers) {
      c.dispose();
    }
    for (final c in _dateRawControllers) {
      c.dispose();
    }
    super.dispose();
  }

  CaptureDraftKey _keyAt(int index) {
    return CaptureDraftKey(
      index: index,
      candidate: widget.args.candidates[index],
      sourceType: widget.args.sourceType,
      sourceRef: widget.args.sourceRef,
    );
  }

  void _seedIfNeeded(int index, CaptureConfirmationController form) {
    if (_seeded[index]) return;
    _eventControllers[index].text = form.eventText;
    _dateRawControllers[index].text = form.dateValueRaw ?? '';
    _seeded[index] = true;
  }

  int get _selectedCount => _selected.where((v) => v).length;

  String get _saveLabel {
    final n = _selectedCount;
    if (n == 0) return 'Save memories';
    if (n == 1) return 'Save 1 memory';
    return 'Save $n memories';
  }

  Future<void> _onSave() async {
    if (_selectedCount == 0) {
      setState(() {
        _batchError = 'Select at least one memory to save.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _batchError = null;
    });

    try {
      final savedPersonUuids = <String>{};
      var anyValidationFailure = false;

      for (var i = 0; i < widget.args.candidates.length; i++) {
        if (!_selected[i]) continue;
        final form = ref.read(
          captureConfirmationControllerProvider(_keyAt(i)).notifier,
        );
        final personUuid = await form.save();
        if (personUuid == null) {
          anyValidationFailure = true;
          // Keep going so other cards can still save; surface first form error.
          _batchError ??= form.saveError?.toString() ??
              form.personError ??
              form.eventTextError ??
              form.categoryError ??
              form.dateError ??
              form.importanceScoreError ??
              'Could not save memory ${i + 1}. Check the fields above.';
        } else {
          savedPersonUuids.add(personUuid);
        }
      }

      if (!mounted) return;

      if (savedPersonUuids.isEmpty) {
        setState(() {
          _batchError ??= 'Nothing was saved. Check each selected memory.';
        });
        return;
      }

      if (anyValidationFailure && savedPersonUuids.isNotEmpty) {
        // Partial success — still navigate so saved rows are visible.
      }

      if (savedPersonUuids.length == 1) {
        context.go(AppRoutes.personProfile(savedPersonUuids.first));
      } else {
        context.go(AppRoutes.circle);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final people = ref.watch(allPeopleProvider).asData?.value ?? const [];
    final theme = Theme.of(context);

    // Touch each draft provider so async build runs.
    for (var i = 0; i < widget.args.candidates.length; i++) {
      ref.watch(captureConfirmationControllerProvider(_keyAt(i)));
    }

    final stillLoading = widget.args.candidates.asMap().entries.any((e) {
      return ref
          .watch(captureConfirmationControllerProvider(_keyAt(e.key)))
          .isLoading;
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review before saving'),
      ),
      body: stillLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          '$_selectedCount of ${widget.args.candidates.length} '
                          'selected to save',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Edit each memory, turn off Save for any you want to skip, '
                          'then save the selected ones.',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        OriginalNoteSection(
                          originalText: widget.args.originalText,
                        ),
                        const SizedBox(height: 20),
                        for (var i = 0;
                            i < widget.args.candidates.length;
                            i++) ...[
                          if (i > 0) const SizedBox(height: 20),
                          _buildCard(context, i, people),
                        ],
                        if (_batchError != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _batchError!,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ],
                        const SizedBox(height: 88),
                      ],
                    ),
                  ),
                  Material(
                    elevation: 4,
                    color: theme.colorScheme.surface,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: FilledButton(
                          onPressed: _saving || _selectedCount == 0
                              ? null
                              : _onSave,
                          child: _saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(_saveLabel),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    int index,
    List<Person> people,
  ) {
    final key = _keyAt(index);
    final asyncForm = ref.watch(captureConfirmationControllerProvider(key));
    return asyncForm.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => Text('$e'),
      data: (_) {
        final form =
            ref.read(captureConfirmationControllerProvider(key).notifier);
        _seedIfNeeded(index, form);
        final theme = Theme.of(context);

        return DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Memory ${index + 1}',
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    Switch(
                      value: _selected[index],
                      onChanged: (value) {
                        setState(() {
                          _selected[index] = value;
                          _batchError = null;
                        });
                      },
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Save',
                      style: theme.textTheme.labelLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Opacity(
                  opacity: _selected[index] ? 1 : 0.55,
                  child: CandidateCard(
                    controller: form,
                    people: people,
                    eventTextController: _eventControllers[index],
                    dateRawController: _dateRawControllers[index],
                  ),
                ),
                if (form.saveError != null ||
                    form.personError != null ||
                    form.eventTextError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    form.saveError?.toString() ??
                        form.personError ??
                        form.eventTextError ??
                        '',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
