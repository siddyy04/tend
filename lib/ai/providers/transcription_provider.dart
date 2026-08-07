/// Platform speech-to-text interface.
///
/// Defined in Sprint 2A; concrete implementation belongs to Sprint 2B.
abstract class TranscriptionProvider {
  Future<String> transcribe(String audioFilePath);
}
