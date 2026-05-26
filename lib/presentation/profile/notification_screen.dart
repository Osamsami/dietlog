import 'package:flutter/material.dart';

import 'package:diet_log/presentation/theme/app_theme.dart';

/// **NotificationScreen** — User-facing notification preferences.
///
/// VIVA NOTE: This is a **StatefulWidget** because the toggle states are
/// local UI state that does not need to persist across sessions (yet).
/// In a production app we would back these with a Riverpod notifier and
/// store them in SharedPreferences or a remote user-settings table.
///
/// Layout breakdown:
/// 1. "Push Notifications" — three switches in a white card.
/// 2. "Reminder Schedule" — three time-slots in a white card.
/// 3. A footer caption with a disclaimer about notification timing.
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // ── Toggle State ─────────────────────────────────────────────────────────
  // VIVA NOTE: Default values match the spec — meal reminders and daily
  // summary are ON, weekly report is OFF. These booleans are the single
  // source of truth for the switch widgets.
  bool _mealReminders = true;
  bool _dailySummary = true;
  bool _weeklyReport = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // VIVA NOTE: AppTheme.background (#F8F9FA) keeps this screen
      // visually consistent with the rest of the app.
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        // VIVA NOTE: The AppBarTheme in AppTheme.lightTheme already
        // centres the title and sets the background to AppTheme.background.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Notifications'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section 1 — Push Notifications ──────────────────────────
            _buildSectionHeading('Push Notifications'),
            const SizedBox(height: AppTheme.spacingSm),

            // VIVA NOTE: We wrap the switches inside a decorated
            // Container instead of a Card widget to have full control
            // over shadow, border-radius, and internal padding.
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  // ── Meal Reminders Toggle ───────────────────────────
                  _buildSwitchTile(
                    title: 'Meal Reminders',
                    subtitle: 'Get reminded to log your meals',
                    value: _mealReminders,
                    onChanged: (bool val) {
                      setState(() => _mealReminders = val);
                    },
                  ),

                  const Divider(
                    height: 1,
                    indent: AppTheme.spacingMd,
                    endIndent: AppTheme.spacingMd,
                    color: AppTheme.divider,
                  ),

                  // ── Daily Summary Toggle ────────────────────────────
                  _buildSwitchTile(
                    title: 'Daily Summary',
                    subtitle: 'Receive end-of-day nutrition summary',
                    value: _dailySummary,
                    onChanged: (bool val) {
                      setState(() => _dailySummary = val);
                    },
                  ),

                  const Divider(
                    height: 1,
                    indent: AppTheme.spacingMd,
                    endIndent: AppTheme.spacingMd,
                    color: AppTheme.divider,
                  ),

                  // ── Weekly Report Toggle ────────────────────────────
                  _buildSwitchTile(
                    title: 'Weekly Report',
                    subtitle: 'Get a weekly progress report',
                    value: _weeklyReport,
                    onChanged: (bool val) {
                      setState(() => _weeklyReport = val);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingLg),

            // ── Section 2 — Reminder Schedule ───────────────────────────
            _buildSectionHeading('Reminder Schedule'),
            const SizedBox(height: AppTheme.spacingSm),

            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  // VIVA NOTE: Each schedule row has a clock icon, label,
                  // spacer, trailing time text, and a chevron_right icon.
                  // Tapping a row would ideally open a TimePicker dialog.
                  _buildScheduleRow(
                    label: 'Breakfast',
                    time: '8:00 AM',
                    showDivider: true,
                  ),
                  _buildScheduleRow(
                    label: 'Lunch',
                    time: '12:30 PM',
                    showDivider: true,
                  ),
                  _buildScheduleRow(
                    label: 'Dinner',
                    time: '7:00 PM',
                    showDivider: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingMd),

            // ── Footer Disclaimer ────────────────────────────────────────
            // VIVA NOTE: A subtle caption informs the user that push
            // notifications are best-effort. This is important on both
            // Android (Doze mode) and iOS (background-app-refresh).
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingXs,
              ),
              child: Text(
                'Notification times are approximate and may vary.',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Private Helper Widgets
  // ═══════════════════════════════════════════════════════════════════════════

  /// Builds a bold section heading above each card.
  ///
  /// VIVA NOTE: Extracted as a method to keep the build tree readable
  /// and to guarantee consistent styling across multiple sections.
  Widget _buildSectionHeading(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: AppTheme.spacingXs),
      child: Text(
        title,
        style: AppTheme.headingSmall,
      ),
    );
  }

  /// Builds a single toggle row inside the Push Notifications card.
  ///
  /// VIVA NOTE: The [Switch.adaptive] constructor renders a Material
  /// switch on Android and a Cupertino switch on iOS, giving a native
  /// feel on both platforms.  The `activeColor` is set to
  /// [AppTheme.primaryDark] so the switch thumb matches our brand.
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm + 4,
      ),
      child: Row(
        children: [
          // ── Text Column (title + subtitle) ──────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.bodyLarge),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // ── Switch ──────────────────────────────────────────────────
          // VIVA NOTE: `Switch.adaptive` provides platform-specific
          // styling automatically.
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppTheme.primaryDark,
          ),
        ],
      ),
    );
  }

  /// Builds a single row inside the Reminder Schedule card.
  ///
  /// VIVA NOTE: The row composition follows a common list-tile pattern:
  /// leading icon → label (expanded) → trailing metadata → chevron.
  /// We use a manual Row instead of ListTile for pixel-precise spacing.
  Widget _buildScheduleRow({
    required String label,
    required String time,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingMd - 2,
          ),
          child: Row(
            children: [
              // ── Clock Icon ──────────────────────────────────────────
              Icon(
                Icons.access_time_rounded,
                size: 22,
                color: AppTheme.primaryDark,
              ),

              const SizedBox(width: AppTheme.spacingSm + 4),

              // ── Meal Label ──────────────────────────────────────────
              Expanded(
                child: Text(label, style: AppTheme.bodyLarge),
              ),

              // ── Time Trailing Text ──────────────────────────────────
              Text(
                time,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),

              const SizedBox(width: AppTheme.spacingXs),

              // ── Chevron Right ───────────────────────────────────────
              // VIVA NOTE: chevron_right signals that tapping this row
              // would open a detail view (e.g. a TimePicker).
              const Icon(
                Icons.chevron_right,
                size: 22,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),

        // ── Conditional Divider ──────────────────────────────────────
        // VIVA NOTE: We hide the divider on the last row to prevent a
        // stray line at the bottom of the card.
        if (showDivider)
          const Divider(
            height: 1,
            indent: AppTheme.spacingMd,
            endIndent: AppTheme.spacingMd,
            color: AppTheme.divider,
          ),
      ],
    );
  }
}
