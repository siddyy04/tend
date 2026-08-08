import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:my_first_app/ai/providers/embedding/noop_embedding_provider.dart';
import 'package:my_first_app/ai/providers/embedding_provider.dart';
import 'package:my_first_app/ai/providers/gecko/gecko_constants.dart';
import 'package:my_first_app/ai/providers/gecko/gecko_embedding_provider.dart';
import 'package:my_first_app/domain/repositories/memory_repository.dart';
import 'package:my_first_app/domain/rules/embedding_similarity_rules.dart';

/// Sequential, coalescing embed queue for post-persist work.
class EmbeddingQueueController {
  EmbeddingQueueController({
    required MemoryRepository memoryRepository,
    required EmbeddingProvider Function() embeddingProviderReader,
  })  : _memories = memoryRepository,
        _providerReader = embeddingProviderReader;

  final MemoryRepository _memories;
  final EmbeddingProvider Function() _providerReader;

  final Queue<String> _pending = Queue<String>();
  final Set<String> _queued = {};
  final Map<String, int> _attempts = {};
  var _pumping = false;

  static const maxAttempts = 3;

  /// Fire-and-forget enqueue. Coalesces duplicate uuids.
  void enqueue(String memoryUuid) {
    final id = memoryUuid.trim();
    if (id.isEmpty) return;
    if (_queued.contains(id)) return;
    _queued.add(id);
    _pending.add(id);
    unawaited(_pump());
  }

  Future<void> _pump() async {
    if (_pumping) return;
    _pumping = true;
    try {
      while (_pending.isNotEmpty) {
        final uuid = _pending.removeFirst();
        _queued.remove(uuid);
        await _process(uuid);
      }
    } finally {
      _pumping = false;
      if (_pending.isNotEmpty) {
        unawaited(_pump());
      }
    }
  }

  Future<void> _process(String uuid) async {
    final provider = _providerReader();
    if (provider is NoOpEmbeddingProvider || provider is! GeckoEmbeddingProvider) {
      // Not ready — leave for backfill once Gecko is available.
      return;
    }

    try {
      final memory = await _memories.getByUuid(uuid);
      if (memory == null) return;
      final text = memory.eventText.trim();
      if (text.isEmpty) return;

      if (isValidEmbedding(
        embedding: memory.embedding,
        embeddingModelVersion: memory.embeddingModelVersion,
        currentVersion: GeckoConstants.modelVersion,
        expectedDimension: GeckoConstants.dimension,
      )) {
        _attempts.remove(uuid);
        return;
      }

      final vector = await provider.embedDocument(text);
      if (vector.length != GeckoConstants.dimension) {
        throw StateError('Unexpected embedding length ${vector.length}');
      }

      await _memories.updateEmbedding(
        uuid: uuid,
        embedding: vector,
        embeddingModelVersion: GeckoConstants.modelVersion,
      );
      _attempts.remove(uuid);
    } catch (e, st) {
      final n = (_attempts[uuid] ?? 0) + 1;
      _attempts[uuid] = n;
      if (kDebugMode) {
        debugPrint('[EmbeddingQueue] fail uuid=$uuid attempt=$n error=$e');
        debugPrint('$st');
      }
      if (n < maxAttempts) {
        final delay = Duration(seconds: 1 << (n - 1));
        await Future<void>.delayed(delay);
        enqueue(uuid);
      }
      // else: leave stale for backfill later
    }
  }
}
