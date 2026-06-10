import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Small rounded tag chip for displaying macro/dietary labels.
///
/// Used in history cards and food detail screens.
class NutrientTag extends StatelessWidget {
  final String label;
  final Color? color;

  const NutrientTag({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final tagColor = color ?? AppTheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tagColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: tagColor,
        ),
      ),
    );
  }
}
