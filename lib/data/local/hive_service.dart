import 'package:hive_flutter/hive_flutter.dart';

import '../../core/utils/logger.dart';
import '../models/nutrition_log.dart';
import '../models/user_profile.dart';
import 'hive_boxes.dart';

final _log = AppLogger('HiveService');

/// Manages Hive local database initialization and lifecycle.
///
/// Responsible for:
/// - Initializing Hive with Flutter path support
/// - Registering all type adapters
/// - Opening required boxes on app startup
/// - Providing a clean shutdown method
class HiveService {
  HiveService._();

  /// Initialize Hive, register adapters, and open all required boxes.
  ///
  /// Must be called once in `main()` before `runApp()`.
  static Future<void> init() async {
    // Initialize Hive with Flutter's application documents directory
    await Hive.initFlutter();
    _log.info('Hive initialized with Flutter path provider');

    // ── Register Type Adapters ────────────────────────────────────────────
    _registerAdapters();

    // ── Open Boxes ────────────────────────────────────────────────────────
    await _openBoxes();

    _log.info('Hive setup complete — all boxes open');
  }

  /// Register all Hive type adapters.
  ///
  /// Each adapter must have a unique typeId defined in [HiveTypeIds].
  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(HiveTypeIds.userProfile)) {
      Hive.registerAdapter(UserProfileAdapter());
      _log.debug(
        'Registered UserProfileAdapter (typeId: ${HiveTypeIds.userProfile})',
      );
    }

    if (!Hive.isAdapterRegistered(HiveTypeIds.nutritionLog)) {
      Hive.registerAdapter(NutritionLogAdapter());
      _log.debug(
        'Registered NutritionLogAdapter (typeId: ${HiveTypeIds.nutritionLog})',
      );
    }
  }

  /// Open all required Hive boxes.
  static Future<void> _openBoxes() async {
    await Hive.openBox<UserProfile>(HiveBoxes.userProfile);
    _log.debug('Opened box: ${HiveBoxes.userProfile}');

    await Hive.openBox<NutritionLog>(HiveBoxes.nutritionLogs);
    _log.debug('Opened box: ${HiveBoxes.nutritionLogs}');

    await Hive.openBox(HiveBoxes.appSettings);
    _log.debug('Opened box: ${HiveBoxes.appSettings}');
  }

  /// Close all open Hive boxes gracefully.
  ///
  /// Call during app lifecycle shutdown if needed.
  static Future<void> close() async {
    await Hive.close();
    _log.info('All Hive boxes closed');
  }
}
