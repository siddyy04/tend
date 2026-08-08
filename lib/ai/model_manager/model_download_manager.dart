import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:my_first_app/ai/model_manager/model_catalog.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsActiveVersionKey = 'tend_model_active_version';
const _prefsPreviousVersionKey = 'tend_model_previous_version';
const _prefsManualModeKey = 'tend_model_manual_mode';
const _prefsRuntimeInstalledVersionKey = 'tend_model_runtime_installed_version';
/// Legacy key from early Phase 4 — migrated once into [ModelAssistStatus].
const _prefsLegacySetupCompletedKey = 'tend_model_setup_completed';

const _defaultUserMessage =
    'Download failed. Please check your internet connection and try again.';

const _connectionTimeout = Duration(seconds: 30);
const _idleTimeout = Duration(seconds: 60);
const _maxDownloadAttempts = 3;

/// On-device assist configuration state (independent of Capture UI).
///
/// - [notConfigured]: no model, user has not chosen manual mode → show setup.
/// - [manualMode]: user opted into manual entry for now; Settings can still
///   offer download later without treating this as permanently complete.
/// - [modelReady]: current catalog model is verified and active.
enum ModelAssistStatus {
  notConfigured,
  manualMode,
  modelReady,
}

/// Stages shown while preparing the catalog model for assisted capture.
enum ModelPreparePhase {
  downloading,
  verifying,
  installing,
  preparing,
  ready,
}

/// Progress update for [ModelDownloadManager.ensureCurrentModel] and setup UI.
class ModelPrepareProgress {
  const ModelPrepareProgress({
    required this.phase,
    this.fraction,
  });

  final ModelPreparePhase phase;

  /// 0.0–1.0 during [ModelPreparePhase.downloading]; otherwise null.
  final double? fraction;
}

/// Download / prepare failure with a user-safe message and optional debug detail.
class ModelPrepareException implements Exception {
  const ModelPrepareException({
    required this.userMessage,
    required this.technicalDetails,
    this.isRetryable = false,
  });

  /// Shown in the UI for all builds.
  final String userMessage;

  /// Shown only under a debug-only "Technical details" expansion.
  final String technicalDetails;

  /// Whether the download layer may automatically retry this failure.
  final bool isRetryable;

  @override
  String toString() => technicalDetails;
}

/// Downloads, verifies, and resolves the active on-device model file.
///
/// Version upgrades later: change [ModelCatalog.current], call [ensureCurrentModel].
/// On checksum failure of a new file, the previously working version stays active.
class ModelDownloadManager {
  ModelDownloadManager({
    http.Client? httpClient,
    SharedPreferences? preferences,
  }) : _ownsHttpClient = httpClient == null,
       _http = httpClient ?? _createDefaultHttpClient(),
       _prefsOverride = preferences;

  final bool _ownsHttpClient;
  final http.Client _http;
  final SharedPreferences? _prefsOverride;

  SharedPreferences? _prefs;

  static http.Client _createDefaultHttpClient() {
    final inner = HttpClient()
      ..connectionTimeout = _connectionTimeout
      ..idleTimeout = _idleTimeout
      ..autoUncompress = false;
    return IOClient(inner);
  }

  Future<SharedPreferences> _preferences() async {
    return _prefs ??= _prefsOverride ?? await SharedPreferences.getInstance();
  }

