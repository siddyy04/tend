import 'dart:async';
import 'dart:collection';

/// Priority for the shared on-device inference mutex (Phase 3.3).
///
/// [extraction] always wins scheduling over [embedding].
enum AiInferencePriority {
  extraction,
  embedding,
}

class _Waiter {
  _Waiter(this.priority) : completer = Completer<void>();

  final AiInferencePriority priority;
  final Completer<void> completer;
}

/// App-wide mutual exclusion for on-device model workloads.
///
/// Gemma-4 extraction and Gecko embedding must never run concurrently.
/// When both are queued, extraction is granted the lock first.
class AiInferenceMutex {
  final Queue<_Waiter> _waiters = Queue<_Waiter>();
  var _locked = false;

  /// Runs [action] while holding the exclusive inference lock.
  Future<T> withLock<T>(
    AiInferencePriority priority,
    Future<T> Function() action,
  ) async {
    await _acquire(priority);
    try {
      return await action();
    } finally {
      _release();
    }
  }

  Future<void> _acquire(AiInferencePriority priority) async {
    if (!_locked && _waiters.isEmpty) {
      _locked = true;
      return;
    }

    final waiter = _Waiter(priority);
    _enqueue(waiter);
    await waiter.completer.future;
  }

  void _enqueue(_Waiter waiter) {
    if (waiter.priority == AiInferencePriority.extraction) {
      // Insert after any existing extraction waiters, before embeddings.
      final list = _waiters.toList();
      var insertAt = 0;
      while (insertAt < list.length &&
          list[insertAt].priority == AiInferencePriority.extraction) {
        insertAt++;
      }
      list.insert(insertAt, waiter);
      _waiters
        ..clear()
        ..addAll(list);
    } else {
      _waiters.add(waiter);
    }
  }

  void _release() {
    if (_waiters.isEmpty) {
      _locked = false;
      return;
    }
    final next = _waiters.removeFirst();
    _locked = true;
    next.completer.complete();
  }
}
