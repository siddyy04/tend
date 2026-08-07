/// Route path constants for Tend navigation.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const auth = '/auth';
  static const circle = '/circle';
  static const today = '/today';
  static const search = '/search';
  static const personNew = '/person/new';

  static String personEdit(String personUuid) => '/person/edit/$personUuid';
}
