import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:my_first_app/ai/model_manager/model_catalog.dart';
import 'package:my_first_app/ai/model_manager/model_download_manager.dart';
import 'package:my_first_app/ai/providers/litert/litert_prompt_builder.dart';

bool _liteRtRuntimeInitialized = false;

/// Registers LiteRT-LM once per process. Safe to call from [main] and the adapter.
void ensureLiteRtRuntimeInitialized() {
  if (_liteRtRuntimeInitialized) {
    return;
  }
  _liteRtRuntimeInitialized = true;
  unawaited(
    FlutterGemma.initialize(inferenceEngines: const [LiteRtLmEngine()]),
  );
}

Future<void> _ensureInitialized() async {
  await FlutterGemma.initialize(inferenceEngines: const [LiteRtLmEngine()]);
  _liteRtRuntimeInitialized = true;
}

/// Vendor-neutral function-call payload returned by [LiteRtInferenceAdapter].
class LiteRtRawFunctionCall {
  const LiteRtRawFunctionCall({
    required this.name,
    required this.args,
  });

  final String name;
  final Map<String, dynamic> args;
}

/// Diagnostic snapshot for debug UI when extraction returns empty.
class LiteRtInferenceDiagnostics {
  const LiteRtInferenceDiagnostics({
    required this.filePath,
    required this.fileExists,
    required this.fileBytes,
    required this.hasActiveModel,
    required this.activeModelType,
    required this.expectedModelType,
    required this.installedThisCall,
    required this.maxTokens,
    required this.promptChars,
    required this.responseType,
    required this.responsePreview,
    required this.parserBranch,
    this.activeBackend,
    this.fullSystemPrompt = '',
    this.fullUserPrompt = '',
    this.toolSchemaSummary = '(none)',
    this.fullRawResponse = '',
    this.errorLine,
  });

  final String? filePath;
  final bool fileExists;
  final int fileBytes;
  final bool hasActiveModel;
  final String? activeModelType;
  final String expectedModelType;
  final bool installedThisCall;
  final int maxTokens;
  final int promptChars;
  final String responseType;
  final String responsePreview;
  final String parserBranch;
  final String? activeBackend;
  final String fullSystemPrompt;
  final String fullUserPrompt;
  final String toolSchemaSummary;
  final String fullRawResponse;
  final String? errorLine;

  @override
  String toString() {
    return 'file=${filePath ?? "(none)"} exists=$fileExists bytes=$fileBytes '
        'hasActive=$hasActiveModel activeType=$activeModelType '
        'expectedType=$expectedModelType installedThisCall=$installedThisCall '
        'maxTokens=$maxTokens backend=${activeBackend ?? "?"} '
        'promptChars=$promptChars response=$responseType parser=$parserBranch '
        'rawLen=${fullRawResponse.length} '
        'previewLen=${responsePreview.length} preview=$responsePreview'
        '${errorLine == null ? '' : ' errorAt=$errorLine'}';
  }
}

/// Thin adapter: the only Tend file that imports `flutter_gemma` / LiteRT-LM.
///
/// Gemma 4 path: `.litertlm` + native function calling (`ModelType.gemma4`).
/// Backend preference: GPU → NPU (Android NNAPI-class) → CPU.
class LiteRtInferenceAdapter {
  LiteRtInferenceAdapter({required this.modelManager});

  final ModelDownloadManager modelManager;
  String? _installedFromPath;
  int? _loadedMaxTokens;
  PreferredBackend? _loadedBackendHint;
  InferenceModel? _loadedModel;
  PreferredBackend? lastActiveBackend;
  LiteRtInferenceDiagnostics? lastDiagnostics;

  /// Debug-only: last user prompt / raw output / parser summary.
  String? lastFullUserPrompt;
  String? lastFullRawResponse;
  String? lastParserResultSummary;

  /// True when file is present and LiteRT has the matching model type active.
  Future<bool> isRuntimePrepared() async {
    await _ensureInitialized();
    final path = await modelManager.resolvedActiveModelPath();
    if (path == null || !File(path).existsSync()) {
      return false;
    }
    final spec = await _activeSpec();
    if (_installedFromPath == path &&
        _loadedModel != null &&
        _loadedMaxTokens == spec.maxTokens) {
      return true;
    }
    final expected = _toFlutterModelType(spec.modelKind);
    final active = FlutterGemma.activeModelSpec;
    if (FlutterGemma.hasActiveModel() &&
        active != null &&
        active.modelType == expected &&
        await modelManager.isRuntimeInstallMarkedForCurrent()) {
      _installedFromPath = path;
      return true;
    }
    return false;
  }

