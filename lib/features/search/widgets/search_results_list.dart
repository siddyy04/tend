import 'package:flutter/material.dart';
import 'package:my_first_app/ai/providers/search/search_provider.dart';
import 'package:my_first_app/features/search/widgets/search_result_tile.dart';

/// Flat ranked list of search hits (never grouped by person).
class SearchResultsList extends StatelessWidget {
  const SearchResultsList({
    super.key,
    required this.hits,
    required this.showPersonAttribution,
    required this.onHitTap,
  });

  final List<SearchHit> hits;
  final bool showPersonAttribution;
  final void Function(SearchHit hit, int index) onHitTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: hits.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final hit = hits[index];
        return SearchResultTile(
          hit: hit,
          showPersonAttribution: showPersonAttribution,
          onTap: () => onHitTap(hit, index),
        );
      },
    );
  }
}
