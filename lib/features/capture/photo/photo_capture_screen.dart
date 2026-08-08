import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_first_app/ai/providers/ai_provider_selection.dart';
import 'package:my_first_app/app/app_routes.dart';
import 'package:my_first_app/features/capture/photo/capture_image_store.dart';
import 'package:my_first_app/features/capture/photo/ocr_text_args.dart';
import 'package:permission_handler/permission_handler.dart';

/// Photo capture entry: camera or gallery → preview → OCR (Sprint 2B.5).
///
/// OCR runs only after the user continues from the preview — never while
/// deciding. Images never go to Gemma.
class PhotoCaptureScreen extends ConsumerStatefulWidget {
  const PhotoCaptureScreen({super.key});

  @override
  ConsumerState<PhotoCaptureScreen> createState() => _PhotoCaptureScreenState();
}

class _PhotoCaptureScreenState extends ConsumerState<PhotoCaptureScreen> {
  var _phase = _PhotoPhase.chooseSource;
  String? _imagePath;
  String? _message;
  var _permanentlyDenied = false;
  var _busy = false;

  final _picker = ImagePicker();

  void _onCancel() {
    if (_busy) return;
    context.pop();
  }

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _busy = true;
      _message = null;
      _permanentlyDenied = false;
    });

    try {
      final permission = source == ImageSource.camera
          ? Permission.camera
          : Permission.photos;

      // Android photo picker / iOS limited library often work without a hard
      // block; still request when the OS exposes a permission.
      final status = await permission.status;
      if (status.isPermanentlyDenied) {
        if (!mounted) return;
        setState(() {
          _phase = _PhotoPhase.permissionBlocked;
          _permanentlyDenied = true;
          _message = source == ImageSource.camera
              ? 'Camera access is turned off. Enable it in system settings to take a photo.'
              : 'Photo library access is turned off. Enable it in system settings to choose an image.';
        });
        return;
      }

      if (!status.isGranted && !status.isLimited) {
        final requested = await permission.request();
        if (!mounted) return;
        if (requested.isPermanentlyDenied) {
          setState(() {
            _phase = _PhotoPhase.permissionBlocked;
            _permanentlyDenied = true;
            _message = source == ImageSource.camera
                ? 'Camera access is turned off. Enable it in system settings to take a photo.'
                : 'Photo library access is turned off. Enable it in system settings to choose an image.';
          });
          return;
        }
        // Gallery: some devices deny Photos but still allow the system picker.
        if (!requested.isGranted &&
            !requested.isLimited &&
            source == ImageSource.camera) {
          setState(() {
            _phase = _PhotoPhase.permissionBlocked;
            _permanentlyDenied = false;
            _message =
                'Camera permission is required to take a photo. You can try again after allowing access.';
          });
          return;
        }
      }

      final file = await _picker.pickImage(
        source: source,
        imageQuality: 92,
      );
      if (!mounted) return;
      if (file == null) {
        setState(() => _phase = _PhotoPhase.chooseSource);
        return;
      }

      final persisted = await persistCaptureImage(file.path);
      if (!mounted) return;
      setState(() {
        _imagePath = persisted;
        _phase = _PhotoPhase.preview;
        _message = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _PhotoPhase.chooseSource;
        _message = 'Could not open the image. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _onPreviewContinue() async {
    final path = _imagePath;
    if (path == null || _busy) return;

    setState(() {
      _busy = true;
      _phase = _PhotoPhase.runningOcr;
      _message = null;
    });

    try {
      final ocr = ref.read(activeOCRProvider);
      final available = await ocr.isAvailable();
      if (!available) {
        if (!mounted) return;
        setState(() {
          _phase = _PhotoPhase.ocrFailed;
          _message = "We couldn't detect any readable text in this image.";
        });
        return;
      }

      final text = await ocr.extractText(path);
      if (!mounted) return;

      if (text.trim().isEmpty) {
        setState(() {
          _phase = _PhotoPhase.ocrFailed;
          _message = "We couldn't detect any readable text in this image.";
        });
        return;
      }

      context.pushReplacement(
        AppRoutes.capturePhotoText,
        extra: OcrTextArgs(text: text, imagePath: path),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _phase = _PhotoPhase.ocrFailed;
        _message = "We couldn't detect any readable text in this image.";
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _openSettings() async {
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onCancel();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Photo capture'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _busy ? null : _onCancel,
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: switch (_phase) {
              _PhotoPhase.chooseSource => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Choose how to add a photo. Tend will read text from the image after you confirm a preview.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 12),
                      Text(_message!, style: theme.textTheme.bodyMedium),
                    ],
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () => unawaited(_pick(ImageSource.camera)),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Take photo'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () => unawaited(_pick(ImageSource.gallery)),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Choose from gallery'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _busy ? null : _onCancel,
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              _PhotoPhase.permissionBlocked => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    Text(
                      _message ?? 'Permission is required for photo capture.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                    if (_permanentlyDenied) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Tend will not ask again until you change the permission in settings.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    const Spacer(),
                    if (_permanentlyDenied)
                      FilledButton(
                        onPressed: _openSettings,
                        child: const Text('Open settings'),
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () {
                        setState(() => _phase = _PhotoPhase.chooseSource);
                      },
                      child: const Text('Try again'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _onCancel,
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              _PhotoPhase.preview => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Preview the image. Continue runs text recognition on this device.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_imagePath!),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _busy ? null : _onPreviewContinue,
                      child: const Text('Continue'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () {
                              setState(() {
                                _imagePath = null;
                                _phase = _PhotoPhase.chooseSource;
                              });
                            },
                      child: const Text('Choose another image'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _busy ? null : _onCancel,
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              _PhotoPhase.runningOcr => const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Reading text…'),
                    ],
                  ),
                ),
              _PhotoPhase.ocrFailed => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    Icon(
                      Icons.text_snippet_outlined,
                      size: 64,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _message ??
                          "We couldn't detect any readable text in this image.",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _imagePath = null;
                          _phase = _PhotoPhase.chooseSource;
                          _message = null;
                        });
                      },
                      child: const Text('Try another image'),
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

enum _PhotoPhase {
  chooseSource,
  permissionBlocked,
  preview,
  runningOcr,
  ocrFailed,
}
