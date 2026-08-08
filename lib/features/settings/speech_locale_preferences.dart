import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _speechLocaleIdKey = 'tend.speech_locale_id';

/// Persisted speech recognition language preference (provider-agnostic).
///
/// Stored as a locale id string (e.g. `en_US`). Used by platform STT today and
/// intended for future long-form transcription providers as well.
class SpeechLocalePreferences {
  SpeechLocalePreferences({SharedPreferences? preferences})
      : _prefsOverride = preferences;

  final SharedPreferences? _prefsOverride;
  SharedPreferences? _prefs;

  Future<SharedPreferences> _preferences() async {
    return _prefs ??= _prefsOverride ?? await SharedPreferences.getInstance();
  }

  Future<String?> getLocaleId() async {
    final prefs = await _preferences();
    return prefs.getString(_speechLocaleIdKey);
  }

  Future<void> setLocaleId(String localeId) async {
    final prefs = await _preferences();
    await prefs.setString(_speechLocaleIdKey, localeId.trim());
  }

  Future<void> clearLocaleId() async {
    final prefs = await _preferences();
    await prefs.remove(_speechLocaleIdKey);
  }
}

final speechLocalePreferencesProvider = Provider<SpeechLocalePreferences>((ref) {
  return SpeechLocalePreferences();
});
