import 'package:my_first_app/ai/providers/extraction_provider.dart';
import 'package:my_first_app/core/constants/enums.dart';
import 'package:my_first_app/core/constants/extraction_defaults.dart';

/// Pure validation helpers for AI extraction candidates (ADR-008).
///
/// No I/O, no widgets, no provider dependencies.

/// True when [candidate.quoteEvidence] is non-empty after trim.
///
/// Prefer [quoteAppearsVerbatimInSource] for Capture gating — non-empty alone
/// is not enough to prevent hallucinations.
bool hasGroundingQuote(ExtractedMemoryCandidate candidate) {
  return candidate.quoteEvidence.trim().isNotEmpty;
}

/// True when [quote] appears as a contiguous substring of [sourceText].
///
/// Comparison is **case-insensitive** after trim; still requires a contiguous
/// match (hallucination guard for invented phrases).
bool textAppearsVerbatimInSource(String sourceText, String quote) {
  final q = quote.trim();
  if (q.isEmpty) {
    return false;
  }
  return sourceText.toLowerCase().contains(q.toLowerCase());
}

/// True when [candidate.quoteEvidence] is a verbatim slice of [sourceText].
bool quoteAppearsVerbatimInSource(
  ExtractedMemoryCandidate candidate,
  String sourceText,
) {
  return textAppearsVerbatimInSource(sourceText, candidate.quoteEvidence);
}

/// True when any [candidate.dateValueRaw] also appears verbatim in [sourceText].
///
/// Missing / empty date phrase is allowed (no date in the note).
bool datePhraseGroundedInSource(
  ExtractedMemoryCandidate candidate,
  String sourceText,
) {
  final raw = candidate.dateValueRaw?.trim();
  if (raw == null || raw.isEmpty) {
    return true;
  }
  return textAppearsVerbatimInSource(sourceText, raw);
}

/// True when the candidate has no model-invented follow-up payload.
///
/// Literal-extraction path must leave follow-up unset; confirmation / later
/// sprints own follow-up creation.
bool hasNoInventedFollowUp(ExtractedMemoryCandidate candidate) {
  final note = candidate.followUpNote?.trim();
  return !candidate.followUpSuggested && (note == null || note.isEmpty);
}

/// Combined Capture gate for literal extraction.
bool passesLiteralExtractionGuards(
  ExtractedMemoryCandidate candidate,
  String sourceText,
) {
  return literalExtractionRejectionReason(
        sourceText,
        personMentioned: candidate.personMentioned,
        eventText: candidate.eventText,
        quoteEvidence: candidate.quoteEvidence,
        dateValueRaw: candidate.dateValueRaw,
        followUpSuggested: candidate.followUpSuggested,
        followUpNote: candidate.followUpNote,
      ) ==
      null;
}

/// Human-readable rejection reason, or null if the candidate would be accepted.
///
/// Used by Capture gating and the debug grounding probe — keep reasons stable.
String? literalExtractionRejectionReason(
  String sourceText, {
  required String personMentioned,
  required String eventText,
  required String quoteEvidence,
  String? dateValueRaw,
  bool followUpSuggested = false,
  String? followUpNote,
}) {
  if (personMentioned.trim().isEmpty) {
    return 'missing personMentioned';
  }
  if (eventText.trim().isEmpty) {
    return 'missing eventText';
  }
  final quote = quoteEvidence.trim();
  if (quote.isEmpty) {
    return 'missing quote';
  }
  if (!textAppearsVerbatimInSource(sourceText, quote)) {
    return 'quote not verbatim in note';
  }
  final dateRaw = dateValueRaw?.trim();
  if (dateRaw != null &&
      dateRaw.isNotEmpty &&
      !textAppearsVerbatimInSource(sourceText, dateRaw)) {
    return 'invalid date phrase (not in note)';
  }
  final note = followUpNote?.trim();
  if (followUpSuggested || (note != null && note.isNotEmpty)) {
    return 'invented follow-up';
  }
  return null;
}

/// True when extraction confidence meets [kExtractionConfidenceThreshold].
bool meetsExtractionConfidenceThreshold(ExtractedMemoryCandidate candidate) {
  return candidate.extractionConfidence >= kExtractionConfidenceThreshold;
}

/// True when person-match confidence meets [kPersonMatchConfidenceThreshold].
///
/// A null [ExtractedMemoryCandidate.personMatchUuid] is handled by confirmation
/// UI separately — this function only compares the confidence score.
bool meetsPersonMatchConfidenceThreshold(ExtractedMemoryCandidate candidate) {
  return candidate.personMatchConfidence >= kPersonMatchConfidenceThreshold;
}

