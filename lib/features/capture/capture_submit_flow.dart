import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/ai/model_manager/device_capability_check.dart';
import 'package:my_first_app/ai/model_manager/model_manager_providers.dart';
import 'package:my_first_app/app/app_routes.dart';
import 'package:my_first_app/core/constants/enums.dart';
import 'package:my_first_app/data/local/isar/collections/person.dart';
import 'package:my_first_app/features/capture/capture_controller.dart';
import 'package:my_first_app/features/capture/confirmation/capture_confirmation_args.dart';
import 'package:my_first_app/features/circle/circle_providers.dart';

/// Shared Capture → extract → confirm (or manual fallback) entry point.
///
/// Used by Typed, Voice, OCR, and Share so empty/failure UX stays consistent.
class CaptureSubmitFlow {
  const CaptureSubmitFlow._();

  static Future<bool> shouldUseAssistedCapture(WidgetRef ref) async {
    final tier = await ref.read(deviceAiTierProvider.future);
    if (tier == DeviceAiTier.unsupported) {
      return false;
    }
    return ref.read(currentModelReadyProvider.future);
  }

  /// Runs [CaptureController.submitText] and navigates to confirmation.
  static Future<CaptureSubmitFlowOutcome> submitText({
    required BuildContext context,
    required WidgetRef ref,
    required String text,
    required SourceType sourceType,
    String? sourceRef,
    required void Function(String route, CaptureConfirmationArgs args)
        onNavigateToConfirmation,
  }) async {
    final useAssisted = await shouldUseAssistedCapture(ref);
    if (!context.mounted) {
      return const CaptureSubmitFlowOutcome.cancelled();
    }

    if (!useAssisted) {
      final wentManual = await enterManually(
        context: context,
        ref: ref,
        text: text,
      );
      return wentManual
          ? const CaptureSubmitFlowOutcome.navigated()
          : const CaptureSubmitFlowOutcome.cancelled();
    }

    final result =
        await ref.read(captureControllerProvider).submitText(text);

    if (!context.mounted) {
      return const CaptureSubmitFlowOutcome.cancelled();
    }

    switch (result) {
      case CaptureSubmitReady(:final candidates):
        final args = CaptureConfirmationArgs(
          candidates: candidates,
          originalText: text,
          sourceType: sourceType,
          sourceRef: sourceRef,
        );
        final route = args.isSingle
            ? AppRoutes.captureConfirm
            : AppRoutes.captureConfirmSummary;
        onNavigateToConfirmation(route, args);
        return const CaptureSubmitFlowOutcome.navigated();
      case CaptureSubmitEmpty():
        return const CaptureSubmitFlowOutcome.empty();
      case CaptureSubmitFailed(:final userMessage):
        return CaptureSubmitFlowOutcome.failure(userMessage);
    }
  }

  /// Unsupported / model-not-ready path: pick a person and open Memory form.
  static Future<bool> enterManually({
    required BuildContext context,
    required WidgetRef ref,
    required String text,
  }) async {
    final people =
        ref.read(allPeopleProvider).asData?.value ?? const <Person>[];
    if (people.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add someone to My Circle before logging a memory.'),
        ),
      );
      return false;
    }

    final selected = await showDialog<Person>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text('Who is this memory about?'),
          children: [
            for (final person in people)
              SimpleDialogOption(
                onPressed: () => Navigator.of(dialogContext).pop(person),
                child: Text(person.name),
              ),
          ],
        );
      },
    );

    if (selected == null || !context.mounted) return false;

    await context.push(
      AppRoutes.memoryNew(selected.uuid),
      extra: text.trim(),
    );
    return true;
  }
}

/// Result of [CaptureSubmitFlow.submitText] for UI status handling.
sealed class CaptureSubmitFlowOutcome {
  const CaptureSubmitFlowOutcome();

  const factory CaptureSubmitFlowOutcome.navigated() =
      CaptureSubmitFlowNavigated;

  const factory CaptureSubmitFlowOutcome.cancelled() =
      CaptureSubmitFlowCancelled;

  /// Valid empty: AI finished; no grounded memories.
  const factory CaptureSubmitFlowOutcome.empty() = CaptureSubmitFlowEmpty;

  /// Genuine pipeline failure only.
  const factory CaptureSubmitFlowOutcome.failure(String userMessage) =
      CaptureSubmitFlowFailure;
}

class CaptureSubmitFlowNavigated extends CaptureSubmitFlowOutcome {
  const CaptureSubmitFlowNavigated();
}

class CaptureSubmitFlowCancelled extends CaptureSubmitFlowOutcome {
  const CaptureSubmitFlowCancelled();
}

class CaptureSubmitFlowEmpty extends CaptureSubmitFlowOutcome {
  const CaptureSubmitFlowEmpty();
}

class CaptureSubmitFlowFailure extends CaptureSubmitFlowOutcome {
  const CaptureSubmitFlowFailure(this.userMessage);

  final String userMessage;
}
