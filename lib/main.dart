// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/hive_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── System UI ──────────────────────────────────────
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // ── Hive: register adapters, open boxes, seed data ──
  // All logic lives in HiveService — see lib/services/hive_service.dart
  await HiveService.init();

  // ── Supabase init (Layer 7 — not started yet) ───────
  // Uncomment when real URL + anonKey are available.
  // await Supabase.initialize(
  //   url: SupabaseConstants.supabaseUrl,
  //   anonKey: SupabaseConstants.supabaseAnonKey,
  //   debug: true,
  // );

  // ── Run app ────────────────────────────────────────
  runApp(
    const ProviderScope(
      child: AgriTrackApp(),
    ),
  );
}