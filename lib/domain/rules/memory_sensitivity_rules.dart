import 'package:my_first_app/core/constants/enums.dart';

/// Default sensitivity for a memory category (Bible/ontology mapping).
///
/// Pure function — no I/O. Recomputed on every save; never a user-editable field.
SensitivityLevel defaultSensitivityForCategory(MemoryCategory category) {
  switch (category) {
    case MemoryCategory.health:
    case MemoryCategory.finance:
      return SensitivityLevel.high;
    case MemoryCategory.family:
      return SensitivityLevel.medium;
    case MemoryCategory.career:
    case MemoryCategory.education:
    case MemoryCategory.travel:
    case MemoryCategory.goals:
    case MemoryCategory.hobbies:
    case MemoryCategory.preferences:
    case MemoryCategory.promises:
    case MemoryCategory.milestones:
      return SensitivityLevel.low;
  }
}
