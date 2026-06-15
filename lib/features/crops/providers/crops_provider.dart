// features/crops/providers/crops_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/season_model.dart';
import '../models/crop_event_model.dart';
import '../../../core/fake/fake_data.dart';

// ── Season filter (by farmer) ─────────────────────────
final seasonsFilterFarmerProvider = StateProvider<String?>((ref) => null);

// ── Master seasons list ───────────────────────────────
// Layer 7 swap: replace body with repository.fetchAll()
final seasonsProvider =
    AsyncNotifierProvider<SeasonsNotifier, List<SeasonModel>>(
  SeasonsNotifier.new,
);

class SeasonsNotifier extends AsyncNotifier<List<SeasonModel>> {
  @override
  Future<List<SeasonModel>> build() async {
    // Layer 7: return ref.read(cropsRepositoryProvider).fetchAllSeasons();
    return FakeData.seasons;
  }

  Future<void> addSeason(Map<String, dynamic> data) async {
    // Layer 7: await ref.read(cropsRepositoryProvider).insertSeason(data);
    final plantingDate = data['planting_date'] as DateTime;
    final harvestDate = plantingDate.add(const Duration(days: 210));
    final newSeason = SeasonModel(
      id: 'S${DateTime.now().millisecondsSinceEpoch}',
      farmerId: data['farmer_id'] as String,
      plotId: data['plot_id'] as String?,
      variety: data['variety'] as String,
      plantingDate: plantingDate,
      harvestDate: data['harvest_date'] as DateTime? ?? harvestDate,
      targetYieldTHa: data['target_yield_t_ha'] as double,
      status: 'On track',
      stage: 'Nursery',
      createdAt: DateTime.now(),
    );
    final current = state.valueOrNull ?? [];
    state = AsyncData([newSeason, ...current]);
  }

  Future<void> updateSeasonStage(String id, String newStage) async {
    // Layer 7: await ref.read(cropsRepositoryProvider).updateStage(id, newStage);
    final current = state.valueOrNull ?? [];
    state = AsyncData([
      for (final s in current)
        if (s.id == id) s.copyWith(stage: newStage) else s,
    ]);
  }

  Future<void> updateSeasonStatus(String id, String newStatus) async {
    // Layer 7: await ref.read(cropsRepositoryProvider).updateStatus(id, newStatus);
    final current = state.valueOrNull ?? [];
    state = AsyncData([
      for (final s in current)
        if (s.id == id) s.copyWith(status: newStatus) else s,
    ]);
  }

  Future<void> deleteSeason(String id) async {
    // Layer 7: await ref.read(cropsRepositoryProvider).deleteSeason(id);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((s) => s.id != id).toList());
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async => FakeData.seasons);
  }
}

// ── Filtered seasons (by optional farmer) ────────────
final filteredSeasonsProvider = Provider<List<SeasonModel>>((ref) {
  final seasons = ref.watch(seasonsProvider).valueOrNull ?? [];
  final farmerId = ref.watch(seasonsFilterFarmerProvider);
  if (farmerId == null) return seasons;
  return seasons.where((s) => s.farmerId == farmerId).toList();
});

// ── Seasons for a specific farmer ─────────────────────
final seasonsByFarmerProvider =
    Provider.family<List<SeasonModel>, String>((ref, farmerId) {
  final seasons = ref.watch(seasonsProvider).valueOrNull ?? [];
  return seasons.where((s) => s.farmerId == farmerId).toList();
});

// ── Single season by id ───────────────────────────────
final seasonByIdProvider =
    Provider.family<SeasonModel?, String>((ref, id) {
  final seasons = ref.watch(seasonsProvider).valueOrNull ?? [];
  return seasons.where((s) => s.id == id).firstOrNull;
});

// ── Active seasons count ──────────────────────────────
final activeSeasonsCountProvider = Provider<int>((ref) {
  final seasons = ref.watch(seasonsProvider).valueOrNull ?? [];
  return seasons.where((s) => s.status != 'Complete').length;
});

// ── Master crop events list ───────────────────────────
final cropEventsProvider =
    AsyncNotifierProvider<CropEventsNotifier, List<CropEventModel>>(
  CropEventsNotifier.new,
);

class CropEventsNotifier extends AsyncNotifier<List<CropEventModel>> {
  @override
  Future<List<CropEventModel>> build() async {
    // Layer 7: return ref.read(cropsRepositoryProvider).fetchAllEvents();
    return FakeData.cropEvents;
  }

  Future<void> addEvent(Map<String, dynamic> data) async {
    // Layer 7: await ref.read(cropsRepositoryProvider).insertEvent(data);
    final newEvent = CropEventModel(
      id: 'E${DateTime.now().millisecondsSinceEpoch}',
      seasonId: data['season_id'] as String,
      eventType: data['event_type'] as String,
      eventDate: data['event_date'] as DateTime,
      nitrogenKg: (data['nitrogen_kg'] as num? ?? 0).toDouble(),
      phosphorusKg: (data['phosphorus_kg'] as num? ?? 0).toDouble(),
      potassiumKg: (data['potassium_kg'] as num? ?? 0).toDouble(),
      organicNKg: (data['organic_n_kg'] as num? ?? 0).toDouble(),
      dieselL: (data['diesel_l'] as num? ?? 0).toDouble(),
      electricityKwh: (data['electricity_kwh'] as num? ?? 0).toDouble(),
      irrigationL: (data['irrigation_l'] as num? ?? 0).toDouble(),
      harvestYieldT: (data['harvest_yield_t'] as num?)?.toDouble(),
      notes: data['notes'] as String?,
      createdAt: DateTime.now(),
    );
    final current = state.valueOrNull ?? [];
    state = AsyncData([...current, newEvent]);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async => FakeData.cropEvents);
  }
}

// ── Events for a specific season ─────────────────────
final eventsBySeasonProvider =
    Provider.family<List<CropEventModel>, String>((ref, seasonId) {
  final events = ref.watch(cropEventsProvider).valueOrNull ?? [];
  return events
      .where((e) => e.seasonId == seasonId)
      .toList()
    ..sort((a, b) => b.eventDate.compareTo(a.eventDate)); // newest first
});