import 'package:flutter/material.dart';

import 'package:diet_log/core/utils/date_formatter.dart';
import 'package:diet_log/data/models/nutrition_log.dart';
import 'package:diet_log/presentation/theme/app_theme.dart';
import 'package:diet_log/presentation/widgets/nutrient_tag.dart';

/// Detail view for a single food/nutrition log entry.
///
/// Receives a [NutritionLog] via route arguments and displays
/// full nutritional breakdown, portion size controls, and dietary tags.
class FoodDetailScreen extends StatefulWidget {
  const FoodDetailScreen({super.key});

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  double _servings = 1.0;

  @override
  Widget build(BuildContext context) {
    final log = ModalRoute.of(context)!.settings.arguments as NutritionLog;

    // Scale values by serving multiplier
    final scaledCalories = (log.calories * _servings).round();
    final scaledProtein = log.proteinG * _servings;
    final scaledCarbs = log.carbsG * _servings;
    final scaledFats = log.fatsG * _servings;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
        ),
        title: const Text(
          'DietLog',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.share_outlined,
              color: AppTheme.textSecondary,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
              child: const Icon(
                Icons.person,
                color: AppTheme.primaryDark,
                size: 18,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Food Image Area ─────────────────────────────────────────
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.06),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.restaurant,
                      size: 60,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Healthy Choice',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title + Calories ────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(log.foodName, style: AppTheme.headingMedium),
                            const SizedBox(height: 4),
                            Text(
                              '${log.servingSizeEstimate ?? 'Serving'} • ${DateFormatter.time(log.loggedAt)}',
                              style: AppTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$scaledCalories',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'KCAL',
                            style: AppTheme.caption.copyWith(
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Macro Mini Cards ────────────────────────────────────
                  Row(
                    children: [
                      _MiniMacro(
                        label: 'Protein',
                        value: '${scaledProtein.toStringAsFixed(0)}g',
                        color: const Color(0xFF2E7D32),
                      ),
                      const SizedBox(width: 12),
                      _MiniMacro(
                        label: 'Carbs',
                        value: '${scaledCarbs.toStringAsFixed(0)}g',
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 12),
                      _MiniMacro(
                        label: 'Fats',
                        value: '${scaledFats.toStringAsFixed(0)}g',
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── Portion Size ────────────────────────────────────────
                  const Text('Portion Size', style: AppTheme.headingSmall),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.cardWhite,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _PortionButton(
                          icon: Icons.remove,
                          onTap: () {
                            if (_servings > 0.5) {
                              setState(() => _servings -= 0.5);
                            }
                          },
                        ),
                        Text(
                          '${_servings.toStringAsFixed(1)}  Servings',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        _PortionButton(
                          icon: Icons.add,
                          onTap: () => setState(() => _servings += 0.5),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Nutritional Info Card ───────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.cardWhite,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nutritional Information',
                          style: AppTheme.headingSmall,
                        ),
                        const SizedBox(height: 16),
                        _NutrientRow(
                          icon: Icons.local_fire_department_outlined,
                          label: 'Calories',
                          value: '$scaledCalories kcal',
                        ),
                        const Divider(color: AppTheme.divider),
                        _NutrientRow(
                          icon: Icons.fitness_center,
                          label: 'Protein',
                          value: '${scaledProtein.toStringAsFixed(1)}g',
                        ),
                        const Divider(color: AppTheme.divider),
                        _NutrientRow(
                          icon: Icons.grain,
                          label: 'Carbohydrates',
                          value: '${scaledCarbs.toStringAsFixed(1)}g',
                        ),
                        const Divider(color: AppTheme.divider),
                        _NutrientRow(
                          icon: Icons.water_drop_outlined,
                          label: 'Fats',
                          value: '${scaledFats.toStringAsFixed(1)}g',
                        ),
                        const Divider(color: AppTheme.divider),
                        _NutrientRow(
                          icon: Icons.science_outlined,
                          label: 'Confidence',
                          value:
                              '${((log.confidenceScore ?? 0) * 100).toStringAsFixed(0)}%',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Dietary Tags ────────────────────────────────────────
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (scaledProtein > 15)
                        const NutrientTag(label: 'High Protein'),
                      if (scaledFats < 10) const NutrientTag(label: 'Low Fat'),
                      if (scaledCarbs < 30)
                        const NutrientTag(label: 'Low Carb'),
                      const NutrientTag(label: 'AI Analyzed'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Edit Log Button ─────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Edit feature coming soon'),
                            backgroundColor: AppTheme.primaryDark,
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit Log'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusRound,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniMacro extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniMacro({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            Text(label, style: AppTheme.caption),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _PortionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.divider),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Icon(icon, color: AppTheme.primaryDark, size: 20),
      ),
    );
  }
}

class _NutrientRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _NutrientRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Text(label, style: AppTheme.bodyMedium),
          const Spacer(),
          Text(value, style: AppTheme.labelLarge),
        ],
      ),
    );
  }
}
