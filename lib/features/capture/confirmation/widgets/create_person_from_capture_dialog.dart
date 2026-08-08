import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/core/analytics/capture_analytics.dart';
import 'package:my_first_app/core/constants/circle_tier_labels.dart';
import 'package:my_first_app/core/constants/enums.dart';
import 'package:my_first_app/core/constants/person_defaults.dart';
import 'package:my_first_app/data/local/isar/collections/person.dart';
import 'package:my_first_app/domain/rules/extraction_validation_rules.dart';
import 'package:my_first_app/domain/validators/person_validators.dart';
import 'package:my_first_app/features/circle/circle_providers.dart';
import 'package:uuid/uuid.dart';

/// Explicit Create Person from capture confirmation.
///
/// Returns the new (or existing exact-match) person uuid, or null if cancelled.
/// Never creates without the user confirming this dialog.
Future<String?> showCreatePersonFromCaptureDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String suggestedName,
  required List<Person> existingPeople,
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return _CreatePersonFromCaptureDialog(
        suggestedName: suggestedName,
        existingPeople: existingPeople,
        ref: ref,
      );
    },
  );
}

class _CreatePersonFromCaptureDialog extends StatefulWidget {
  const _CreatePersonFromCaptureDialog({
    required this.suggestedName,
    required this.existingPeople,
    required this.ref,
  });

  final String suggestedName;
  final List<Person> existingPeople;
  final WidgetRef ref;

  @override
  State<_CreatePersonFromCaptureDialog> createState() =>
      _CreatePersonFromCaptureDialogState();
}

class _CreatePersonFromCaptureDialogState
    extends State<_CreatePersonFromCaptureDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _relationshipController;
  var _circleTier = defaultCircleTier;
  String? _nameError;
  String? _relationshipError;
  String? _formError;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.suggestedName.trim());
    _relationshipController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    setState(() {
      _formError = null;
      _nameError = validatePersonName(_nameController.text);
      _relationshipError =
          validateRelationshipType(_relationshipController.text);
    });
    if (_nameError != null || _relationshipError != null) {
      return;
    }

    final trimmedName = _nameController.text.trim();
    final known = widget.existingPeople
        .map((p) => (uuid: p.uuid, name: p.name));

    // Prevent duplicate: if an exact unique match already exists, select it.
    final existing = resolveUniquePersonNameMatch(
      personMentioned: trimmedName,
      knownPeople: known,
    );
    if (existing.uuid != null) {
      if (mounted) {
        Navigator.of(context).pop(existing.uuid);
      }
      return;
    }

    if (hasExactPersonNameMatch(
      personMentioned: trimmedName,
      knownNames: widget.existingPeople.map((p) => p.name),
    )) {
      setState(() {
        _formError =
            'A person named "$trimmedName" already exists in My Circle. '
            'Select them from the list instead.';
      });
      return;
    }

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final relationship = _relationshipController.text.trim();
      final person = Person()
        ..uuid = const Uuid().v4()
        ..name = trimmedName
        ..circleTier = _circleTier
        ..relationshipType = relationship.isEmpty ? null : relationship
        ..createdAt = now
        ..updatedAt = now
        ..syncStatus = SyncStatus.pending
        ..deletedAt = null;

      await widget.ref.read(personRepositoryProvider).create(person);
      widget.ref
          .read(captureAnalyticsProvider)
          .personCreatedDuringConfirmation();
      if (!mounted) return;
      Navigator.of(context).pop(person.uuid);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _formError =
            'Could not create this person. Please try again.';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create person'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add this person to My Circle, then continue reviewing the memory.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                errorText: _nameError,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) {
                if (_nameError != null) {
                  setState(() => _nameError = null);
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _relationshipController,
              decoration: InputDecoration(
                labelText: 'Relationship',
                hintText: 'e.g. college friend',
                errorText: _relationshipError,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (_relationshipError != null) {
                  setState(() => _relationshipError = null);
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CircleTier>(
              // ignore: deprecated_member_use
              value: _circleTier,
              decoration: const InputDecoration(
                labelText: 'Circle',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final tier in CircleTier.values)
                  DropdownMenuItem(
                    value: tier,
                    child: Text(circleTierLabel(tier)),
                  ),
              ],
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _circleTier = value);
                      }
                    },
            ),
            if (_formError != null) ...[
              const SizedBox(height: 12),
              Text(
                _formError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _onConfirm,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create person'),
        ),
      ],
    );
  }
}
