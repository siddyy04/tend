import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/ai/model_manager/device_capability_check.dart';
import 'package:my_first_app/ai/model_manager/model_catalog.dart';
import 'package:my_first_app/ai/model_manager/model_download_manager.dart';
import 'package:my_first_app/ai/model_manager/model_manager_providers.dart';
import 'package:my_first_app/ai/providers/ai_provider_selection.dart';
import 'package:my_first_app/app/app_routes.dart';
import 'package:path/path.dart' as p;

/// First-run gate before Capture: capability check → auto download/verify/install.
///
/// Manual installation is a fallback only (download failure, no URL, or explicit choice).
class ModelSetupScreen extends ConsumerStatefulWidget {
  const ModelSetupScreen({super.key});

  @override
  ConsumerState<ModelSetupScreen> createState() => _ModelSetupScreenState();
}

class _ModelSetupScreenState extends ConsumerState<ModelSetupScreen> {
  var _busy = false;
  var _showManualGuide = false;
  ModelPreparePhase? _phase;
  double? _downloadFraction;
  String? _message;
  String? _userError;
  String? _technicalDetails;
  String? _modelsDirPath;
  String? _expectedFilePath;

  void _invalidateAssistProviders() {
    ref.invalidate(modelAssistStatusProvider);
    ref.invalidate(currentModelReadyProvider);
  }

  Future<void> _openCaptureAfterModelReady() async {
    _invalidateAssistProviders();
    if (!mounted) return;
    context.go(AppRoutes.capture);
  }

  Future<void> _openCaptureInManualMode() async {
    await ref.read(modelDownloadManagerProvider).setManualMode();
    _invalidateAssistProviders();
    if (!mounted) return;
    context.go(AppRoutes.capture);
  }

  Future<void> _loadManualPaths() async {
    final manager = ref.read(modelDownloadManagerProvider);
    final dir = await manager.modelsDirectoryPath();
    final filePath = await manager.pathFor(ModelCatalog.current);
    if (!mounted) return;
    setState(() {
      _modelsDirPath = dir;
      _expectedFilePath = filePath;
    });
  }

  void _captureError(Object error) {
    if (error is ModelPrepareException) {
      _userError = error.userMessage;
      _technicalDetails = error.technicalDetails;
      return;
    }
    _userError =
        'Download failed. Please check your internet connection and try again.';
    _technicalDetails = error.toString();
  }

