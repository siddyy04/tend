import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/ai/providers/ai_provider_selection.dart';
import 'package:my_first_app/ai/providers/search/hybrid_search_models.dart';
import 'package:my_first_app/ai/providers/search/keyword_search_provider.dart';
import 'package:my_first_app/ai/providers/search/search_provider.dart';
import 'package:my_first_app/core/analytics/search_analytics.dart';
import 'package:my_first_app/domain/repositories/memory_repository.dart';
import 'package:my_first_app/features/circle/circle_providers.dart';
import 'package:my_first_app/features/person_profile/person_profile_providers.dart';
import 'package:my_first_app/domain/rules/search_ranking_rules.dart';

/// DI: concrete keyword search behind the pluggable [SearchProvider] interface.
final activeSearchProvider = Provider<SearchProvider>((ref) {
  return KeywordSearchProvider(
    memoryRepository: ref.watch(memoryRepositoryProvider),
    personRepository: ref.watch(personRepositoryProvider),
  );
});

/// Scope key for [searchControllerProvider].
class SearchControllerArgs {
  const SearchControllerArgs.global()
      : scope = SearchScope.global,
        personUuid = null;

  const SearchControllerArgs.person(this.personUuid)
      : scope = SearchScope.person;

  final SearchScope scope;
  final String? personUuid;

  @override
  bool operator ==(Object other) {
    return other is SearchControllerArgs &&
        other.scope == scope &&
        other.personUuid == personUuid;
  }

  @override
  int get hashCode => Object.hash(scope, personUuid);
}

class SearchUiState {
  const SearchUiState({
    this.query = '',
    this.results = const AsyncData(HybridSearchResult.empty),
    this.corpusEmpty = false,
    this.hasCompletedSearch = false,
    this.tier2Loading = false,
  });

  final String query;
  final AsyncValue<HybridSearchResult> results;

  /// True when the scoped corpus has zero active memories.
  final bool corpusEmpty;

  /// True after a debounced non-empty query has finished Tier 1 (success or error).
  final bool hasCompletedSearch;

  /// True while Tier 2 is still computing after Tier 1 painted.
  final bool tier2Loading;

  bool get isIdle => normalizeSearchQuery(query).isEmpty;

  SearchUiState copyWith({
    String? query,
    AsyncValue<HybridSearchResult>? results,
    bool? corpusEmpty,
    bool? hasCompletedSearch,
    bool? tier2Loading,
  }) {
    return SearchUiState(
      query: query ?? this.query,
      results: results ?? this.results,
      corpusEmpty: corpusEmpty ?? this.corpusEmpty,
      hasCompletedSearch: hasCompletedSearch ?? this.hasCompletedSearch,
      tier2Loading: tier2Loading ?? this.tier2Loading,
    );
  }
}

final searchControllerProvider = NotifierProvider.autoDispose
    .family<SearchController, SearchUiState, SearchControllerArgs>(
  SearchController.new,
);

class SearchController extends Notifier<SearchUiState> {
  SearchController(this.args);

  final SearchControllerArgs args;

  static const debounce = Duration(milliseconds: 300);

  Timer? _debounce;
  int _requestId = 0;

  @override
  SearchUiState build() {
    ref.onDispose(() {
      _debounce?.cancel();
    });
    // Warm backfill controller while Search is used.
    ref.watch(embeddingBackfillControllerProvider);
    return const SearchUiState();
  }

  void onQueryChanged(String raw) {
    state = state.copyWith(query: raw);
    _debounce?.cancel();

    final normalized = normalizeSearchQuery(raw);
    if (normalized.isEmpty) {
      _requestId++;
      state = state.copyWith(
        results: const AsyncData(HybridSearchResult.empty),
        hasCompletedSearch: false,
        corpusEmpty: false,
        tier2Loading: false,
      );
      return;
    }

    _debounce = Timer(debounce, () => _runSearch(normalized));
  }

  void clearQuery() => onQueryChanged('');

  Future<void> _runSearch(String normalizedQuery) async {
    final id = ++_requestId;
    state = state.copyWith(
      results: const AsyncLoading(),
      tier2Loading: false,
    );

    try {
      final keyword = ref.read(activeSearchProvider);
      final analytics = ref.read(searchAnalyticsProvider);
      final memoryRepo = ref.read(memoryRepositoryProvider);
      final composer = ref.read(hybridResultComposerProvider);

      final query = SearchQuery(
        text: normalizedQuery,
        scope: args.scope,
        personUuid: args.personUuid,
      );

      // Tier 1 first — protect keyword latency.
      final tier1 = await keyword.search(query);
      if (id != _requestId) return;

      final corpusEmpty = await _isCorpusEmpty(memoryRepo);
      if (id != _requestId) return;

      final partial = composer.compose(tier1: tier1, tier2Candidates: const []);
      analytics.searchPerformed(
        query: normalizedQuery,
        resultCount: partial.totalCount,
        scope: args.scope,
        personUuid: args.personUuid,
      );

      state = state.copyWith(
        results: AsyncData(partial),
        corpusEmpty: corpusEmpty,
        hasCompletedSearch: true,
        tier2Loading: true,
      );

      // Tier 2 — additive; failures stay Tier-1-only.
      final semantic = ref.read(semanticSearchProvider);
      List<SearchHit> tier2 = const [];
      if (semantic != null) {
        tier2 = await semantic.search(query);
      }
      if (id != _requestId) return;

      final hybrid = composer.compose(tier1: tier1, tier2Candidates: tier2);
      state = state.copyWith(
        results: AsyncData(hybrid),
        tier2Loading: false,
      );
    } catch (e, st) {
      if (id != _requestId) return;
      state = state.copyWith(
        results: AsyncError(e, st),
        hasCompletedSearch: true,
        tier2Loading: false,
      );
    }
  }

  Future<bool> _isCorpusEmpty(MemoryRepository memoryRepo) async {
    if (args.scope == SearchScope.person) {
      final list =
          await memoryRepo.getActiveMemoriesForPerson(args.personUuid!);
      return list.isEmpty;
    }
    final list = await memoryRepo.getActiveMemories();
    return list.isEmpty;
  }

  void onResultTapped(SearchHit hit, int index) {
    final query = normalizeSearchQuery(state.query);
    ref.read(searchAnalyticsProvider).searchResultTapped(
          query: query,
          memoryUuid: hit.memoryUuid,
          personUuid: hit.personUuid,
          resultIndex: index,
          scope: args.scope,
        );
  }
}
