import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Copies a picked/captured image into app documents for stable [sourceRef].
Future<String> persistCaptureImage(String sourcePath) async {
  final docs = await getApplicationDocumentsDirectory();
  final captures = Directory(p.join(docs.path, 'captures'));
  if (!await captures.exists()) {
    await captures.create(recursive: true);
  }

  final ext = p.extension(sourcePath);
  final safeExt = ext.isEmpty ? '.jpg' : ext;
  final destPath = p.join(
    captures.path,
    'photo_${const Uuid().v4()}$safeExt',
  );
  await File(sourcePath).copy(destPath);
  return destPath;
}
