import 'package:my_first_app/core/constants/enums.dart';

/// Human-readable labels for [CircleTier] (display only — not persisted).
String circleTierLabel(CircleTier tier) {
  switch (tier) {
    case CircleTier.innerCircle:
      return 'Inner Circle';
    case CircleTier.family:
      return 'Family';
    case CircleTier.friends:
      return 'Friends';
    case CircleTier.professional:
      return 'Professional';
    case CircleTier.mentors:
      return 'Mentors';
    case CircleTier.acquaintances:
      return 'Acquaintances';
  }
}
