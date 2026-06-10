import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/local/hive_boxes.dart';

/// User nutrition and hydration goals, persisted locally via Hive.
///
/// These preferences are stored in the `appSettings` Hive box and
/// survive app restarts. The Dashboard's dailySummaryProvider reads
/// these values instead of hardcoded defaults from AppConstants.
class UserPreferences {
  final int calorieGoal;
  final double waterGoalLiters;

  const UserPreferences({this.calorieGoal = 2000, this.waterGoalLiters = 3.2});

  UserPreferences copyWith({int? calorieGoal, double? waterGoalLiters}) {
    return UserPreferences(
      calorieGoal: calorieGoal ?? this.calorieGoal,
      waterGoalLiters: waterGoalLiters ?? this.waterGoalLiters,
    );
  }
}

/// Manages [UserPreferences] with Hive persistence.
///
/// On construction, loads saved values from the `appSettings` box.
/// Every mutation writes back to Hive immediately, ensuring data
/// survives app restarts without requiring a network call.
class UserPreferencesNotifier extends StateNotifier<UserPreferences> {
  UserPreferencesNotifier() : super(const UserPreferences()) {
    _loadFromHive();
  }

  /// Hydrate state from Hive on app startup.
  void _loadFromHive() {
    try {
      final box = Hive.box(HiveBoxes.appSettings);
      final calories = box.get('calorie_goal', defaultValue: 2000) as int;
      final water = box.get('water_goal', defaultValue: 3.2) as double;
      state = UserPreferences(calorieGoal: calories, waterGoalLiters: water);
    } catch (_) {
      // First launch — defaults are fine
    }
  }

  /// Persist state to Hive after every mutation.
  Future<void> _saveToHive() async {
    try {
      final box = Hive.box(HiveBoxes.appSettings);
      await box.put('calorie_goal', state.calorieGoal);
      await box.put('water_goal', state.waterGoalLiters);
    } catch (_) {
      // Hive write failure — non-fatal
    }
  }

  void updateCalorieGoal(int goal) {
    state = state.copyWith(calorieGoal: goal);
    _saveToHive();
  }

  void updateWaterGoal(double liters) {
    state = state.copyWith(waterGoalLiters: liters);
    _saveToHive();
  }

  void updateAll({required int calorieGoal, required double waterGoalLiters}) {
    state = UserPreferences(
      calorieGoal: calorieGoal,
      waterGoalLiters: waterGoalLiters,
    );
    _saveToHive();
  }
}

/// Global provider for user nutrition/hydration goals.
/// Consumed by the Dashboard (via dailySummaryProvider) and the Profile screen.
final userPreferencesProvider =
    StateNotifierProvider<UserPreferencesNotifier, UserPreferences>((ref) {
      return UserPreferencesNotifier();
    });