  Future<void> _onContinueUnsupported() async {
    setState(() {
      _busy = true;
      _userError = null;
      _technicalDetails = null;
    });
    try {
      await _openCaptureInManualMode();
    } catch (e) {
      if (!mounted) return;
      setState(() => _captureError(e));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _applyProgress(ModelPrepareProgress progress) {
    if (!mounted) return;
    setState(() {
      _phase = progress.phase;
      _downloadFraction = progress.fraction;
      _message = _labelForPhase(progress.phase);
    });
  }

  /// Paint the new phase, then dwell so the user can actually see it.
  Future<void> _showPhase(
    ModelPreparePhase phase, {
    double? fraction,
    Duration dwell = const Duration(milliseconds: 450),
  }) async {
    if (!mounted) return;
    setState(() {
      _phase = phase;
      _downloadFraction = fraction;
      _message = _labelForPhase(phase);
    });
    await WidgetsBinding.instance.endOfFrame;
    if (dwell > Duration.zero) {
      await Future<void>.delayed(dwell);
    }
  }

  String _labelForPhase(ModelPreparePhase phase) {
    switch (phase) {
      case ModelPreparePhase.downloading:
        return 'Downloading';
      case ModelPreparePhase.verifying:
        return 'Verifying';
      case ModelPreparePhase.installing:
        return 'Installing';
      case ModelPreparePhase.preparing:
        return 'Preparing model';
      case ModelPreparePhase.ready:
        return 'Ready';
    }
  }

  /// Install → prepare → Ready (does not navigate; user taps Continue).
  Future<void> _finishInstallToReady({
    required bool skipInstallIfPrepared,
  }) async {
    final adapter = ref.read(liteRtInferenceAdapterProvider);
    final manager = ref.read(modelDownloadManagerProvider);

    final alreadyPrepared =
        skipInstallIfPrepared && await adapter.isRuntimePrepared();
    if (!alreadyPrepared) {
      await _showPhase(ModelPreparePhase.installing);
      await adapter.prepareActiveModel();

      await _showPhase(ModelPreparePhase.preparing);
      await manager.clearManualMode();
    } else {
      await manager.clearManualMode();
    }

    await _showPhase(
      ModelPreparePhase.ready,
      dwell: const Duration(milliseconds: 200),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = alreadyPrepared
          ? 'Model already prepared. You can continue to capture.'
          : 'Model is ready. You can continue to capture.';
    });
  }

  Future<void> _onPrepareModel() async {
    setState(() {
      _busy = true;
      _userError = null;
      _technicalDetails = null;
      _showManualGuide = false;
      _phase = null;
      _downloadFraction = null;
      _message = 'Preparing on-device assistance…';
    });

    try {
      final manager = ref.read(modelDownloadManagerProvider);
      final adapter = ref.read(liteRtInferenceAdapterProvider);
      final fileReady = await manager.isCurrentModelReady();
      final runtimeReady = fileReady && await adapter.isRuntimePrepared();

      if (runtimeReady) {
        // File + checksum + prior install → skip download entirely.
        await _finishInstallToReady(skipInstallIfPrepared: true);
        return;
      }

      if (fileReady) {
        // File is on disk — skip download, still install into runtime.
        await _showPhase(ModelPreparePhase.verifying);
        await _finishInstallToReady(skipInstallIfPrepared: false);
        return;
      }

      if (!ModelCatalog.current.hasDownloadUrl) {
        await _loadManualPaths();
        if (!mounted) return;
        setState(() {
          _showManualGuide = true;
          _message =
              'Automatic download is not configured. '
              'Follow the manual installation steps below.';
          _phase = null;
          _downloadFraction = null;
          _busy = false;
        });
        return;
      }

      ModelPreparePhase? lastPhase;
      await manager.ensureCurrentModel(
        onProgress: (progress) {
          _applyProgress(progress);
          // Dwell only when the phase label changes (not every download tick).
          if (progress.phase != lastPhase &&
              progress.phase != ModelPreparePhase.downloading) {
            lastPhase = progress.phase;
          } else {
            lastPhase = progress.phase;
          }
        },
      );
      // Ensure Verifying is visible after download completes.
      await _showPhase(ModelPreparePhase.verifying);
      await _finishInstallToReady(skipInstallIfPrepared: false);
    } catch (e) {
      await _loadManualPaths();
      if (!mounted) return;
      setState(() {
        _captureError(e);
        _showManualGuide = true;
        _message =
            'You can retry, install the model manually, or continue without assistance.';
        _phase = null;
        _downloadFraction = null;
        _busy = false;
      });
    }
  }

  Future<void> _onVerifyManualPlacement() async {
    setState(() {
      _busy = true;
      _userError = null;
      _technicalDetails = null;
      _message = 'Verifying';
      _phase = ModelPreparePhase.verifying;
      _downloadFraction = null;
    });
    try {
      final manager = ref.read(modelDownloadManagerProvider);
      await _showPhase(ModelPreparePhase.verifying);
      await manager.verifyManualPlacement();
      await _finishInstallToReady(skipInstallIfPrepared: false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _captureError(e);
        _showManualGuide = true;
        _message = 'Manual installation could not be verified yet.';
        _phase = null;
        _busy = false;
      });
    }
  }

  Future<void> _onShowManualGuide() async {
    await _loadManualPaths();
    if (!mounted) return;
    setState(() {
      _showManualGuide = true;
      _userError = null;
      _technicalDetails = null;
      _message = 'Manual installation steps';
    });
  }

