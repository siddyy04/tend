import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/ai/providers/ai_provider_selection.dart';
import 'package:my_first_app/features/settings/speech_locale_preferences.dart';
import 'package:my_first_app/features/settings/speech_locale_resolver.dart';
import 'package:my_first_app/features/settings/widgets/gecko_model_settings_tile.dart';

/// Minimal Settings surface (Sprint 2B.4): speech language for transcription.
///
/// Broader settings (logout relocation, sync, etc.) remain backlog.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _localeId;
  String? _localeLabel;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final prefs = ref.read(speechLocalePreferencesProvider);
    final saved = await prefs.getLocaleId();
    final provider = ref.read(activeTranscriptionProvider);
    final supported = await provider.supportedLocales();
    final recommended = await provider.recommendedLocale();

    String? label;
    if (saved != null) {
      for (final locale in supported) {
        if (locale.localeId.toLowerCase().replaceAll('-', '_') ==
            saved.toLowerCase().replaceAll('-', '_')) {
          label = locale.name;
          break;
        }
      }
      label ??= saved;
    } else if (recommended != null) {
      label = '${recommended.name} (device default)';
    }

    if (!mounted) return;
    setState(() {
      _localeId = saved;
      _localeLabel = label ?? 'Not set';
      _loading = false;
    });
  }

  Future<void> _changeSpeechLanguage() async {
    final provider = ref.read(activeTranscriptionProvider);
    final supported = await provider.supportedLocales();
    if (!mounted) return;

    if (supported.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No speech languages are available from the current transcription engine.',
          ),
        ),
      );
      return;
    }

    final chosen = await showSpeechLocalePicker(
      context: context,
      locales: supported,
      title: 'Speech language',
      message:
          'Used for voice capture transcription. Applies to the active '
          'speech engine (platform STT today; future engines will reuse this preference).',
      selectedLocaleId: _localeId,
    );

    if (chosen == null) return;
    await ref.read(speechLocalePreferencesProvider).setLocaleId(chosen.localeId);
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Voice'),
            subtitle: Text(
              'Speech language applies to whatever transcription provider '
              'is active. Sprint 2B.4 uses platform speech-to-text; a future '
              'long-form engine can reuse this setting.',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.record_voice_over_outlined),
            title: const Text('Speech language'),
            subtitle: Text(
              _loading ? 'Loading…' : (_localeLabel ?? 'Not set'),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _loading ? null : _changeSpeechLanguage,
          ),
          const Divider(),
          const GeckoModelSettingsTile(),
        ],
      ),
    );
  }
}
