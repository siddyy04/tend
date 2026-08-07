import 'package:my_first_app/core/constants/enums.dart';

/// Human-readable labels for [MemoryCategory] (display only — not persisted).
String memoryCategoryLabel(MemoryCategory category) {
  switch (category) {
    case MemoryCategory.family:
      return 'Family';
    case MemoryCategory.career:
      return 'Career';
    case MemoryCategory.health:
      return 'Health';
    case MemoryCategory.education:
      return 'Education';
    case MemoryCategory.travel:
      return 'Travel';
    case MemoryCategory.finance:
      return 'Finance';
    case MemoryCategory.goals:
      return 'Goals';
    case MemoryCategory.hobbies:
      return 'Hobbies';
    case MemoryCategory.preferences:
      return 'Preferences';
    case MemoryCategory.promises:
      return 'Promises';
    case MemoryCategory.milestones:
      return 'Milestones';
  }
}
