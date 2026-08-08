import 'dart:io';

import 'package:my_first_app/ai/model_manager/embedding_model_catalog.dart';
import 'package:my_first_app/ai/model_manager/model_download_manager.dart';
import 'package:my_first_app/ai/providers/gecko/gecko_constants.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

const _prefsGeckoDeclinedKey = 'tend_gecko_embedder_declined';
const _prefsGeckoReadyVersionKey = 'tend_gecko_embedder_ready_version';
const _prefsGeckoRuntimeInstalledKey = 'tend_gecko_runtime_installed_version';

/// User-facing / readiness status for the optional Gecko embedder.
enum GeckoEmbedderStatus {
  /// Files not on disk; user has not declined.
  notDownloaded,

  /// User explicitly deferred / declined (Settings can retry).
  declined,

  /// Model + tokenizer present on disk; runtime may still need install.
  filesReady,

  /// Installed into flutter_gemma embedder and ready for [embed].
  runtimeReady,
}

/// Downloads and tracks Gecko artifacts via [ModelDownloadManager] staging.
class EmbeddingModelManager {
  EmbeddingModelManager({
    required ModelDownloadManager downloadManager,
    SharedPreferences? preferences,
  })  : _downloads = downloadManager,
        _prefsOverride = preferences;

  final ModelDownloadManager _downloads;
  final SharedPreferences? _prefsOverride;
  SharedPreferences? _prefs;

  Future<SharedPreferences> _preferences() async {
    return _prefs ??= _prefsOverride ?? await SharedPreferences.getInstance();
  }

  Future<String> modelPath() async {
    final dir = await _downloads.modelsDirectory();
    return p.join(dir.path, EmbeddingModelCatalog.geckoModel.fileName);
  }

  Future<String> tokenizerPath() async {
    final dir = await _downloads.modelsDirectory();
    return p.join(dir.path, EmbeddingModelCatalog.geckoTokenizer.fileName);
  }

  Future<bool> areFilesOnDisk() async {
    final model = File(await modelPath());
    final tok = File(await tokenizerPath());
    return model.existsSync() && tok.existsSync();
  }

  Future<GeckoEmbedderStatus> status() async {
    final prefs = await _preferences();
    final readyVersion = prefs.getString(_prefsGeckoReadyVersionKey);
    final runtime = prefs.getString(_prefsGeckoRuntimeInstalledKey);
    if (readyVersion == GeckoConstants.modelVersion &&
        runtime == GeckoConstants.modelVersion &&
        await areFilesOnDisk()) {
      return GeckoEmbedderStatus.runtimeReady;
    }
    if (await areFilesOnDisk()) {
      return GeckoEmbedderStatus.filesReady;
    }
    if (prefs.getBool(_prefsGeckoDeclinedKey) ?? false) {
      return GeckoEmbedderStatus.declined;
    }
    return GeckoEmbedderStatus.notDownloaded;
  }

  Future<void> setDeclined(bool declined) async {
    final prefs = await _preferences();
    if (declined) {
      await prefs.setBool(_prefsGeckoDeclinedKey, true);
    } else {
      await prefs.remove(_prefsGeckoDeclinedKey);
    }
  }

  Future<void> markFilesReady() async {
    final prefs = await _preferences();
    await prefs.setString(
      _prefsGeckoReadyVersionKey,
      GeckoConstants.modelVersion,
    );
    await prefs.remove(_prefsGeckoDeclinedKey);
  }

  Future<void> markRuntimeInstalled() async {
    final prefs = await _preferences();
    await prefs.setString(
      _prefsGeckoRuntimeInstalledKey,
      GeckoConstants.modelVersion,
    );
    await markFilesReady();
  }

  Future<void> clearRuntimeInstallMark() async {
    final prefs = await _preferences();
    await prefs.remove(_prefsGeckoRuntimeInstalledKey);
  }

  /// Downloads model + tokenizer. Does not install into the embedder runtime.
  Future<void> ensureFilesDownloaded({
    void Function(ModelPrepareProgress progress)? onProgress,
  }) async {
    await setDeclined(false);
    for (final spec in EmbeddingModelCatalog.requiredFiles) {
      await _downloads.ensureDownloadedFile(
        fileName: spec.fileName,
        downloadUrl: spec.downloadUrl,
        checksumHex: spec.sha256,
        onProgress: onProgress,
      );
    }
    await markFilesReady();
    await clearRuntimeInstallMark();
  }
}
