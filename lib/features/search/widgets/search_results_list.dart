import 'package:flutter/material.dart';
import 'package:my_first_app/ai/providers/search/hybrid_search_models.dart';
import 'package:my_first_app/ai/providers/search/search_provider.dart';
import 'package:my_first_app/features/search/widgets/search_result_tile.dart';

/// Tiered hybrid results: keyword Tier 1, then optional “Possibly related” Tier 2.
class SearchResultsList extends StatelessWidget {
  const SearchResultsList({
    super.key,
    required this.result,
    required this.showPersonAttribution,
    required this.onHitTap,
    this.tier2Loading = false,
  });

  final HybridSearchResult result;
  final bool showPersonAttribution;
  final void Function(SearchHit hit, int index) onHitTap;
  final bool tier2Loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final children = <Widget>[];

    for (var i = 0; i < result.tier1.length; i++) {
      final hit = result.tier1[i];
      if (i > 0) {
        children.add(const Divider(height: 1));
      }
      children.add(
        SearchResultTile(
          hit: hit,
          showPersonAttribution: showPersonAttribution,
          onTap: () => onHitTap(hit, i),
        ),
      );
    }

    if (tier2Loading) {
      children.add(
        Semantics(
          liveRegion: true,
          label: 'Finding related memories',
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Finding related memories…'),
              ],
            ),
          ),
        ),
      );
    }

    if (result.tier2.isNotEmpty) {
      children.add(
        Semantics(
          header: true,
          label: 'Possibly related results',
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Possibly related',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < result.tier2.length; i++) {
        final hit = result.tier2[i];
        final globalIndex = result.tier1.length + i;
        children.add(const Divider(height: 1));
        children.add(
          SearchResultTile(
            hit: hit,
            showPersonAttribution: showPersonAttribution,
            possiblyRelated: true,
            onTap: () => onHitTap(hit, globalIndex),
          ),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: children,
    );
  }
}