  Future<void> prepareActiveModel() async {
    await _ensureInitialized();
    // Prefer reuse when FlutterGemma already has this artifact active.
    await _ensureModelInstalledFromManager(force: false);
  }

  /// Runs extraction via native tool calling (Gemma 4 LiteRT-LM).
  ///
  /// Returns **all** function calls from a single generate turn. Gemma 4 emits
  /// [ParallelFunctionCallResponse] for multi-memory notes (Sprint 2B.1).
  Future<List<LiteRtRawFunctionCall>> runFunctionCalls({
    required String systemInstruction,
    required String userPrompt,
    required List<LiteRtToolDefinition> tools,
  }) async {
    await _ensureInitialized();

    ({String? path, bool exists, int bytes, bool installedThisCall})?
        installInfo;
    var modelType = ModelType.gemma4;
    var maxTokens = ModelCatalog.current.maxTokens;
    var promptChars = 0;
    var responsePreview = '';
    var responseType = 'none';
    var parserBranch = 'not_started';
    String? errorLine;

    try {
      installInfo = await _ensureModelInstalledFromManager(force: false);
      final spec = await _activeSpec();
      modelType = _toFlutterModelType(spec.modelKind);
      maxTokens = spec.maxTokens;
      final model = await _getLoadedModel(spec);

      if (tools.isEmpty) {
        parserBranch = 'no_tools_provided';
        errorLine = 'runFunctionCalls:tools_empty';
        lastDiagnostics = _diag(
          installInfo: installInfo,
          modelType: modelType,
          maxTokens: maxTokens,
          promptChars: 0,
          responseType: responseType,
          responsePreview: '',
          parserBranch: parserBranch,
          fullSystemPrompt: '',
          fullUserPrompt: userPrompt,
          toolSchemaSummary: '(none)',
          fullRawResponse: '',
          errorLine: errorLine,
        );
        return const [];
      }

      const systemPromptSent = '';
      final extractionUser = userPrompt.trim();
      final sdkTools = tools.map(_toSdkTool).toList(growable: false);
      final toolSchemaSummary = tools
          .map(
            (t) =>
                '${t.name}: ${t.description}; params=${jsonEncode(t.parameters)}',
          )
          .join('\n');
      promptChars = extractionUser.length;
      if (kDebugMode) {
        lastFullUserPrompt = extractionUser;
        lastFullRawResponse = null;
        lastParserResultSummary = null;
      }

      _dbgBlock('===== PROMPT =====', () {
        _dbgChunk('--- user message ---');
        _dbgChunk(extractionUser);
        _dbgChunk('--- tools ---');
        _dbgChunk(toolSchemaSummary);
        _dbgChunk(
          '--- createChat knobs ---\n'
          'temperature=1.0 topK=64 topP=0.95 tokenBuffer=256 '
          'supportsFunctionCalls=true toolChoice=auto isThinking=false '
          'modelType=${modelType.name} maxTokens=$maxTokens '
          'backend=${lastActiveBackend?.name ?? "?"}',
        );
      });

      final ModelResponse response = await _generateWithNativeTools(
        model: model,
        userPrompt: extractionUser,
        modelType: modelType,
        tools: sdkTools,
      );
      responseType = response.runtimeType.toString();
      responsePreview = _previewOf(response);
      if (kDebugMode) {
        lastFullRawResponse = responsePreview;
      }

      _dbgBlock('===== RAW MODEL OUTPUT =====', () {
        _dbgChunk('runtimeType=$responseType');
        _dbgChunk(responsePreview.isEmpty ? '(empty string)' : responsePreview);
      });

      final mapped = <LiteRtRawFunctionCall>[];
      if (response is FunctionCallResponse) {
        parserBranch = 'function_call_response';
        mapped.add(
          LiteRtRawFunctionCall(
            name: response.name,
            args: _safeStringKeyedMap(response.args) ?? const {},
          ),
        );
      } else if (response is ParallelFunctionCallResponse &&
          response.calls.isNotEmpty) {
        parserBranch = 'parallel_function_call';
        for (final call in response.calls) {
          mapped.add(
            LiteRtRawFunctionCall(
              name: call.name,
              args: _safeStringKeyedMap(call.args) ?? const {},
            ),
          );
        }
      } else if (response is TextResponse) {
        parserBranch = 'protocol_failure_text_response';
        errorLine = 'expected_FunctionCallResponse_got_TextResponse';
        if (kDebugMode) {
          final textToken = response.token;
          _dbgBlock('===== PROTOCOL NOTE =====', () {
            _dbgChunk(
              'supportsFunctionCalls=true but runtimeType=TextResponse',
            );
            _dbgChunk(textToken.isEmpty ? '(empty)' : textToken);
          });
        }
      } else {
        parserBranch = 'unknown_response_type';
      }

      if (kDebugMode) {
        lastParserResultSummary = mapped.isEmpty
            ? 'branch=$parserBranch mapped=0'
            : 'branch=$parserBranch mapped=${mapped.length} '
                '${mapped.map((m) => '${m.name}(${m.args})').join(' | ')}';
        _dbgBlock('===== PARSER RESULT =====', () {
          _dbgChunk(lastParserResultSummary!);
        });
      }

      lastDiagnostics = _diag(
        installInfo: installInfo,
        modelType: modelType,
        maxTokens: maxTokens,
        promptChars: promptChars,
        responseType: responseType,
        responsePreview: responsePreview,
        parserBranch: parserBranch,
        fullSystemPrompt: systemPromptSent,
        fullUserPrompt: extractionUser,
        toolSchemaSummary: toolSchemaSummary,
        fullRawResponse: responsePreview,
        errorLine: errorLine,
      );
      return mapped;
    } catch (e, st) {
      errorLine = _firstFrame(st);
      parserBranch = 'exception';
      _dbg('EXCEPTION at $errorLine: $e\n$st');
      // Do not close the loaded InferenceModel on generate/session errors —
      // that clears the expensive weights and forces reinstall next capture
      // (installedThisCall=true). Only drop on explicit prepare/install paths.
      lastDiagnostics = _diag(
        installInfo: installInfo,
        modelType: modelType,
        maxTokens: maxTokens,
        promptChars: promptChars,
        responseType: 'error:${e.runtimeType}',
        responsePreview: '$e',
        parserBranch: parserBranch,
        fullSystemPrompt: '',
        fullUserPrompt: lastFullUserPrompt ?? '',
        toolSchemaSummary: '(n/a)',
        fullRawResponse: lastFullRawResponse ?? '',
        errorLine: errorLine,
      );
      return const [];
    }
  }

