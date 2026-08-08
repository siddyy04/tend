import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/ai/providers/ai_provider_selection.dart';
import 'package:my_first_app/ai/providers/extraction_provider.dart';
import 'package:my_first_app/core/constants/enums.dart';
import 'package:my_first_app/data/local/isar/collections/memory.dart';
import 'package:my_first_app/domain/rules/date_resolution_rules.dart';
import 'package:my_first_app/domain/rules/extraction_validation_rules.dart';
import 'package:my_first_app/domain/rules/memory_sensitivity_rules.dart';
import 'package:my_first_app/domain/validators/memory_validators.dart';
import 'package:my_first_app/features/capture/confirmation/capture_confirmation_args.dart';
import 'package:my_first_app/features/person_profile/person_profile_providers.dart';
import 'package:uuid/uuid.dart';

/// Editable confirmation draft for one capture candidate.
final captureConfirmationControllerProvider = AsyncNotifierProvider.autoDispose
    .family<CaptureConfirmationController, void, CaptureDraftKey>(
  CaptureConfirmationController.new,
);

class CaptureConfirmationController extends AsyncNotifier<void> {
  CaptureConfirmationController(this.key);

  final CaptureDraftKey key;

  ExtractedMemoryCandidate get initial => key.candidate;

  late MemoryCategory category;
  late String eventText;
  late String quoteEvidence;
  late DatePrecision datePrecision;
  String? dateValueRaw;
  DateTime? dateValue;
  late int importanceScore;
  String? selectedPersonUuid;
  late double extractionConfidence;
  late double personMatchConfidence;

  String? personError;
  String? categoryError;
  String? eventTextError;
  String? dateError;
  String? importanceScoreError;
  Object? saveError;
  var _saveInFlight = false;

  /// How many draft fields differ from the extraction candidate (analytics).
  int get editedFieldCount {
    var n = 0;
    if (eventText.trim() != initial.eventText.trim()) n++;
    if (category != initial.category) n++;
    if (importanceScore != initial.importanceScore) n++;
    if (datePrecision != initial.datePrecision) n++;
    if (dateValueRaw != initial.dateValueRaw) n++;
    if (dateValue != initial.dateValue) n++;
    if (selectedPersonUuid != initial.personMatchUuid) n++;
    return n;
  }

  bool get wasEdited => editedFieldCount > 0;

  bool get needsPersonSelection {
    final matched = initial.personMatchUuid;
    return matched == null ||
        !meetsPersonMatchConfidenceThreshold(initial);
  }

  bool get showLowConfidenceLabel =>
      !meetsExtractionConfidenceThreshold(initial);

  @override
  bool updateShouldNotify(AsyncValue<void> previous, AsyncValue<void> next) {
    return true;
  }

  @override
  Future<void> build() async {
    category = initial.category;
    eventText = initial.eventText;
    quoteEvidence = initial.quoteEvidence;
    datePrecision = initial.datePrecision;
    dateValueRaw = initial.dateValueRaw;
    dateValue = initial.dateValue;
    importanceScore = initial.importanceScore;
    extractionConfidence = initial.extractionConfidence;
    personMatchConfidence = initial.personMatchConfidence;

    if (!needsPersonSelection) {
      selectedPersonUuid = initial.personMatchUuid;
    } else {
      selectedPersonUuid = null;
    }

    personError = null;
    categoryError = null;
    eventTextError = null;
    dateError = null;
    importanceScoreError = null;
    saveError = null;
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

  void updateImportanceScore(int value) {
    importanceScore = value;
    importanceScoreError = null;
    _emitDraft();
  }

  void updateSelectedPersonUuid(String? uuid) {
    selectedPersonUuid = uuid;
    personError = null;
    _emitDraft();
  }

  void updateDateEnabled(bool enabled) {
    if (enabled) {
      datePrecision = DatePrecision.explicit;
      dateValue ??= DateTime.now();
      dateValueRaw = null;
    } else {
      datePrecision = DatePrecision.none;
      dateValue = null;
      dateValueRaw = null;
    }
    dateError = null;
    _emitDraft();
  }

  void updateDateValue(DateTime? value) {
    dateValue = value;
    if (value != null) {
      datePrecision = DatePrecision.explicit;
      dateValueRaw = null;
    }
    dateError = null;
    _emitDraft();
  }

  void updateDateValueRaw(String? value) {
    final trimmed = value?.trim();
    dateValueRaw = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    if (dateValueRaw != null) {
      datePrecision = DatePrecision.relative;
      dateValue = null;
    }
    dateError = null;
    _emitDraft();
  }

  /// Validates and writes via [MemoryRepository.create]. Returns saved person uuid.
  Future<String?> save() async {
    if (_saveInFlight) return null;
    _saveInFlight = true;
    saveError = null;

    try {
      if (selectedPersonUuid == null || selectedPersonUuid!.isEmpty) {
        personError = 'Select a person before saving';
      } else {
        personError = null;
      }

      categoryError = validateMemoryCategory(category);
      eventTextError = validateMemoryEventText(eventText);
      importanceScoreError = validateImportanceScore(importanceScore);

      final dateEnabled = datePrecision == DatePrecision.explicit;
      dateError = validateMemoryDate(
        dateEnabled: dateEnabled,
        dateValue: dateValue,
      );

      if (personError != null ||
          categoryError != null ||
          eventTextError != null ||
          importanceScoreError != null ||
          dateError != null) {
        _emitDraft();
        return null;
      }

      final personUuid = selectedPersonUuid!;
      final now = DateTime.now();
      final sensitivity = defaultSensitivityForCategory(category);
      final needsConfirmation = !meetsExtractionConfidenceThreshold(initial);
      final persistedDateValue = resolveDateValueForPersistence(
        datePrecision: datePrecision,
        dateValue: dateValue,
        dateValueRaw: dateValueRaw,
        anchorDate: now,
      );

      // followUpSuggested / followUpNote are intentionally discarded (Sprint 2A).
      final memory = Memory()
        ..uuid = const Uuid().v4()
        ..personUuid = personUuid
        ..category = category
        ..eventText = eventText.trim()
        ..quoteEvidence =
            quoteEvidence.trim().isEmpty ? null : quoteEvidence.trim()
        ..datePrecision = datePrecision
        ..dateValueRaw =
            datePrecision == DatePrecision.relative ? dateValueRaw : null
        ..dateValue = persistedDateValue
        ..importanceScore = importanceScore
        ..extractionConfidence = extractionConfidence
        ..personMatchConfidence = personMatchConfidence
        ..sensitivityFlag = sensitivity
        ..sourceType = key.sourceType
        ..sourceRef = key.sourceRef
        ..needsUserConfirmation = needsConfirmation
        ..embedding = null
        ..createdAt = now
        ..updatedAt = now
        ..syncStatus = SyncStatus.pending
        ..deletedAt = null;

      try {
        await ref.read(memoryRepositoryProvider).create(memory);
        ref.read(embeddingEnqueueHookProvider).enqueue(memory.uuid);
        _emitDraft();
        return personUuid;
      } catch (e) {
        saveError = e;
        _emitDraft();
        return null;
      }
    } finally {
      _saveInFlight = false;
    }
  }

  void _emitDraft() {
    state = const AsyncData(null);
  }
}
