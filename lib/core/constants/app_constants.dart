/// ChargeMate — App Constants
abstract final class AppConstants {
  // ── App Info ───────────────────────────────────────────────────────
  static const String appName = 'ChargeMate';
  static const String appTagline = 'Find Chargers. Discover Places. Enjoy Your Journey.';
  static const String appVersion = '0.1.0';

  // ── Storage Keys ──────────────────────────────────────────────────
  static const String accessTokenKey = 'jwt_access_token';
  static const String refreshTokenKey = 'jwt_refresh_token';
  static const String userDataKey = 'cached_user_data';
  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String themeKey = 'theme_mode';

  // ── Map Defaults ──────────────────────────────────────────────────
  /// Default center: Colombo, Sri Lanka.
  static const double defaultLat = 6.9271;
  static const double defaultLng = 79.8612;
  static const double defaultZoom = 13.0;
  static const double stationDetailZoom = 16.0;

  /// Nearby station search radius in kilometers.
  static const double defaultSearchRadiusKm = 25.0;

  // ── Connector Types ───────────────────────────────────────────────
  static const String connectorCCS2 = 'CCS2';
  static const String connectorCHAdeMO = 'CHAdeMO';
  static const String connectorType2 = 'Type 2';
  static const String connectorType1 = 'Type 1';
  static const String connectorGBT = 'GB/T';

  // ── Charging Speed Thresholds (kW) ────────────────────────────────
  static const double speedFastThreshold = 50.0;
  static const double speedMediumThreshold = 22.0;

  // ── Time-Based Recommendation Thresholds (minutes) ────────────────
  static const int quickStopMax = 15;
  static const int shortBreakMax = 30;
  static const int mediumBreakMax = 45;
  static const int longBreakMax = 60;

  // ── Pagination ────────────────────────────────────────────────────
  static const int defaultPageSize = 20;

  // ── Validation ────────────────────────────────────────────────────
  static const int minPasswordLength = 8;
  static const int maxNameLength = 50;
  static const int maxCommentLength = 500;

  // ── Animation Durations ───────────────────────────────────────────
  static const Duration splashDuration = Duration(milliseconds: 2500);
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
}
