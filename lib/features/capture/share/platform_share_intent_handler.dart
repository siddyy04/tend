import 'package:my_first_app/features/capture/share/share_intent_handler.dart';
import 'package:my_first_app/features/capture/share/shared_capture_payload.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// Android (and iOS when configured) share ingress via `receive_sharing_intent`.
///
/// Sprint 2B.6: plain text + URLs only. Images/PDFs/files are ignored.
class PlatformShareIntentHandler implements ShareIntentHandler {
  PlatformShareIntentHandler({ReceiveSharingIntent? plugin})
      : _plugin = plugin ?? ReceiveSharingIntent.instance;

  final ReceiveSharingIntent _plugin;

  @override
  Future<SharedCapturePayload?> getInitialShare() async {
    final media = await _plugin.getInitialMedia();
    return _payloadFromMedia(media);
  }

  @override
  Stream<SharedCapturePayload> watchShares() async* {
    await for (final media in _plugin.getMediaStream()) {
      final payload = _payloadFromMedia(media);
      if (payload != null) {
        yield payload;
      }
    }
  }

  @override
  Future<void> reset() => _plugin.reset();

  SharedCapturePayload? _payloadFromMedia(List<SharedMediaFile> media) {
    if (media.isEmpty) return null;

    // First text or URL only — multi-item share is out of scope.
    for (final file in media) {
      if (file.type == SharedMediaType.text ||
          file.type == SharedMediaType.url) {
        return SharedCapturePayload(
          text: file.path,
          sourceRef: null,
        );
      }
    }
    return null;
  }
}
