import 'package:my_first_app/features/capture/share/shared_capture_payload.dart';

/// Abstraction over OS share-sheet ingress.
///
/// Converts incoming shared content into [SharedCapturePayload] only.
/// Must never call LiteRT / Gemma.
abstract class ShareIntentHandler {
  /// Share that launched a cold start (app was not running), if any.
  Future<SharedCapturePayload?> getInitialShare();

  /// Shares while the app is already running.
  Stream<SharedCapturePayload> watchShares();

  /// Clears the native pending intent so it is not re-delivered.
  Future<void> reset();
}
