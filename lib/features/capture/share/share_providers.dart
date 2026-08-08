import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/features/capture/share/platform_share_intent_handler.dart';
import 'package:my_first_app/features/capture/share/share_intent_handler.dart';
import 'package:my_first_app/features/capture/share/shared_capture_payload.dart';

final shareIntentHandlerProvider = Provider<ShareIntentHandler>((ref) {
  return PlatformShareIntentHandler();
});

/// Pre-auth / recovery staging for share payloads.
///
/// Navigation normally passes [SharedCapturePayload] via GoRouter `extra`.
/// This provider only bridges cold start (and auth flicker recovery) until
/// [ShareTextScreen] clears it after a successful seed — never mutate it
/// during widget build / didChangeDependencies.
class PendingShareNotifier extends Notifier<SharedCapturePayload?> {
  @override
  SharedCapturePayload? build() => null;

  void setPending(SharedCapturePayload payload) {
    state = payload;
  }

  void clear() {
    state = null;
  }
}

final pendingShareProvider =
    NotifierProvider<PendingShareNotifier, SharedCapturePayload?>(
  PendingShareNotifier.new,
);
