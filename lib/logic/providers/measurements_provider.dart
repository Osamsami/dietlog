import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/local/hive_boxes.dart';

/// Holds the user's body measurements for the profile screen.
///
/// Persisted via Hive in the `appSettings` box so values survive
/// app restarts. The Clean Architecture boundary is maintained:
/// this provider lives in the Logic layer and reads from the Data layer.
class UserMeasurements {
  final double heightCm;
  final double weightKg;
  final int age;

  const UserMeasurements({
    this.heightCm = 170,
    this.weightKg = 70,
    this.age = 25,
  });

  UserMeasurements copyWith({double? heightCm, double? weightKg, int? age}) {
    return UserMeasurements(
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      age: age ?? this.age,
    );
  }
}

/// Notifier managing [UserMeasurements] state with Hive persistence.
///
/// Loads saved values from Hive on construction and writes back
/// on every mutation. This ensures offline-first data persistence
/// without requiring a Supabase network call.
class MeasurementsNotifier extends StateNotifier<UserMeasurements> {
  MeasurementsNotifier() : super(const UserMeasurements()) {
    _loadFromHive();
  }

  /// Load persisted measurements from Hive on startup.
  void _loadFromHive() {
    try {
      final box = Hive.box(HiveBoxes.appSettings);
      final height = box.get('height_cm', defaultValue: 170.0) as double;
      final weight = box.get('weight_kg', defaultValue: 70.0) as double;
      final age = box.get('age', defaultValue: 25) as int;
      state = UserMeasurements(heightCm: height, weightKg: weight, age: age);
    } catch (_) {
      // First launch or Hive not ready — defaults are fine
    }
  }

  /// Persist current state to Hive.
  Future<void> _saveToHive() async {
    try {
      final box = Hive.box(HiveBoxes.appSettings);
      await box.put('height_cm', state.heightCm);
      await box.put('weight_kg', state.weightKg);
      await box.put('age', state.age);
    } catch (_) {
      // Non-fatal write failure
    }
  }

  void updateHeight(double cm) {
    state = state.copyWith(heightCm: cm);
    _saveToHive();
  }

  void updateWeight(double kg) {
    state = state.copyWith(weightKg: kg);
    _saveToHive();
  }

  void updateAge(int age) {
    state = state.copyWith(age: age);
    _saveToHive();
  }

  void updateAll({
    required double heightCm,
    required double weightKg,
    required int age,
  }) {
    state = UserMeasurements(heightCm: heightCm, weightKg: weightKg, age: age);
    _saveToHive();
  }
}

/// Global provider for user body measurements.
/// Consumed by ProfileScreen to display dynamic height/weight/age values.
final measurementsProvider =
    StateNotifierProvider<MeasurementsNotifier, UserMeasurements>((ref) {
      return MeasurementsNotifier();
    });
