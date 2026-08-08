import 'package:my_first_app/core/constants/enums.dart';

/// Pluggable local search ranking strategy (Phase 3.1+).
///
/// UI and controllers depend only on this interface — never on a concrete
/// keyword/semantic implementation.
abstract class SearchProvider {
  Future<List<SearchHit>> search(SearchQuery query);
}

enum SearchScope { global, person }

enum MatchKind { exactPhrase, allTerms, partial }

class SearchQuery {
  const SearchQuery({
    required this.text,
    required this.scope,
    this.personUuid,
  }) : assert(
          scope != SearchScope.person || personUuid != null,
          'personUuid is required when scope is person',
        );

  final String text;
  final SearchScope scope;

  /// Required when [scope] is [SearchScope.person].
  final String? personUuid;
}

class SearchHit {
  const SearchHit({
    required this.memoryUuid,
    required this.personUuid,
    required this.personName,
    required this.eventText,
    required this.snippet,
    required this.category,
    required this.dateValue,
    required this.dateValueRaw,
    required this.datePrecision,
    required this.matchKind,
    required this.matchedInEventText,
  });

  final String memoryUuid;
  final String personUuid;
  final String personName;
  final String eventText;
  final String snippet;
  final MemoryCategory category;
  final DateTime? dateValue;
  final String? dateValueRaw;
  final DatePrecision datePrecision;
  final MatchKind matchKind;
  final bool matchedInEventText;
}
