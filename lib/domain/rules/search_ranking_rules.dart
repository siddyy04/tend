import 'package:my_first_app/ai/providers/search/search_provider.dart';
import 'package:my_first_app/core/constants/enums.dart';
import 'package:my_first_app/core/constants/memory_category_labels.dart';

/// Pure keyword ranking for Phase 3.1 Search (ADR-008).
///
/// No I/O — unit-testable without Flutter/Isar.

/// Input document for ranking (person name already resolved).
class MemorySearchDocument {
  const MemorySearchDocument({
    required this.memoryUuid,
    required this.personUuid,
    required this.personName,
    required this.eventText,
    required this.category,
    required this.datePrecision,
    this.dateValueRaw,
    this.dateValue,
    this.quoteEvidence,
    required this.createdAt,
  });

  final String memoryUuid;
  final String personUuid;
  final String personName;
  final String eventText;
  final MemoryCategory category;
  final DatePrecision datePrecision;
  final String? dateValueRaw;
  final DateTime? dateValue;
  final String? quoteEvidence;
  final DateTime createdAt;
}

/// Intermediate scored hit before mapping to [SearchHit].
class ScoredMemoryMatch {
  const ScoredMemoryMatch({
    required this.document,
    required this.matchKind,
    required this.matchedInEventText,
    required this.snippet,
  });

  final MemorySearchDocument document;
  final MatchKind matchKind;
  final bool matchedInEventText;
  final String snippet;
}

