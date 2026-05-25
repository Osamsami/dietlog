/// Application-wide constants for DietLog.
class AppConstants {
  AppConstants._();

  // ── App Metadata ──────────────────────────────────────────────────────
  static const String appName = 'DietLog';
  static const String appVersion = '1.0.0';

  // ── API Configuration ─────────────────────────────────────────────────
  /// Default HTTP request timeout in milliseconds.
  static const int httpTimeoutMs = 15000;

  /// Default connection timeout in milliseconds.
  static const int connectionTimeoutMs = 10000;

  // ── Nutritional Defaults ──────────────────────────────────────────────
  /// Default daily calorie target (kcal).
  static const int defaultCalorieTarget = 2000;

  /// Default daily protein target (grams).
  static const double defaultProteinTarget = 50.0;

  /// Default daily carbohydrate target (grams).
  static const double defaultCarbsTarget = 250.0;

  /// Default daily fat target (grams).
  static const double defaultFatsTarget = 65.0;

  // ── Date Range Windows ────────────────────────────────────────────────
  /// Number of days for weekly aggregation window.
  static const int weeklyWindowDays = 7;

  /// Number of days for monthly aggregation window.
  static const int monthlyWindowDays = 30;

  // ── Hive Encryption ───────────────────────────────────────────────────
  /// SharedPreferences key for the Hive encryption cipher key.
  static const String hiveEncryptionKeyName = 'dietlog_hive_key';
}
