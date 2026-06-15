// services/hive_service.dart

import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants/supabase_constants.dart';
import '../features/farmers/models/farmer_model.dart';
import '../features/plots/models/plot_model.dart';
import '../features/crops/models/season_model.dart';
import '../features/crops/models/crop_event_model.dart';
import '../features/carbon/models/emission_model.dart';

/// Central Hive setup: register adapters, open typed boxes, seed sample
/// data on first run only.
///
/// Call `HiveService.init()` once in main.dart, before runApp().
/// This replaces the old placeholder `_initHive()` in main.dart (Step 4).
class HiveService {
  HiveService._();

  // ── Typed box getters ────────────────────────────────────
  // Use these everywhere (providers, repos) instead of
  // Hive.box<dynamic>(...) — gives compile-time type safety.
  static Box<FarmerModel> get farmersBox =>
      Hive.box<FarmerModel>(SupabaseConstants.hiveBoxFarmers);

  static Box<PlotModel> get plotsBox =>
      Hive.box<PlotModel>(SupabaseConstants.hiveBoxPlots);

  static Box<SeasonModel> get seasonsBox =>
      Hive.box<SeasonModel>(SupabaseConstants.hiveBoxSeasons);

  static Box<CropEventModel> get cropEventsBox =>
      Hive.box<CropEventModel>(SupabaseConstants.hiveBoxCropEvents);

  static Box<EmissionModel> get emissionsBox =>
      Hive.box<EmissionModel>(SupabaseConstants.hiveBoxEmissions);

  // Untyped boxes — store plain Maps (sync queue, app settings)
  static Box get pendingOpsBox =>
      Hive.box(SupabaseConstants.hiveBoxPendingOps);

  static Box get settingsBox =>
      Hive.box(SupabaseConstants.hiveBoxSettings);

  // ── Init: register adapters, open boxes, seed data ───────
  // Call once from main.dart, before runApp().
  static Future<void> init() async {
    await Hive.initFlutter();

    // ── Register TypeAdapters ────────────────────────────
    // IDs come from SupabaseConstants.hiveAdapter* — never reuse a
    // deleted ID once shipped (breaks existing user data).
    if (!Hive.isAdapterRegistered(SupabaseConstants.hiveAdapterFarmer)) {
      Hive.registerAdapter(FarmerModelAdapter());
    }
    if (!Hive.isAdapterRegistered(SupabaseConstants.hiveAdapterPlot)) {
      Hive.registerAdapter(PlotModelAdapter());
    }
    if (!Hive.isAdapterRegistered(SupabaseConstants.hiveAdapterSeason)) {
      Hive.registerAdapter(SeasonModelAdapter());
    }
    if (!Hive.isAdapterRegistered(SupabaseConstants.hiveAdapterCropEvent)) {
      Hive.registerAdapter(CropEventModelAdapter());
    }
    if (!Hive.isAdapterRegistered(SupabaseConstants.hiveAdapterEmission)) {
      Hive.registerAdapter(EmissionModelAdapter());
    }

    // ── Open boxes (typed where a model adapter exists) ──
    await Future.wait([
      Hive.openBox<FarmerModel>(SupabaseConstants.hiveBoxFarmers),
      Hive.openBox<PlotModel>(SupabaseConstants.hiveBoxPlots),
      Hive.openBox<SeasonModel>(SupabaseConstants.hiveBoxSeasons),
      Hive.openBox<CropEventModel>(SupabaseConstants.hiveBoxCropEvents),
      Hive.openBox<EmissionModel>(SupabaseConstants.hiveBoxEmissions),
      Hive.openBox(SupabaseConstants.hiveBoxPendingOps),
      Hive.openBox(SupabaseConstants.hiveBoxSettings),
    ]);

    // ── Seed sample data — first run only ────────────────
    await _seedIfEmpty();
  }

  // ── Seed each box from model.seedList(), skip if already populated ──
  static Future<void> _seedIfEmpty() async {
    if (farmersBox.isEmpty) {
      for (final f in FarmerModel.seedList()) {
        await farmersBox.put(f.id, f);
      }
    }
    if (plotsBox.isEmpty) {
      for (final p in PlotModel.seedList()) {
        await plotsBox.put(p.id, p);
      }
    }
    if (seasonsBox.isEmpty) {
      for (final s in SeasonModel.seedList()) {
        await seasonsBox.put(s.id, s);
      }
    }
    if (cropEventsBox.isEmpty) {
      for (final e in CropEventModel.seedList()) {
        await cropEventsBox.put(e.id, e);
      }
    }
    if (emissionsBox.isEmpty) {
      for (final em in EmissionModel.seedList()) {
        await emissionsBox.put(em.id, em);
      }
    }
  }

  // ── Dev helper: wipe all data boxes and reseed ───────────
  // Handy while iterating on seedList() — not used in normal app flow.
  static Future<void> resetAndReseed() async {
    await farmersBox.clear();
    await plotsBox.clear();
    await seasonsBox.clear();
    await cropEventsBox.clear();
    await emissionsBox.clear();
    await _seedIfEmpty();
  }
}