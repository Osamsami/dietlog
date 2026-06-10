import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:diet_log/logic/providers/auth_provider.dart';
import 'package:diet_log/logic/providers/nutrition_log_provider.dart';
import 'package:diet_log/presentation/theme/app_theme.dart';
import 'package:diet_log/presentation/widgets/macro_card.dart';
import 'package:diet_log/presentation/widgets/progress_ring.dart';

/// Main dashboard screen displaying daily calorie/macro overview.
///
/// Consumes [dailySummaryProvider] for the progress ring and macro cards,
/// and [currentUserProfileProvider] for the greeting.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dailySummaryProvider);
    final user = ref.watch(currentAuthUserProvider);
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Custom Header ───────────────────────────────────────────
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

            // ── Body ────────────────────────────────────────────────────
            Expanded(
              child: summaryAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppTheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load dashboard',
                          style: AppTheme.headingSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(error.toString(), style: AppTheme.bodySmall),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(dailySummaryProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (summary) => SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // ── Calorie Ring Card ─────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        decoration: BoxDecoration(
                          color: AppTheme.cardWhite,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusLg,
                          ),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: ProgressRing(
                          consumed: summary.totalCalories,
                          goal: summary.calorieTarget,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Macro Cards Row ───────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: MacroCard(
                              label: 'Protein',
                              value: summary.totalProtein,
                              goal: summary.proteinTarget,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: MacroCard(
                              label: 'Carbs',
                              value: summary.totalCarbs,
                              goal: summary.carbsTarget,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: MacroCard(
                              label: 'Fats',
                              value: summary.totalFats,
                              goal: summary.fatsTarget,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Motivation Card ───────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusLg,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.emoji_events,
                                color: AppTheme.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Great Progress!',
                                    style: AppTheme.labelLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _motivationMessage(summary),
                                    style: AppTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 80), // Space for FAB
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppTheme.primaryDark,
          boxShadow: AppTheme.elevatedShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.pushNamed(context, '/camera'),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Icon(Icons.camera_alt, color: Colors.white, size: 26),
            ),
          ),
        ),
      ),
    );
  }

  String _motivationMessage(DailySummary summary) {
    final proteinPct = (summary.proteinProgress * 100).toInt();
    final calPct = (summary.calorieProgress * 100).toInt();

    if (calPct >= 100) {
      return "You've reached your calorie goal for today!";
    } else if (proteinPct >= 50) {
      return "You've hit $proteinPct% of your protein goal for today.";
    } else if (summary.logCount > 0) {
      return "Keep going! You've logged ${summary.logCount} meal${summary.logCount > 1 ? 's' : ''} today.";
    }
    return 'Start logging meals to track your nutrition!';
  }
}
