import 'package:hive_flutter/hive_flutter.dart';

import '../../core/utils/logger.dart';
import '../local/hive_boxes.dart';
import '../models/nutrition_log.dart';
import '../models/user_profile.dart';

final _log = AppLogger('LocalCacheRepository');

/// Repository for managing Hive local cache operations.
///
/// Provides a clean API for caching and retrieving data from Hive boxes.
/// Used as a fallback data source when Supabase is unreachable and for
/// instant UI rendering before network responses arrive.
class LocalCacheRepository {
  // ── Nutrition Logs ──────────────────────────────────────────────────────

  /// Cache a list of nutrition logs to Hive.
  Future<void> cacheNutritionLogs(List<NutritionLog> logs) async {
    final box = Hive.box<NutritionLog>(HiveBoxes.nutritionLogs);

    for (final log in logs) {
      await box.put(log.logId, log);
    }

    _log.debug('Cached ${logs.length} nutrition logs');
  }

  /// Retrieve all cached nutrition logs.
  List<NutritionLog> getCachedLogs() {
    final box = Hive.box<NutritionLog>(HiveBoxes.nutritionLogs);
    final logs = box.values.toList();

    // Sort by loggedAt descending (most recent first)
    logs.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

    _log.debug('Retrieved ${logs.length} cached logs');
    return logs;
  }

  /// Remove a single cached log by ID.
  Future<void> removeCachedLog(String logId) async {
    final box = Hive.box<NutritionLog>(HiveBoxes.nutritionLogs);
    await box.delete(logId);
    _log.debug('Removed cached log: $logId');
  }

  /// Get the count of cached logs.
  int get cachedLogCount =>
      Hive.box<NutritionLog>(HiveBoxes.nutritionLogs).length;

  // ── User Profile ────────────────────────────────────────────────────────

  /// Cache the current user's profile.
  Future<void> cacheUserProfile(UserProfile profile) async {
    final box = Hive.box<UserProfile>(HiveBoxes.userProfile);
    await box.put('current', profile);
    _log.debug('User profile cached: ${profile.fullName}');
  }

  /// Retrieve the cached user profile, or `null` if not cached.
  UserProfile? getCachedProfile() {
    final box = Hive.box<UserProfile>(HiveBoxes.userProfile);
    final profile = box.get('current');
    _log.debug(
      profile != null
          ? 'Cached profile found: ${profile.fullName}'
          : 'No cached profile found',
    );
    return profile;
  }

  // ── App Settings ────────────────────────────────────────────────────────

  /// Save a setting value to the app settings box.
  Future<void> saveSetting(String key, dynamic value) async {
    final box = Hive.box(HiveBoxes.appSettings);
    await box.put(key, value);
    _log.debug('Setting saved: $key');
  }

  /// Read a setting value from the app settings box.
  T? getSetting<T>(String key, {T? defaultValue}) {
    final box = Hive.box(HiveBoxes.appSettings);
    return box.get(key, defaultValue: defaultValue) as T?;
  }

  // ── Cache Management ────────────────────────────────────────────────────

  /// Clear all cached data across all Hive boxes.
  Future<void> clearAllCache() async {
    await Hive.box<NutritionLog>(HiveBoxes.nutritionLogs).clear();
    await Hive.box<UserProfile>(HiveBoxes.userProfile).clear();
    await Hive.box(HiveBoxes.appSettings).clear();
    _log.info('All local caches cleared');
  }

  /// Clear only the nutrition logs cache.
  Future<void> clearLogsCache() async {
    await Hive.box<NutritionLog>(HiveBoxes.nutritionLogs).clear();
    _log.debug('Nutrition logs cache cleared');
  }

  /// Get total cache size info (number of entries per box).
  Map<String, int> get cacheStats => {
        'nutritionLogs':
            Hive.box<NutritionLog>(HiveBoxes.nutritionLogs).length,
        'userProfile':
            Hive.box<UserProfile>(HiveBoxes.userProfile).length,
        'appSettings':
            Hive.box(HiveBoxes.appSettings).length,
      };
}
