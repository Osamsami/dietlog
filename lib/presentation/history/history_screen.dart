import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:diet_log/logic/providers/nutrition_log_provider.dart';
import 'package:diet_log/presentation/theme/app_theme.dart';
import 'package:diet_log/presentation/widgets/meal_log_card.dart';

/// Meal history screen showing today's logged meals.
///
/// Consumes [todayLogsProvider] to display a chronological list
/// of [MealLogCard] entries with an end-of-list indicator.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(todayLogsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor:
                        AppTheme.primary.withValues(alpha: 0.15),
                    child: const Icon(Icons.person,
                        color: AppTheme.primaryDark, size: 22),
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
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_none_rounded,
                        color: AppTheme.textSecondary),
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
                    'TODAY',
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.primaryDark,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('Meal History',
                          style: AppTheme.headingLarge),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.divider),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Filter',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
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
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                ),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppTheme.error),
                      const SizedBox(height: 12),
                      Text(error.toString(), style: AppTheme.bodySmall),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            ref.invalidate(todayLogsProvider),
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
                          Icon(Icons.restaurant_menu,
                              size: 64,
                              color: AppTheme.textSecondary
                                  .withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text(
                            'No meals logged today',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the camera button to start tracking',
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
                                "End of today's log",
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.textSecondary
                                      .withValues(alpha: 0.5),
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
