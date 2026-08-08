import 'package:flutter/foundation.dart';
import 'package:my_first_app/ai/providers/extraction_provider.dart';
import 'package:my_first_app/core/constants/enums.dart';

/// Navigation payload for capture confirmation (single or multi).
///
/// [originalText] is UI-only reference — never persisted to [Memory].
class CaptureConfirmationArgs {
  const CaptureConfirmationArgs({
    required this.candidates,
    required this.originalText,
    this.sourceType = SourceType.text,
    this.sourceRef,
    this.clarificationNeeded = const [],
  }) : assert(candidates.length > 0);

  final List<ExtractedMemoryCandidate> candidates;

  /// Exact text the user typed (or finalized from voice/OCR) on capture.
  final String originalText;

  /// How this capture entered the pipeline (typed, voice, …).
  final SourceType sourceType;

  /// Optional local file path for voice/photo captures.
  final String? sourceRef;

  /// Passive notes (ambiguous person names). Never blocks save.
  final List<ClarificationNeeded> clarificationNeeded;

  bool get isSingle => candidates.length == 1;

  ExtractedMemoryCandidate get candidate => candidates.first;
}

/// Stable family key so each multi-card draft has isolated Riverpod state.
@immutable
class CaptureDraftKey {
  const CaptureDraftKey({
    required this.index,
    required this.candidate,
    this.sourceType = SourceType.text,
    this.sourceRef,
  });

  final int index;
  final ExtractedMemoryCandidate candidate;
  final SourceType sourceType;
  final String? sourceRef;

  @override
  bool operator ==(Object other) {
    return other is CaptureDraftKey &&
        other.index == index &&
        other.candidate == candidate &&
        other.sourceType == sourceType &&
        other.sourceRef == sourceRef;
  }

  @override
  int get hashCode => Object.hash(index, candidate, sourceType, sourceRef);
}
