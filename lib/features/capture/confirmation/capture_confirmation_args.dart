import 'package:my_first_app/ai/providers/extraction_provider.dart';

/// Navigation payload for the capture confirmation screen.
///
/// [originalText] is UI-only reference — never persisted to [Memory].
/// Sprint 2B.1 may pass multiple [candidates]; multi-card UI is Phase 2B.2.
class CaptureConfirmationArgs {
  const CaptureConfirmationArgs({
    required this.candidates,
    required this.originalText,
  }) : assert(candidates.length > 0);

  final List<ExtractedMemoryCandidate> candidates;

  /// Exact text the user typed on the capture screen.
  final String originalText;

  /// Temporary: single-card confirmation uses the first candidate until 2B.2.
  ExtractedMemoryCandidate get candidate => candidates.first;
}
