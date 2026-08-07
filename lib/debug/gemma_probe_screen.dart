import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/ai/model_manager/model_catalog.dart';
import 'package:my_first_app/ai/model_manager/model_manager_providers.dart';
import 'package:my_first_app/debug/gemma_runtime_probe.dart';

/// Debug-only screen: Gemma 4 LiteRT-LM grounding / smoke probe.
class GemmaProbeScreen extends ConsumerStatefulWidget {
  const GemmaProbeScreen({super.key});

  @override
  ConsumerState<GemmaProbeScreen> createState() => _GemmaProbeScreenState();
}

class _GemmaProbeScreenState extends ConsumerState<GemmaProbeScreen> {
  var _running = false;
  String? _log;
  OfficialProbeReport? _report;

  Future<void> _run() async {
    setState(() {
      _running = true;
      _log = 'Resolving model path…';
      _report = null;
    });

    try {
      final path = await ref
          .read(modelDownloadManagerProvider)
          .pathFor(ModelCatalog.current);
      setState(
        () => _log =
            'Running Gemma 4 grounding probe on:\n$path\n'
            '(${ModelCatalog.current.displayName})',
      );

      final report = await GemmaRuntimeProbe(
        modelFilePath: path,
        allowNetworkDownload: true,
        suite: OfficialProbeSuite.extractionGrounding,
        artifact: ModelCatalog.current,
      ).run();
      if (!mounted) return;
      setState(() {
        _report = report;
        _log = report.toString();
      });
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _log = 'Probe runner threw (app still alive):\n$e\n$st');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(kDebugMode, 'GemmaProbeScreen is debug-only');
    return Scaffold(
      appBar: AppBar(title: const Text('Gemma 4 LiteRT-LM probe')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Runs the same 11-prompt literal-grounding suite against '
                '${ModelCatalog.current.displayName} '
                '(${ModelCatalog.current.fileName}) via LiteRT-LM.\n'
                'Backend preference: GPU → NPU → CPU.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _running ? null : _run,
                child: _running
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Run 11-prompt grounding probe'),
              ),
              if (_report != null) ...[
                const SizedBox(height: 12),
                Text(
                  'GROUNDING: accepted=${_report!.acceptedCount} '
                  'rejected=${_report!.rejectedCount} '
                  'avgQuality=${_report!.averageExtractionQuality.toStringAsFixed(2)} '
                  'backend=${_report!.activeBackend ?? "?"}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _report!.acceptedCount >= 8
                        ? Colors.green.shade800
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    _log ?? 'Idle.',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
