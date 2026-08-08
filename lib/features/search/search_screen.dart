import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/ai/providers/search/search_provider.dart';
import 'package:my_first_app/app/app_routes.dart';
import 'package:my_first_app/features/person_profile/person_profile_screen.dart';
import 'package:my_first_app/features/search/search_controller.dart';
import 'package:my_first_app/features/search/widgets/search_empty_state.dart';
import 'package:my_first_app/features/search/widgets/search_query_field.dart';
import 'package:my_first_app/features/search/widgets/search_results_list.dart';

/// Shared body for global and person-scoped Search screens.
class SearchView extends ConsumerStatefulWidget {
  const SearchView({
    super.key,
    required this.args,
    this.personName,
  });

  final SearchControllerArgs args;
  final String? personName;

  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  late final TextEditingController _textController;

  bool get _isPersonScoped => widget.args.scope == SearchScope.person;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(searchControllerProvider(widget.args).notifier);
    final ui = ref.watch(searchControllerProvider(widget.args));
    final showPerson = widget.args.scope == SearchScope.global;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SearchQueryField(
            controller: _textController,
            onChanged: controller.onQueryChanged,
            onClear: () {
              _textController.clear();
              controller.clearQuery();
            },
            hintText: _isPersonScoped
                ? 'Search this person’s memories…'
                : 'Ask about a memory…',
          ),
        ),
        Expanded(child: _buildBody(context, ui, controller, showPerson)),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    SearchUiState ui,
    SearchController controller,
    bool showPerson,
  ) {
    if (ui.isIdle) {
      return SearchEmptyState(
        kind: SearchEmptyKind.idle,
        isPersonScoped: _isPersonScoped,
        personName: widget.personName,
      );
    }

    return ui.results.when(
      loading: () => Semantics(
        liveRegion: true,
        label: 'Searching',
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(error.toString(), textAlign: TextAlign.center),
        ),
      ),
      data: (hits) {
        if (hits.isEmpty && ui.hasCompletedSearch) {
          if (ui.corpusEmpty) {
            return SearchEmptyState(
              kind: SearchEmptyKind.noCorpus,
              isPersonScoped: _isPersonScoped,
              personName: widget.personName,
              onAddMemory: _isPersonScoped && widget.args.personUuid != null
                  ? () => context.push(
                        AppRoutes.memoryNew(widget.args.personUuid!),
                      )
                  : null,
              onOpenCapture: !_isPersonScoped
                  ? () => context.push(AppRoutes.capture)
                  : null,
            );
          }
          return SearchEmptyState(
            kind: SearchEmptyKind.noResults,
            isPersonScoped: _isPersonScoped,
            personName: widget.personName,
          );
        }

        return SearchResultsList(
          hits: hits,
          showPersonAttribution: showPerson,
          onHitTap: (hit, index) {
            controller.onResultTapped(hit, index);
            context.openPersonProfile(hit.personUuid);
          },
        );
      },
    );
  }
}

/// Global Search tab — keyword recall across the Circle.
class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: const SearchView(args: SearchControllerArgs.global()),
    );
  }
}
