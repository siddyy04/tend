import 'dart:ffi';
import 'dart:io';

import 'package:isar_community/isar.dart';

/// Points Isar at the Windows native library from pub-cache for VM unit tests.
///
/// Plain `flutter test` does not bundle `libisar.dll`; without this, Isar.open
/// fails looking for the DLL in the project root.
Future<void> ensureIsarCoreForTests() async {
  if (!Platform.isWindows) {
    await Isar.initializeIsarCore(download: true);
    return;
  }

  final localAppData = Platform.environment['LOCALAPPDATA'];
  if (localAppData == null) {
    await Isar.initializeIsarCore(download: true);
    return;
  }

  final pubHosted = Directory('$localAppData\\Pub\\Cache\\hosted\\pub.dev');
  if (!pubHosted.existsSync()) {
    await Isar.initializeIsarCore(download: true);
    return;
  }

  final matches = pubHosted
      .listSync()
      .whereType<Directory>()
      .where((d) => d.path.contains('isar_community_flutter_libs-'))
      .toList()
    ..sort((a, b) => b.path.compareTo(a.path));

  for (final dir in matches) {
    final dll = File('${dir.path}\\windows\\libisar.dll');
    if (dll.existsSync()) {
      await Isar.initializeIsarCore(
        libraries: {Abi.windowsX64: dll.path},
      );
      return;
    }
  }

  await Isar.initializeIsarCore(download: true);
}
