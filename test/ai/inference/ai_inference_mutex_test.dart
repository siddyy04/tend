import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/ai/inference/ai_inference_mutex.dart';

void main() {
  test('extraction is preferred over queued embedding', () async {
    final mutex = AiInferenceMutex();
    final order = <String>[];

    // Hold lock with a slow embedding start after extraction is queued.
    final embeddingStarted = mutex.withLock(
      AiInferencePriority.embedding,
      () async {
        order.add('emb-start');
        await Future<void>.delayed(const Duration(milliseconds: 40));
        order.add('emb-end');
      },
    );

    await Future<void>.delayed(const Duration(milliseconds: 5));

    final extraction = mutex.withLock(
      AiInferencePriority.extraction,
      () async {
        order.add('ext');
      },
    );

    final embeddingWaiting = mutex.withLock(
      AiInferencePriority.embedding,
      () async {
        order.add('emb2');
      },
    );

    await Future.wait([embeddingStarted, extraction, embeddingWaiting]);

    expect(order.first, 'emb-start');
    expect(order.contains('ext'), isTrue);
    // After in-flight embedding ends, extraction should run before emb2.
    final extIdx = order.indexOf('ext');
    final emb2Idx = order.indexOf('emb2');
    expect(extIdx, lessThan(emb2Idx));
  });
}
