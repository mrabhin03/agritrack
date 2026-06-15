// features/farmers/providers/farmers_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/farmer_model.dart';
import '../../../services/hive_service.dart';

// ── Search query ──────────────────────────────────────
final farmersSearchProvider = StateProvider<String>((ref) => '');

// ── Stage filter ──────────────────────────────────────
final farmersStageFilterProvider = StateProvider<String>((ref) => 'All');

// ── Master farmers list ───────────────────────────────
// Layer 6b: reads from Hive box (persists across app restarts)
// Layer 7 swap: replace body with repository.fetchAll()
final farmersProvider =
    AsyncNotifierProvider<FarmersNotifier, List<FarmerModel>>(
  FarmersNotifier.new,
);

class FarmersNotifier extends AsyncNotifier<List<FarmerModel>> {
  @override
  Future<List<FarmerModel>> build() async {
    // Layer 7: return ref.read(farmersRepositoryProvider).fetchAll();
    final box = HiveService.farmersBox;
    return box.values.where((f) => !f.isDeleted).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
    await HiveService.farmersBox.put(newFarmer.id, newFarmer);
    ref.invalidateSelf();
  }

  Future<void> updateFarmer(String id, Map<String, dynamic> data) async {
    // Layer 7: await ref.read(farmersRepositoryProvider).update(id, data);
    final box = HiveService.farmersBox;
    final existing = box.get(id);
    if (existing == null) return;
    final updated = existing.copyWith(
      name: data['name'] as String? ?? existing.name,
      phone: data['phone'] as String? ?? existing.phone,
      age: data['age'] as int? ?? existing.age,
      village: data['village'] as String? ?? existing.village,
      areaHa: data['area_ha'] as double? ?? existing.areaHa,
      notes: data['notes'] as String? ?? existing.notes,
      updatedAt: DateTime.now(),
    );
    await box.put(id, updated);
    ref.invalidateSelf();
  }

  Future<void> deleteFarmer(String id) async {
    // Layer 7: await ref.read(farmersRepositoryProvider).softDelete(id);
    final box = HiveService.farmersBox;
    final existing = box.get(id);
    if (existing == null) return;
    await box.put(id, existing.copyWith(isDeleted: true));
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final box = HiveService.farmersBox;
      return box.values.where((f) => !f.isDeleted).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }
}

// ── Filtered list (search + stage) ───────────────────
// Pure derived provider — no extra DB call
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

// ── Plots count per farmer (wired to live plots provider) ──
// Layer 7: replace with plotsRepositoryProvider.countForFarmer(farmerId)
final farmerPlotCountProvider =
    Provider.family<int, String>((ref, farmerId) {
  final plots = ref.watch(plotsProviderForCount(farmerId));
  return plots;
});

// Helper: reads live plots box directly to avoid circular import
final plotsProviderForCount =
    Provider.family<int, String>((ref, farmerId) {
  return HiveService.plotsBox.values
      .where((p) => p.farmerId == farmerId)
      .length;
});

// ── Active season stage for farmer (wired to live seasons) ──
final farmerActiveSeasonProvider =
    Provider.family<String?, String>((ref, farmerId) {
  final active = HiveService.seasonsBox.values
      .where((s) => s.farmerId == farmerId && s.status != 'Complete')
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return active.firstOrNull?.stage;
});