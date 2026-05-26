import 'package:flutter/material.dart';

import 'package:diet_log/presentation/theme/app_theme.dart';

/// **ConfirmationPendingScreen** — Post-signup email-verification gate.
///
/// VIVA NOTE: This screen is shown when Supabase's `signUp()` returns a
/// `null` session, which happens when email confirmation is enabled in the
/// Supabase dashboard.  The user cannot proceed to the main app until they
/// click the magic-link in their inbox.  This is a pure UI screen — it has
/// no providers or business-logic dependencies.
///
/// Design rationale:
/// • A calming, single-purpose layout keeps the user focused on one task.
/// • The circular icon gives a strong visual anchor, following Material 3
///   empty-state guidelines.
/// • Two CTAs: "Open Email App" (primary action) and "Back to Login" (escape
///   hatch if the user entered the wrong email).
class ConfirmationPendingScreen extends StatelessWidget {
  const ConfirmationPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // VIVA NOTE: We use Scaffold with AppTheme.background to match every
    // other screen in the app and maintain visual consistency.
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          // VIVA NOTE: SingleChildScrollView prevents overflow on small
          // devices or when the system font-scale is increased.
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingXl,
              vertical: AppTheme.spacingLg,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Email Icon ────────────────────────────────────────────
                // VIVA NOTE: A Container with a circular shape and the
                // primary colour acts as a branded "hero" element.  We use
                // a native Flutter Icon instead of Lottie to avoid an
                // additional dependency and keep the APK size small.
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.elevatedShadow,
                  ),
                  child: const Icon(
                    Icons.email_outlined,
                    size: 48,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: AppTheme.spacingLg),

                // ── Heading ───────────────────────────────────────────────
                // VIVA NOTE: headingLarge is the biggest text style in
                // our design-system — appropriate for a page-level title.
                const Text(
                  'Check Your Email',
                  style: AppTheme.headingLarge,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppTheme.spacingMd),

                // ── Body Copy ─────────────────────────────────────────────
                // VIVA NOTE: bodyLarge with textSecondary keeps the
                // paragraph readable but visually subordinate to the
                // heading, establishing a clear information hierarchy.
                Text(
                  'We\'ve sent a confirmation link to your email. '
                  'Please verify your account to continue.',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppTheme.spacingXl),

                // ── Primary CTA — "Open Email App" ────────────────────────
                // VIVA NOTE: We intentionally do NOT launch the email
                // client via url_launcher because the user may use any
                // mail app.  Instead we surface a SnackBar hint.  A
                // production enhancement could use `android_intent` or
                // `url_launcher` with a `mailto:` scheme.
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please check your email inbox'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.open_in_new, size: 20),
                    label: const Text('Open Email App'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppTheme.spacingMd),

                // ── Secondary CTA — "Back to Login" ──────────────────────
                // VIVA NOTE: pushReplacementNamed removes this screen
                // from the navigation stack, which prevents the user from
                // pressing the system back button and landing back here.
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: Text(
                    'Back to Login',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
