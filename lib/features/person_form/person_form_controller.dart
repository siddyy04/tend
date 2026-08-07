import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/core/constants/enums.dart';
import 'package:my_first_app/core/constants/person_defaults.dart';
import 'package:my_first_app/data/local/isar/collections/person.dart';
import 'package:my_first_app/domain/validators/person_validators.dart';
import 'package:my_first_app/features/circle/circle_providers.dart';
import 'package:uuid/uuid.dart';

/// Create/edit person form — family key is optional [personUuid]
/// (`null` = create mode).
///
/// Auto-dispose so each Add/Edit navigation gets a fresh controller.
/// Create vs edit is determined solely by [personUuid], never by mutable
/// controller state.
///
/// `AsyncValue<void>` covers load + save lifecycle; draft fields live on the
/// notifier and are updated via setters so the UI stays logic-free.
final personFormControllerProvider = AsyncNotifierProvider.autoDispose
    .family<PersonFormController, void, String?>(PersonFormController.new);

class PersonFormController extends AsyncNotifier<void> {
  PersonFormController(this.personUuid);

  /// `null` → create; non-null → edit that person.
  /// This is the sole source of truth for create vs edit.
  final String? personUuid;

  String name = '';
  CircleTier circleTier = defaultCircleTier;
  String relationshipType = '';

  String? nameError;
  String? circleTierError;
  String? relationshipTypeError;

  /// Set when persist fails; cleared on the next [save] attempt.
  Object? saveError;

  bool get isEditMode => personUuid != null;

  @override
  bool updateShouldNotify(AsyncValue<void> previous, AsyncValue<void> next) {
    // Draft field updates re-emit AsyncData(null); always notify so the form
    // rebuilds for validation clears and tier changes.
    return true;
  }

  @override
  Future<void> build() async {
    nameError = null;
    circleTierError = null;
    relationshipTypeError = null;
    saveError = null;

    if (personUuid == null) {
      name = '';
      circleTier = defaultCircleTier;
      relationshipType = '';
      return;
    }

    final person =
        await ref.read(personRepositoryProvider).getByUuid(personUuid!);
    if (person == null) {
      throw StateError('Person not found: $personUuid');
    }

    name = person.name;
    circleTier = person.circleTier;
    relationshipType = person.relationshipType ?? '';
  }

  void updateName(String value) {
    name = value;
    nameError = null;
    _emitDraft();
  }

  void updateCircleTier(CircleTier value) {
    circleTier = value;
    circleTierError = null;
    _emitDraft();
  }

  void updateRelationshipType(String value) {
    relationshipType = value;
    relationshipTypeError = null;
    _emitDraft();
  }

  /// Validates and persists. Returns `true` on success.
  ///
  /// On validation failure, sets field errors, does not write to Isar, and
  /// returns `false`. Persist failures set [saveError] and keep [AsyncData]
  /// so the form stays visible (load errors still use [AsyncError]).
  ///
  /// Create vs update is decided only by [personUuid].
  Future<bool> save() async {
    saveError = null;
    nameError = validatePersonName(name);
    circleTierError = validateCircleTier(circleTier);
    relationshipTypeError = validateRelationshipType(relationshipType);

    if (nameError != null ||
        circleTierError != null ||
        relationshipTypeError != null) {
      _emitDraft();
      return false;
    }

    final trimmedName = name.trim();
    final trimmedRelationship = relationshipType.trim();
    final relationship =
        trimmedRelationship.isEmpty ? null : trimmedRelationship;
    final now = DateTime.now();

    try {
      final repo = ref.read(personRepositoryProvider);

      if (personUuid == null) {
        final person = Person()
          ..uuid = const Uuid().v4()
          ..name = trimmedName
          ..circleTier = circleTier
          ..relationshipType = relationship
          ..createdAt = now
          ..updatedAt = now
          ..syncStatus = SyncStatus.pending
          ..deletedAt = null;
        await repo.create(person);
      } else {
        final person = await repo.getByUuid(personUuid!);
        if (person == null) {
          throw StateError('Person not found: $personUuid');
        }
        person
          ..name = trimmedName
          ..circleTier = circleTier
          ..relationshipType = relationship
          ..updatedAt = now
          ..syncStatus = SyncStatus.pending;
        await repo.update(person);
      }

      _emitDraft();
      return true;
    } catch (e) {
      saveError = e;
      _emitDraft();
      return false;
    }
  }

  void _emitDraft() {
    state = const AsyncData(null);
  }
}
