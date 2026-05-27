import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // INJECTED: Supabase import for session refresh

import 'package:diet_log/logic/providers/auth_provider.dart';
import 'package:diet_log/logic/providers/measurements_provider.dart';
import 'package:diet_log/logic/providers/user_preferences_provider.dart';
import 'package:diet_log/presentation/theme/app_theme.dart';
import 'measurements_updater.dart';

/// User profile screen with daily goals, personal info, and settings.
///
/// ## Clean Architecture (Presentation Layer):
/// Consumes:
/// - [currentAuthUserProvider] for user credentials and metadata (e.g. name, email, avatar).
/// - [currentUserProfileProvider] for full database profile details.
/// - [measurementsProvider] for Height, Weight, Age (Hive-backed).
/// - [userPreferencesProvider] for Calorie and Water goals (Hive-backed).
/// - [authRepositoryProvider] to perform sign-out and profile modifications in a clean manner.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  bool _notificationsEnabled = true;

  /// Prompt modal to upload a new profile picture and update Supabase metadata.
  Future<void> _pickAndUploadAvatar() async {
    final userId = ref.read(currentAuthUserIdProvider);
    if (userId == null) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 500,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      // Upload picture to 'profile-pictures' storage bucket via Repository
      await ref.read(authRepositoryProvider).uploadAvatar(image.path);

      // INDUSTRIAL FIX: Force refresh Supabase session metadata AND Riverpod states
      await Supabase.instance.client.auth.refreshSession();
      ref.invalidate(currentAuthUserProvider);
      ref.invalidate(currentUserProfileProvider);

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Profile picture updated successfully!'),
          backgroundColor: AppTheme.primaryDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  /// Show a dialog to update the user's display name.
  void _editDisplayName(String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            hintText: 'e.g. John Doe',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                try {
                  await ref
                      .read(authRepositoryProvider)
                      .updateProfile(fullName: newName);

                  // INDUSTRIAL FIX: Force refresh Supabase session metadata AND Riverpod states
                  await Supabase.instance.client.auth.refreshSession();
                  ref.invalidate(currentAuthUserProvider);
                  ref.invalidate(currentUserProfileProvider);

                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Display name updated successfully!'),
                      backgroundColor: AppTheme.primaryDark,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to update name: $e'),
                      backgroundColor: AppTheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Present a sheet/menu for avatar or name modification.
  void _showEditProfileMenu(String currentName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_camera,
                color: AppTheme.primaryDark,
              ),
              title: const Text('Change Profile Picture'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadAvatar();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: AppTheme.primaryDark),
              title: const Text('Edit Display Name'),
              onTap: () {
                Navigator.pop(context);
                _editDisplayName(currentName);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog to update the daily calorie goal.
  void _editCalorieGoal(BuildContext context, int currentGoal) {
    final controller = TextEditingController(text: currentGoal.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Update Calorie Goal'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Daily Calories (kcal)',
            hintText: 'e.g. 2000',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final newGoal = int.tryParse(controller.text);
              if (newGoal != null && newGoal > 0) {
                ref
                    .read(userPreferencesProvider.notifier)
                    .updateCalorieGoal(newGoal);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Calorie goal updated!'),
                    backgroundColor: AppTheme.primaryDark,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Dialog to update the daily water goal.
  void _editWaterGoal(BuildContext context, double currentGoal) {
    final controller = TextEditingController(
      text: currentGoal.toStringAsFixed(1),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Update Water Goal'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Daily Water (Liters)',
            hintText: 'e.g. 3.2',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final newGoal = double.tryParse(controller.text);
              if (newGoal != null && newGoal > 0) {
                ref
                    .read(userPreferencesProvider.notifier)
                    .updateWaterGoal(newGoal);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Water goal updated!'),
                    backgroundColor: AppTheme.primaryDark,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentAuthUserProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final measurements = ref.watch(measurementsProvider);
    final userPrefs = ref.watch(userPreferencesProvider);

    // Bind Name and Email to metadata with database profile fallback
    final String displayName =
        profileAsync.value?.fullName ?? // Database result first
        user?.userMetadata?['full_name'] as String? ?? // Auth metadata fallback
        user?.email?.split('@').first ?? // Email handle fallback
        'User';

    final String userEmail =
        user?.email ?? profileAsync.value?.email ?? 'No email';
    final String? avatarUrl =
        user?.userMetadata?['avatar_url'] as String? ??
        user?.userMetadata?['picture']
            as String?; // Support google signin if present

    final String signupYear = profileAsync.value?.createdAt != null
        ? profileAsync.value!.createdAt!.year.toString()
        : DateTime.now().year.toString();

    // Check if navigated as standalone screen or embedded tab
    final bool canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  if (canPop) ...[
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 20,
                        color: AppTheme.textPrimary,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                  ],
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

            // ── Scrollable Content ────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // ── Avatar Section ────────────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: () => _showEditProfileMenu(displayName),
                                child: CircleAvatar(
                                  radius: 54,
                                  backgroundColor: AppTheme.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                  backgroundImage: avatarUrl != null
                                      ? NetworkImage(avatarUrl)
                                      : null,
                                  child: avatarUrl == null
                                      ? const Icon(
                                          Icons.person,
                                          size: 54,
                                          color: AppTheme.primaryDark,
                                        )
                                      : null,
                                ),
                              ),
                              if (_isUploading)
                                Positioned.fill(
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black45,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppTheme.primary,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                bottom: 0,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () =>
                                      _showEditProfileMenu(displayName),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryDark,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppTheme.background,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(displayName, style: AppTheme.headingMedium),
                              const SizedBox(width: 4),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: AppTheme.textSecondary,
                                ),
                                onPressed: () => _editDisplayName(displayName),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(userEmail, style: AppTheme.bodySmall),
                          const SizedBox(height: 4),
                          Text(
                            'Member since $signupYear',
                            style: AppTheme.caption,
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
                          value:
                              '${userPrefs.calorieGoal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} kcal',
                          onTap: () =>
                              _editCalorieGoal(context, userPrefs.calorieGoal),
                        ),
                        const Divider(color: AppTheme.divider, height: 1),
                        _GoalRow(
                          icon: Icons.water_drop,
                          iconColor: Colors.blue,
                          label: 'WATER GOAL',
                          value:
                              '${userPrefs.waterGoalLiters.toStringAsFixed(1)} Liters',
                          onTap: () => _editWaterGoal(
                            context,
                            userPrefs.waterGoalLiters,
                          ),
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
                              _InfoChip(
                                label: 'HEIGHT',
                                value:
                                    '${measurements.heightCm.toStringAsFixed(0)} cm',
                              ),
                              const SizedBox(width: 12),
                              _InfoChip(
                                label: 'WEIGHT',
                                value:
                                    '${measurements.weightKg.toStringAsFixed(0)} kg',
                              ),
                              const SizedBox(width: 12),
                              _InfoChip(
                                label: 'AGE',
                                value: '${measurements.age} yrs',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => MeasurementsUpdater.show(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.divider),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd,
                                ),
                              ),
                            ),
                            child: const Text(
                              'Update Measurements',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
                            const Icon(
                              Icons.notifications_active_outlined,
                              size: 20,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Notifications',
                              style: AppTheme.bodyMedium,
                            ),
                            const Spacer(),
                            Switch.adaptive(
                              value: _notificationsEnabled,
                              onChanged: (v) {
                                setState(() => _notificationsEnabled = v);
                                if (v) {
                                  Navigator.pushNamed(
                                    context,
                                    '/notifications',
                                  );
                                }
                              },
                              activeTrackColor: AppTheme.primaryDark,
                            ),
                          ],
                        ),
                        const Divider(color: AppTheme.divider, height: 1),
                        _SettingsRow(
                          icon: Icons.straighten,
                          label: 'Units',
                          trailing: 'Metric',
                          onTap: () => Navigator.pushNamed(context, '/units'),
                        ),
                        const Divider(color: AppTheme.divider, height: 1),
                        _SettingsRow(
                          icon: Icons.help_outline,
                          label: 'Support',
                          onTap: () => Navigator.pushNamed(context, '/support'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── Sign Out Button ───────────────────────────────────
                    TextButton.icon(
                      onPressed: () async {
                        await ref.read(authRepositoryProvider).signOut();
                        if (!context.mounted) return;
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
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
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
