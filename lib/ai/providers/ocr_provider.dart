/// On-device OCR interface — swappable without touching Capture / Extraction.
///
/// Sprint 2B.5 MVP: [PlatformOCRProvider] (ML Kit text recognition).
/// Images never go to LiteRT / Gemma; only extracted text enters Capture.
abstract class OCRProvider {
  /// Extract plain text from a local image file path.
  ///
  /// Returns an empty string when no readable text is found (not an error).
  Future<String> extractText(String imageFilePath);

  /// Whether OCR is available on this device for the active engine.
  Future<bool> isAvailable();
}
