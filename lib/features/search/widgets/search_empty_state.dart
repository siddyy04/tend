import 'package:flutter/material.dart';

enum SearchEmptyKind {
  /// Blank query — coaching examples.
  idle,

  /// Circle / person has no memories yet.
  noCorpus,

  /// Query ran; nothing matched.
  noResults,
}

/// Helpful empty / idle states for Search (required, not afterthoughts).
class SearchEmptyState extends StatelessWidget {
  const SearchEmptyState({
    super.key,
    required this.kind,
    this.isPersonScoped = false,
    this.personName,
    this.onAddMemory,
    this.onOpenCapture,
  });

  final SearchEmptyKind kind;
  final bool isPersonScoped;
  final String? personName;
  final VoidCallback? onAddMemory;
  final VoidCallback? onOpenCapture;

  static const exampleQueries = [
    'What did Mom say about physiotherapy?',
    'Who mentioned Bangalore?',
    'Promises about a gift',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (icon, title, body) = switch (kind) {
      SearchEmptyKind.idle => (
          Icons.search,
          isPersonScoped
              ? 'Search memories${personName != null ? ' about $personName' : ''}'
              : 'Ask about a memory',
          isPersonScoped
              ? 'Try a name, place, or phrase from something you captured.'
              : 'Search across your Circle using your own words.',
        ),
      SearchEmptyKind.noCorpus => (
          Icons.notes_outlined,
          isPersonScoped ? 'No memories yet' : 'Nothing to search yet',
          isPersonScoped
              ? 'Add a memory for this person, then search will find it instantly.'
              : 'Capture a memory first — Search works on what you have saved.',
        ),
      SearchEmptyKind.noResults => (
          Icons.search_off_outlined,
          'No matching memories',
          'Try different words, a shorter phrase, a name, or a place. '
              'Search matches the text you captured — it does not invent answers.',
        ),
    };

    return Semantics(
      liveRegion: kind == SearchEmptyKind.noResults,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 56,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (kind == SearchEmptyKind.idle) ...[
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Try asking',
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                const SizedBox(height: 8),
                for (final example in exampleQueries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '“$example”',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
              ],
              if (kind == SearchEmptyKind.noCorpus) ...[
                const SizedBox(height: 24),
                if (isPersonScoped && onAddMemory != null)
                  FilledButton.icon(
                    onPressed: onAddMemory,
                    icon: const Icon(Icons.add),
                    label: const Text('Add memory'),
                  )
                else if (!isPersonScoped && onOpenCapture != null)
                  FilledButton.icon(
                    onPressed: onOpenCapture,
                    icon: const Icon(Icons.edit_note_outlined),
                    label: const Text('Capture a memory'),
                  ),
              ],
              if (kind == SearchEmptyKind.noResults) ...[
                const SizedBox(height: 16),
                Text(
                  'Examples: a shorter word, a person’s name, or a place.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
