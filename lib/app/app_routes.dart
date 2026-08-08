/// Route path constants for Tend navigation.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const auth = '/auth';
  static const circle = '/circle';
  static const today = '/today';
  static const search = '/search';
  static const personNew = '/person/new';
  static const capture = '/capture';
  static const captureVoice = '/capture/voice';
  static const captureVoiceTranscript = '/capture/voice/transcript';
  static const capturePhoto = '/capture/photo';
  static const capturePhotoText = '/capture/photo/text';
  static const captureShare = '/capture/share';
  static const captureConfirm = '/capture/confirm';
  static const captureConfirmSummary = '/capture/confirm/summary';
  static const captureConfirmMulti = '/capture/confirm/multi';
  static const modelSetup = '/capture/setup';
  static const settings = '/settings';
  static const gemmaProbe = '/debug/gemma-probe';

  static String personEdit(String personUuid) => '/person/edit/$personUuid';

  static String personProfile(String personUuid) => '/profile/$personUuid';

  static String personSearch(String personUuid) =>
      '/profile/$personUuid/search';

  static String memoryNew(String personUuid) =>
      '/profile/$personUuid/memory/new';

  static String memoryEdit(String personUuid, String memoryUuid) =>
      '/profile/$personUuid/memory/edit/$memoryUuid';
}
