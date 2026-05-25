import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent;

import 'package:diet_log/logic/providers/auth_provider.dart';
import 'package:diet_log/presentation/theme/app_theme.dart';

/// Full-screen splash / loading screen shown at app launch.
///
/// Watches the [authStateProvider] and, after a 2-second branding
/// delay, navigates to `/home` (authenticated) or `/login` (guest).
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ── Auth routing ───────────────────────────────────────────────────────
    ref.listen(authStateProvider, (previous, next) {
      next.whenData((authState) {
        Future.delayed(const Duration(seconds: 2), () {
          if (!context.mounted) return;

          final event = authState.event;
          if (event == AuthChangeEvent.signedIn ||
              event == AuthChangeEvent.tokenRefreshed ||
              event == AuthChangeEvent.initialSession) {
            // User is authenticated
            if (authState.session != null) {
              Navigator.pushReplacementNamed(context, '/home');
            } else {
              Navigator.pushReplacementNamed(context, '/login');
            }
          } else if (event == AuthChangeEvent.signedOut) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        });
      });
    });

    // ── UI ──────────────────────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SizedBox.expand(
        child: Column(
          children: [
            const Spacer(flex: 3),

            // Logo
            Image.asset(
              'assets/logo/dietlog_logo.png',
              width: 120,
              height: 120,
            ),

            const SizedBox(height: 24),

            // App name
            const Text(
              'DietLog',
              style: AppTheme.headingLarge,
            ),

            const SizedBox(height: 8),

            // Subtitle
            Text(
              'Track your nutrition, effortlessly',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),

            const Spacer(flex: 3),

            // Loading indicator
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
