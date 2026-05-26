import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/supabase_constants.dart';
import 'core/utils/logger.dart';
import 'data/local/hive_service.dart';
import 'presentation/app_shell.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/auth/signup_screen.dart';
import 'presentation/dashboard/camera_screen.dart';
import 'presentation/history/food_detail_screen.dart';
import 'presentation/profile/notification_screen.dart';
import 'presentation/profile/profile_screen.dart';
import 'presentation/profile/support_screen.dart';
import 'presentation/profile/units_screen.dart';
import 'presentation/splash_screen.dart';
import 'presentation/theme/app_theme.dart';

final _log = AppLogger('Main');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 1. Load Environment Variables ─────────────────────────────────────
  await dotenv.load(fileName: '.env');
  _log.info('Environment variables loaded');

  // ── 2. Initialize Supabase ────────────────────────────────────────────
  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
  );
  _log.info('Supabase client initialized');

  // ── 3. Initialize Hive (local storage + adapters + boxes) ─────────────
  await HiveService.init();
  _log.info('Hive local storage initialized');

  // ── 4. Launch App ─────────────────────────────────────────────────────
  runApp(
    const ProviderScope(
      child: DietLogApp(),
    ),
  );
}

/// Root application widget with full route table.
class DietLogApp extends StatelessWidget {
  const DietLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DietLog',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/home': (_) => const AppShell(),
        '/camera': (_) => const CameraScreen(),
        '/food-detail': (_) => const FoodDetailScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/notifications': (_) => const NotificationScreen(),
        '/units': (_) => const UnitsScreen(),
        '/support': (_) => const SupportScreen(),
      },
    );
  }
}
