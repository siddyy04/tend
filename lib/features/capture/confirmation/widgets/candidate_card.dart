import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/core/constants/enums.dart';
import 'package:my_first_app/core/constants/memory_category_labels.dart';
import 'package:my_first_app/data/local/isar/collections/person.dart';
import 'package:my_first_app/features/capture/confirmation/capture_confirmation_controller.dart';
import 'package:my_first_app/features/capture/confirmation/widgets/create_person_from_capture_dialog.dart';
import 'package:my_first_app/features/capture/confirmation/widgets/needs_review_chip.dart';
import 'package:my_first_app/features/capture/confirmation/widgets/person_picker_field.dart';
import 'package:my_first_app/features/circle/circle_providers.dart';

/// Single-candidate editable card (plain treatment — polish is Sprint 2B).
class CandidateCard extends ConsumerStatefulWidget {
  const CandidateCard({
    super.key,
    required this.controller,
    required this.people,
    required this.eventTextController,
    required this.dateRawController,
  });

  final CaptureConfirmationController controller;
  final List<Person> people;
  final TextEditingController eventTextController;
  final TextEditingController dateRawController;

  @override
  ConsumerState<CandidateCard> createState() => _CandidateCardState();
}

class _CandidateCardState extends ConsumerState<CandidateCard> {
  /// People created on this card before [allPeopleProvider] catches up.
  final List<Person> _createdPeople = [];

  bool get _dateEnabled =>
      widget.controller.datePrecision == DatePrecision.explicit;

  List<Person> get _peopleForPicker {
    final byUuid = <String, Person>{
      for (final p in widget.people) p.uuid: p,
      for (final p in _createdPeople) p.uuid: p,
    };
    return byUuid.values.toList();
  }

  Future<void> _onCreatePerson() async {
    final mentioned = widget.controller.initial.personMentioned.trim();
    if (mentioned.isEmpty) return;

    final uuid = await showCreatePersonFromCaptureDialog(
      context: context,
      ref: ref,
      suggestedName: mentioned,
      existingPeople: _peopleForPicker,
    );
    if (uuid == null || !mounted) return;

    final created =
        await ref.read(personRepositoryProvider).getByUuid(uuid);
    if (created != null &&
        !_peopleForPicker.any((p) => p.uuid == created.uuid)) {
      setState(() => _createdPeople.add(created));
    }
    widget.controller.updateSelectedPersonUuid(uuid);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (controller.showLowConfidenceLabel)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: NeedsReviewChip(),
          ),
        PersonPickerField(
          people: _peopleForPicker,
          selectedPersonUuid: controller.selectedPersonUuid,
          personMentioned: controller.initial.personMentioned,
          errorText: controller.personError,
          onChanged: controller.updateSelectedPersonUuid,
          onCreatePerson: _onCreatePerson,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<MemoryCategory>(
          // ignore: deprecated_member_use — value is the stable API in this Flutter pin
          value: controller.category,
          decoration: InputDecoration(
            labelText: 'Category',
            errorText: controller.categoryError,
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final category in MemoryCategory.values)
              DropdownMenuItem(
                value: category,
                child: Text(memoryCategoryLabel(category)),
              ),
          ],
          onChanged: (value) {
            if (value != null) controller.updateCategory(value);
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: widget.eventTextController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Event',
            errorText: controller.eventTextError,
            border: const OutlineInputBorder(),
          ),
          onChanged: controller.updateEventText,
        ),
        const SizedBox(height: 12),
        Text(
          'Grounding quote',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        Text(
          controller.quoteEvidence,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Exact date'),
          value: _dateEnabled,
          onChanged: controller.updateDateEnabled,
        ),
        if (_dateEnabled) ...[
          const SizedBox(height: 8),
          if (controller.dateValue == null &&
              (controller.dateValueRaw?.trim().isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'From note: ${controller.dateValueRaw!.trim()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          OutlinedButton(
            onPressed: () async {
              final now = DateTime.now();
              final initial = controller.dateValue ?? now;
              final picked = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: DateTime(1900),
                lastDate: DateTime(now.year + 50),
              );
              if (picked != null) {
                controller.updateDateValue(picked);
              }
            },
            child: Text(
              controller.dateValue == null
                  ? 'Pick date'
                  : _formatDate(controller.dateValue!),
            ),
          ),
          if (controller.dateError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                controller.dateError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ] else if (controller.datePrecision == DatePrecision.relative ||
            (controller.dateValueRaw?.isNotEmpty ?? false)) ...[
          const SizedBox(height: 8),
          TextField(
            controller: widget.dateRawController,
            decoration: const InputDecoration(
              labelText: 'Relative date',
              border: OutlineInputBorder(),
            ),
            onChanged: controller.updateDateValueRaw,
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Importance: ${controller.importanceScore}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        Slider(
          value: controller.importanceScore.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          label: '${controller.importanceScore}',
          onChanged: (value) {
            controller.updateImportanceScore(value.round());
          },
        ),
        if (controller.importanceScoreError != null)
          Text(
            controller.importanceScoreError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
