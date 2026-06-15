// core/fake/fake_data.dart
//
// Single source of fake data for ALL Layer 6 providers.
// Delete this file entirely when Layer 7 (Supabase) is wired.
// Providers switch from:  ref.watch(fakeDataProvider)
//                     to: ref.watch(repositoryProvider).fetchAll()

import 'package:collection/collection.dart';

import '../../features/farmers/models/farmer_model.dart';
import '../../features/plots/models/plot_model.dart';
import '../../features/crops/models/season_model.dart';
import '../../features/crops/models/crop_event_model.dart';
import '../../features/carbon/models/emission_model.dart';

class FakeData {
  FakeData._();

  // ── Farmers ───────────────────────────────────────
  static final List<FarmerModel> farmers = FarmerModel.seedList();

  // ── Plots ─────────────────────────────────────────
  static final List<PlotModel> plots = PlotModel.seedList();

  // ── Seasons ───────────────────────────────────────
  static final List<SeasonModel> seasons = SeasonModel.seedList();

  // ── Crop Events ───────────────────────────────────
  static final List<CropEventModel> cropEvents = CropEventModel.seedList();

  // ── Emission Records ──────────────────────────────
  static final List<EmissionModel> emissions = EmissionModel.seedList();

  // ── Relational helpers (replaces SQL JOINs) ───────

  /// Plots belonging to a farmer
  static List<PlotModel> plotsForFarmer(String farmerId) =>
      plots.where((p) => p.farmerId == farmerId).toList();

  /// Seasons belonging to a farmer
  static List<SeasonModel> seasonsForFarmer(String farmerId) =>
      seasons.where((s) => s.farmerId == farmerId).toList();

  /// Active seasons (not Complete)
  static List<SeasonModel> get activeSeasons =>
      seasons.where((s) => s.status != 'Complete').toList();

  /// Events for a specific season
  static List<CropEventModel> eventsForSeason(String seasonId) =>
      cropEvents.where((e) => e.seasonId == seasonId).toList();

  /// Emissions for a specific season
  static List<EmissionModel> emissionsForSeason(String seasonId) =>
      emissions.where((e) => e.seasonId == seasonId).toList();

  /// Farmer by id
  static FarmerModel? farmerById(String id) =>
      farmers.where((f) => f.id == id).firstOrNull;

  /// Plot by id
  static PlotModel? plotById(String id) =>
      plots.where((p) => p.id == id).firstOrNull;

  /// Season by id
  static SeasonModel? seasonById(String id) =>
      seasons.where((s) => s.id == id).firstOrNull;

  // ── Dashboard KPI aggregates ──────────────────────

  static int get totalFarmers => farmers.where((f) => !f.isDeleted).length;

  static int get totalPlots => plots.length;

  /// Total mapped area in hectares
  static double get totalAreaHa =>
      plots.fold(0.0, (sum, p) => sum + p.areaHa);

  /// Total mapped area in acres (for StatCard display)
  static double get totalAreaAcres => totalAreaHa * 2.47105;

  static int get totalActiveSeasons => activeSeasons.length;

  /// Net total CO₂e across all emission records (kg)
  static double get totalCo2eKg =>
      emissions.fold(0.0, (sum, e) => sum + e.totalCo2eKg);

  /// Net total CO₂e in tonnes
  static double get totalCo2eTonnes => totalCo2eKg / 1000;

  /// Average CO₂e per ha across all seasons that have area
  static double get avgCo2ePerHa {
    final withArea = emissions.where((e) => e.intensityPerHa != null).toList();
    if (withArea.isEmpty) return 0;
    return withArea.fold(0.0, (sum, e) => sum + e.intensityPerHa!) /
        withArea.length;
  }

  static bool get isLowEmissionsOverall =>
      totalAreaHa > 0 && (totalCo2eKg / totalAreaHa) < 500;
}