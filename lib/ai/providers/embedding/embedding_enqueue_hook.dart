import 'package:my_first_app/ai/providers/embedding/embedding_queue_controller.dart';

/// Thin fire-and-forget API used after Memory persistence.
class EmbeddingEnqueueHook {
  EmbeddingEnqueueHook(this._queue);

  final EmbeddingQueueController _queue;

  void enqueue(String memoryUuid) => _queue.enqueue(memoryUuid);
}
