import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/app/app_routes.dart';
import 'package:my_first_app/core/constants/circle_tier_labels.dart';
import 'package:my_first_app/core/constants/enums.dart';
import 'package:my_first_app/features/person_form/person_form_controller.dart';

/// Shared create/edit person form. Mode is determined by [personUuid].
class PersonFormScreen extends ConsumerStatefulWidget {
  const PersonFormScreen({
    super.key,
    this.personUuid,
  });

  /// `null` = create; non-null = edit that person (uuid, never Isar id).
  final String? personUuid;

  @override
  ConsumerState<PersonFormScreen> createState() => _PersonFormScreenState();
}

class _PersonFormScreenState extends ConsumerState<PersonFormScreen> {
  final _nameController = TextEditingController();
  final _relationshipController = TextEditingController();
  var _seeded = false;
  var _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  void _seedFieldsIfNeeded(PersonFormController form) {
    if (_seeded) return;
    _nameController.text = form.name;
    _relationshipController.text = form.relationshipType;
    _seeded = true;
  }

  Future<void> _onSave(PersonFormController form) async {
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

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(personFormControllerProvider(widget.personUuid));
    final form =
        ref.read(personFormControllerProvider(widget.personUuid).notifier);
    final isCreate = widget.personUuid == null;
    final title = isCreate ? 'Add person' : 'Edit person';

    ref.listen<AsyncValue<void>>(
      personFormControllerProvider(widget.personUuid),
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
              TextField(
                controller: _nameController,
                enabled: !_saving,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Name',
                  errorText: form.nameError,
                ),
                onChanged: form.updateName,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<CircleTier>(
                initialValue: form.circleTier,
                decoration: InputDecoration(
                  labelText: 'Circle tier',
                  errorText: form.circleTierError,
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
                    : (tier) {
                        if (tier != null) {
                          form.updateCircleTier(tier);
                        }
                      },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _relationshipController,
                enabled: !_saving,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Relationship type',
                  hintText: 'Optional — e.g. college friend',
                  errorText: form.relationshipTypeError,
                ),
                onChanged: form.updateRelationshipType,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _saving ? null : () => _onSave(form),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isCreate ? 'Add person' : 'Save changes'),
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

/// Convenience navigation helpers for person form routes.
extension PersonFormNavigation on BuildContext {
  void openCreatePerson() => push(AppRoutes.personNew);

  void openEditPerson(String personUuid) =>
      push(AppRoutes.personEdit(personUuid));
}
