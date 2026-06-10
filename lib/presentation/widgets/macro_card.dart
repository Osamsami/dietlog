import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Macro nutrient card displaying a single macro with progress bar.
///
/// Matches the dashboard stitch: label, large value, colored progress
/// bar, and goal text beneath.
class MacroCard extends StatelessWidget {
  final String label;
  final double value;
  final double goal;
  final Color? barColor;

  const MacroCard({
    super.key,
    required this.label,
    required this.value,
    required this.goal,
    this.barColor,
  });

  double get progress => goal > 0 ? (value / goal).clamp(0.0, 1.0) : 0;

  Color get _barColor {
    if (barColor != null) return barColor!;
    switch (label.toLowerCase()) {
      case 'protein':
        return const Color(0xFF2E7D32); // Dark green
      case 'carbs':
        return AppTheme.primary;
      case 'fats':
        return AppTheme.textSecondary;
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.bodySmall),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 2),
              const Text(
                'g',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, animValue, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: animValue,
                  minHeight: 5,
                  backgroundColor: AppTheme.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(_barColor),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text('Goal: ${goal.toStringAsFixed(0)}g', style: AppTheme.caption),
        ],
      ),
    );
  }
}
