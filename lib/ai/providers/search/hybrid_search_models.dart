import 'package:my_first_app/ai/providers/search/search_provider.dart';

/// Result of tiered hybrid search (Phase 3.3) — never a blended score list.
class HybridSearchResult {
  const HybridSearchResult({
    required this.tier1,
    required this.tier2,
  });

  /// Keyword hits — Phase 3.1 order, unmodified.
  final List<SearchHit> tier1;

  /// Semantic-only hits — not present in [tier1].
  final List<SearchHit> tier2;

  bool get isEmpty => tier1.isEmpty && tier2.isEmpty;

  int get totalCount => tier1.length + tier2.length;

  static const empty = HybridSearchResult(tier1: [], tier2: []);
}

enum SearchResultTier { keyword, semantic }
