import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/core/constants/enums.dart';

/// Capture-funnel analytics hooks (Sprint 2B.7).
///
/// Not wired to a backend yet — [NoOpCaptureAnalytics] logs in debug only.
/// Replace via [captureAnalyticsProvider] when product analytics ships.
abstract class CaptureAnalytics {
  void extractionStarted({required SourceType sourceType});

  void extractionCompleted({
    required SourceType sourceType,
    required Duration duration,
    required int memoryCount,
  });

  void extractionEmpty({required SourceType sourceType});

  void extractionFailed({required SourceType sourceType});

  void memoriesApproved({required int count});

  void memoriesRejected({required int count});

  void memoryEdited({required int fieldCount});

  void personCreatedDuringConfirmation();
}

/// Default no-op / debug-print sink until analytics infrastructure exists.
class NoOpCaptureAnalytics implements CaptureAnalytics {
  const NoOpCaptureAnalytics();

  void _log(String event, [Map<String, Object?>? props]) {
    assert(() {
      debugPrint('[CaptureAnalytics] $event ${props ?? const {}}');
      return true;
    }());
  }

  @override
  void extractionStarted({required SourceType sourceType}) {
    _log('extraction_started', {'sourceType': sourceType.name});
  }

  @override
  void extractionCompleted({
    required SourceType sourceType,
    required Duration duration,
    required int memoryCount,
  }) {
    _log('extraction_completed', {
      'sourceType': sourceType.name,
      'durationMs': duration.inMilliseconds,
      'memoryCount': memoryCount,
    });
  }

  @override
  void extractionEmpty({required SourceType sourceType}) {
    _log('extraction_empty', {'sourceType': sourceType.name});
  }

  @override
  void extractionFailed({required SourceType sourceType}) {
    _log('extraction_failed', {'sourceType': sourceType.name});
  }

  @override
  void memoriesApproved({required int count}) {
    _log('memories_approved', {'count': count});
  }

  @override
  void memoriesRejected({required int count}) {
    _log('memories_rejected', {'count': count});
  }

  @override
  void memoryEdited({required int fieldCount}) {
    _log('memory_edited', {'fieldCount': fieldCount});
  }

  @override
  void personCreatedDuringConfirmation() {
    _log('person_created_during_confirmation');
  }
}

final captureAnalyticsProvider = Provider<CaptureAnalytics>((ref) {
  return const NoOpCaptureAnalytics();
});
