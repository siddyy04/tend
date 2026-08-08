import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:my_first_app/ai/providers/embedding/embedding_queue_controller.dart';
import 'package:my_first_app/ai/providers/embedding/noop_embedding_provider.dart';
import 'package:my_first_app/ai/providers/embedding_provider.dart';
import 'package:my_first_app/ai/providers/gecko/gecko_constants.dart';
import 'package:my_first_app/ai/providers/gecko/gecko_embedding_provider.dart';
import 'package:my_first_app/domain/repositories/memory_repository.dart';

/// Foreground-only batched backfill for missing/stale embeddings.
///
/// No workmanager — only progresses while the controller is started.
class EmbeddingBackfillController {
  EmbeddingBackfillController({
    required MemoryRepository memoryRepository,
    required EmbeddingQueueController queue,
    required EmbeddingProvider Function() embeddingProviderReader,
    this.batchSize = 15,
    this.tickInterval = const Duration(seconds: 3),
  })  : _memories = memoryRepository,
        _queue = queue,
        _providerReader = embeddingProviderReader;

  final MemoryRepository _memories;
  final EmbeddingQueueController _queue;
  final EmbeddingProvider Function() _providerReader;
  final int batchSize;
  final Duration tickInterval;

  Timer? _timer;
  var _tickInFlight = false;
  var _captureBusy = false;

  /// When true, backfill skips ticks (capture extraction in progress).
  set captureBusy(bool value) => _captureBusy = value;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(tickInterval, (_) => unawaited(_tick()));
    unawaited(_tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<int> remainingCount() {
    return _memories
        .getMemoriesNeedingEmbedding(
          GeckoConstants.modelVersion,
          limit: null,
        )
        .then((list) => list.length);
  }

  Future<void> _tick() async {
    if (_tickInFlight || _captureBusy) return;
    final provider = _providerReader();
    if (provider is NoOpEmbeddingProvider ||
        provider is! GeckoEmbeddingProvider) {
      return;
    }

    _tickInFlight = true;
    try {
      final batch = await _memories.getMemoriesNeedingEmbedding(
        GeckoConstants.modelVersion,
        limit: batchSize,
      );
      if (batch.isEmpty) return;
      if (kDebugMode) {
        debugPrint('[EmbeddingBackfill] enqueueing ${batch.length}');
      }
      for (final memory in batch) {
        if (_captureBusy) break;
        _queue.enqueue(memory.uuid);
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[EmbeddingBackfill] tick failed: $e\n$st');
      }
    } finally {
      _tickInFlight = false;
    }
  }
}