  /// Absolute path to the models directory.
  Future<Directory> modelsDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(documents.path, kModelStorageRelativeDir));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Absolute destination path for [spec] (exact file the user must place).
  Future<String> pathFor(ModelArtifactSpec spec) async {
    final dir = await modelsDirectory();
    return p.join(dir.path, spec.fileName);
  }

  /// Absolute models folder path for manual-install instructions.
  Future<String> modelsDirectoryPath() async {
    final dir = await modelsDirectory();
    return dir.path;
  }

  /// Resolves assist status for setup gating and future Settings.
  Future<ModelAssistStatus> assistStatus() async {
    if (await isCurrentModelReady()) {
      await _clearManualModeFlag();
      return ModelAssistStatus.modelReady;
    }

    final prefs = await _preferences();
    await _migrateLegacySetupFlag(prefs);

    if (prefs.getBool(_prefsManualModeKey) ?? false) {
      return ModelAssistStatus.manualMode;
    }
    return ModelAssistStatus.notConfigured;
  }

  /// Persist temporary manual-only preference (does **not** mean setup is done).
  Future<void> setManualMode() async {
    final prefs = await _preferences();
    await prefs.setBool(_prefsManualModeKey, true);
    await prefs.remove(_prefsLegacySetupCompletedKey);
  }

  /// Clears manual-mode preference (e.g. after a successful model install).
  Future<void> clearManualMode() async {
    await _clearManualModeFlag();
  }

  /// True when a prior successful LiteRT install was recorded for [ModelCatalog.current].
  Future<bool> isRuntimeInstallMarkedForCurrent() async {
    final prefs = await _preferences();
    final marked = prefs.getString(_prefsRuntimeInstalledVersionKey);
    return marked == ModelCatalog.current.versionId;
  }

  /// Records that the current catalog model was installed into the LiteRT runtime.
  Future<void> markRuntimeInstallForCurrent() async {
    final prefs = await _preferences();
    await prefs.setString(
      _prefsRuntimeInstalledVersionKey,
      ModelCatalog.current.versionId,
    );
  }

  /// Clears the runtime-install marker (e.g. after catalog version change).
  Future<void> clearRuntimeInstallMark() async {
    final prefs = await _preferences();
    await prefs.remove(_prefsRuntimeInstalledVersionKey);
  }

  /// Version id of the active verified model, if any.
  Future<String?> activeVersionId() async {
    final prefs = await _preferences();
    return prefs.getString(_prefsActiveVersionKey);
  }

  /// True when the catalog's [ModelCatalog.current] file is present and verified.
  Future<bool> isCurrentModelReady() async {
    final path = await resolvedActiveModelPath();
    if (path == null) {
      return false;
    }
    final active = await activeVersionId();
    return active == ModelCatalog.current.versionId;
  }

  /// Absolute path of the active verified model, or null.
  ///
  /// Prefer the prefs-recorded active version; also accept a manually placed
  /// current catalog file that passes verification (dev workflow).
  Future<String?> resolvedActiveModelPath() async {
    final prefs = await _preferences();
    final activeId = prefs.getString(_prefsActiveVersionKey);
    if (activeId != null) {
      final spec = ModelCatalog.findByVersionId(activeId);
      if (spec != null) {
        final path = await pathFor(spec);
        if (await _isVerifiedFile(path, spec)) {
          return path;
        }
      }
    }

    // Manual placement of the current artifact.
    final currentPath = await pathFor(ModelCatalog.current);
    if (await _isVerifiedFile(currentPath, ModelCatalog.current)) {
      await _setActiveVersion(ModelCatalog.current.versionId);
      return currentPath;
    }

    return null;
  }

  /// Ensures [ModelCatalog.current] is on disk and verified.
  ///
  /// Uses download when [ModelArtifactSpec.hasDownloadUrl]; otherwise requires
  /// manual placement at the expected path.
  ///
  /// Reports [ModelPreparePhase.downloading] and [ModelPreparePhase.verifying]
  /// only. Installing / preparing are orchestrated by setup after this returns.
  Future<void> ensureCurrentModel({
    void Function(ModelPrepareProgress progress)? onProgress,
  }) async {
    final current = ModelCatalog.current;
    final path = await pathFor(current);

    if (await _isVerifiedFile(path, current)) {
      await _promoteToActive(current);
      await clearManualMode();
      return;
    }

    if (!current.hasDownloadUrl) {
      throw const ModelPrepareException(
        userMessage:
            'Automatic download is not available. Please install the model manually.',
        technicalDetails:
            'No download URL configured for the current catalog model.',
      );
    }

    final previousId = await activeVersionId();
    final tempPath = '$path.download';

    try {
      onProgress?.call(
        const ModelPrepareProgress(
          phase: ModelPreparePhase.downloading,
          fraction: 0,
        ),
      );
      await _downloadToFile(
        url: current.downloadUrl,
        destinationPath: tempPath,
        onProgress: (p) {
          onProgress?.call(
            ModelPrepareProgress(
              phase: ModelPreparePhase.downloading,
              fraction: p,
            ),
          );
        },
      );

      onProgress?.call(
        const ModelPrepareProgress(phase: ModelPreparePhase.verifying),
      );
      if (!await _verifyFile(tempPath, current)) {
        await _deleteQuietly(tempPath);
        throw ModelPrepareException(
          userMessage:
              'The downloaded model could not be verified. Please try again.',
          technicalDetails:
              'Checksum verification failed for ${current.versionId}.',
        );
      }

      final dest = File(path);
      if (await dest.exists()) {
        await dest.delete();
      }
      await File(tempPath).rename(path);
      // New bytes on disk — require a fresh LiteRT install pass.
      await clearRuntimeInstallMark();
      await _promoteToActive(current, previousVersionId: previousId);
      await clearManualMode();
    } on ModelPrepareException catch (e) {
      // Keep a partial `.download` file when the failure is retryable so the
      // next attempt (or user Retry) can resume with Range requests.
      if (!e.isRetryable) {
        await _deleteQuietly(tempPath);
      }
      rethrow;
    } catch (e) {
      final mapped = _mapToPrepareException(e);
      if (!mapped.isRetryable) {
        await _deleteQuietly(tempPath);
      }
      throw mapped;
    }
  }

  /// Verifies a manually placed current-catalog file and promotes it.
  Future<void> verifyManualPlacement({
    void Function(ModelPrepareProgress progress)? onProgress,
  }) async {
    final current = ModelCatalog.current;
    final path = await pathFor(current);
    onProgress?.call(
      const ModelPrepareProgress(phase: ModelPreparePhase.verifying),
    );
    if (!await _isVerifiedFile(path, current)) {
      throw ModelPrepareException(
        userMessage:
            'We could not find a valid model file in the expected folder. '
            'Check the steps below and try again.',
        technicalDetails:
            'Missing or invalid model at $path '
            '(expected file name: ${current.fileName}).',
      );
    }
    await _promoteToActive(current);
    await clearManualMode();
  }

  Future<void> _migrateLegacySetupFlag(SharedPreferences prefs) async {
    if (!(prefs.getBool(_prefsLegacySetupCompletedKey) ?? false)) {
      return;
    }
    // Old Phase 4 treated "skip / unsupported continue" as setup complete.
    // Map that to manual mode so Settings can still offer download later.
    await prefs.setBool(_prefsManualModeKey, true);
    await prefs.remove(_prefsLegacySetupCompletedKey);
  }

  Future<void> _clearManualModeFlag() async {
    final prefs = await _preferences();
    await prefs.remove(_prefsManualModeKey);
    await prefs.remove(_prefsLegacySetupCompletedKey);
  }

  Future<void> _promoteToActive(
    ModelArtifactSpec spec, {
    String? previousVersionId,
  }) async {
    final prefs = await _preferences();
    final existing = prefs.getString(_prefsActiveVersionKey);
    if (existing != null &&
        existing != spec.versionId &&
        previousVersionId == null) {
      await prefs.setString(_prefsPreviousVersionKey, existing);
    } else if (previousVersionId != null &&
        previousVersionId != spec.versionId) {
      await prefs.setString(_prefsPreviousVersionKey, previousVersionId);
    }
    await prefs.setString(_prefsActiveVersionKey, spec.versionId);
    // Installing a different catalog version invalidates the prior runtime mark
    // until prepareActiveModel / install succeeds again.
    final marked = prefs.getString(_prefsRuntimeInstalledVersionKey);
    if (marked != null && marked != spec.versionId) {
      await prefs.remove(_prefsRuntimeInstalledVersionKey);
    }
  }

  Future<void> _setActiveVersion(String versionId) async {
    final prefs = await _preferences();
    await prefs.setString(_prefsActiveVersionKey, versionId);
  }

  Future<bool> _isVerifiedFile(String path, ModelArtifactSpec spec) async {
    final file = File(path);
    if (!await file.exists()) {
      return false;
    }
    return _verifyFile(path, spec);
  }

  Future<bool> _verifyFile(String path, ModelArtifactSpec spec) async {
    if (!spec.hasChecksum) {
      // Dev / manual placement without checksum — presence is enough.
      return File(path).exists();
    }
    final digest = await sha256.bind(File(path).openRead()).first;
    final hex = digest.toString();
    return hex.toLowerCase() == spec.sha256.trim().toLowerCase();
  }

  /// Downloads [url] to [destinationPath] with retries and optional resume.
  Future<void> _downloadToFile({
    required String url,
    required String destinationPath,
    void Function(double progress)? onProgress,
  }) async {
    ModelPrepareException? lastError;

    for (var attempt = 1; attempt <= _maxDownloadAttempts; attempt++) {
      try {
        await _downloadAttempt(
          url: url,
          destinationPath: destinationPath,
          onProgress: onProgress,
        );
        return;
      } on ModelPrepareException catch (e) {
        lastError = e;
        if (!e.isRetryable || attempt == _maxDownloadAttempts) {
          rethrow;
        }
        // Brief backoff before retrying flaky connections.
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      } catch (e) {
        final mapped = _mapToPrepareException(e);
        lastError = mapped;
        if (!mapped.isRetryable || attempt == _maxDownloadAttempts) {
          throw mapped;
        }
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      }
    }

    throw lastError ??
        const ModelPrepareException(
          userMessage: _defaultUserMessage,
          technicalDetails: 'Download failed after retries with no detail.',
          isRetryable: true,
        );
  }

  Future<void> _downloadAttempt({
    required String url,
    required String destinationPath,
    void Function(double progress)? onProgress,
  }) async {
    final uri = Uri.parse(url);
    final file = File(destinationPath);
    var existingBytes = 0;
    if (await file.exists()) {
      existingBytes = await file.length();
    }

    final request = http.Request('GET', uri);
    request.headers['User-Agent'] = 'Tend/1.0 (Flutter; model-download)';
    request.headers['Accept'] = '*/*';
    // Prefer raw bytes; compressed transfer of multi-GB model files is less reliable.
    request.headers['Accept-Encoding'] = 'identity';
    if (existingBytes > 0) {
      request.headers['Range'] = 'bytes=$existingBytes-';
    }

    late final http.StreamedResponse response;
    try {
      response = await _http.send(request).timeout(_connectionTimeout);
    } on TimeoutException catch (e) {
      throw ModelPrepareException(
        userMessage: _defaultUserMessage,
        technicalDetails: 'Connection timed out opening $url: $e',
        isRetryable: true,
      );
    } on SocketException catch (e) {
      throw ModelPrepareException(
        userMessage: _defaultUserMessage,
        technicalDetails: 'Socket error opening $url: $e',
        isRetryable: true,
      );
    } on http.ClientException catch (e) {
      throw ModelPrepareException(
        userMessage: _defaultUserMessage,
        technicalDetails: 'ClientException opening $url: $e',
        isRetryable: true,
      );
    }

    // 200 = full body; 206 = partial content for resume.
    final isPartial = response.statusCode == 206;
    final isOk = response.statusCode >= 200 && response.statusCode < 300;
    if (!isOk) {
      // Unsatisfiable Range — discard partial and retry a full download.
      if (existingBytes > 0 && response.statusCode == 416) {
        await _deleteQuietly(destinationPath);
        throw ModelPrepareException(
          userMessage: _defaultUserMessage,
          technicalDetails:
              'Resume rejected (HTTP 416) for $url; restarting full download.',
          isRetryable: true,
        );
      }
      throw ModelPrepareException(
        userMessage: _defaultUserMessage,
        technicalDetails: 'HTTP ${response.statusCode} for $url',
        isRetryable: response.statusCode >= 500 || response.statusCode == 429,
      );
    }

    if (!isPartial && existingBytes > 0) {
      // Server ignored Range and sent a full body — overwrite.
      existingBytes = 0;
      await _deleteQuietly(destinationPath);
    }

    final contentLength = response.contentLength ?? -1;
    final totalBytes = contentLength < 0
        ? -1
        : (isPartial ? existingBytes + contentLength : contentLength);

    if (totalBytes > 0 && onProgress != null) {
      onProgress(existingBytes / totalBytes);
    }

    final sink = file.openWrite(
      mode: isPartial && existingBytes > 0 ? FileMode.append : FileMode.write,
    );
    var received = existingBytes;

    try {
      await for (final chunk in response.stream.timeout(_idleTimeout)) {
        sink.add(chunk);
        received += chunk.length;
        if (totalBytes > 0 && onProgress != null) {
          onProgress((received / totalBytes).clamp(0.0, 1.0));
        }
      }
      await sink.flush();
    } on TimeoutException catch (e) {
      throw ModelPrepareException(
        userMessage: _defaultUserMessage,
        technicalDetails:
            'Idle timeout while receiving data from $url '
            '(received $received bytes): $e',
        isRetryable: true,
      );
    } on http.ClientException catch (e) {
      // Common on large HF downloads: connection closed mid-stream.
      throw ModelPrepareException(
        userMessage: _defaultUserMessage,
        technicalDetails:
            'Connection closed while receiving data from $url '
            '(received $received bytes): $e',
        isRetryable: true,
      );
    } on SocketException catch (e) {
      throw ModelPrepareException(
        userMessage: _defaultUserMessage,
        technicalDetails:
            'Socket error while receiving data from $url '
            '(received $received bytes): $e',
        isRetryable: true,
      );
    } finally {
      await sink.close();
    }

    if (totalBytes > 0 && received < totalBytes) {
      throw ModelPrepareException(
        userMessage: _defaultUserMessage,
        technicalDetails:
            'Incomplete download from $url ($received / $totalBytes bytes).',
        isRetryable: true,
      );
    }

    // Guard against empty / tiny failed responses.
    if (received <= 0) {
      await _deleteQuietly(destinationPath);
      throw ModelPrepareException(
        userMessage: _defaultUserMessage,
        technicalDetails: 'Empty download body from $url.',
        isRetryable: true,
      );
    }

    onProgress?.call(1);
  }

  ModelPrepareException _mapToPrepareException(Object error) {
    if (error is ModelPrepareException) {
      return error;
    }
    return ModelPrepareException(
      userMessage: _defaultUserMessage,
      technicalDetails: error.toString(),
      isRetryable: true,
    );
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Best-effort cleanup.
    }
  }

  /// Downloads [fileName] from [downloadUrl] into the shared models directory.
  ///
  /// Used by embedding artifacts (Gecko) so Phase 3.3 does not invent a second
  /// HTTP download stack. [checksumHex] empty → presence-only verification.
  Future<String> ensureDownloadedFile({
    required String fileName,
    required String downloadUrl,
    String checksumHex = '',
    void Function(ModelPrepareProgress progress)? onProgress,
  }) async {
    final path = p.join((await modelsDirectory()).path, fileName);
    if (await _isVerifiedPath(path, checksumHex)) {
      return path;
    }

    if (downloadUrl.trim().isEmpty) {
      throw ModelPrepareException(
        userMessage:
            'Automatic download is not available. Please install the file manually.',
        technicalDetails: 'No download URL for $fileName.',
      );
    }

    final tempPath = '$path.download';
    try {
      onProgress?.call(
        const ModelPrepareProgress(
          phase: ModelPreparePhase.downloading,
          fraction: 0,
        ),
      );
      await _downloadToFile(
        url: downloadUrl,
        destinationPath: tempPath,
        onProgress: (progress) {
          onProgress?.call(
            ModelPrepareProgress(
              phase: ModelPreparePhase.downloading,
              fraction: progress,
            ),
          );
        },
      );

      onProgress?.call(
        const ModelPrepareProgress(phase: ModelPreparePhase.verifying),
      );
      if (!await _verifyPath(tempPath, checksumHex)) {
        await _deleteQuietly(tempPath);
        throw ModelPrepareException(
          userMessage:
              'The downloaded file could not be verified. Please try again.',
          technicalDetails: 'Verification failed for $fileName.',
        );
      }

      final dest = File(path);
      if (await dest.exists()) {
        await dest.delete();
      }
      await File(tempPath).rename(path);
      return path;
    } on ModelPrepareException catch (e) {
      if (!e.isRetryable) {
        await _deleteQuietly(tempPath);
      }
      rethrow;
    } catch (e) {
      final mapped = _mapToPrepareException(e);
      if (!mapped.isRetryable) {
        await _deleteQuietly(tempPath);
      }
      throw mapped;
    }
  }

  Future<bool> _isVerifiedPath(String path, String checksumHex) async {
    final file = File(path);
    if (!await file.exists()) return false;
    return _verifyPath(path, checksumHex);
  }

  Future<bool> _verifyPath(String path, String checksumHex) async {
    if (checksumHex.trim().isEmpty) {
      return File(path).exists();
    }
    final digest = await sha256.bind(File(path).openRead()).first;
    return digest.toString().toLowerCase() == checksumHex.trim().toLowerCase();
  }

  /// Closes the owned HTTP client (no-op when a client was injected).
  void dispose() {
    if (_ownsHttpClient) {
      _http.close();
    }
  }
}
