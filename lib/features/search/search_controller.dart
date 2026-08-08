import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    this.results = const AsyncData(<SearchHit>[]),
    this.corpusEmpty = false,
    this.hasCompletedSearch = false,
  });

  final String query;
  final AsyncValue<List<SearchHit>> results;

  /// True when the scoped corpus has zero active memories.
  final bool corpusEmpty;

  /// True after a debounced non-empty query has finished (success or error).
  final bool hasCompletedSearch;

  bool get isIdle => normalizeSearchQuery(query).isEmpty;

  SearchUiState copyWith({
    String? query,
    AsyncValue<List<SearchHit>>? results,
    bool? corpusEmpty,
    bool? hasCompletedSearch,
  }) {
    return SearchUiState(
      query: query ?? this.query,
      results: results ?? this.results,
      corpusEmpty: corpusEmpty ?? this.corpusEmpty,
      hasCompletedSearch: hasCompletedSearch ?? this.hasCompletedSearch,
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
    return const SearchUiState();
  }

  void onQueryChanged(String raw) {
    state = state.copyWith(query: raw);
    _debounce?.cancel();

    final normalized = normalizeSearchQuery(raw);
    if (normalized.isEmpty) {
      _requestId++;
      state = state.copyWith(
        results: const AsyncData(<SearchHit>[]),
        hasCompletedSearch: false,
        corpusEmpty: false,
      );
      return;
    }

    _debounce = Timer(debounce, () => _runSearch(normalized));
  }

  void clearQuery() => onQueryChanged('');

  Future<void> _runSearch(String normalizedQuery) async {
    final id = ++_requestId;
    state = state.copyWith(results: const AsyncLoading());

    try {
      final search = ref.read(activeSearchProvider);
      final analytics = ref.read(searchAnalyticsProvider);
      final memoryRepo = ref.read(memoryRepositoryProvider);

      final query = SearchQuery(
        text: normalizedQuery,
        scope: args.scope,
        personUuid: args.personUuid,
      );

      final hits = await search.search(query);
      if (id != _requestId) return;

      final corpusEmpty = await _isCorpusEmpty(memoryRepo);
      if (id != _requestId) return;

      analytics.searchPerformed(
        query: normalizedQuery,
        resultCount: hits.length,
        scope: args.scope,
        personUuid: args.personUuid,
      );

      state = state.copyWith(
        results: AsyncData(hits),
        corpusEmpty: corpusEmpty,
        hasCompletedSearch: true,
      );
    } catch (e, st) {
      if (id != _requestId) return;
      state = state.copyWith(
        results: AsyncError(e, st),
        hasCompletedSearch: true,
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
