import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/ai/providers/ai_provider_selection.dart';
import 'package:my_first_app/core/constants/enums.dart';
import 'package:my_first_app/core/constants/memory_defaults.dart';
import 'package:my_first_app/data/local/isar/collections/memory.dart';
import 'package:my_first_app/domain/rules/date_resolution_rules.dart';
import 'package:my_first_app/domain/rules/memory_sensitivity_rules.dart';
import 'package:my_first_app/domain/validators/memory_validators.dart';
import 'package:my_first_app/features/person_profile/person_profile_providers.dart';
import 'package:uuid/uuid.dart';

/// Family key for [memoryFormControllerProvider].
///
/// [personUuid] is always required. [memoryUuid] is null in create mode.
/// [initialEventText] optionally pre-fills create mode (capture fallback).
typedef MemoryFormArgs = ({
  String personUuid,
  String? memoryUuid,
  String? initialEventText,
});

/// Create/edit memory form — autoDispose family keyed by [MemoryFormArgs].
///
/// Create vs edit is determined solely by [MemoryFormArgs.memoryUuid].
final memoryFormControllerProvider = AsyncNotifierProvider.autoDispose
    .family<MemoryFormController, void, MemoryFormArgs>(
  MemoryFormController.new,
);

class MemoryFormController extends AsyncNotifier<void> {
  MemoryFormController(this.args);

  final MemoryFormArgs args;

  String get personUuid => args.personUuid;
  String? get memoryUuid => args.memoryUuid;

  /// Sole source of truth for create vs edit.
  bool get isEditMode => memoryUuid != null;

  MemoryCategory? category;
  String eventText = '';
  bool dateEnabled = false;
  DateTime? dateValue;
  int importanceScore = defaultImportanceScore;

  String? categoryError;
  String? eventTextError;
  String? dateError;
  String? importanceScoreError;

  /// Set when persist fails; cleared on the next [save] attempt.
  Object? saveError;

  @override
  bool updateShouldNotify(AsyncValue<void> previous, AsyncValue<void> next) {
    return true;
  }

  @override
  Future<void> build() async {
    categoryError = null;
    eventTextError = null;
    dateError = null;
    importanceScoreError = null;
    saveError = null;

    if (memoryUuid == null) {
      category = null;
      eventText = args.initialEventText?.trim() ?? '';
      dateEnabled = false;
      dateValue = null;
      importanceScore = defaultImportanceScore;
      return;
    }

    final memory =
        await ref.read(memoryRepositoryProvider).getByUuid(memoryUuid!);
    if (memory == null) {
      throw StateError('Memory not found: $memoryUuid');
    }

    category = memory.category;
    eventText = memory.eventText;
    dateEnabled = memory.datePrecision == DatePrecision.explicit &&
        memory.dateValue != null;
    dateValue = memory.dateValue;
    importanceScore = memory.importanceScore;
  }

  void updateCategory(MemoryCategory value) {
    category = value;
    categoryError = null;
    _emitDraft();
  }

  void updateEventText(String value) {
    eventText = value;
    eventTextError = null;
    _emitDraft();
  }

  void updateDateEnabled(bool enabled) {
    dateEnabled = enabled;
    if (!enabled) {
      dateValue = null;
    }
    dateError = null;
    _emitDraft();
  }

  void updateDateValue(DateTime? value) {
    dateValue = value;
    if (value != null) {
      dateEnabled = true;
    }
    dateError = null;
    _emitDraft();
  }

  void updateImportanceScore(int value) {
    importanceScore = value;
    importanceScoreError = null;
    _emitDraft();
  }

  /// Validates and persists. Returns `true` on success.
  ///
  /// Create vs update is decided only by [memoryUuid].
  Future<bool> save() async {
    saveError = null;
    categoryError = validateMemoryCategory(category);
    eventTextError = validateMemoryEventText(eventText);
    importanceScoreError = validateImportanceScore(importanceScore);
    dateError = validateMemoryDate(
      dateEnabled: dateEnabled,
      dateValue: dateValue,
    );

    if (categoryError != null ||
        eventTextError != null ||
        importanceScoreError != null ||
        dateError != null) {
      _emitDraft();
      return false;
    }

    final selectedCategory = category!;
    final trimmedEvent = eventText.trim();
    final now = DateTime.now();
    final sensitivity = defaultSensitivityForCategory(selectedCategory);
    final precision =
        dateEnabled ? DatePrecision.explicit : DatePrecision.none;

    try {
      final repo = ref.read(memoryRepositoryProvider);

      if (memoryUuid == null) {
        final persistedDateValue = resolveDateValueForPersistence(
          datePrecision: precision,
          dateValue: dateEnabled ? dateValue : null,
          dateValueRaw: null,
          anchorDate: now,
        );
        final memory = Memory()
          ..uuid = const Uuid().v4()
          ..personUuid = personUuid
          ..category = selectedCategory
          ..eventText = trimmedEvent
          ..quoteEvidence = null
          ..datePrecision = precision
          ..dateValueRaw = null
          ..dateValue = persistedDateValue
          ..importanceScore = importanceScore
          ..extractionConfidence = null
          ..personMatchConfidence = null
          ..sensitivityFlag = sensitivity
          ..sourceType = SourceType.text
          ..sourceRef = null
          ..needsUserConfirmation = false
          ..embedding = null
          ..createdAt = now
          ..updatedAt = now
          ..syncStatus = SyncStatus.pending
          ..deletedAt = null;
        await repo.create(memory);
        ref.read(embeddingEnqueueHookProvider).enqueue(memory.uuid);
      } else {
        final memory = await repo.getByUuid(memoryUuid!);
        if (memory == null) {
          throw StateError('Memory not found: $memoryUuid');
        }
        final textChanged = memory.eventText != trimmedEvent;
        final categoryChanged = memory.category != selectedCategory;
        // Anchor relative resolution to original capture time, not wall-clock now.
        final persistedDateValue = resolveDateValueForPersistence(
          datePrecision: precision,
          dateValue: dateEnabled ? dateValue : null,
          dateValueRaw: null,
          anchorDate: memory.createdAt,
        );
        // uuid and personUuid are immutable after creation.
        memory
          ..category = selectedCategory
          ..eventText = trimmedEvent
          ..datePrecision = precision
          ..dateValueRaw = null
          ..dateValue = persistedDateValue
          ..importanceScore = importanceScore
          ..sensitivityFlag = sensitivity
          ..updatedAt = now
          ..syncStatus = SyncStatus.pending;
        if (textChanged || categoryChanged) {
          // Invalidate embedding until queue regenerates.
          memory.embedding = null;
          memory.embeddingModelVersion = null;
        }
        await repo.update(memory);
        if (textChanged || categoryChanged) {
          ref.read(embeddingEnqueueHookProvider).enqueue(memory.uuid);
        }
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
