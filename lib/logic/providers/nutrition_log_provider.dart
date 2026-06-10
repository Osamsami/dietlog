import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/nutrition_log.dart';
import '../../data/repositories/nutrition_log_repository.dart';
import 'user_preferences_provider.dart';

/// Provides the [NutritionLogRepository] singleton instance.
/// Encapsulates all Supabase + Hive CRUD operations for nutrition logs.
final nutritionLogRepositoryProvider = Provider<NutritionLogRepository>((ref) {
  return NutritionLogRepository();
});

/// FutureProvider for today's nutrition logs.
///
/// Auto-disposes when no longer listened to, ensuring fresh data on re-read.
/// Consumed by the History screen (via filteredLogsProvider) and Dashboard.
final todayLogsProvider = AutoDisposeFutureProvider<List<NutritionLog>>((
  ref,
) async {
  final repo = ref.watch(nutritionLogRepositoryProvider);
  final allLogs = await repo.getWeeklyLogs();

  final now = DateTime.now();
  return allLogs.where((log) {
    final localDate = log.loggedAt.toLocal();
    return localDate.year == now.year &&
        localDate.month == now.month &&
        localDate.day == now.day;
  }).toList();
});

/// FutureProvider for the last 7 days of nutrition logs.
final weeklyLogsProvider = AutoDisposeFutureProvider<List<NutritionLog>>((
  ref,
) async {
  final repo = ref.watch(nutritionLogRepositoryProvider);
  return repo.getWeeklyLogs();
});

/// FutureProvider for the last 30 days of nutrition logs.
final monthlyLogsProvider = AutoDisposeFutureProvider<List<NutritionLog>>((
  ref,
) async {
  final repo = ref.watch(nutritionLogRepositoryProvider);
  return repo.getMonthlyLogs();
});

/// Computed provider for today's daily nutrition summary.
///
/// DYNAMIC GOALS: Reads calorie/macro targets from [userPreferencesProvider]
/// instead of hardcoded AppConstants. This means when the user updates
/// their goals in the Profile screen, the Dashboard progress ring
/// updates reactively via Riverpod's dependency graph.
final dailySummaryProvider = AutoDisposeFutureProvider<DailySummary>((
  ref,
) async {
  final logsAsync = await ref.watch(todayLogsProvider.future);
  // Read dynamic user goals — reactively rebuilds when goals change
  final prefs = ref.watch(userPreferencesProvider);

  final totalCalories = logsAsync.fold<int>(
    0,
    (sum, log) => sum + log.calories,
  );
  final totalProtein = logsAsync.fold<double>(
    0,
    (sum, log) => sum + log.proteinG,
  );
  final totalCarbs = logsAsync.fold<double>(0, (sum, log) => sum + log.carbsG);
  final totalFats = logsAsync.fold<double>(0, (sum, log) => sum + log.fatsG);

  return DailySummary(
    totalCalories: totalCalories,
    totalProtein: totalProtein,
    totalCarbs: totalCarbs,
    totalFats: totalFats,
    logCount: logsAsync.length,
    calorieTarget: prefs.calorieGoal,
    proteinTarget: (prefs.calorieGoal * 0.25) / 4.0,
    carbsTarget: (prefs.calorieGoal * 0.50) / 4.0,
    fatsTarget: (prefs.calorieGoal * 0.25) / 9.0,
  );
});

/// Immutable data class representing a daily nutrition summary.
///
/// Contains aggregated totals and targets used by the Dashboard's
/// ProgressRing and MacroCard widgets.
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
  double get carbsProgress => carbsTarget > 0 ? totalCarbs / carbsTarget : 0;

  /// Fats progress as a fraction.
  double get fatsProgress => fatsTarget > 0 ? totalFats / fatsTarget : 0;

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
