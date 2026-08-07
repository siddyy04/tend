import 'package:my_first_app/core/constants/enums.dart';

/// Placeholder max length for person text fields (not a product requirement).
const int personTextMaxLength = 100;

/// Validates [name]: required after trim, max [personTextMaxLength].
///
/// Returns an error message, or `null` when valid.
String? validatePersonName(String? name) {
  final trimmed = name?.trim() ?? '';
  if (trimmed.isEmpty) {
    return 'Name is required';
  }
  if (trimmed.length > personTextMaxLength) {
    return 'Name must be at most $personTextMaxLength characters';
  }
  return null;
}

/// Validates [circleTier]: required (defensive — schema field is non-null).
///
/// Returns an error message, or `null` when valid.
String? validateCircleTier(CircleTier? circleTier) {
  if (circleTier == null) {
    return 'Circle tier is required';
  }
  return null;
}

/// Validates optional [relationshipType]: if provided, same max length as name.
///
/// Empty/whitespace-only values are treated as absent (valid).
/// Returns an error message, or `null` when valid.
String? validateRelationshipType(String? relationshipType) {
  final trimmed = relationshipType?.trim() ?? '';
  if (trimmed.isEmpty) {
    return null;
  }
  if (trimmed.length > personTextMaxLength) {
    return 'Relationship type must be at most $personTextMaxLength characters';
  }
  return null;
}
