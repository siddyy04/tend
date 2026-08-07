import 'package:my_first_app/core/constants/enums.dart';

/// Placeholder max length for memory event text (not a product requirement).
const int memoryEventTextMaxLength = 1000;

/// Validates [eventText]: required after trim, max [memoryEventTextMaxLength].
///
/// Returns an error message, or `null` when valid.
String? validateMemoryEventText(String? eventText) {
  final trimmed = eventText?.trim() ?? '';
  if (trimmed.isEmpty) {
    return 'Event text is required';
  }
  if (trimmed.length > memoryEventTextMaxLength) {
    return 'Event text must be at most $memoryEventTextMaxLength characters';
  }
  return null;
}

/// Validates [category]: required.
///
/// Returns an error message, or `null` when valid.
String? validateMemoryCategory(MemoryCategory? category) {
  if (category == null) {
    return 'Category is required';
  }
  return null;
}

/// Validates [importanceScore]: integer 1–5 inclusive.
///
/// Returns an error message, or `null` when valid.
String? validateImportanceScore(int? importanceScore) {
  if (importanceScore == null) {
    return 'Importance is required';
  }
  if (importanceScore < 1 || importanceScore > 5) {
    return 'Importance must be between 1 and 5';
  }
  return null;
}

/// Validates date toggle vs [dateValue] consistency.
///
/// - Toggle on → [dateValue] must be non-null.
/// - Toggle off → [dateValue] must be null.
///
/// Returns an error message, or `null` when valid.
String? validateMemoryDate({
  required bool dateEnabled,
  DateTime? dateValue,
}) {
  if (dateEnabled && dateValue == null) {
    return 'Pick a date or turn the date off';
  }
  if (!dateEnabled && dateValue != null) {
    return 'Date state is inconsistent';
  }
  return null;
}
