import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:diet_log/logic/providers/measurements_provider.dart';
import 'package:diet_log/presentation/theme/app_theme.dart';

/// Modal bottom sheet for updating user body measurements.
///
/// Reads current values from [measurementsProvider], presents editable
/// fields, validates input, and writes back via [MeasurementsNotifier].
class MeasurementsUpdater extends ConsumerStatefulWidget {
  const MeasurementsUpdater({super.key});

  /// Convenience method to show this as a modal bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MeasurementsUpdater(),
    );
  }

  @override
  ConsumerState<MeasurementsUpdater> createState() =>
      _MeasurementsUpdaterState();
}

class _MeasurementsUpdaterState extends ConsumerState<MeasurementsUpdater> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _heightCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _ageCtrl;

  @override
  void initState() {
    super.initState();
    final m = ref.read(measurementsProvider);
    _heightCtrl = TextEditingController(text: m.heightCm.toStringAsFixed(0));
    _weightCtrl = TextEditingController(text: m.weightKg.toStringAsFixed(0));
    _ageCtrl = TextEditingController(text: m.age.toString());
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    ref
        .read(measurementsProvider.notifier)
        .updateAll(
          heightCm: double.parse(_heightCtrl.text.trim()),
          weightKg: double.parse(_weightCtrl.text.trim()),
          age: int.parse(_ageCtrl.text.trim()),
        );

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Measurements updated'),
        backgroundColor: AppTheme.primaryDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String? _validatePositiveNumber(String? value, String field) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    final n = double.tryParse(value.trim());
    if (n == null || n <= 0) return 'Enter a valid $field';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle bar ─────────────────────────────────────────────────
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

            // ── Title ──────────────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.straighten, color: AppTheme.primaryDark),
                const SizedBox(width: 8),
                const Text('Update Measurements', style: AppTheme.headingSmall),
              ],
            ),
            const SizedBox(height: 24),

            // ── Height ─────────────────────────────────────────────────────
            TextFormField(
              controller: _heightCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) => _validatePositiveNumber(v, 'height'),
              decoration: const InputDecoration(
                labelText: 'Height (cm)',
                prefixIcon: Icon(Icons.height),
              ),
            ),
            const SizedBox(height: 14),

            // ── Weight ─────────────────────────────────────────────────────
            TextFormField(
              controller: _weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              validator: (v) => _validatePositiveNumber(v, 'weight'),
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                prefixIcon: Icon(Icons.monitor_weight_outlined),
              ),
            ),
            const SizedBox(height: 14),

            // ── Age ────────────────────────────────────────────────────────
            TextFormField(
              controller: _ageCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) => _validatePositiveNumber(v, 'age'),
              decoration: const InputDecoration(
                labelText: 'Age (years)',
                prefixIcon: Icon(Icons.cake_outlined),
              ),
            ),
            const SizedBox(height: 28),

            // ── Save Button ────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
