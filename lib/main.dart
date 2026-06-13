// main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/constants/supabase_constants.dart';

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

  // ── Hive init ──────────────────────────────────────
  await _initHive();

  // ── Supabase init ──────────────────────────────────
  await _initSupabase();

  // ── Run app ────────────────────────────────────────
  runApp(
    const ProviderScope(
      child: AgriTrackApp(),
    ),
  );
}

// ── Hive initialization ────────────────────────────────
Future<void> _initHive() async {
  await Hive.initFlutter();

  // Register TypeAdapters here later (Phase 9)
  // Hive.registerAdapter(FarmerModelAdapter());
  // Hive.registerAdapter(PlotModelAdapter());
  // Hive.registerAdapter(SeasonModelAdapter());
  // Hive.registerAdapter(CropEventModelAdapter());
  // Hive.registerAdapter(EmissionModelAdapter());

  // Open boxes
  await Future.wait([
    Hive.openBox<dynamic>(SupabaseConstants.hiveBoxFarmers),
    Hive.openBox<dynamic>(SupabaseConstants.hiveBoxPlots),
    Hive.openBox<dynamic>(SupabaseConstants.hiveBoxSeasons),
    Hive.openBox<dynamic>(SupabaseConstants.hiveBoxEmissions),
    Hive.openBox<dynamic>(SupabaseConstants.hiveBoxPendingOps),
    Hive.openBox<dynamic>(SupabaseConstants.hiveBoxSettings),
  ]);
}

// ── Supabase initialization ────────────────────────────
Future<void> _initSupabase() async {
  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
    debug: false, // set true during development
  );
}