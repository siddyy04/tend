/// Navigation payload for the editable OCR text screen.
class OcrTextArgs {
  const OcrTextArgs({
    required this.text,
    required this.imagePath,
  });

  final String text;
  final String imagePath;
}
