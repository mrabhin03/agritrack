// features/farmers/providers/farmers_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/farmer_model.dart';
import '../../../core/fake/fake_data.dart';

// ── Search query ──────────────────────────────────────
final farmersSearchProvider = StateProvider<String>((ref) => '');

// ── Stage filter ──────────────────────────────────────
final farmersStageFilterProvider = StateProvider<String>((ref) => 'All');

// ── Master farmers list ───────────────────────────────
// Layer 6: returns FakeData.farmers
// Layer 7 swap: replace body with repository.fetchAll()
final farmersProvider =
    AsyncNotifierProvider<FarmersNotifier, List<FarmerModel>>(
  FarmersNotifier.new,
);

class FarmersNotifier extends AsyncNotifier<List<FarmerModel>> {
  @override
  Future<List<FarmerModel>> build() async {
    // Layer 7: return ref.read(farmersRepositoryProvider).fetchAll();
    return FakeData.farmers;
  }

  Future<void> addFarmer(Map<String, dynamic> data) async {
    // Layer 7: await ref.read(farmersRepositoryProvider).insert(data);
    final newFarmer = FarmerModel(
      id: 'F${DateTime.now().millisecondsSinceEpoch}',
      name: data['name'] as String,
      phone: data['phone'] as String,
      age: data['age'] as int,
      village: data['village'] as String,
      areaHa: data['area_ha'] as double,
      notes: data['notes'] as String?,
      gpsLat: data['gps_lat'] as double?,
      gpsLng: data['gps_lng'] as double?,
      stage: 'Nursery',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final current = state.valueOrNull ?? [];
    state = AsyncData([newFarmer, ...current]);
  }

  Future<void> updateFarmer(String id, Map<String, dynamic> data) async {
    // Layer 7: await ref.read(farmersRepositoryProvider).update(id, data);
    final current = state.valueOrNull ?? [];
    state = AsyncData([
      for (final f in current)
        if (f.id == id) f.copyWith(
          name: data['name'] as String? ?? f.name,
          phone: data['phone'] as String? ?? f.phone,
          age: data['age'] as int? ?? f.age,
          village: data['village'] as String? ?? f.village,
          areaHa: data['area_ha'] as double? ?? f.areaHa,
          notes: data['notes'] as String? ?? f.notes,
          updatedAt: DateTime.now(),
        )
        else f,
    ]);
  }

  Future<void> deleteFarmer(String id) async {
    // Layer 7: await ref.read(farmersRepositoryProvider).softDelete(id);
    final current = state.valueOrNull ?? [];
    state = AsyncData([
      for (final f in current)
        if (f.id == id) f.copyWith(isDeleted: true) else f,
    ]);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async => FakeData.farmers);
  }
}

// ── Filtered list (search + stage) ───────────────────
// Pure derived provider — no extra network call
final filteredFarmersProvider = Provider<List<FarmerModel>>((ref) {
  final farmers = ref.watch(farmersProvider).valueOrNull ?? [];
  final query = ref.watch(farmersSearchProvider).toLowerCase().trim();
  final stage = ref.watch(farmersStageFilterProvider);

  return farmers.where((f) {
    if (f.isDeleted) return false;

    final matchQuery = query.isEmpty ||
        f.name.toLowerCase().contains(query) ||
        f.phone.contains(query) ||
        f.village.toLowerCase().contains(query);

    final matchStage = stage == 'All' || f.stage == stage;

    return matchQuery && matchStage;
  }).toList();
});

// ── Single farmer by id ───────────────────────────────
final farmerByIdProvider =
    Provider.family<FarmerModel?, String>((ref, id) {
  final farmers = ref.watch(farmersProvider).valueOrNull ?? [];
  return farmers.where((f) => f.id == id).firstOrNull;
});

// ── Plots count per farmer (used in detail screen) ────
final farmerPlotCountProvider =
    Provider.family<int, String>((ref, farmerId) {
  return FakeData.plotsForFarmer(farmerId).length;
});

// ── Active season for farmer (used in farmer card) ────
final farmerActiveSeasonProvider =
    Provider.family<String?, String>((ref, farmerId) {
  final seasons = FakeData.seasonsForFarmer(farmerId);
  final active = seasons.where((s) => s.status != 'Complete').firstOrNull;
  return active?.stage;
});