// features/carbon/providers/carbon_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/emission_model.dart';
import '../../../core/fake/fake_data.dart';
import '../../../core/utils/emission_calc.dart';

// ── Season filter (for carbon screen) ────────────────
final carbonSeasonFilterProvider = StateProvider<String?>((ref) => null);

// ── Master emission records list ──────────────────────
// Layer 7 swap: replace body with repository.fetchAll()
final carbonProvider =
    AsyncNotifierProvider<CarbonNotifier, List<EmissionModel>>(
  CarbonNotifier.new,
);

class CarbonNotifier extends AsyncNotifier<List<EmissionModel>> {
  @override
  Future<List<EmissionModel>> build() async {
    // Layer 7: return ref.read(carbonRepositoryProvider).fetchAll();
    return FakeData.emissions;
  }

  Future<void> addEmission(Map<String, dynamic> data) async {
    // Layer 7: await ref.read(carbonRepositoryProvider).insert(data);
    final record = EmissionModel.compute(
      id: 'EM${DateTime.now().millisecondsSinceEpoch}',
      seasonId: data['season_id'] as String,
      eventId: data['event_id'] as String?,
      nitrogenKg: (data['nitrogen_kg'] as num? ?? 0).toDouble(),
      organicNKg: (data['organic_n_kg'] as num? ?? 0).toDouble(),
      dieselL: (data['diesel_l'] as num? ?? 0).toDouble(),
      electricityKwh: (data['electricity_kwh'] as num? ?? 0).toDouble(),
      areaHa: (data['area_ha'] as num? ?? 0).toDouble(),
      harvestYieldT: (data['harvest_yield_t'] as num?)?.toDouble(),
    );
    final current = state.valueOrNull ?? [];
    state = AsyncData([record, ...current]);
  }

  Future<void> deleteEmission(String id) async {
    // Layer 7: await ref.read(carbonRepositoryProvider).delete(id);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((e) => e.id != id).toList());
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async => FakeData.emissions);
  }
}

// ── Emissions for a specific season ──────────────────
final emissionsBySeasonProvider =
    Provider.family<List<EmissionModel>, String>((ref, seasonId) {
  final emissions = ref.watch(carbonProvider).valueOrNull ?? [];
  return emissions.where((e) => e.seasonId == seasonId).toList();
});

// ── Filtered emissions (by optional season) ───────────
final filteredEmissionsProvider = Provider<List<EmissionModel>>((ref) {
  final emissions = ref.watch(carbonProvider).valueOrNull ?? [];
  final seasonId = ref.watch(carbonSeasonFilterProvider);
  if (seasonId == null) return emissions;
  return emissions.where((e) => e.seasonId == seasonId).toList();
});

// ── Summary KPIs for carbon screen ───────────────────
class CarbonSummary {
  final double totalCo2eKg;
  final double n2oCo2eKg;
  final double dieselCo2eKg;
  final double electricityCo2eKg;
  final double avgIntensityPerHa;
  final bool isLowEmissions;
  final int recordCount;

  const CarbonSummary({
    required this.totalCo2eKg,
    required this.n2oCo2eKg,
    required this.dieselCo2eKg,
    required this.electricityCo2eKg,
    required this.avgIntensityPerHa,
    required this.isLowEmissions,
    required this.recordCount,
  });

  static const zero = CarbonSummary(
    totalCo2eKg: 0,
    n2oCo2eKg: 0,
    dieselCo2eKg: 0,
    electricityCo2eKg: 0,
    avgIntensityPerHa: 0,
    isLowEmissions: true,
    recordCount: 0,
  );
}

final carbonSummaryProvider = Provider<CarbonSummary>((ref) {
  final emissions = ref.watch(filteredEmissionsProvider);
  if (emissions.isEmpty) return CarbonSummary.zero;

  final total = emissions.fold(0.0, (s, e) => s + e.totalCo2eKg);
  final n2o = emissions.fold(0.0, (s, e) => s + e.n2oCo2eKg);
  final diesel = emissions.fold(0.0, (s, e) => s + e.dieselCo2eKg);
  final electricity = emissions.fold(0.0, (s, e) => s + e.electricityCo2eKg);

  final withArea = emissions.where((e) => e.intensityPerHa != null).toList();
  final avgPerHa = withArea.isEmpty
      ? 0.0
      : withArea.fold(0.0, (s, e) => s + e.intensityPerHa!) / withArea.length;

  return CarbonSummary(
    totalCo2eKg: EmissionCalc.round2(total),
    n2oCo2eKg: EmissionCalc.round2(n2o),
    dieselCo2eKg: EmissionCalc.round2(diesel),
    electricityCo2eKg: EmissionCalc.round2(electricity),
    avgIntensityPerHa: EmissionCalc.round2(avgPerHa),
    isLowEmissions: EmissionCalc.isLowEmissions(avgPerHa),
    recordCount: emissions.length,
  );
});

// ── Breakdown map for fl_chart ────────────────────────
final carbonBreakdownProvider = Provider<Map<String, double>>((ref) {
  final summary = ref.watch(carbonSummaryProvider);
  return {
    'N₂O (Fertiliser)': summary.n2oCo2eKg,
    'CO₂ (Diesel)': summary.dieselCo2eKg,
    'CO₂ (Grid)': summary.electricityCo2eKg,
  };
});