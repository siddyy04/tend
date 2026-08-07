import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/ai/model_manager/model_download_manager.dart';
import 'package:my_first_app/ai/model_manager/model_manager_providers.dart';
import 'package:my_first_app/app/app_routes.dart';

/// Persistent capture entry for the app shell (global, not person-scoped).
///
/// - [ModelAssistStatus.notConfigured] → model setup
/// - [ModelAssistStatus.manualMode] / [ModelAssistStatus.modelReady] → capture
class CaptureEntryPoint extends ConsumerWidget {
  const CaptureEntryPoint({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      onPressed: () => unawaited(_openCapture(context, ref)),
      tooltip: 'Capture memory',
      child: const Icon(Icons.edit_note),
    );
  }

  Future<void> _openCapture(BuildContext context, WidgetRef ref) async {
    final status = await ref.read(modelAssistStatusProvider.future);
    if (!context.mounted) return;

    switch (status) {
      case ModelAssistStatus.notConfigured:
        unawaited(context.push(AppRoutes.modelSetup));
      case ModelAssistStatus.manualMode:
      case ModelAssistStatus.modelReady:
        unawaited(context.push(AppRoutes.capture));
    }
  }
}
