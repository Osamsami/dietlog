import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/supabase_constants.dart';
import 'core/utils/logger.dart';
import 'data/local/hive_service.dart';

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

/// Root application widget.
///
/// ⛔ Presentation layer is blocked — this is a headless shell only.
/// Screens will be added after the stitch file is provided.
class DietLogApp extends StatelessWidget {
  const DietLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DietLog',
      debugShowCheckedModeBanner: false,
      // Placeholder — no screens until stitch file is provided
      home: const Scaffold(
        body: Center(
          child: Text('DietLog — Headless Shell'),
        ),
      ),
    );
  }
}
