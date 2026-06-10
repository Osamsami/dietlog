import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/nutrition_log.dart';
import 'nutrition_log_provider.dart';

/// Supported history filter modes.
enum HistoryFilter {
  today('Today'),
  last7Days('Last 7 Days'),
  last30Days('Last 30 Days'),
  highestCalories('Highest Calories');

  final String label;
  const HistoryFilter(this.label);
}

/// Holds the currently selected history filter.
final historyFilterProvider = StateProvider<HistoryFilter>((ref) {
  return HistoryFilter.today;
});

/// Computed provider that returns filtered/sorted nutrition logs
/// based on the current [historyFilterProvider] selection.
final filteredLogsProvider = AutoDisposeFutureProvider<List<NutritionLog>>((
  ref,
) async {
  final filter = ref.watch(historyFilterProvider);

  switch (filter) {
    case HistoryFilter.today:
      return ref.watch(todayLogsProvider.future);

    case HistoryFilter.last7Days:
      return ref.watch(weeklyLogsProvider.future);

    case HistoryFilter.last30Days:
      return ref.watch(monthlyLogsProvider.future);

    case HistoryFilter.highestCalories:
      final logs = await ref.watch(monthlyLogsProvider.future);
      final sorted = List<NutritionLog>.from(logs)
        ..sort((a, b) => b.calories.compareTo(a.calories));
      return sorted;
  }
});