  Future<void> _onContinueWithoutModel() async {
    setState(() => _busy = true);
    try {
      await _openCaptureInManualMode();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _onContinueWhenReady() async {
    setState(() => _busy = true);
    try {
      await _openCaptureAfterModelReady();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tierAsync = ref.watch(deviceAiTierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Get ready to capture'),
        actions: [
          if (kDebugMode)
            TextButton(
              onPressed: () => context.push(AppRoutes.gemmaProbe),
              child: const Text('Probe'),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: tierAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const Center(
              child: Text(
                'Something went wrong checking this device. Please try again.',
              ),
            ),
            data: (tier) {
              if (tier == DeviceAiTier.unsupported) {
                return _UnsupportedBody(
                  busy: _busy,
                  userError: _userError,
                  technicalDetails: _technicalDetails,
                  onContinue: _onContinueUnsupported,
                );
              }
              return _SupportedBody(
                tier: tier,
                busy: _busy,
                phase: _phase,
                downloadFraction: _downloadFraction,
                message: _message,
                userError: _userError,
                technicalDetails: _technicalDetails,
                showManualGuide: _showManualGuide,
                modelsDirPath: _modelsDirPath,
                expectedFilePath: _expectedFilePath,
                displayName: ModelCatalog.current.displayName,
                fileName: ModelCatalog.current.fileName,
                hasDownloadUrl: ModelCatalog.current.hasDownloadUrl,
                onPrepare: _onPrepareModel,
                onShowManual: _onShowManualGuide,
                onVerifyManual: _onVerifyManualPlacement,
                onSkipToManual: _onContinueWithoutModel,
                onContinueWhenReady: _onContinueWhenReady,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _UnsupportedBody extends StatelessWidget {
  const _UnsupportedBody({
    required this.busy,
    required this.userError,
    required this.technicalDetails,
    required this.onContinue,
  });

  final bool busy;
  final String? userError;
  final String? technicalDetails;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return _ScrollableSetupColumn(
      children: [
        Text(
          'Assisted capture isn’t available on this device',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Text(
          'You can still write notes and save memories manually — '
          'everything works offline, just without on-device assistance.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (userError != null) ...[
          const SizedBox(height: 12),
          _UserFacingError(
            message: userError!,
            technicalDetails: technicalDetails,
          ),
        ],
        const Spacer(),
        FilledButton(
          onPressed: busy ? null : onContinue,
          child: busy
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Continue to capture'),
        ),
      ],
    );
  }
}

class _SupportedBody extends StatelessWidget {
  const _SupportedBody({
    required this.tier,
    required this.busy,
    required this.phase,
    required this.downloadFraction,
    required this.message,
    required this.userError,
    required this.technicalDetails,
    required this.showManualGuide,
    required this.modelsDirPath,
    required this.expectedFilePath,
    required this.displayName,
    required this.fileName,
    required this.hasDownloadUrl,
    required this.onPrepare,
    required this.onShowManual,
    required this.onVerifyManual,
    required this.onSkipToManual,
    required this.onContinueWhenReady,
  });

  final DeviceAiTier tier;
  final bool busy;
  final ModelPreparePhase? phase;
  final double? downloadFraction;
  final String? message;
  final String? userError;
  final String? technicalDetails;
  final bool showManualGuide;
  final String? modelsDirPath;
  final String? expectedFilePath;
  final String displayName;
  final String fileName;
  final bool hasDownloadUrl;
  final VoidCallback onPrepare;
  final VoidCallback onShowManual;
  final VoidCallback onVerifyManual;
  final VoidCallback onSkipToManual;
  final VoidCallback onContinueWhenReady;

  bool get _isReady => phase == ModelPreparePhase.ready;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _ScrollableSetupColumn(
      children: [
        Text(
          'Set up capture',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Text(
          tier == DeviceAiTier.constrained
              ? 'This device can use on-device assistance with $displayName. '
                  'Tend will download and prepare the model automatically.'
              : 'Tend will download and prepare $displayName automatically '
                  'for offline assisted capture.',
          style: theme.textTheme.bodyMedium,
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(message!, style: theme.textTheme.bodyMedium),
        ],
        if (phase != null) ...[
          const SizedBox(height: 16),
          Text(
            _phaseHeadline(phase!),
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          if (phase == ModelPreparePhase.downloading)
            LinearProgressIndicator(value: downloadFraction)
          else if (phase == ModelPreparePhase.ready)
            const LinearProgressIndicator(value: 1)
          else
            const LinearProgressIndicator(),
          if (phase == ModelPreparePhase.downloading &&
              downloadFraction != null) ...[
            const SizedBox(height: 8),
            Text(
              '${(downloadFraction! * 100).clamp(0, 100).toStringAsFixed(0)}%',
            ),
          ],
        ],
        if (userError != null) ...[
          const SizedBox(height: 12),
          _UserFacingError(
            message: userError!,
            technicalDetails: technicalDetails,
          ),
        ],
        if (showManualGuide && !_isReady) ...[
          const SizedBox(height: 16),
          _ManualInstallGuide(
            displayName: displayName,
            fileName: fileName,
            modelsDirPath: modelsDirPath,
            expectedFilePath: expectedFilePath,
          ),
        ],
        const Spacer(),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: busy
              ? null
              : (_isReady
                  ? onContinueWhenReady
                  : (showManualGuide ? onVerifyManual : onPrepare)),
          child: busy
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  _isReady
                      ? 'Continue to capture'
                      : (showManualGuide
                          ? 'I’ve placed the file — verify'
                          : 'Download and prepare'),
                ),
        ),
        if (!_isReady && showManualGuide && hasDownloadUrl) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: busy ? null : onPrepare,
            child: const Text('Retry automatic download'),
          ),
        ],
        if (!_isReady && !showManualGuide) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: busy ? null : onShowManual,
            child: const Text('Install manually instead'),
          ),
        ],
        if (!_isReady) ...[
          const SizedBox(height: 4),
          TextButton(
            onPressed: busy ? null : onSkipToManual,
            child: const Text('Continue without assistance'),
          ),
        ],
      ],
    );
  }

  String _phaseHeadline(ModelPreparePhase phase) {
    switch (phase) {
      case ModelPreparePhase.downloading:
        return 'Downloading';
      case ModelPreparePhase.verifying:
        return 'Verifying';
      case ModelPreparePhase.installing:
        return 'Installing';
      case ModelPreparePhase.preparing:
        return 'Preparing model';
      case ModelPreparePhase.ready:
        return 'Ready';
    }
  }
}

/// Scrollable column that still pins actions toward the bottom on tall screens.
class _ScrollableSetupColumn extends StatelessWidget {
  const _ScrollableSetupColumn({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _UserFacingError extends StatelessWidget {
  const _UserFacingError({
    required this.message,
    required this.technicalDetails,
  });

  final String message;
  final String? technicalDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
        if (kDebugMode &&
            technicalDetails != null &&
            technicalDetails!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              title: Text(
                'Technical details',
                style: theme.textTheme.labelLarge,
              ),
              children: [
                SelectableText(
                  technicalDetails!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ManualInstallGuide extends StatelessWidget {
  const _ManualInstallGuide({
    required this.displayName,
    required this.fileName,
    required this.modelsDirPath,
    required this.expectedFilePath,
  });

  final String displayName;
  final String fileName;
  final String? modelsDirPath;
  final String? expectedFilePath;

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final folder = modelsDirPath ?? '(resolving app documents…)';
    final fullPath = expectedFilePath ?? p.join(folder, fileName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Manual installation for $displayName',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Text(
          '1. Download the model file. The exact file name must be:\n'
          '   $fileName\n\n'
          '2. Copy that file into this folder on the device '
          '(create the folder if it does not exist):\n'
          '   $folder\n\n'
          '3. The full destination path must be exactly:\n'
          '   $fullPath\n\n'
          '4. Do not rename the file. Then tap “I’ve placed the file — verify”.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: () => _copy(fileName),
              child: const Text('Copy file name'),
            ),
            if (modelsDirPath != null)
              OutlinedButton(
                onPressed: () => _copy(modelsDirPath!),
                child: const Text('Copy folder path'),
              ),
            if (expectedFilePath != null)
              OutlinedButton(
                onPressed: () => _copy(expectedFilePath!),
                child: const Text('Copy full path'),
              ),
          ],
        ),
      ],
    );
  }
}
