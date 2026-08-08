import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/ai/providers/search/search_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Search analytics hooks (Phase 3.1).
///
/// On-device only — never syncs to Supabase or a remote sink.
abstract class SearchAnalytics {
  void searchPerformed({
    required String query,
    required int resultCount,
    required SearchScope scope,
    String? personUuid,
  });

  void searchResultTapped({
    required String query,
    required String memoryUuid,
    required String personUuid,
    required int resultIndex,
    required SearchScope scope,
  });
}

/// Debug print + durable local append-only log (capped).
class LocalSearchAnalytics implements SearchAnalytics {
  LocalSearchAnalytics({
    SharedPreferences? preferences,
    this.maxEntries = 200,
  }) : _prefsOverride = preferences;

  static const prefsKey = 'search_query_log_v1';

  final SharedPreferences? _prefsOverride;
  final int maxEntries;
  SharedPreferences? _prefs;

  Future<SharedPreferences> _preferences() async {
    return _prefs ??= _prefsOverride ?? await SharedPreferences.getInstance();
  }

  void _debug(String event, Map<String, Object?> props) {
    assert(() {
      debugPrint('[SearchAnalytics] $event $props');
      return true;
    }());
  }

  Future<void> _append(Map<String, Object?> entry) async {
    try {
      final prefs = await _preferences();
      final raw = prefs.getString(prefsKey);
      final list = <Map<String, Object?>>[];
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              list.add(Map<String, Object?>.from(item));
            }
          }
        }
      }
      list.insert(0, {
        ...entry,
        'at': DateTime.now().toIso8601String(),
      });
      while (list.length > maxEntries) {
        list.removeLast();
      }
      await prefs.setString(prefsKey, jsonEncode(list));
    } catch (e, st) {
      assert(() {
        debugPrint('[SearchAnalytics] log append failed: $e\n$st');
        return true;
      }());
    }
  }

  @override
  void searchPerformed({
    required String query,
    required int resultCount,
    required SearchScope scope,
    String? personUuid,
  }) {
    final props = <String, Object?>{
      'query': query,
      'resultCount': resultCount,
      'scope': scope.name,
      'personUuid': ?personUuid,
    };
    _debug('search_performed', props);
    // Fire-and-forget durable log (on-device).
    // ignore: unawaited_futures
    _append({'event': 'search_performed', ...props});
  }

  @override
  void searchResultTapped({
    required String query,
    required String memoryUuid,
    required String personUuid,
    required int resultIndex,
    required SearchScope scope,
  }) {
    final props = <String, Object?>{
      'query': query,
      'memoryUuid': memoryUuid,
      'personUuid': personUuid,
      'resultIndex': resultIndex,
      'scope': scope.name,
    };
    _debug('search_result_tapped', props);
    // ignore: unawaited_futures
    _append({'event': 'search_result_tapped', ...props});
  }
}

/// Debug-only sink when durable logging is not desired (tests).
class NoOpSearchAnalytics implements SearchAnalytics {
  const NoOpSearchAnalytics();

  void _log(String event, [Map<String, Object?>? props]) {
    assert(() {
      debugPrint('[SearchAnalytics] $event ${props ?? const {}}');
      return true;
    }());
  }

  @override
  void searchPerformed({
    required String query,
    required int resultCount,
    required SearchScope scope,
    String? personUuid,
  }) {
    _log('search_performed', {
      'query': query,
      'resultCount': resultCount,
      'scope': scope.name,
      'personUuid': ?personUuid,
    });
  }

  @override
  void searchResultTapped({
    required String query,
    required String memoryUuid,
    required String personUuid,
    required int resultIndex,
    required SearchScope scope,
  }) {
    _log('search_result_tapped', {
      'query': query,
      'memoryUuid': memoryUuid,
      'personUuid': personUuid,
      'resultIndex': resultIndex,
      'scope': scope.name,
    });
  }
}

final searchAnalyticsProvider = Provider<SearchAnalytics>((ref) {
  return LocalSearchAnalytics();
});
