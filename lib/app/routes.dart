/// Route path constants — keeps navigation calls typo-free.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  // Bottom-navigation tabs
  static const home = '/home';
  static const map = '/map';
  static const vehicles = '/vehicles';
  static const profile = '/profile';

  // Pushed screens
  static const stations = '/stations';
  static String station(String id) => '/stations/$id';
  static String stationExplore(String id) => '/stations/$id/explore';
  static const favourites = '/favourites';
  static const addVehicle = '/vehicles/add';
  static String vehicle(String id) => '/vehicles/$id';
  static String editVehicle(String id) => '/vehicles/$id/edit';
  static const editProfile = '/profile/edit';

  /// Routes reachable without being signed in.
  static const public = {splash, onboarding, login, register, forgotPassword};
}
