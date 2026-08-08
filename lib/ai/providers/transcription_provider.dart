/// Speech recognition locale independent of any concrete STT engine.
///
/// [localeId] should be a BCP-47 / platform tag (e.g. `en_US`, `en_IN`, `hi_IN`)
/// that the active [TranscriptionProvider] understands.
class TranscriptionLocale {
  const TranscriptionLocale({
    required this.localeId,
    required this.name,
  });

  final String localeId;

  /// Human-readable label for Settings / pickers.
  final String name;
}

/// Abstract speech-to-text — swappable without touching Capture / Extraction.
///
/// Sprint 2B.4 MVP: [PlatformTranscriptionProvider] (OS ASR).
/// Future: long-form engines (Whisper, cloud STT, etc.) implement this same
/// interface. Capture only consumes text; the model never receives audio.
///
/// Must never import or call the LiteRT / Gemma inference stack.
abstract class TranscriptionProvider {
  /// Transcribe a previously recorded audio file (file-based STT backends).
  ///
  /// Listen-session providers (current platform MVP) may throw
  /// [UnsupportedError] until a file-capable engine is selected.
  Future<String> transcribe(String audioFilePath);

  /// Whether speech recognition is available on this device for the
  /// active engine.
  Future<bool> isAvailable();

  /// Locales this engine can recognize (empty if unknown / unavailable).
  Future<List<TranscriptionLocale>> supportedLocales();

  /// Engine-recommended default (usually the device / system speech locale).
  Future<TranscriptionLocale?> recommendedLocale();

  /// Start a listen session. Callers must not display partial results for MVP
  /// (no live transcription UI). Stop/cancel via [stopListening] / [cancelListening].
  ///
  /// [localeId] selects the speech language when the engine supports it.
  Future<void> startListening({
    required void Function(String words, bool isFinal) onResult,
    void Function(String error)? onError,
    String? localeId,
  });

  /// Ends listening and returns the best transcript gathered for this session.
  Future<String> stopListening();

  /// Aborts listening and discards the session transcript.
  Future<void> cancelListening();
}
