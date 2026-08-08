import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/ai/providers/ai_provider_selection.dart';
import 'package:my_first_app/ai/providers/transcription_provider.dart';
import 'package:my_first_app/features/settings/speech_locale_preferences.dart';

/// Result of resolving speech language for a transcription session.
class ResolvedSpeechLocale {
  const ResolvedSpeechLocale({this.localeId});

  /// Engine locale id, or null to let the engine use its default.
  final String? localeId;
}

/// Resolves which speech locale to use for the next transcription session.
///
/// Order: saved preference (if still supported) → engine recommended/system →
/// user picker when detection is unavailable or ambiguous.
///
/// Returns `null` only when the user cancels the language picker.
Future<ResolvedSpeechLocale?> ensureSpeechLocale({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final provider = ref.read(activeTranscriptionProvider);
  final prefs = ref.read(speechLocalePreferencesProvider);

  final supported = await provider.supportedLocales();
  final saved = await prefs.getLocaleId();

  if (saved != null && saved.isNotEmpty) {
    final match = _findLocale(supported, saved);
    if (match != null) {
      return ResolvedSpeechLocale(localeId: match.localeId);
    }
    // Saved id unknown to this engine — fall through to recommend / pick.
  }

  final recommended = await provider.recommendedLocale();
  if (recommended != null) {
    final match = _findLocale(supported, recommended.localeId);
    if (supported.isEmpty || match != null) {
      final locale = match ?? recommended;
      await prefs.setLocaleId(locale.localeId);
      return ResolvedSpeechLocale(localeId: locale.localeId);
    }
  }

  if (supported.isEmpty) {
    // No locale catalog — proceed with engine default.
    return const ResolvedSpeechLocale(localeId: null);
  }

  if (!context.mounted) return null;

  final chosen = await showSpeechLocalePicker(
    context: context,
    locales: supported,
    title: 'Choose speech language',
    message:
        'Tend could not detect a clear speech language for this device. '
        'Pick the language you will speak in. You can change this later in Settings.',
  );

  if (chosen == null) return null;
  await prefs.setLocaleId(chosen.localeId);
  return ResolvedSpeechLocale(localeId: chosen.localeId);
}

TranscriptionLocale? _findLocale(
  List<TranscriptionLocale> locales,
  String localeId,
) {
  final needle = localeId.toLowerCase().replaceAll('-', '_');
  for (final locale in locales) {
    final id = locale.localeId.toLowerCase().replaceAll('-', '_');
    if (id == needle) return locale;
  }
  final lang = needle.split('_').first;
  for (final locale in locales) {
    final id = locale.localeId.toLowerCase().replaceAll('-', '_');
    if (id == lang || id.startsWith('${lang}_')) return locale;
  }
  return null;
}

/// Modal picker for speech language (first-run or Settings).
Future<TranscriptionLocale?> showSpeechLocalePicker({
  required BuildContext context,
  required List<TranscriptionLocale> locales,
  required String title,
  String? message,
  String? selectedLocaleId,
}) {
  return showDialog<TranscriptionLocale>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (message != null) ...[
                Text(message),
                const SizedBox(height: 12),
              ],
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: locales.length,
                  itemBuilder: (context, index) {
                    final locale = locales[index];
                    final selected = selectedLocaleId != null &&
                        locale.localeId.toLowerCase().replaceAll('-', '_') ==
                            selectedLocaleId
                                .toLowerCase()
                                .replaceAll('-', '_');
                    return ListTile(
                      title: Text(locale.name),
                      subtitle: Text(locale.localeId),
                      selected: selected,
                      onTap: () => Navigator.of(dialogContext).pop(locale),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );
}
