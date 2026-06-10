import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:diet_log/logic/providers/auth_provider.dart';
import 'package:diet_log/logic/providers/history_filter_provider.dart';
import 'package:diet_log/presentation/theme/app_theme.dart';
import 'package:diet_log/presentation/widgets/meal_log_card.dart';

/// Meal history screen with filter support.
///
/// Consumes [filteredLogsProvider] to display meals based on the
/// active [HistoryFilter], and [historyFilterProvider] for filter state.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    final current = ref.read(historyFilterProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                const Icon(Icons.filter_list, color: AppTheme.primaryDark),
                const SizedBox(width: 8),
                const Text('Filter History', style: AppTheme.headingSmall),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Choose a time range or sort order for your meals.',
              style: AppTheme.bodySmall,
            ),
            const SizedBox(height: 20),

            ...HistoryFilter.values.map(
              (filter) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _FilterOption(
                  filter: filter,
                  isSelected: filter == current,
                  onTap: () {
                    ref.read(historyFilterProvider.notifier).state = filter;
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(filteredLogsProvider);
    final activeFilter = ref.watch(historyFilterProvider);
    final user = ref.watch(currentAuthUserProvider);
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/profile'),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                      backgroundImage: avatarUrl != null
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl == null
                          ? const Icon(
                              Icons.person,
                              color: AppTheme.primaryDark,
                              size: 22,
                            )
                          : null,
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'DietLog',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/notifications'),
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppTheme.divider),

            // ── Title Section ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activeFilter.label.toUpperCase(),
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.primaryDark,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('Meal History', style: AppTheme.headingLarge),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _showFilterSheet(context, ref),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: activeFilter != HistoryFilter.today
                                ? AppTheme.primary.withValues(alpha: 0.1)
                                : Colors.transparent,
                            border: Border.all(
                              color: activeFilter != HistoryFilter.today
                                  ? AppTheme.primaryDark
                                  : AppTheme.divider,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.filter_list,
                                size: 14,
                                color: activeFilter != HistoryFilter.today
                                    ? AppTheme.primaryDark
                                    : AppTheme.textPrimary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                activeFilter == HistoryFilter.today
                                    ? 'Filter'
                                    : activeFilter.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: activeFilter != HistoryFilter.today
                                      ? AppTheme.primaryDark
                                      : AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Meal List ───────────────────────────────────────────────
            Expanded(
              child: logsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                ),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppTheme.error,
                      ),
                      const SizedBox(height: 12),
                      Text(error.toString(), style: AppTheme.bodySmall),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(filteredLogsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (logs) {
                  if (logs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.restaurant_menu,
                            size: 64,
                            color: AppTheme.textSecondary.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No meals found',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            activeFilter == HistoryFilter.today
                                ? 'Tap the camera button to start tracking'
                                : 'No meals logged in this period',
                            style: AppTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: logs.length + 1, // +1 for end indicator
                    itemBuilder: (context, index) {
                      if (index == logs.length) {
                        // End-of-list indicator
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            children: [
                              Container(
                                width: 2,
                                height: 40,
                                color: AppTheme.divider,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'End of ${activeFilter.label.toLowerCase()} log',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.textSecondary.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return MealLogCard(
                        log: logs[index],
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/food-detail',
                            arguments: logs[index],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  final HistoryFilter filter;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterOption({
    required this.filter,
    required this.isSelected,
    required this.onTap,
  });

  IconData get _icon {
    switch (filter) {
      case HistoryFilter.today:
        return Icons.today;
      case HistoryFilter.last7Days:
        return Icons.date_range;
      case HistoryFilter.last30Days:
        return Icons.calendar_month;
      case HistoryFilter.highestCalories:
        return Icons.local_fire_department;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.08)
              : AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isSelected ? AppTheme.primaryDark : AppTheme.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _icon,
              size: 20,
              color: isSelected ? AppTheme.primaryDark : AppTheme.textSecondary,
            ),
            const SizedBox(width: 12),
            Text(
              filter.label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppTheme.primaryDark : AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                size: 20,
                color: AppTheme.primaryDark,
              ),
          ],
        ),
      ),
    );
  }
}
