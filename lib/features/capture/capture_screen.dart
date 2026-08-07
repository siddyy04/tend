import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/ai/model_manager/device_capability_check.dart';
import 'package:my_first_app/ai/model_manager/model_manager_providers.dart';
import 'package:my_first_app/app/app_routes.dart';
import 'package:my_first_app/data/local/isar/collections/person.dart';
import 'package:my_first_app/features/capture/capture_controller.dart';
import 'package:my_first_app/features/capture/confirmation/capture_confirmation_args.dart';
import 'package:my_first_app/features/circle/circle_providers.dart';

/// Global text-only capture screen (Sprint 2A).
class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  final _textController = TextEditingController();
  var _submitting = false;
  String? _statusMessage;
  Object? _error;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// Assisted capture only when the device tier allows it and a model is ready.
  Future<bool> _shouldUseAssistedCapture() async {
    final tier = await ref.read(deviceAiTierProvider.future);
    if (tier == DeviceAiTier.unsupported) {
      return false;
    }
    return ref.read(currentModelReadyProvider.future);
  }

  Future<void> _onContinue() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _statusMessage = null;
      _error = null;
    });

    try {
      final useAssisted = await _shouldUseAssistedCapture();
      if (!mounted) return;

      if (!useAssisted) {
        await _onEnterManually();
        return;
      }

      final result = await ref
          .read(captureControllerProvider)
          .submitText(_textController.text);

      if (!mounted) return;

      switch (result) {
        case CaptureSubmitReady(:final candidates):
          final args = CaptureConfirmationArgs(
            candidates: candidates,
            originalText: _textController.text,
          );
          unawaited(
            context.push(
              args.isSingle
                  ? AppRoutes.captureConfirm
                  : AppRoutes.captureConfirmSummary,
              extra: args,
            ),
          );
        case CaptureSubmitEmpty(:final debugDetail):
          setState(() {
            _statusMessage =
                'Nothing could be captured from that note. Try again, or enter a memory manually.';
            if (kDebugMode && debugDetail != null) {
              _error = debugDetail;
            }
          });
        case CaptureSubmitFailed(:final userMessage, :final debugDetail):
          setState(() {
            _statusMessage = userMessage;
            if (kDebugMode && debugDetail != null) {
              _error = debugDetail;
            }
          });
      }
    } catch (error, st) {
      if (!mounted) return;
      setState(() {
        _statusMessage =
            'Extraction failed. Please try again, or enter the memory manually.';
        if (kDebugMode) {
          _error = '$error\n$st';
        }
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _onEnterManually() async {
    final people = ref.read(allPeopleProvider).asData?.value ?? const <Person>[];
    if (people.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add someone to My Circle before logging a memory.'),
        ),
      );
      return;
    }

    final selected = await showDialog<Person>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text('Who is this memory about?'),
          children: [
            for (final person in people)
              SimpleDialogOption(
                onPressed: () => Navigator.of(dialogContext).pop(person),
                child: Text(person.name),
              ),
          ],
        );
      },
    );

    if (selected == null || !mounted) return;

    unawaited(
      context.push(
        AppRoutes.memoryNew(selected.uuid),
        extra: _textController.text.trim(),
      ),
    );
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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                assisted
                    ? 'Type a note about someone in your circle. You can review the memory before saving.'
                    : 'Type a note about someone in your circle. You’ll pick who it’s about and finish the details yourself.',
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
                onPressed: canSubmit ? _onContinue : null,
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
            ],
          ),
        ),
      ),
    );
  }
}
