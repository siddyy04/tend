import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/app/router.dart';
import 'package:my_first_app/features/auth/auth_controller.dart';
import 'package:my_first_app/features/capture/share/share_providers.dart';
import 'package:my_first_app/features/capture/share/shared_capture_payload.dart';

/// Listens for OS share intents and routes into Share Capture when ready.
///
/// Payload is delivered via GoRouter `extra` whenever navigation runs.
/// [pendingShareProvider] is only a cold-start / auth-recovery bridge.
class ShareIntentBootstrap extends ConsumerStatefulWidget {
  const ShareIntentBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ShareIntentBootstrap> createState() =>
      _ShareIntentBootstrapState();
}

class _ShareIntentBootstrapState extends ConsumerState<ShareIntentBootstrap> {
  StreamSubscription<SharedCapturePayload>? _sub;
  var _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_start());
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    if (_started) return;
    _started = true;

    final handler = ref.read(shareIntentHandlerProvider);

    try {
      final initial = await handler.getInitialShare();
      if (initial != null) {
        await _accept(initial, resetNative: true);
      }
    } catch (e, st) {
      debugPrint('[ShareIntentBootstrap] initial share failed: $e\n$st');
    }

    _sub = handler.watchShares().listen(
      (payload) {
        unawaited(_accept(payload, resetNative: true));
      },
      onError: (Object e, StackTrace st) {
        debugPrint('[ShareIntentBootstrap] share stream error: $e\n$st');
      },
    );
  }

  Future<void> _accept(
    SharedCapturePayload payload, {
    required bool resetNative,
  }) async {
    // Staging for cold start / auth recovery. Cleared after ShareTextScreen seeds.
    ref.read(pendingShareProvider.notifier).setPending(payload);

    if (resetNative) {
      try {
        await ref.read(shareIntentHandlerProvider).reset();
      } catch (_) {}
    }

    final auth = ref.read(authControllerProvider);
    if (!auth.isAuthenticated) {
      // Router redirect after login opens Share Capture; bootstrap will go(extra).
      return;
    }

    if (!mounted) return;
    _goShareCapture(payload);
  }

  void _goShareCapture(SharedCapturePayload payload) {
    final router = ref.read(routerProvider);
    router.go(AppRoutes.captureShare, extra: payload);
  }

  @override
  Widget build(BuildContext context) {
    // Cold start: once auth completes with a staged share, navigate with extra
    // (redirect alone cannot attach GoRouter extra).
    ref.listen<AppAuthState>(authControllerProvider, (previous, next) {
      if (!next.isAuthenticated) return;
      if (previous?.isAuthenticated == true) return;
      final pending = ref.read(pendingShareProvider);
      if (pending == null) return;
      _goShareCapture(pending);
    });

    return widget.child;
  }
}