  LiteRtInferenceDiagnostics _diag({
    required ({String? path, bool exists, int bytes, bool installedThisCall})?
        installInfo,
    required ModelType modelType,
    required int maxTokens,
    required int promptChars,
    required String responseType,
    required String responsePreview,
    required String parserBranch,
    required String fullSystemPrompt,
    required String fullUserPrompt,
    required String toolSchemaSummary,
    required String fullRawResponse,
    String? errorLine,
  }) {
    // Keep compact metadata in all builds; omit verbose AI payloads in release.
    final includeVerbose = kDebugMode;
    return LiteRtInferenceDiagnostics(
      filePath: installInfo?.path,
      fileExists: installInfo?.exists ?? false,
      fileBytes: installInfo?.bytes ?? 0,
      hasActiveModel: FlutterGemma.hasActiveModel(),
      activeModelType: _activeTypeName(),
      expectedModelType: modelType.name,
      installedThisCall: installInfo?.installedThisCall ?? false,
      maxTokens: maxTokens,
      promptChars: promptChars,
      responseType: responseType,
      responsePreview: includeVerbose ? responsePreview : '',
      parserBranch: parserBranch,
      activeBackend: lastActiveBackend?.name,
      fullSystemPrompt: includeVerbose ? fullSystemPrompt : '',
      fullUserPrompt: includeVerbose ? fullUserPrompt : '',
      toolSchemaSummary: includeVerbose ? toolSchemaSummary : '(omitted)',
      fullRawResponse: includeVerbose ? fullRawResponse : '',
      errorLine: errorLine,
    );
  }

  /// Gemma 4 ChatScreen-shaped generation with native tools.
  ///
  /// LiteRT-LM allows one live conversation at a time. Closing the chat before
  /// [generateChatResponse] completes cancels native streaming
  /// (`SessionAdvanced::CancelProcess` / `Failed to start streaming`).
  /// Always `await` the response before [InferenceChat.close].
  Future<ModelResponse> _generateWithNativeTools({
    required InferenceModel model,
    required String userPrompt,
    required ModelType modelType,
    required List<Tool> tools,
  }) async {
    final chat = await model.createChat(
      temperature: 1.0,
      randomSeed: 1,
      topK: 64,
      topP: 0.95,
      tokenBuffer: 256,
      supportsFunctionCalls: true,
      tools: tools,
      toolChoice: ToolChoice.auto,
      // Thinking burns latency for capture; keep extraction crisp.
      isThinking: false,
      modelType: modelType,
    );

    try {
      await chat.addQueryChunk(
        Message.text(text: userPrompt, isUser: true),
      );
      // MUST await: a bare `return future` runs `finally` (chat.close) before
      // streaming starts, which cancels the native session.
      return await chat.generateChatResponse();
    } finally {
      try {
        await chat.close();
      } catch (_) {}
    }
  }

