import 'package:my_first_app/core/constants/enums.dart';
import 'package:my_first_app/data/local/isar/collections/person.dart';

/// On-device structured extraction from free text.
///
/// Business logic depends only on this interface — never on a concrete model SDK.
abstract class ExtractionProvider {
  Future<ExtractionResult> extract({
    required String text,
    required List<Person> knownPeople,
  });
}

/// Sprint 2A result shape — candidates only (no clarification fields).
class ExtractionResult {
  const ExtractionResult({required this.candidates});

  final List<ExtractedMemoryCandidate> candidates;
}

/// One model-proposed memory before user confirmation.
///
/// LiteRT fills person / event / quote / optional date / category.
/// [importanceScore] uses a deterministic default; [followUpSuggested] /
/// [followUpNote] stay false/null and are never persisted in Sprint 2A.
/// [personMatchUuid] is resolved by Tend from [personMentioned] against
/// known people (exact unique name match), not by the model.
class ExtractedMemoryCandidate {
  const ExtractedMemoryCandidate({
    required this.personMentioned,
    required this.personMatchUuid,
    required this.personMatchConfidence,
    required this.category,
    required this.eventText,
    required this.quoteEvidence,
    required this.datePrecision,
    required this.dateValueRaw,
    required this.dateValue,
    required this.importanceScore,
    required this.extractionConfidence,
    required this.followUpSuggested,
    required this.followUpNote,
  });

  /// Name as stated in the input.
  final String personMentioned;

  /// Matched existing [Person.uuid], or null if unmatched/ambiguous.
  final String? personMatchUuid;

  /// 0.0–1.0
  final double personMatchConfidence;

  final MemoryCategory category;
  final String eventText;

  /// Grounding quote from source — mandatory for a valid candidate.
  final String quoteEvidence;

  final DatePrecision datePrecision;
  final String? dateValueRaw;
  final DateTime? dateValue;

  /// 1–5, model-suggested, user-editable.
  final int importanceScore;

  /// 0.0–1.0
  final double extractionConfidence;

  /// Present in model output — discarded after confirmation (Sprint 2A).
  final bool followUpSuggested;

  /// Present in model output — discarded after confirmation (Sprint 2A).
  final String? followUpNote;

  @override
  bool operator ==(Object other) {
    return other is ExtractedMemoryCandidate &&
        other.personMentioned == personMentioned &&
        other.personMatchUuid == personMatchUuid &&
        other.personMatchConfidence == personMatchConfidence &&
        other.category == category &&
        other.eventText == eventText &&
        other.quoteEvidence == quoteEvidence &&
        other.datePrecision == datePrecision &&
        other.dateValueRaw == dateValueRaw &&
        other.dateValue == dateValue &&
        other.importanceScore == importanceScore &&
        other.extractionConfidence == extractionConfidence &&
        other.followUpSuggested == followUpSuggested &&
        other.followUpNote == followUpNote;
  }

  @override
  int get hashCode => Object.hash(
        personMentioned,
        personMatchUuid,
        personMatchConfidence,
        category,
        eventText,
        quoteEvidence,
        datePrecision,
        dateValueRaw,
        dateValue,
        importanceScore,
        extractionConfidence,
        followUpSuggested,
        followUpNote,
      );
}
