import 'package:flutter/material.dart';

import 'package:diet_log/presentation/theme/app_theme.dart';

/// Units preference screen.
///
/// Allows switching between Metric and Imperial measurement units.
class UnitsScreen extends StatefulWidget {
  const UnitsScreen({super.key});

  @override
  State<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends State<UnitsScreen> {
  String _selectedUnit = 'Metric';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
        ),
        title: const Text(
          'Units',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Measurement System', style: AppTheme.headingSmall),
            const SizedBox(height: 6),
            Text(
              'Choose your preferred unit system for weight, height, and nutrition values.',
              style: AppTheme.bodySmall,
            ),
            const SizedBox(height: 20),

            _UnitOption(
              title: 'Metric',
              subtitle: 'Kilograms, centimeters, liters',
              icon: Icons.straighten,
              isSelected: _selectedUnit == 'Metric',
              onTap: () => setState(() => _selectedUnit = 'Metric'),
            ),
            const SizedBox(height: 12),
            _UnitOption(
              title: 'Imperial',
              subtitle: 'Pounds, inches, ounces',
              icon: Icons.square_foot,
              isSelected: _selectedUnit == 'Imperial',
              onTap: () => setState(() => _selectedUnit = 'Imperial'),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Units set to $_selectedUnit'),
                      backgroundColor: AppTheme.primaryDark,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _UnitOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _UnitOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: isSelected ? AppTheme.primaryDark : AppTheme.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppTheme.cardShadow : null,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: (isSelected ? AppTheme.primaryDark : AppTheme.textSecondary)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(icon,
                  color: isSelected ? AppTheme.primaryDark : AppTheme.textSecondary,
                  size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.labelLarge),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTheme.bodySmall),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppTheme.primaryDark : AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