  Tool _toSdkTool(LiteRtToolDefinition definition) {
    return Tool(
      name: definition.name,
      description: definition.description,
      parameters: definition.parameters,
    );
  }

  Future<ModelArtifactSpec> _activeSpec() async {
    final activeId = await modelManager.activeVersionId();
    return (activeId != null ? ModelCatalog.findByVersionId(activeId) : null) ??
        ModelCatalog.current;
  }

  Future<InferenceModel> _getLoadedModel(ModelArtifactSpec spec) async {
    if (_loadedModel != null &&
        _loadedMaxTokens == spec.maxTokens &&
        _loadedBackendHint == _primaryBackendHint(spec)) {
      return _loadedModel!;
    }
    await _dropLoadedModel();
    _loadedModel = await _loadWithBackendFallback(spec);
    _loadedMaxTokens = spec.maxTokens;
    _loadedBackendHint = _primaryBackendHint(spec);
    return _loadedModel!;
  }

  PreferredBackend _primaryBackendHint(ModelArtifactSpec spec) {
    switch (spec.backendPreference) {
      case LiteRtBackendPreference.cpuOnly:
        return PreferredBackend.cpu;
      case LiteRtBackendPreference.gpuThenNpuThenCpu:
        return PreferredBackend.gpu;
    }
  }

  /// Prefer GPU, then NPU (Android NNAPI-class accelerators), then CPU.
  Future<InferenceModel> _loadWithBackendFallback(
    ModelArtifactSpec spec,
  ) async {
    final order = switch (spec.backendPreference) {
      LiteRtBackendPreference.cpuOnly => <PreferredBackend>[
          PreferredBackend.cpu,
        ],
      LiteRtBackendPreference.gpuThenNpuThenCpu => <PreferredBackend>[
          PreferredBackend.gpu,
          PreferredBackend.npu,
          PreferredBackend.cpu,
        ],
    };

    Object? lastError;
    for (final backend in order) {
      try {
        _dbg('getActiveModel maxTokens=${spec.maxTokens} prefer=${backend.name}');
        final model = await FlutterGemma.getActiveModel(
          maxTokens: spec.maxTokens,
          preferredBackend: backend,
        );
        lastActiveBackend = model.activeBackend ?? backend;
        _dbg('loaded activeBackend=${lastActiveBackend?.name}');
        return model;
      } catch (e) {
        lastError = e;
        _dbg('backend ${backend.name} failed: $e');
      }
    }
    throw StateError(
      'Failed to load model on GPU/NPU/CPU. Last error: $lastError',
    );
  }

  Future<void> _dropLoadedModel() async {
    if (_loadedModel != null) {
      try {
        await _loadedModel!.close();
      } catch (_) {}
      _loadedModel = null;
      _loadedMaxTokens = null;
      _loadedBackendHint = null;
    }
  }

