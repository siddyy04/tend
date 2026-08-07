import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/core/constants/enums.dart';
import 'package:my_first_app/core/constants/memory_category_labels.dart';
import 'package:my_first_app/data/local/isar/collections/person.dart';
import 'package:my_first_app/features/capture/confirmation/capture_confirmation_controller.dart';
import 'package:my_first_app/features/capture/confirmation/widgets/person_picker_field.dart';

/// Single-candidate editable card (plain treatment — polish is Sprint 2B).
class CandidateCard extends ConsumerWidget {
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

  bool get _dateEnabled =>
      controller.datePrecision == DatePrecision.explicit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (controller.showLowConfidenceLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Please double-check this memory before saving.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        PersonPickerField(
          people: people,
          selectedPersonUuid: controller.selectedPersonUuid,
          errorText: controller.personError,
          onChanged: controller.updateSelectedPersonUuid,
        ),
        if (controller.initial.personMentioned.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Mentioned as: ${controller.initial.personMentioned}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
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
          controller: eventTextController,
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
            controller: dateRawController,
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
