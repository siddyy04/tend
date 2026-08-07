import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/app/app_routes.dart';
import 'package:my_first_app/core/constants/memory_category_labels.dart';
import 'package:my_first_app/core/constants/enums.dart';
import 'package:my_first_app/features/memory_form/memory_form_controller.dart';

/// Shared create/edit memory form. Mode is determined by [memoryUuid].
class MemoryFormScreen extends ConsumerStatefulWidget {
  const MemoryFormScreen({
    super.key,
    required this.personUuid,
    this.memoryUuid,
    this.initialEventText,
  });

  final String personUuid;

  /// `null` = create; non-null = edit that memory (uuid, never Isar id).
  final String? memoryUuid;

  /// Optional create-mode prefill (e.g. capture fallback).
  final String? initialEventText;

  @override
  ConsumerState<MemoryFormScreen> createState() => _MemoryFormScreenState();
}

class _MemoryFormScreenState extends ConsumerState<MemoryFormScreen> {
  final _eventTextController = TextEditingController();
  var _seeded = false;
  var _saving = false;

  MemoryFormArgs get _args => (
        personUuid: widget.personUuid,
        memoryUuid: widget.memoryUuid,
        initialEventText: widget.initialEventText,
      );

  @override
  void dispose() {
    _eventTextController.dispose();
    super.dispose();
  }

  void _seedFieldsIfNeeded(MemoryFormController form) {
    if (_seeded) return;
    _eventTextController.text = form.eventText;
    _seeded = true;
  }

  Future<void> _onSave(MemoryFormController form) async {
    setState(() => _saving = true);
    try {
      final saved = await form.save();
      if (!mounted) return;
      if (saved) {
        context.pop();
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickDate(MemoryFormController form) async {
    final now = DateTime.now();
    final initial = form.dateValue ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 50),
    );
    if (picked == null) return;
    form.updateDateValue(picked);
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(memoryFormControllerProvider(_args));
    final form = ref.read(memoryFormControllerProvider(_args).notifier);
    final isCreate = widget.memoryUuid == null;
    final title = isCreate ? 'Add memory' : 'Edit memory';

    ref.listen<AsyncValue<void>>(
      memoryFormControllerProvider(_args),
      (previous, next) {
        if (next.hasValue) {
          _seedFieldsIfNeeded(form);
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (_) {
          if (!_seeded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _seedFieldsIfNeeded(form);
            });
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<MemoryCategory>(
                initialValue: form.category,
                decoration: InputDecoration(
                  labelText: 'Category',
                  errorText: form.categoryError,
                ),
                hint: const Text('Select a category'),
                items: [
                  for (final category in MemoryCategory.values)
                    DropdownMenuItem(
                      value: category,
                      child: Text(memoryCategoryLabel(category)),
                    ),
                ],
                onChanged: _saving
                    ? null
                    : (category) {
                        if (category != null) {
                          form.updateCategory(category);
                        }
                      },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _eventTextController,
                enabled: !_saving,
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'What happened',
                  alignLabelWithHint: true,
                  errorText: form.eventTextError,
                ),
                onChanged: form.updateEventText,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Include a date'),
                value: form.dateEnabled,
                onChanged: _saving
                    ? null
                    : (enabled) => form.updateDateEnabled(enabled),
              ),
              if (form.dateEnabled) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    form.dateValue != null
                        ? _formatDate(form.dateValue!)
                        : 'Pick a date',
                  ),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: _saving ? null : () => _pickDate(form),
                ),
              ],
              if (form.dateError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    form.dateError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Importance',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('1')),
                  ButtonSegment(value: 2, label: Text('2')),
                  ButtonSegment(value: 3, label: Text('3')),
                  ButtonSegment(value: 4, label: Text('4')),
                  ButtonSegment(value: 5, label: Text('5')),
                ],
                selected: {form.importanceScore},
                onSelectionChanged: _saving
                    ? null
                    : (values) {
                        if (values.isNotEmpty) {
                          form.updateImportanceScore(values.first);
                        }
                      },
              ),
              if (form.importanceScoreError != null) ...[
                const SizedBox(height: 4),
                Text(
                  form.importanceScoreError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _saving ? null : () => _onSave(form),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isCreate ? 'Add memory' : 'Save changes'),
              ),
              if (form.saveError != null) ...[
                const SizedBox(height: 16),
                Text(
                  form.saveError.toString(),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Navigation helpers for memory form routes.
extension MemoryFormNavigation on BuildContext {
  void openCreateMemory(String personUuid) =>
      push(AppRoutes.memoryNew(personUuid));

  void openEditMemory(String personUuid, String memoryUuid) =>
      push(AppRoutes.memoryEdit(personUuid, memoryUuid));
}
