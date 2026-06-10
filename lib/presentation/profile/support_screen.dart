import 'package:flutter/material.dart';

import 'package:diet_log/presentation/theme/app_theme.dart';

/// Support / Help screen with FAQ sections and contact options.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

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
          'Support',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Help Header ────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.support_agent,
                      color: AppTheme.primaryDark,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('How can we help?', style: AppTheme.headingMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Find answers to common questions or contact our team.',
                    style: AppTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── FAQ Section ────────────────────────────────────────────────
            const Text(
              'Frequently Asked Questions',
              style: AppTheme.headingSmall,
            ),
            const SizedBox(height: 14),

            _FaqItem(
              question: 'How does AI food recognition work?',
              answer:
                  'DietLog uses the Gemini Vision API to analyze food images. '
                  'Simply take a photo of your meal, and our AI model identifies '
                  'the food items and estimates nutritional content including '
                  'calories, protein, carbs, and fats.',
            ),
            _FaqItem(
              question: 'Is my data stored securely?',
              answer:
                  'Yes. All data is stored in Supabase with Row Level Security '
                  '(RLS) policies. Only you can access your own nutrition logs '
                  'and profile data. Local caching via Hive is encrypted on-device.',
            ),
            _FaqItem(
              question: 'Can I use the app offline?',
              answer:
                  'Viewing cached logs and your profile works offline. '
                  'However, food image analysis requires an internet connection '
                  'to communicate with the Gemini API.',
            ),
            _FaqItem(
              question: 'How accurate are the nutritional estimates?',
              answer:
                  'AI estimates typically have a confidence score shown on each '
                  'log. For best results, photograph meals with clear lighting '
                  'and a single plate in frame. You can manually edit logs if '
                  'the estimates need adjustment.',
            ),

            const SizedBox(height: 24),

            // ── Contact Section ────────────────────────────────────────────
            const Text('Contact Us', style: AppTheme.headingSmall),
            const SizedBox(height: 14),

            _ContactRow(
              icon: Icons.email_outlined,
              label: 'Email Support',
              subtitle: 'support@dietlog.app',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Email support coming soon'),
                    backgroundColor: AppTheme.primaryDark,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _ContactRow(
              icon: Icons.bug_report_outlined,
              label: 'Report a Bug',
              subtitle: 'Help us improve DietLog',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bug reporting coming soon'),
                    backgroundColor: AppTheme.primaryDark,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // ── Version ────────────────────────────────────────────────────
            Center(child: Text('DietLog v1.0.0', style: AppTheme.caption)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(widget.question, style: AppTheme.labelLarge),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(widget.answer, style: AppTheme.bodySmall),
                ),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(icon, color: AppTheme.primaryDark, size: 20),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTheme.labelLarge),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTheme.bodySmall),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
