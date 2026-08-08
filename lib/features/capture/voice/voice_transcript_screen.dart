import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/core/constants/enums.dart';
import 'package:my_first_app/features/capture/capture_submit_flow.dart';
import 'package:my_first_app/features/capture/widgets/capture_empty_memories_panel.dart';
import 'package:my_first_app/features/capture/widgets/capture_extracting_status.dart';

/// Editable transcript after platform speech-to-text (Sprint 2B.4).
class VoiceTranscriptScreen extends ConsumerStatefulWidget {
  const VoiceTranscriptScreen({
    super.key,
    required this.initialTranscript,
  });

  final String initialTranscript;

  @override
  ConsumerState<VoiceTranscriptScreen> createState() =>
      _VoiceTranscriptScreenState();
}

class _VoiceTranscriptScreenState
    extends ConsumerState<VoiceTranscriptScreen> {
  late final TextEditingController _controller;
  var _submitting = false;
  var _showEmptyPanel = false;
  String? _failureMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTranscript);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clearOutcome() {
    _showEmptyPanel = false;
    _failureMessage = null;
  }

  Future<void> _onContinue() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _submitting) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _clearOutcome();
    });

    try {
      final outcome = await CaptureSubmitFlow.submitText(
        context: context,
        ref: ref,
        text: text,
        sourceType: SourceType.voice,
        sourceRef: null,
        onNavigateToConfirmation: (route, args) {
          context.pushReplacement(route, extra: args);
        },
      );

      if (!mounted) return;

      switch (outcome) {
        case CaptureSubmitFlowNavigated():
        case CaptureSubmitFlowCancelled():
          break;
        case CaptureSubmitFlowEmpty():
          setState(() => _showEmptyPanel = true);
        case CaptureSubmitFlowFailure(:final userMessage):
          setState(() => _failureMessage = userMessage);
      }
    } catch (error, st) {
      if (!mounted) return;
      setState(() {
        _failureMessage =
            'Something went wrong while extracting memories. Please try again, or enter the memory manually.';
      });
      assert(() {
        debugPrint('[VoiceTranscript] submit failed: $error\n$st');
        return true;
      }());
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _onEnterManually() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      await CaptureSubmitFlow.enterManually(
        context: context,
        ref: ref,
        text: text,
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _onCancel() {
    if (_submitting) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final canContinue =
        _controller.text.trim().isNotEmpty && !_submitting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit transcript'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _submitting ? null : _onCancel,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Review and edit the transcript, then continue to extract memories.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  enabled: !_submitting,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                    labelText: 'Transcript',
                  ),
                  onChanged: (_) => setState(_clearOutcome),
                ),
              ),
              if (_showEmptyPanel) ...[
                const SizedBox(height: 12),
                CaptureEmptyMemoriesPanel(
                  enabled: !_submitting,
                  onEditText: () => setState(_clearOutcome),
                  onEnterManually: _onEnterManually,
                ),
              ],
              if (_failureMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _failureMessage!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _submitting ? null : _onEnterManually,
                  child: const Text('Enter manually'),
                ),
              ],
              if (!_showEmptyPanel) ...[
                const SizedBox(height: 16),
                if (_submitting) ...[
                  const CaptureExtractingStatus(),
                  const SizedBox(height: 12),
                ],
                Semantics(
                  button: true,
                  label: 'Continue to extract memories',
                  child: FilledButton(
                    onPressed: canContinue ? _onContinue : null,
                    child: _submitting
                        ? const CaptureExtractingButtonChild()
                        : const Text('Continue'),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _submitting ? null : _onCancel,
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
