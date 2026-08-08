import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/ai/providers/ai_provider_selection.dart';
import 'package:my_first_app/app/app_routes.dart';
import 'package:my_first_app/features/settings/speech_locale_resolver.dart';
import 'package:permission_handler/permission_handler.dart';

/// Dedicated recording UI for voice capture (Sprint 2B.4).
///
/// Collects speech via platform ASR without showing live transcript text.
/// On Stop, finalizes transcription and opens the editable transcript screen.
/// Cancel discards everything and returns to Capture.
class VoiceRecordingScreen extends ConsumerStatefulWidget {
  const VoiceRecordingScreen({super.key});

  @override
  ConsumerState<VoiceRecordingScreen> createState() =>
      _VoiceRecordingScreenState();
}

class _VoiceRecordingScreenState extends ConsumerState<VoiceRecordingScreen> {
  var _phase = _VoicePhase.checkingPermission;
  String? _permissionMessage;
  var _permanentlyDenied = false;
  var _elapsed = Duration.zero;
  Timer? _timer;
  var _stopping = false;
  var _sessionActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_begin());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _discardSession() async {
    if (!_sessionActive) return;
    _sessionActive = false;
    await ref.read(activeTranscriptionProvider).cancelListening();
  }

  Future<void> _begin() async {
    setState(() {
      _phase = _VoicePhase.checkingPermission;
      _permissionMessage = null;
      _permanentlyDenied = false;
      _stopping = false;
    });

    final status = await Permission.microphone.status;

    if (!mounted) return;

    if (status.isPermanentlyDenied) {
      setState(() {
        _phase = _VoicePhase.permissionBlocked;
        _permanentlyDenied = true;
        _permissionMessage =
            'Microphone access is turned off. Enable it in system settings to use voice capture.';
      });
      return;
    }

    if (!status.isGranted) {
      final requested = await Permission.microphone.request();
      if (!mounted) return;
      if (requested.isPermanentlyDenied) {
        setState(() {
          _phase = _VoicePhase.permissionBlocked;
          _permanentlyDenied = true;
          _permissionMessage =
              'Microphone access is turned off. Enable it in system settings to use voice capture.';
        });
        return;
      }
      if (!requested.isGranted) {
        setState(() {
          _phase = _VoicePhase.permissionBlocked;
          _permanentlyDenied = false;
          _permissionMessage =
              'Microphone permission is required to record a voice note. You can try again after allowing access.';
        });
        return;
      }
    }

    final provider = ref.read(activeTranscriptionProvider);
    final available = await provider.isAvailable();
    if (!mounted) return;
    if (!available) {
      setState(() {
        _phase = _VoicePhase.error;
        _permissionMessage =
            'Speech recognition is not available on this device.';
      });
      return;
    }

    final locale = await ensureSpeechLocale(context: context, ref: ref);
    if (!mounted) return;
    if (locale == null) {
      // User cancelled language picker — no draft.
      context.pop();
      return;
    }

    await _startListening(localeId: locale.localeId);
  }

  Future<void> _startListening({String? localeId}) async {
    setState(() {
      _phase = _VoicePhase.recording;
      _elapsed = Duration.zero;
      _permissionMessage = null;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed += const Duration(seconds: 1));
    });

    final provider = ref.read(activeTranscriptionProvider);
    _sessionActive = true;
    await provider.startListening(
      localeId: localeId,
      onResult: (_, _) {
        // Intentionally ignore partials — no live transcription UI (MVP).
      },
      onError: (message) {
        if (!mounted) return;
        _timer?.cancel();
        _sessionActive = false;
        setState(() {
          _phase = _VoicePhase.error;
          _permissionMessage = message;
        });
      },
    );
  }

  Future<void> _onStop() async {
    if (_stopping || _phase != _VoicePhase.recording) return;
    setState(() {
      _stopping = true;
      _phase = _VoicePhase.transcribing;
    });
    _timer?.cancel();

    final provider = ref.read(activeTranscriptionProvider);
    final transcript = await provider.stopListening();
    _sessionActive = false;

    if (!mounted) return;

    if (transcript.trim().isEmpty) {
      setState(() {
        _stopping = false;
        _phase = _VoicePhase.error;
        _permissionMessage =
            "We couldn't understand any speech. Please try again.";
      });
      return;
    }

    context.pushReplacement(
      AppRoutes.captureVoiceTranscript,
      extra: transcript,
    );
  }

  Future<void> _onCancel() async {
    _timer?.cancel();
    await _discardSession();
    if (!mounted) return;
    context.pop();
  }

  Future<void> _openSettings() async {
    await openAppSettings();
  }

  String _formatElapsed(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        unawaited(_onCancel());
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Voice capture'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancel voice capture',
          onPressed: _stopping ? null : _onCancel,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: switch (_phase) {
            _VoicePhase.checkingPermission => const Center(
                child: CircularProgressIndicator(),
              ),
            _VoicePhase.permissionBlocked => _PermissionBody(
                message: _permissionMessage ??
                    'Microphone permission is required for voice capture.',
                permanentlyDenied: _permanentlyDenied,
                onOpenSettings: _permanentlyDenied ? _openSettings : null,
                onRetry: _begin,
                onCancel: _onCancel,
              ),
            _VoicePhase.recording => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Icon(
                    Icons.mic,
                    size: 72,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Recording',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatElapsed(_elapsed),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap Stop when you are finished speaking.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  Semantics(
                    button: true,
                    label: 'Stop recording',
                    child: FilledButton(
                      onPressed: _stopping ? null : _onStop,
                      child: const Text('Stop'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    button: true,
                    label: 'Cancel voice capture',
                    child: OutlinedButton(
                      onPressed: _stopping ? null : _onCancel,
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            _VoicePhase.transcribing => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Transcribing…'),
                  ],
                ),
              ),
            _VoicePhase.error => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Icon(
                    Icons.mic_off_outlined,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _permissionMessage ??
                        "We couldn't understand any speech. Please try again.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _begin,
                    child: const Text('Try again'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _onCancel,
                    child: const Text('Back to Capture'),
                  ),
                ],
              ),
          },
        ),
      ),
    ),
    );
  }
}

enum _VoicePhase {
  checkingPermission,
  permissionBlocked,
  recording,
  transcribing,
  error,
}

class _PermissionBody extends StatelessWidget {
  const _PermissionBody({
    required this.message,
    required this.permanentlyDenied,
    required this.onRetry,
    required this.onCancel,
    this.onOpenSettings,
  });

  final String message;
  final bool permanentlyDenied;
  final VoidCallback onRetry;
  final VoidCallback onCancel;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (permanentlyDenied) ...[
          const SizedBox(height: 12),
          Text(
            'Tend will not ask again until you change the permission in settings.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        const Spacer(),
        if (onOpenSettings != null) ...[
          FilledButton(
            onPressed: onOpenSettings,
            child: const Text('Open settings'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
        ] else
          FilledButton(
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
