import 'package:flutter/foundation.dart';
import 'package:my_first_app/ai/providers/extraction_provider.dart';

/// Navigation payload for capture confirmation (single or multi).
///
/// [originalText] is UI-only reference — never persisted to [Memory].
class CaptureConfirmationArgs {
  const CaptureConfirmationArgs({
    required this.candidates,
    required this.originalText,
  }) : assert(candidates.length > 0);

  final List<ExtractedMemoryCandidate> candidates;

  /// Exact text the user typed on the capture screen.
  final String originalText;

  bool get isSingle => candidates.length == 1;

  ExtractedMemoryCandidate get candidate => candidates.first;
}

/// Stable family key so each multi-card draft has isolated Riverpod state.
@immutable
class CaptureDraftKey {
  const CaptureDraftKey({
    required this.index,
    required this.candidate,
  });

  final int index;
  final ExtractedMemoryCandidate candidate;

  @override
  bool operator ==(Object other) {
    return other is CaptureDraftKey &&
        other.index == index &&
        other.candidate == candidate;
  }

  @override
  int get hashCode => Object.hash(index, candidate);
}
