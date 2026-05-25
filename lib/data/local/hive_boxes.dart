/// Centralized Hive box name constants for DietLog.
///
/// All box names are defined here to prevent typos and ensure
/// consistent access across the application.
class HiveBoxes {
  HiveBoxes._();

  /// Box for caching nutrition log entries for offline access.
  static const String nutritionLogs = 'nutrition_logs_box';

  /// Box for caching the current user's profile data.
  static const String userProfile = 'user_profile_box';

  /// Box for lightweight app settings and preferences.
  static const String appSettings = 'app_settings_box';
}

/// Hive type adapter IDs — must be unique across all registered adapters.
///
/// Keeping them in one place prevents ID collisions when adding new models.
class HiveTypeIds {
  HiveTypeIds._();

  /// Type ID for [UserProfile] adapter.
  static const int userProfile = 0;

  /// Type ID for [NutritionLog] adapter.
  static const int nutritionLog = 1;
}
