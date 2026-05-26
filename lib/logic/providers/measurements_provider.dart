import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the user's body measurements for the profile screen.
///
/// Persisted in-memory via [StateNotifier]. A production version
/// would sync these to Supabase `profiles.metadata`.
class UserMeasurements {
  final double heightCm;
  final double weightKg;
  final int age;

  const UserMeasurements({
    this.heightCm = 182,
    this.weightKg = 78,
    this.age = 28,
  });

  UserMeasurements copyWith({
    double? heightCm,
    double? weightKg,
    int? age,
  }) {
    return UserMeasurements(
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      age: age ?? this.age,
    );
  }
}

/// Notifier managing [UserMeasurements] state.
class MeasurementsNotifier extends StateNotifier<UserMeasurements> {
  MeasurementsNotifier() : super(const UserMeasurements());

  void updateHeight(double cm) {
    state = state.copyWith(heightCm: cm);
  }

  void updateWeight(double kg) {
    state = state.copyWith(weightKg: kg);
  }

  void updateAge(int age) {
    state = state.copyWith(age: age);
  }

  void updateAll({
    required double heightCm,
    required double weightKg,
    required int age,
  }) {
    state = UserMeasurements(
      heightCm: heightCm,
      weightKg: weightKg,
      age: age,
    );
  }
}

/// Global provider for user body measurements.
final measurementsProvider =
    StateNotifierProvider<MeasurementsNotifier, UserMeasurements>((ref) {
  return MeasurementsNotifier();
});
