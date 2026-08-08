import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/ai/model_manager/embedding_model_catalog.dart';
import 'package:my_first_app/ai/model_manager/embedding_model_manager.dart';
import 'package:my_first_app/ai/model_manager/model_download_manager.dart';
import 'package:my_first_app/ai/model_manager/model_manager_providers.dart';
import 'package:my_first_app/ai/providers/ai_provider_selection.dart';
import 'package:my_first_app/ai/providers/gecko/gecko_constants.dart';

/// Settings row for optional Gecko embedder download / defer / retry.
class GeckoModelSettingsTile extends ConsumerStatefulWidget {
  const GeckoModelSettingsTile({super.key});

  @override
  ConsumerState<GeckoModelSettingsTile> createState() =>
      _GeckoModelSettingsTileState();
}

class _GeckoModelSettingsTileState
    extends ConsumerState<GeckoModelSettingsTile> {
  var _busy = false;
  String? _error;
  double? _progress;

  Future<void> _download() async {
    setState(() {
      _busy = true;
      _error = null;
      _progress = 0;
    });
    try {
      final manager = ref.read(embeddingModelManagerProvider);
      await manager.ensureFilesDownloaded(
        onProgress: (p) {
          if (!mounted) return;
          setState(() => _progress = p.fraction);
        },
      );
      final adapter = ref.read(geckoInferenceAdapterProvider);
      await adapter.prepare(
        onDownloadProgress: (f) {
          if (!mounted) return;
          setState(() => _progress = f);
        },
      );
      ref.invalidate(geckoEmbedderStatusProvider);
    } on ModelPrepareException catch (e) {
      setState(() => _error = e.userMessage);
    } catch (e) {
      setState(() => _error = 'Could not prepare semantic search model.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decline() async {
    await ref.read(embeddingModelManagerProvider).setDeclined(true);
    ref.invalidate(geckoEmbedderStatusProvider);
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(geckoEmbedderStatusProvider);
    final sizeLabel = EmbeddingModelCatalog.geckoModel.downloadSizeLabel;

    return statusAsync.when(
      loading: () => const ListTile(
        title: Text('Semantic search model'),
        subtitle: Text('Checking…'),
      ),
      error: (e, _) => ListTile(
        title: const Text('Semantic search model'),
        subtitle: Text('Status unavailable: $e'),
      ),
      data: (status) {
        String subtitle;
        switch (status) {
          case GeckoEmbedderStatus.runtimeReady:
            subtitle =
                'Ready (${GeckoConstants.modelVersion}). Improves paraphrase search.';
          case GeckoEmbedderStatus.filesReady:
            subtitle = 'Downloaded — tap to finish preparing.';
          case GeckoEmbedderStatus.declined:
            subtitle =
                'Declined. Keyword search still works. You can download later ($sizeLabel).';
          case GeckoEmbedderStatus.notDownloaded:
            subtitle =
                'Optional. Adds “possibly related” results ($sizeLabel). '
                'Keyword search works without it.';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              title: const Text('Semantic search model (Gecko)'),
              subtitle: Text(subtitle),
              isThreeLine: true,
            ),
            if (_busy)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LinearProgressIndicator(value: _progress),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Wrap(
                spacing: 8,
                children: [
                  if (status != GeckoEmbedderStatus.runtimeReady)
                    FilledButton(
                      onPressed: _busy ? null : _download,
                      child: Text(
                        status == GeckoEmbedderStatus.declined
                            ? 'Download'
                            : status == GeckoEmbedderStatus.filesReady
                                ? 'Prepare'
                                : 'Download ($sizeLabel)',
                      ),
                    ),
                  if (status == GeckoEmbedderStatus.notDownloaded ||
                      status == GeckoEmbedderStatus.filesReady)
                    TextButton(
                      onPressed: _busy ? null : _decline,
                      child: const Text('Not now'),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
