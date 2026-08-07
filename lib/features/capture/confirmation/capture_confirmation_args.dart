import 'package:my_first_app/ai/providers/extraction_provider.dart';

/// Navigation payload for the capture confirmation screen.
///
/// [originalText] is UI-only reference — never persisted to [Memory].
class CaptureConfirmationArgs {
  const CaptureConfirmationArgs({
    required this.candidate,
    required this.originalText,
  });

  final ExtractedMemoryCandidate candidate;

  /// Exact text the user typed on the capture screen.
  final String originalText;
}
