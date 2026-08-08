import 'package:my_first_app/ai/providers/transcription_provider.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Platform ASR via `speech_to_text` — never touches LiteRT / Gemma.
///
/// Sprint 2B.4 MVP. Suitable for short-to-medium notes; Android session /
/// pause limits make this a poor long-term fit for conversational dictation.
/// Swap via [activeTranscriptionProvider] when a long-form engine is chosen.
class PlatformTranscriptionProvider implements TranscriptionProvider {
  PlatformTranscriptionProvider({SpeechToText? speech})
      : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  var _initialized = false;
  String _sessionWords = '';
  var _listening = false;
  void Function(String error)? _activeOnError;

  @override
  Future<bool> isAvailable() async {
    final ready = await _ensureInitialized();
    return ready && _speech.isAvailable;
  }

  Future<bool> _ensureInitialized() async {
    if (_initialized) {
      return _speech.isAvailable;
    }
    _initialized = true;
    return _speech.initialize(
      onError: (error) {
        final message = error.errorMsg.trim().isEmpty
            ? 'Speech recognition failed. Please try again.'
            : error.errorMsg;
        _activeOnError?.call(message);
      },
      onStatus: (_) {},
    );
  }

  @override
  Future<List<TranscriptionLocale>> supportedLocales() async {
    final ready = await _ensureInitialized();
    if (!ready || !_speech.isAvailable) return const [];
    final locales = await _speech.locales();
    return [
      for (final locale in locales)
        TranscriptionLocale(localeId: locale.localeId, name: locale.name),
    ];
  }

  @override
  Future<TranscriptionLocale?> recommendedLocale() async {
    final ready = await _ensureInitialized();
    if (!ready || !_speech.isAvailable) return null;
    final system = await _speech.systemLocale();
    if (system == null) return null;
    return TranscriptionLocale(localeId: system.localeId, name: system.name);
  }

  @override
  Future<String> transcribe(String audioFilePath) async {
    throw UnsupportedError(
      'File-based transcription is not available in Sprint 2B.4 platform STT. '
      'Use startListening / stopListening, or a future file-capable provider.',
    );
  }

  @override
  Future<void> startListening({
    required void Function(String words, bool isFinal) onResult,
    void Function(String error)? onError,
    String? localeId,
  }) async {
    final ready = await _ensureInitialized();
    if (!ready || !_speech.isAvailable) {
      onError?.call('Speech recognition is not available on this device.');
      return;
    }
    if (_listening) {
      await cancelListening();
    }
    _sessionWords = '';
    _listening = true;
    _activeOnError = onError;
    await _speech.listen(
      onResult: (result) {
        final words = result.recognizedWords.trim();
        if (words.isNotEmpty) {
          _sessionWords = words;
        }
        onResult(words, result.finalResult);
      },
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
        listenFor: const Duration(minutes: 5),
        pauseFor: const Duration(seconds: 30),
        localeId: localeId,
      ),
    );
  }

  @override
  Future<String> stopListening() async {
    if (_listening) {
      await _speech.stop();
      _listening = false;
    }
    _activeOnError = null;
    final text = _sessionWords.trim();
    _sessionWords = '';
    return text;
  }

  @override
  Future<void> cancelListening() async {
    if (_listening) {
      await _speech.cancel();
      _listening = false;
    }
    _activeOnError = null;
    _sessionWords = '';
  }
}
