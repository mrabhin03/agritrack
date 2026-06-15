// features/plots/providers/plots_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/plot_model.dart';
import '../../../services/hive_service.dart';

// ── Master plots list ─────────────────────────────────
// Layer 6b: reads from Hive box
// Layer 7 swap: replace body with repository.fetchAll()
final plotsProvider =
    AsyncNotifierProvider<PlotsNotifier, List<PlotModel>>(
  PlotsNotifier.new,
);

class PlotsNotifier extends AsyncNotifier<List<PlotModel>> {
  @override
  Future<List<PlotModel>> build() async {
    // Layer 7: return ref.read(plotsRepositoryProvider).fetchAll();
    final box = HiveService.plotsBox;
    return box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> addPlot(Map<String, dynamic> data) async {
    // Layer 7: await ref.read(plotsRepositoryProvider).insert(data);
    final newPlot = PlotModel(
      id: 'PL${DateTime.now().millisecondsSinceEpoch}',
      farmerId: data['farmer_id'] as String,
      name: data['name'] as String,
      boundary: (data['boundary'] as List).cast<List<double>>(),
      areaHa: data['area_ha'] as double,
      soilType: data['soil_type'] as String,
      irrigation: data['irrigation'] as String,
      crop: data['crop'] as String? ?? 'Turmeric',
      createdAt: DateTime.now(),
    );
    await HiveService.plotsBox.put(newPlot.id, newPlot);
    ref.invalidateSelf();
  }

  Future<void> updatePlot(String id, Map<String, dynamic> data) async {
    // Layer 7: await ref.read(plotsRepositoryProvider).update(id, data);
    final box = HiveService.plotsBox;
    final existing = box.get(id);
    if (existing == null) return;
    final updated = existing.copyWith(
      name: data['name'] as String? ?? existing.name,
      soilType: data['soil_type'] as String? ?? existing.soilType,
      irrigation: data['irrigation'] as String? ?? existing.irrigation,
    );
    await box.put(id, updated);
    ref.invalidateSelf();
  }

  Future<void> deletePlot(String id) async {
    // Layer 7: await ref.read(plotsRepositoryProvider).delete(id);
    await HiveService.plotsBox.delete(id);
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final box = HiveService.plotsBox;
      return box.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }
}

// ── Plots filtered by farmer ──────────────────────────
final plotsByFarmerProvider =
    Provider.family<List<PlotModel>, String>((ref, farmerId) {
  final plots = ref.watch(plotsProvider).valueOrNull ?? [];
  return plots.where((p) => p.farmerId == farmerId).toList();
});

// ── Single plot by id ─────────────────────────────────
final plotByIdProvider =
    Provider.family<PlotModel?, String>((ref, id) {
  final plots = ref.watch(plotsProvider).valueOrNull ?? [];
  return plots.where((p) => p.id == id).firstOrNull;
});

// ── Total area across all plots (ha) ─────────────────
final totalPlotAreaProvider = Provider<double>((ref) {
  final plots = ref.watch(plotsProvider).valueOrNull ?? [];
  return plots.fold(0.0, (sum, p) => sum + p.areaHa);
});