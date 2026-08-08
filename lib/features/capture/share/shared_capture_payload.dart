/// Incoming share content converted to editable Capture text.
///
/// No AI logic — platform share intents only produce text for Capture.
class SharedCapturePayload {
  const SharedCapturePayload({
    required this.text,
    this.sourceRef,
  });

  /// Shared plain text or URL string.
  final String text;

  /// Optional referring app / package id for analytics (not shown in UI).
  final String? sourceRef;

  bool get hasText => text.trim().isNotEmpty;
}
