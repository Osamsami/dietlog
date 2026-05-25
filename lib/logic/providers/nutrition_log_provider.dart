import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/nutrition_log.dart';
import '../../data/repositories/nutrition_log_repository.dart';

/// Provides the [NutritionLogRepository] singleton instance.
final nutritionLogRepositoryProvider =
    Provider<NutritionLogRepository>((ref) {
  return NutritionLogRepository();
});

/// FutureProvider for today's nutrition logs.
///
/// Auto-disposes when no longer listened to, ensuring fresh data on re-read.
final todayLogsProvider =
    AutoDisposeFutureProvider<List<NutritionLog>>((ref) async {
  final repo = ref.watch(nutritionLogRepositoryProvider);
  return repo.getTodayLogs();
});

/// FutureProvider for the last 7 days of nutrition logs.
final weeklyLogsProvider =
    AutoDisposeFutureProvider<List<NutritionLog>>((ref) async {
  final repo = ref.watch(nutritionLogRepositoryProvider);
  return repo.getWeeklyLogs();
});

/// FutureProvider for the last 30 days of nutrition logs.
final monthlyLogsProvider =
    AutoDisposeFutureProvider<List<NutritionLog>>((ref) async {
  final repo = ref.watch(nutritionLogRepositoryProvider);
  return repo.getMonthlyLogs();
});

/// Computed provider for today's daily nutrition summary.
///
/// Returns a [DailySummary] containing total calories and macros
/// for the current day, computed from [todayLogsProvider].
final dailySummaryProvider =
    AutoDisposeFutureProvider<DailySummary>((ref) async {
  final logsAsync = await ref.watch(todayLogsProvider.future);

  final totalCalories =
      logsAsync.fold<int>(0, (sum, log) => sum + log.calories);
  final totalProtein =
      logsAsync.fold<double>(0, (sum, log) => sum + log.proteinG);
  final totalCarbs =
      logsAsync.fold<double>(0, (sum, log) => sum + log.carbsG);
  final totalFats =
      logsAsync.fold<double>(0, (sum, log) => sum + log.fatsG);

  return DailySummary(
    totalCalories: totalCalories,
    totalProtein: totalProtein,
    totalCarbs: totalCarbs,
    totalFats: totalFats,
    logCount: logsAsync.length,
    calorieTarget: AppConstants.defaultCalorieTarget,
    proteinTarget: AppConstants.defaultProteinTarget,
    carbsTarget: AppConstants.defaultCarbsTarget,
    fatsTarget: AppConstants.defaultFatsTarget,
  );
});

/// Immutable data class representing a daily nutrition summary.
class DailySummary {
  final int totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFats;
  final int logCount;
  final int calorieTarget;
  final double proteinTarget;
  final double carbsTarget;
  final double fatsTarget;

  const DailySummary({
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFats,
    required this.logCount,
    required this.calorieTarget,
    required this.proteinTarget,
    required this.carbsTarget,
    required this.fatsTarget,
  });

  /// Calorie progress as a fraction (0.0 to 1.0+).
  double get calorieProgress =>
      calorieTarget > 0 ? totalCalories / calorieTarget : 0;

  /// Protein progress as a fraction.
  double get proteinProgress =>
      proteinTarget > 0 ? totalProtein / proteinTarget : 0;

  /// Carbs progress as a fraction.
  double get carbsProgress =>
      carbsTarget > 0 ? totalCarbs / carbsTarget : 0;

  /// Fats progress as a fraction.
  double get fatsProgress =>
      fatsTarget > 0 ? totalFats / fatsTarget : 0;

  /// Remaining calories to reach the daily target.
  int get remainingCalories => calorieTarget - totalCalories;

  @override
  String toString() =>
      'DailySummary(cal: $totalCalories/$calorieTarget, '
      'P: ${totalProtein.toStringAsFixed(1)}g, '
      'C: ${totalCarbs.toStringAsFixed(1)}g, '
      'F: ${totalFats.toStringAsFixed(1)}g, '
      'logs: $logCount)';
}
