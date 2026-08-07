import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

/// On-device AI capability tier (ARCHITECTURE.md Section 7).
enum DeviceAiTier {
  /// ≥8GB RAM — full local model experience.
  full,

  /// ~6GB RAM — model works; Sprint 2A text capture is fine (camera rules later).
  constrained,

  /// Below floor — no local model; manual capture only.
  unsupported,
}

/// Thresholds in megabytes (physical RAM).
const int kFullExperienceRamMb = 8192;
const int kConstrainedMinRamMb = 4096;

/// Assesses device RAM and returns an [DeviceAiTier].
class DeviceCapabilityCheck {
  DeviceCapabilityCheck({DeviceInfoPlugin? plugin})
      : _plugin = plugin ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _plugin;

  /// Reads physical RAM and maps to a tier.
  Future<DeviceAiTier> assess() async {
    final ramMb = await _physicalRamMb();
    if (ramMb == null) {
      // Unknown platform / missing API — allow AI on desktop/dev hosts.
      return DeviceAiTier.full;
    }
    return tierForRamMb(ramMb);
  }

  /// Pure mapping for tests and reuse.
  static DeviceAiTier tierForRamMb(int ramMb) {
    if (ramMb >= kFullExperienceRamMb) {
      return DeviceAiTier.full;
    }
    if (ramMb >= kConstrainedMinRamMb) {
      return DeviceAiTier.constrained;
    }
    return DeviceAiTier.unsupported;
  }

  Future<int?> _physicalRamMb() async {
    if (Platform.isAndroid) {
      final info = await _plugin.androidInfo;
      return info.physicalRamSize;
    }
    if (Platform.isIOS) {
      final info = await _plugin.iosInfo;
      return info.physicalRamSize;
    }
    return null;
  }
}
