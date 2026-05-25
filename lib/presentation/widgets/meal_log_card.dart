import 'package:flutter/material.dart';

import '../../core/utils/date_formatter.dart';
import '../../data/models/nutrition_log.dart';
import '../theme/app_theme.dart';
import 'nutrient_tag.dart';

/// Elevated white card displaying a single meal log entry.
///
/// Matches the history stitch: food icon/placeholder, food name,
/// calorie count, time, and macro tags.
class MealLogCard extends StatelessWidget {
  final NutritionLog log;
  final VoidCallback? onTap;

  const MealLogCard({
    super.key,
    required this.log,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            // Food icon placeholder
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: const Icon(
                Icons.restaurant,
                color: AppTheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          log.foodName,
                          style: AppTheme.labelLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${log.calories}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'kcal',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormatter.time(log.loggedAt),
                        style: AppTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Macro tags
                  Wrap(
                    spacing: 6,
                    children: [
                      if (log.proteinG > 0)
                        const NutrientTag(label: 'Protein'),
                      if (log.carbsG > 0)
                        const NutrientTag(label: 'Carbs'),
                      if (log.fatsG > 0)
                        const NutrientTag(label: 'Fats'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
