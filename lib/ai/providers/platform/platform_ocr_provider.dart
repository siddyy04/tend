import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:my_first_app/ai/providers/ocr_provider.dart';

/// Platform OCR via Google ML Kit — never touches LiteRT / Gemma.
///
/// Fully on-device recognition for Latin script (MVP). The model may be
/// downloaded once by the OS/Play Services; inference does not require a
/// network round-trip per image.
class PlatformOCRProvider implements OCRProvider {
  PlatformOCRProvider({TextRecognizer? recognizer})
      : _recognizer = recognizer ??
            TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;
  var _closed = false;

  @override
  Future<bool> isAvailable() async {
    // ML Kit text recognition is available on supported Android/iOS devices
    // once the native plugin is linked; there is no separate readiness probe.
    return !_closed;
  }

  @override
  Future<String> extractText(String imageFilePath) async {
    if (_closed) {
      throw StateError('PlatformOCRProvider has been closed.');
    }
    final input = InputImage.fromFilePath(imageFilePath);
    final recognized = await _recognizer.processImage(input);
    return recognized.text.trim();
  }

  /// Releases native resources. Call when the provider is disposed.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _recognizer.close();
  }
}