/// Trim, lowercase, collapse internal whitespace.
String normalizeSearchQuery(String raw) {
  return raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

/// Tokenize a normalized query on whitespace and common punctuation.
List<String> tokenizeSearchQuery(String normalizedQuery) {
  if (normalizedQuery.isEmpty) return const [];
  return normalizedQuery
      .split(RegExp(r'''[\s.,!?;:"“”‘’()\[\]{}\-_/\\|+*=&@#%$^~`<>]+'''))
      .where((t) => t.isNotEmpty)
      .toList(growable: false);
}

/// Format [date] as `YYYY-MM-DD` for substring matching (timeline-compatible).
String formatSearchDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Build lowercase haystacks for a document.
({String eventText, String metadata, String full}) buildSearchHaystacks(
  MemorySearchDocument doc,
) {
  final event = doc.eventText.toLowerCase();
  final parts = <String>[
    doc.category.name,
    memoryCategoryLabel(doc.category).toLowerCase(),
    doc.personName.toLowerCase(),
    if (doc.dateValueRaw != null && doc.dateValueRaw!.trim().isNotEmpty)
      doc.dateValueRaw!.toLowerCase(),
    if (doc.dateValue != null) formatSearchDate(doc.dateValue!),
    if (doc.quoteEvidence != null && doc.quoteEvidence!.trim().isNotEmpty)
      doc.quoteEvidence!.toLowerCase(),
  ];
  final metadata = parts.join(' ');
  final full = '$event $metadata'.trim();
  return (eventText: event, metadata: metadata, full: full);
}

int matchKindTier(MatchKind kind) {
  switch (kind) {
    case MatchKind.exactPhrase:
      return 3;
    case MatchKind.allTerms:
      return 2;
    case MatchKind.partial:
      return 1;
  }
}

/// Classify and score [doc] against [rawQuery]. Returns null if no match.
ScoredMemoryMatch? scoreMemoryAgainstQuery({
  required MemorySearchDocument doc,
  required String rawQuery,
}) {
  final normalized = normalizeSearchQuery(rawQuery);
  if (normalized.isEmpty) return null;

  final haystacks = buildSearchHaystacks(doc);
  final tokens = tokenizeSearchQuery(normalized);

  MatchKind? kind;
  if (haystacks.eventText.contains(normalized) ||
      haystacks.full.contains(normalized)) {
    kind = MatchKind.exactPhrase;
  } else if (tokens.isNotEmpty &&
      tokens.every((t) => haystacks.full.contains(t))) {
    kind = MatchKind.allTerms;
  } else if (tokens.any((t) => haystacks.full.contains(t)) ||
      haystacks.full.contains(normalized)) {
    kind = MatchKind.partial;
  }

  if (kind == null) return null;

  final matchedInEventText = tokens.isEmpty
      ? haystacks.eventText.contains(normalized)
      : haystacks.eventText.contains(normalized) ||
          tokens.any((t) => haystacks.eventText.contains(t));

  return ScoredMemoryMatch(
    document: doc,
    matchKind: kind,
    matchedInEventText: matchedInEventText,
    snippet: buildSearchSnippet(doc.eventText, normalized, tokens),
  );
}

/// Window around the first match in [eventText]; falls back to a prefix.
String buildSearchSnippet(
  String eventText,
  String normalizedQuery,
  List<String> tokens, {
  int radius = 48,
  int maxLen = 120,
}) {
  final trimmed = eventText.trim();
  if (trimmed.isEmpty) return '';

  final lower = trimmed.toLowerCase();
  var idx = lower.indexOf(normalizedQuery);
  var matchLen = normalizedQuery.length;

  if (idx < 0) {
    for (final t in tokens) {
      final i = lower.indexOf(t);
      if (i >= 0) {
        idx = i;
        matchLen = t.length;
        break;
      }
    }
  }

  if (idx < 0) {
    if (trimmed.length <= maxLen) return trimmed;
    return '${trimmed.substring(0, maxLen).trimRight()}…';
  }

  final start = (idx - radius).clamp(0, trimmed.length);
  final end = (idx + matchLen + radius).clamp(0, trimmed.length);
  var snippet = trimmed.substring(start, end).trim();
  if (start > 0) snippet = '…$snippet';
  if (end < trimmed.length) snippet = '$snippet…';
  if (snippet.length > maxLen) {
    snippet = '${snippet.substring(0, maxLen).trimRight()}…';
  }
  return snippet;
}

/// Deterministic sort: MatchKind → eventText boost → recency → uuid.
int compareScoredMemoryMatches(ScoredMemoryMatch a, ScoredMemoryMatch b) {
  final byKind =
      matchKindTier(b.matchKind).compareTo(matchKindTier(a.matchKind));
  if (byKind != 0) return byKind;

  if (a.matchedInEventText != b.matchedInEventText) {
    return a.matchedInEventText ? -1 : 1;
  }

  final aRecency = a.document.dateValue ?? a.document.createdAt;
  final bRecency = b.document.dateValue ?? b.document.createdAt;
  final byRecency = bRecency.compareTo(aRecency);
  if (byRecency != 0) return byRecency;

  return a.document.memoryUuid.compareTo(b.document.memoryUuid);
}

/// Score + sort a corpus. Empty query → empty list.
List<ScoredMemoryMatch> rankMemoriesForQuery({
  required List<MemorySearchDocument> documents,
  required String rawQuery,
}) {
  final normalized = normalizeSearchQuery(rawQuery);
  if (normalized.isEmpty) return const [];

  final scored = <ScoredMemoryMatch>[];
  for (final doc in documents) {
    final match = scoreMemoryAgainstQuery(doc: doc, rawQuery: rawQuery);
    if (match != null) scored.add(match);
  }
  scored.sort(compareScoredMemoryMatches);
  return scored;
}

/// Map a scored match to a [SearchHit].
SearchHit searchHitFromScoredMatch(ScoredMemoryMatch match) {
  final d = match.document;
  return SearchHit(
    memoryUuid: d.memoryUuid,
    personUuid: d.personUuid,
    personName: d.personName,
    eventText: d.eventText,
    snippet: match.snippet,
    category: d.category,
    dateValue: d.dateValue,
    dateValueRaw: d.dateValueRaw,
    datePrecision: d.datePrecision,
    matchKind: match.matchKind,
    matchedInEventText: match.matchedInEventText,
  );
}
