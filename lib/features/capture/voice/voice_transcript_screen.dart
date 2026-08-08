import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/core/constants/enums.dart';
import 'package:my_first_app/features/capture/capture_submit_flow.dart';

/// Editable transcript after platform speech-to-text (Sprint 2B.4).
///
/// Continue runs the same [CaptureSubmitFlow] / [CaptureController.submitText]
/// path as typed capture — it does not return to Capture first.
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
  String? _statusMessage;
  Object? _error;

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

  Future<void> _onContinue() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _submitting) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _statusMessage = null;
      _error = null;
    });

    try {
      final outcome = await CaptureSubmitFlow.submitText(
        context: context,
        ref: ref,
        text: text,
        sourceType: SourceType.voice,
        sourceRef: null,
        onNavigateToConfirmation: (route, args) {
          // Replace transcript so Back from confirmation returns to Capture,
          // not the voice edit screen.
          context.pushReplacement(route, extra: args);
        },
      );

      if (!mounted) return;

      switch (outcome) {
        case CaptureSubmitFlowNavigated():
        case CaptureSubmitFlowCancelled():
          break;
        case CaptureSubmitFlowMessage(:final statusMessage):
          setState(() {
            _statusMessage = statusMessage;
            _error = outcome.debugForUi;
          });
      }
    } catch (error, st) {
      if (!mounted) return;
      setState(() {
        _statusMessage =
            'Extraction failed. Please try again, or enter the memory manually.';
        _error = '$error\n$st';
      });
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
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (_statusMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _statusMessage!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  '$_error',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: canContinue ? _onContinue : null,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continue'),
              ),
              if (_statusMessage != null) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _submitting ? null : _onEnterManually,
                  child: const Text('Enter manually'),
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
