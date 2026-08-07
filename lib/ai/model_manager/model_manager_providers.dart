import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/ai/model_manager/device_capability_check.dart';
import 'package:my_first_app/ai/model_manager/model_download_manager.dart';

final deviceCapabilityCheckProvider = Provider<DeviceCapabilityCheck>((ref) {
  return DeviceCapabilityCheck();
});

final modelDownloadManagerProvider = Provider<ModelDownloadManager>((ref) {
  ref.keepAlive();
  return ModelDownloadManager();
});

/// Device AI tier from RAM assessment.
final deviceAiTierProvider = FutureProvider<DeviceAiTier>((ref) {
  return ref.watch(deviceCapabilityCheckProvider).assess();
});

/// Whether assisted (on-device model) capture is available on this device.
final isAiCaptureSupportedProvider = Provider<AsyncValue<bool>>((ref) {
  return ref.watch(deviceAiTierProvider).whenData(
        (tier) => tier != DeviceAiTier.unsupported,
      );
});

/// [ModelAssistStatus]: notConfigured | manualMode | modelReady.
final modelAssistStatusProvider = FutureProvider<ModelAssistStatus>((ref) {
  return ref.watch(modelDownloadManagerProvider).assistStatus();
});

/// Whether the current catalog model is on disk and verified.
final currentModelReadyProvider = FutureProvider<bool>((ref) {
  return ref.watch(modelDownloadManagerProvider).isCurrentModelReady();
});