  Future<({String? path, bool exists, int bytes, bool installedThisCall})>
      _ensureModelInstalledFromManager({required bool force}) async {
    final path = await modelManager.resolvedActiveModelPath();
    if (path == null) {
      throw StateError(
        'No verified on-device model file is available. '
        'Complete model setup first.',
      );
    }

    final file = File(path);
    final exists = await file.exists();
    final bytes = exists ? await file.length() : 0;
    if (!exists || bytes < 1024 * 1024) {
      throw StateError(
        'Model file missing or too small at $path (bytes=$bytes). '
        'Re-run Download and prepare.',
      );
    }

    final spec = await _activeSpec();
    final expected = _toFlutterModelType(spec.modelKind);
    final fileType = _toFlutterFileType(spec.fileKind);
    final active = FlutterGemma.activeModelSpec;

    final activeMatches = FlutterGemma.hasActiveModel() &&
        active != null &&
        active.modelType == expected;

    if (!force && activeMatches) {
      _installedFromPath = path;
      if (_loadedModel == null ||
          _loadedMaxTokens != spec.maxTokens ||
          _loadedBackendHint != _primaryBackendHint(spec)) {
        _loadedModel = await _loadWithBackendFallback(spec);
        _loadedMaxTokens = spec.maxTokens;
        _loadedBackendHint = _primaryBackendHint(spec);
      }
      _dbg('reuse active model type=${expected.name} '
          'maxTokens=${spec.maxTokens} '
          'backend=${lastActiveBackend?.name ?? "?"}');
      return (
        path: path,
        exists: true,
        bytes: bytes,
        installedThisCall: false,
      );
    }

    // force=true, or no active install yet — register file with FlutterGemma.
    _dbg('installing modelType=${expected.name} fileType=${fileType.name} '
        'maxTokens=${spec.maxTokens} path=$path bytes=$bytes '
        'force=$force hasActive=${FlutterGemma.hasActiveModel()}');

    await _dropLoadedModel();

    final installation = await FlutterGemma.installModel(
      modelType: expected,
      fileType: fileType,
    ).fromFile(path).install();

    if (!FlutterGemma.hasActiveModel()) {
      throw StateError(
        'Install completed but FlutterGemma.hasActiveModel() is still false.',
      );
    }
    final activeAfter = FlutterGemma.activeModelSpec;
    if (activeAfter == null || activeAfter.modelType != expected) {
      throw StateError(
        'Install active model type mismatch: '
        'expected ${expected.name}, got ${activeAfter?.modelType.name}',
      );
    }

    _installedFromPath = path;
    await modelManager.markRuntimeInstallForCurrent();
    _loadedModel = await _loadWithBackendFallback(spec);
    _loadedMaxTokens = spec.maxTokens;
    _loadedBackendHint = _primaryBackendHint(spec);

    _dbg('install OK id=${installation.modelId} '
        'type=${installation.modelType.name}');

    return (path: path, exists: true, bytes: bytes, installedThisCall: true);
  }

  String? _activeTypeName() {
    return FlutterGemma.activeModelSpec?.modelType.name;
  }

  String _previewOf(ModelResponse response) {
    if (response is TextResponse) {
      return response.token;
    }
    if (response is FunctionCallResponse) {
      return '${response.name}(${response.args})';
    }
    if (response is ParallelFunctionCallResponse) {
      return '${response.calls.length} parallel calls: '
          '${response.calls.map((c) => '${c.name}(${c.args})').join(' | ')}';
    }
    return response.toString();
  }

  ModelType _toFlutterModelType(LiteRtModelKind kind) {
    switch (kind) {
      case LiteRtModelKind.gemmaIt:
        return ModelType.gemmaIt;
      case LiteRtModelKind.gemma4:
        return ModelType.gemma4;
      case LiteRtModelKind.deepSeek:
        return ModelType.deepSeek;
      case LiteRtModelKind.qwen:
        return ModelType.qwen;
      case LiteRtModelKind.qwen3:
        return ModelType.qwen3;
      case LiteRtModelKind.llama:
        return ModelType.llama;
      case LiteRtModelKind.hammer:
        return ModelType.hammer;
      case LiteRtModelKind.functionGemma:
        return ModelType.functionGemma;
      case LiteRtModelKind.phi:
        return ModelType.phi;
      case LiteRtModelKind.general:
        return ModelType.general;
    }
  }

  ModelFileType _toFlutterFileType(LiteRtFileKind kind) {
    switch (kind) {
      case LiteRtFileKind.task:
        return ModelFileType.task;
      case LiteRtFileKind.binary:
        return ModelFileType.binary;
      case LiteRtFileKind.litertlm:
        return ModelFileType.litertlm;
    }
  }

  Map<String, dynamic>? _safeStringKeyedMap(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      try {
        return Map<String, dynamic>.from(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  String _firstFrame(StackTrace st) {
    final lines = st.toString().split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('#0') || trimmed.contains('litert_')) {
        return trimmed;
      }
    }
    return lines.isEmpty ? '(no stack)' : lines.first.trim();
  }

  void _dbg(String message) {
    if (kDebugMode) {
      debugPrint('[LiteRtInferenceAdapter] $message');
    }
  }

  void _dbgBlock(String title, void Function() body) {
    if (!kDebugMode) {
      return;
    }
    debugPrint('[LiteRtInferenceAdapter] $title');
    body();
    debugPrint('[LiteRtInferenceAdapter] ${'=' * title.length}');
  }

  void _dbgChunk(String text) {
    if (!kDebugMode) {
      return;
    }
    const chunkSize = 700;
    if (text.isEmpty) {
      debugPrint('[LiteRtInferenceAdapter] (empty)');
      return;
    }
    for (var i = 0; i < text.length; i += chunkSize) {
      final end =
          i + chunkSize < text.length ? i + chunkSize : text.length;
      debugPrint(text.substring(i, end));
    }
  }
}
