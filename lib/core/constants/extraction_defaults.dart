// Confidence thresholds for AI extraction (Sprint 2A).
// Single source of truth — do not inline these numbers elsewhere (ADR-007).
// Starter values are intentionally conservative; tune with real capture data later.

import 'package:my_first_app/core/constants/enums.dart';

/// Minimum extraction confidence for treating a candidate as above-threshold.
///
/// Below this, confirmation still shows the candidate but save sets
/// needsUserConfirmation = true.
const double kExtractionConfidenceThreshold = 0.70;

/// Minimum person-match confidence to pre-select a matched person.
const double kPersonMatchConfidenceThreshold = 0.70;

/// Default [MemoryCategory] only for non-model paths (e.g. manual stubs).
/// Model extraction must return a validated enum name — no silent fallback.
const MemoryCategory kLiteralExtractionDefaultCategory =
    MemoryCategory.preferences;

/// Default importance when the model does not predict importance.
const int kLiteralExtractionDefaultImportance = 3;
