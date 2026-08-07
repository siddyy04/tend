import 'package:my_first_app/core/constants/enums.dart';

/// Default [CircleTier] for a newly created person.
///
/// Single source of truth — form create-mode and any other caller must reuse
/// this constant rather than hardcoding a tier literal.
const CircleTier defaultCircleTier = CircleTier.acquaintances;
