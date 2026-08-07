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
/// `AsyncValue<void>` covers load + save lifecycle; draft fields live on the
/// notifier and are updated via setters so the UI stays logic-free.
final personFormControllerProvider = AsyncNotifierProvider.family<
    PersonFormController,
    void,
    String?>(PersonFormController.new);

class PersonFormController extends AsyncNotifier<void> {
  PersonFormController(this.personUuid);

  /// `null` → create; non-null → edit that person.
  final String? personUuid;

  String name = '';
  CircleTier circleTier = defaultCircleTier;
  String relationshipType = '';

  String? nameError;
  String? circleTierError;
  String? relationshipTypeError;

  Person? _existing;

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

    if (personUuid == null) {
      name = '';
      circleTier = defaultCircleTier;
      relationshipType = '';
      _existing = null;
      return;
    }

    final person =
        await ref.read(personRepositoryProvider).getByUuid(personUuid!);
    if (person == null) {
      throw StateError('Person not found: $personUuid');
    }

    _existing = person;
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
  /// returns `false`. On success, state is [AsyncData]; on persist failure,
  /// state is [AsyncError].
  Future<bool> save() async {
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

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(personRepositoryProvider);

      if (_existing == null) {
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
        _existing = person;
      } else {
        final person = _existing!
          ..name = trimmedName
          ..circleTier = circleTier
          ..relationshipType = relationship
          ..updatedAt = now
          ..syncStatus = SyncStatus.pending;
        await repo.update(person);
      }
    });

    return !state.hasError;
  }

  void _emitDraft() {
    state = const AsyncData(null);
  }
}
