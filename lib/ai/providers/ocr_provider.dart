/// Platform on-device OCR interface.
///
/// Defined in Sprint 2A; concrete implementation belongs to Sprint 2B.
abstract class OCRProvider {
  Future<String> extractText(String imageFilePath);
}
