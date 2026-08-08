import 'package:my_first_app/ai/providers/search/hybrid_search_models.dart';
import 'package:my_first_app/ai/providers/search/search_provider.dart';
import 'package:my_first_app/domain/rules/hybrid_search_rules.dart';

/// Merges Tier 1 (keyword) and Tier 2 (semantic) without blending scores.
class HybridResultComposer {
  const HybridResultComposer();

  HybridSearchResult compose({
    required List<SearchHit> tier1,
    required List<SearchHit> tier2Candidates,
  }) {
    return composeHybridTiers(
      tier1: tier1,
      tier2Candidates: tier2Candidates,
    );
  }
}
