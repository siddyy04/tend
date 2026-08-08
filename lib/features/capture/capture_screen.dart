import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/ai/model_manager/device_capability_check.dart';
import 'package:my_first_app/ai/model_manager/model_manager_providers.dart';
import 'package:my_first_app/app/app_routes.dart';
import 'package:my_first_app/core/constants/enums.dart';
import 'package:my_first_app/features/capture/capture_submit_flow.dart';
import 'package:my_first_app/features/capture/confirmation/capture_confirmation_args.dart';
import 'package:my_first_app/features/capture/widgets/capture_empty_memories_panel.dart';

/// Global capture screen (text + voice + photo ingress).
class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  final _textController = TextEditingController();
  var _submitting = false;
  var _showEmptyPanel = false;
  String? _failureMessage;
  var _sourceType = SourceType.text;
  String? _sourceRef;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _clearOutcome() {
    _showEmptyPanel = false;
    _failureMessage = null;
  }

  Future<void> _onMic() async {
    FocusScope.of(context).unfocus();
    await context.push<void>(AppRoutes.captureVoice);
  }

  Future<void> _onPhoto() async {
    FocusScope.of(context).unfocus();
    await context.push<void>(AppRoutes.capturePhoto);
  }

  Future<void> _onContinue() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _clearOutcome();
    });

    try {
      final outcome = await CaptureSubmitFlow.submitText(
        context: context,
        ref: ref,
        text: _textController.text,
        sourceType: _sourceType,
        sourceRef: _sourceRef,
        onNavigateToConfirmation: (route, CaptureConfirmationArgs args) {
          context.push(route, extra: args);
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
        debugPrint('[CaptureScreen] submit failed: $error\n$st');
        return true;
      }());
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _onEnterManually() async {
    setState(() => _submitting = true);
    try {
      await CaptureSubmitFlow.enterManually(
        context: context,
        ref: ref,
        text: _textController.text,
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _textController.text.trim().isNotEmpty && !_submitting;
    final tier = ref.watch(deviceAiTierProvider).asData?.value;
    final modelReady =
        ref.watch(currentModelReadyProvider).asData?.value ?? false;
    final assisted =
        tier != null &&
        tier != DeviceAiTier.unsupported &&
        modelReady;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture'),
        actions: [
          IconButton(
            tooltip: 'Photo capture',
            onPressed: _submitting ? null : _onPhoto,
            icon: const Icon(Icons.photo_camera_outlined),
          ),
          IconButton(
            tooltip: 'Voice capture',
            onPressed: _submitting ? null : _onMic,
            icon: const Icon(Icons.mic_none),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                assisted
                    ? 'Type a note about someone in your circle, or use the microphone or camera. You can review the memory before saving.'
                    : 'Type a note about someone in your circle, or use the microphone or camera. You’ll pick who it’s about and finish the details yourself.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  enabled: !_submitting,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'e.g. Sarah mentioned her surgery is next month…',
                    alignLabelWithHint: true,
                    labelText: 'Capture text',
                  ),
                  onChanged: (_) {
                    setState(() {
                      _sourceType = SourceType.text;
                      _sourceRef = null;
                      _clearOutcome();
                    });
                  },
                ),
              ),
              if (_showEmptyPanel) ...[
                const SizedBox(height: 12),
                CaptureEmptyMemoriesPanel(
                  enabled: !_submitting,
                  onEditText: () {
                    setState(_clearOutcome);
                  },
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
                FilledButton(
                  onPressed: canSubmit ? _onContinue : null,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continue'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
