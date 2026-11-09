/// ChargeMate — API Endpoints
///
/// Central registry of all REST API endpoints.
/// Points to mock/dev server initially.
abstract final class ApiEndpoints {
  /// Base URL — override via environment config for production.
  static const String baseUrl = 'http://10.0.2.2:8080/api'; // Android emulator localhost

  // ── Authentication ──────────────────────────────────────────────
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';

  // ── User Management ─────────────────────────────────────────────
  static const String userProfile = '/users/profile';
  static const String deleteAccount = '/users/account';

  // ── Vehicle Management ──────────────────────────────────────────
  static const String vehicles = '/vehicles';
  static String vehicleById(String id) => '/vehicles/$id';

  // ── Charging Stations ───────────────────────────────────────────
  static const String nearbyStations = '/stations/nearby';
  static const String searchStations = '/stations/search';
  static String stationById(String id) => '/stations/$id';
  static String stationConnectors(String id) => '/stations/$id/connectors';
  static String stationReviews(String id) => '/stations/$id/reviews';
  static String stationReports(String id) => '/stations/$id/reports';

  // ── Charge & Explore ────────────────────────────────────────────
  static const String nearbyPlaces = '/places/nearby';
  static const String placeCategories = '/places/categories';
  static const String placeRecommendations = '/places/recommendations';

  // ── Charging Sessions ───────────────────────────────────────────
  static const String sessions = '/sessions';
  static String sessionById(String id) => '/sessions/$id';
  static String sessionRecommendations(String id) =>
      '/sessions/$id/recommendations';
}
