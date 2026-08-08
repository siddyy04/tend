import 'package:flutter/material.dart';
import 'package:my_first_app/core/constants/memory_category_labels.dart';
import 'package:my_first_app/ai/providers/search/search_provider.dart';
import 'package:my_first_app/domain/rules/search_ranking_rules.dart';

/// One flat search result row — memory card, not a chatbot answer.
class SearchResultTile extends StatelessWidget {
  const SearchResultTile({
    super.key,
    required this.hit,
    required this.showPersonAttribution,
    required this.onTap,
  });

  final SearchHit hit;
  final bool showPersonAttribution;
  final VoidCallback onTap;

  String _dateLabel() {
    if (hit.dateValue != null) {
      return formatSearchDate(hit.dateValue!);
    }
    if (hit.dateValueRaw != null && hit.dateValueRaw!.trim().isNotEmpty) {
      return hit.dateValueRaw!.trim();
    }
    return 'No date';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta =
        '${memoryCategoryLabel(hit.category)} · ${_dateLabel()}';
    final semanticLabel = showPersonAttribution
        ? '${hit.personName}. ${hit.snippet}. $meta'
        : '${hit.snippet}. $meta';

    return Semantics(
      button: true,
      label: semanticLabel,
      child: ListTile(
        title: Text(
          hit.snippet,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          showPersonAttribution ? '${hit.personName} · $meta' : meta,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: onTap,
      ),
    );
  }
}
