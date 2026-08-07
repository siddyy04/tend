import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/ai/providers/ai_provider_selection.dart';
import 'package:my_first_app/ai/providers/extraction_provider.dart';
import 'package:my_first_app/ai/providers/litert/litert_extraction_provider.dart';
import 'package:my_first_app/domain/rules/extraction_validation_rules.dart';
import 'package:my_first_app/features/circle/circle_providers.dart';

/// Orchestrates text → extract → validated candidate handoff.
///
/// Sprint 2B.1: returns **all** grounded candidates. Multi-card confirmation
/// UI is Phase 2B.2 — Capture currently navigates with the full list but the
/// confirmation screen still drafts the first card until that phase.
final captureControllerProvider = Provider<CaptureController>((ref) {
  return CaptureController(ref);
});

/// Result of submitting capture text for extraction.
sealed class CaptureSubmitResult {
  const CaptureSubmitResult();
}

/// Validated candidates ready for the confirmation screen.
class CaptureSubmitReady extends CaptureSubmitResult {
  const CaptureSubmitReady(this.candidates)
      : assert(candidates.length > 0);

  final List<ExtractedMemoryCandidate> candidates;
}

/// No candidate survived grounding/taxonomy checks.
class CaptureSubmitEmpty extends CaptureSubmitResult {
  const CaptureSubmitEmpty({this.debugDetail});

  /// Populated in debug builds to explain install/inference failures.
  final String? debugDetail;
}

/// Extraction ran but failed (parse/map/inference error) — show failure UX.
class CaptureSubmitFailed extends CaptureSubmitResult {
  const CaptureSubmitFailed({
    this.userMessage =
        'Extraction failed. Please try again, or enter the memory manually.',
    this.debugDetail,
  });

  final String userMessage;
  final String? debugDetail;
}

class CaptureController {
  CaptureController(this._ref);

  final Ref _ref;

  /// Runs extraction and returns every validated candidate (Sprint 2B.1).
  Future<CaptureSubmitResult> submitText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const CaptureSubmitEmpty(debugDetail: 'empty input');
    }

    try {
      final knownPeople = await _ref.read(allPeopleProvider.future);
      final provider = _ref.read(activeExtractionProvider);
      final extraction = await provider.extract(
        text: trimmed,
        knownPeople: knownPeople,
      );

      final surviving = <ExtractedMemoryCandidate>[];
      if (extraction.candidates.isEmpty && kDebugMode) {
        debugPrint(
          '[CaptureController] ===== GROUNDING DEBUG =====\n'
          'Model produced a candidate: No\n'
          'Quote grounded: No\n'
          'Date grounded: No\n'
          'Candidate: rejected\n'
          'Exact rejection reason: no model candidate\n'
          '=======================',
        );
      }
      for (final candidate in extraction.candidates) {
        final rejection = literalExtractionRejectionReason(
          trimmed,
          personMentioned: candidate.personMentioned,
          eventText: candidate.eventText,
          quoteEvidence: candidate.quoteEvidence,
          dateValueRaw: candidate.dateValueRaw,
          followUpSuggested: candidate.followUpSuggested,
          followUpNote: candidate.followUpNote,
        );
        final quoteOk = quoteAppearsVerbatimInSource(candidate, trimmed);
        final dateOk = datePhraseGroundedInSource(candidate, trimmed);
        final pass = rejection == null;
        if (kDebugMode) {
          debugPrint(
            '[CaptureController] ===== GROUNDING DEBUG =====\n'
            'Model produced a candidate: Yes\n'
            'Quote grounded: ${quoteOk ? 'Yes' : 'No'}\n'
            'Date grounded: ${dateOk ? 'Yes' : 'No'}\n'
            'Candidate: ${pass ? 'accepted' : 'rejected'}\n'
            '${pass ? '' : 'Exact rejection reason: $rejection\n'}'
            '=======================',
          );
        }
        if (!pass) {
          continue;
        }
        surviving.add(candidate);
      }

      if (surviving.isEmpty) {
        String? detail;
        var softFailed = false;
        if (provider is LiteRtExtractionProvider) {
          softFailed = provider.lastFailureReason != null ||
              provider.adapter.lastDiagnostics?.parserBranch == 'exception';
          if (kDebugMode) {
            final raw = provider.adapter.lastFullRawResponse;
            detail = [
              provider.lastFailureReason ??
                  provider.adapter.lastDiagnostics?.toString(),
              if (raw != null) 'FULL_RAW_RESPONSE=$raw',
              if (provider.adapter.lastParserResultSummary != null)
                'PARSER=${provider.adapter.lastParserResultSummary}',
            ].whereType<String>().join('\n');
          }
        }
        if (kDebugMode && detail == null) {
          detail = 'rawCandidates=${extraction.candidates.length}';
        }
        if (softFailed) {
          return CaptureSubmitFailed(debugDetail: detail);
        }
        return CaptureSubmitEmpty(debugDetail: detail);
      }

      if (kDebugMode && surviving.length > 1) {
        debugPrint(
          '[CaptureController] ${surviving.length} candidates survived; '
          'Phase 2B.2 will show multi-card UI (currently passes full list).',
        );
      }

      return CaptureSubmitReady(List.unmodifiable(surviving));
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[CaptureController] submitText failed: $e\n$st');
      }
      return CaptureSubmitFailed(
        debugDetail: kDebugMode ? '$e\n$st' : null,
      );
    }
  }
}