/// Maps a raw model category string to [MemoryCategory], or null if invalid.
///
/// Matching is case-insensitive against [MemoryCategory.name] only.
/// Never invents a fallback category when the string does not match.
MemoryCategory? validatedCategory(String rawCategoryValue) {
  final normalized = rawCategoryValue.trim().toLowerCase();
  if (normalized.isEmpty) {
    return null;
  }
  for (final category in MemoryCategory.values) {
    if (category.name.toLowerCase() == normalized) {
      return category;
    }
  }
  return null;
}

/// Classifies a verbatim date phrase as [DatePrecision.explicit],
/// [DatePrecision.relative], or [DatePrecision.none].
///
/// Deterministic app logic — the model only copies the phrase.
/// Calendar-shaped phrases (e.g. "15 August", "March 2024") are explicit;
/// relative phrases (e.g. "tomorrow", "next week") stay relative.
DatePrecision classifyDatePrecision(String? dateValueRaw) {
  final raw = dateValueRaw?.trim();
  if (raw == null || raw.isEmpty) {
    return DatePrecision.none;
  }

  final lower = raw.toLowerCase();

  const relativeExact = <String>{
    'today',
    'tonight',
    'tomorrow',
    'yesterday',
  };
  if (relativeExact.contains(lower)) {
    return DatePrecision.relative;
  }

  // next/last/this + unit or weekday
  if (RegExp(
        r'\b(next|last|this)\s+'
        r'(week|month|year|monday|tuesday|wednesday|thursday|friday|'
        r'saturday|sunday)\b',
      ).hasMatch(lower)) {
    return DatePrecision.relative;
  }

  // in N units / N units back|ago
  if (RegExp(
        r'\bin\s+\d+(\.\d+)?\s+(day|week|month|year)s?\b',
      ).hasMatch(lower)) {
    return DatePrecision.relative;
  }
  if (RegExp(
        r'\b\d+(\.\d+)?\s+(day|week|month|year)s?\s+(back|ago)\b',
      ).hasMatch(lower)) {
    return DatePrecision.relative;
  }

  // Bare weekday (treated as relative until resolved against "today")
  if (RegExp(
        r'^(monday|tuesday|wednesday|thursday|friday|saturday|sunday)$',
      ).hasMatch(lower)) {
    return DatePrecision.relative;
  }

  const monthPattern =
      r'(january|february|march|april|may|june|july|august|september|'
      r'october|november|december|jan|feb|mar|apr|jun|jul|aug|sep|sept|'
      r'oct|nov|dec)';
  final hasMonth = RegExp('\\b$monthPattern\\b').hasMatch(lower);
  final hasYear = RegExp(r'\b(19|20)\d{2}\b').hasMatch(lower);
  // Day-of-month: avoid matching years by requiring 1–31 with optional suffix.
  final hasDay = RegExp(
    r'\b([1-9]|[12]\d|3[01])(st|nd|rd|th)?\b',
  ).hasMatch(lower);

  if (hasMonth && (hasDay || hasYear)) {
    return DatePrecision.explicit;
  }

  if (RegExp(r'\b\d{4}-\d{1,2}-\d{1,2}\b').hasMatch(lower)) {
    return DatePrecision.explicit;
  }
  if (RegExp(r'\b\d{1,2}[/-]\d{1,2}([/-]\d{2,4})?\b').hasMatch(lower)) {
    return DatePrecision.explicit;
  }

  // Unknown temporal phrase — keep relative (literal phrase preserved).
  return DatePrecision.relative;
}

/// Resolves [personMentioned] to an existing person when there is exactly one
/// case-insensitive, trimmed name match in [knownPeople].
///
/// Zero or multiple matches → null uuid and 0.0 confidence (confirmation asks).
({String? uuid, double confidence}) resolveUniquePersonNameMatch({
  required String personMentioned,
  required Iterable<({String uuid, String name})> knownPeople,
}) {
  final needle = personMentioned.trim().toLowerCase();
  if (needle.isEmpty) {
    return (uuid: null, confidence: 0.0);
  }

  String? matchUuid;
  for (final person in knownPeople) {
    if (person.name.trim().toLowerCase() == needle) {
      if (matchUuid != null) {
        // Ambiguous — more than one person shares this name.
        return (uuid: null, confidence: 0.0);
      }
      matchUuid = person.uuid;
    }
  }

  if (matchUuid == null) {
    return (uuid: null, confidence: 0.0);
  }
  return (uuid: matchUuid, confidence: 1.0);
}
