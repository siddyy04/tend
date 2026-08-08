import 'package:my_first_app/ai/providers/search/hybrid_search_models.dart';
import 'package:my_first_app/ai/providers/search/search_provider.dart';

/// Pure Tier 1 + Tier 2 merge helpers (no blending).
HybridSearchResult composeHybridTiers({
  required List<SearchHit> tier1,
  required List<SearchHit> tier2Candidates,
}) {
  final tier1Uuids = {for (final h in tier1) h.memoryUuid};
  final tier2 = <SearchHit>[
    for (final h in tier2Candidates)
      if (!tier1Uuids.contains(h.memoryUuid)) h,
  ];
  return HybridSearchResult(tier1: tier1, tier2: tier2);
}
