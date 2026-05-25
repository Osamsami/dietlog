import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:diet_log/logic/providers/auth_provider.dart';
import 'package:diet_log/presentation/theme/app_theme.dart';

/// User profile screen with daily goals, personal info, and settings.
///
/// Consumes [currentUserProfileProvider] for user data and
/// [authRepositoryProvider] for sign-out.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_none_rounded,
                        color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),

            // ── Scrollable Content ────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // ── Avatar Section ────────────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor:
                                    AppTheme.primary.withValues(alpha: 0.15),
                                child: const Icon(Icons.person,
                                    size: 48, color: AppTheme.primaryDark),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryDark,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppTheme.background,
                                        width: 2),
                                  ),
                                  child: const Icon(Icons.edit,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          profileAsync.when(
                            loading: () => const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            ),
                            error: (e, s) => const Text('User',
                                style: AppTheme.headingMedium),
                            data: (profile) => Text(
                              profile?.fullName ?? 'User',
                              style: AppTheme.headingMedium,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Member since ${DateTime.now().year}',
                            style: AppTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Daily Goals Card ──────────────────────────────────
                    _SectionCard(
                      icon: Icons.flag_outlined,
                      title: 'Daily Goals',
                      children: [
                        _GoalRow(
                          icon: Icons.local_fire_department,
                          iconColor: AppTheme.primaryDark,
                          label: 'CALORIE GOAL',
                          value: '2,000 kcal',
                          onTap: () {},
                        ),
                        const Divider(color: AppTheme.divider, height: 1),
                        _GoalRow(
                          icon: Icons.water_drop,
                          iconColor: Colors.blue,
                          label: 'WATER GOAL',
                          value: '3.2 Liters',
                          onTap: () {},
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Personal Info Card ────────────────────────────────
                    _SectionCard(
                      icon: Icons.person_outline,
                      title: 'Personal Info',
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              _InfoChip(label: 'HEIGHT', value: '182 cm'),
                              const SizedBox(width: 12),
                              _InfoChip(label: 'WEIGHT', value: '78 kg'),
                              const SizedBox(width: 12),
                              _InfoChip(label: 'AGE', value: '28 yrs'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: AppTheme.divider),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMd),
                              ),
                            ),
                            child: const Text('Update Measurements',
                                style:
                                    TextStyle(color: AppTheme.textPrimary)),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Account Settings Card ─────────────────────────────
                    _SectionCard(
                      icon: Icons.settings_outlined,
                      title: 'Account Settings',
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.notifications_active_outlined,
                                size: 20, color: AppTheme.textSecondary),
                            const SizedBox(width: 12),
                            const Text('Notifications',
                                style: AppTheme.bodyMedium),
                            const Spacer(),
                            Switch(
                              value: _notificationsEnabled,
                              onChanged: (v) =>
                                  setState(() => _notificationsEnabled = v),
                              activeTrackColor: AppTheme.primaryDark,
                            ),
                          ],
                        ),
                        const Divider(color: AppTheme.divider, height: 1),
                        _SettingsRow(
                          icon: Icons.straighten,
                          label: 'Units',
                          trailing: 'Metric',
                          onTap: () {},
                        ),
                        const Divider(color: AppTheme.divider, height: 1),
                        _SettingsRow(
                          icon: Icons.help_outline,
                          label: 'Support',
                          onTap: () {},
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── Sign Out Button ───────────────────────────────────
                    TextButton.icon(
                      onPressed: () async {
                        await ref.read(authRepositoryProvider).signOut();
                        if (!context.mounted) return;
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      icon: const Icon(Icons.logout, color: AppTheme.error),
                      label: const Text(
                        'Sign Out',
                        style: TextStyle(
                          color: AppTheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private Widgets ───────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primaryDark),
              const SizedBox(width: 8),
              Text(title, style: AppTheme.headingSmall),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _GoalRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTheme.caption),
                const SizedBox(height: 2),
                Text(value, style: AppTheme.labelLarge),
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

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Column(
          children: [
            Text(label, style: AppTheme.caption),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.textSecondary),
            const SizedBox(width: 12),
            Text(label, style: AppTheme.bodyMedium),
            const Spacer(),
            if (trailing != null) ...[
              Text(trailing!, style: AppTheme.bodySmall),
              const SizedBox(width: 4),
            ],
            const Icon(Icons.chevron_right,
                color: AppTheme.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
