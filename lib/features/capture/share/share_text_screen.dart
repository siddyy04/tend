import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/app/app_routes.dart';
import 'package:my_first_app/core/constants/enums.dart';
import 'package:my_first_app/features/capture/capture_submit_flow.dart';
import 'package:my_first_app/features/capture/share/share_providers.dart';
import 'package:my_first_app/features/capture/share/shared_capture_payload.dart';
import 'package:my_first_app/features/capture/widgets/capture_empty_memories_panel.dart';

/// Editable shared text — Continue runs the same Capture submit pipeline.
///
/// Prefer [initialPayload] from GoRouter `extra`. [pendingShareProvider] is only
/// a fallback when redirect reached this route without `extra` (cold start).
class ShareTextScreen extends ConsumerStatefulWidget {
  const ShareTextScreen({
    super.key,
    this.initialPayload,
  });

  final SharedCapturePayload? initialPayload;

  @override
  ConsumerState<ShareTextScreen> createState() => _ShareTextScreenState();
}

class _ShareTextScreenState extends ConsumerState<ShareTextScreen> {
  final _controller = TextEditingController();
  String? _sourceRef;
  var _seeded = false;
  var _submitting = false;
  var _showEmptyPanel = false;
  var _emptyShare = false;
  String? _failureMessage;

  @override
  void initState() {
    super.initState();
    // Seed from navigation extra only — no provider writes here.
    final initial = widget.initialPayload;
    if (initial != null) {
      _seeded = true;
      _applyPayload(initial);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(pendingShareProvider.notifier).clear();
      });
    } else {
      // Cold-start redirect may land here without extra; read+clear after frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _seeded) return;
        final pending = ref.read(pendingShareProvider);
        _seeded = true;
        _applyPayload(pending);
        ref.read(pendingShareProvider.notifier).clear();
        setState(() {});
      });
    }
  }

  @override
  void didUpdateWidget(covariant ShareTextScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.initialPayload;
    if (next == null || next == oldWidget.initialPayload) return;
    if (next.text == oldWidget.initialPayload?.text &&
        next.sourceRef == oldWidget.initialPayload?.sourceRef) {
      return;
    }
    _seeded = true;
    _applyPayload(next);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(pendingShareProvider.notifier).clear();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyPayload(SharedCapturePayload? payload) {
    final text = payload?.text ?? '';
    _sourceRef = payload?.sourceRef;
    _controller.text = text;
    _emptyShare = text.trim().isEmpty;
    _showEmptyPanel = false;
    _failureMessage = null;
  }

  void _clearOutcome() {
    _showEmptyPanel = false;
    _failureMessage = null;
  }

  Future<void> _onContinue() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _submitting) {
      setState(() {
        _emptyShare = true;
        _showEmptyPanel = false;
        _failureMessage = null;
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _emptyShare = false;
      _clearOutcome();
    });

    try {
      final outcome = await CaptureSubmitFlow.submitText(
        context: context,
        ref: ref,
        text: text,
        sourceType: SourceType.share,
        sourceRef: _sourceRef,
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
        debugPrint('[ShareTextScreen] submit failed: $error\n$st');
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
    ref.read(pendingShareProvider.notifier).clear();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.circle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canContinue =
        _controller.text.trim().isNotEmpty && !_submitting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared text'),
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
                'Review and edit the shared text, then continue to extract memories.',
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
                    labelText: 'Shared text',
                  ),
                  onChanged: (_) {
                    setState(() {
                      _emptyShare = false;
                      _clearOutcome();
                    });
                  },
                ),
              ),
              if (_emptyShare) ...[
                const SizedBox(height: 12),
                Text(
                  'Nothing was shared. Paste or type a note, or cancel and share again from another app.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
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
