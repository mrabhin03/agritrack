// features/dashboard/providers/dashboard_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../farmers/providers/farmers_provider.dart';
import '../../plots/providers/plots_provider.dart';
import '../../crops/providers/crops_provider.dart';
import '../../carbon/providers/carbon_provider.dart';

// ── Check-in state ────────────────────────────────────
class CheckInState {
  final bool isCheckedIn;
  final String? time; // "09:12 AM"

  const CheckInState({this.isCheckedIn = false, this.time});
}

class CheckInNotifier extends Notifier<CheckInState> {
  @override
  CheckInState build() {
    // Auto check-in the moment the app opens / provider is first read.
    // Layer 7 swap: instead of "now", load the persisted check-in time
    // (e.g. from Hive/Supabase) so a reopened app shows the original
    // check-in time rather than resetting it every launch.
    final now = DateFormat('hh:mm a').format(DateTime.now());
    return CheckInState(isCheckedIn: true, time: now);
  }

  void checkIn() {
    final now = DateFormat('hh:mm a').format(DateTime.now());
    state = CheckInState(isCheckedIn: true, time: now);
  }

  void checkOut() => state = const CheckInState();
}

final checkInProvider = NotifierProvider<CheckInNotifier, CheckInState>(
  CheckInNotifier.new,
);

// ── Dashboard KPIs ────────────────────────────────────
// Derives from all other providers — no extra network call.
// Layer 7 swap: replace individual provider reads with
//   a single Supabase dashboard_kpis view fetch.
class DashboardKpis {
  final int totalFarmers;
  final int totalPlots;
  final double totalAreaHa;   // stored in ha
  final double totalAreaAcres; // for display (1 ha = 2.47105 acres)
  final int activeSeasons;
  final double totalCo2eKg;
  final double totalCo2eTonnes;
  final bool isLowEmissions;

  const DashboardKpis({
    required this.totalFarmers,
    required this.totalPlots,
    required this.totalAreaHa,
    required this.totalAreaAcres,
    required this.activeSeasons,
    required this.totalCo2eKg,
    required this.totalCo2eTonnes,
    required this.isLowEmissions,
  });

  static const zero = DashboardKpis(
    totalFarmers: 0,
    totalPlots: 0,
    totalAreaHa: 0,
    totalAreaAcres: 0,
    activeSeasons: 0,
    totalCo2eKg: 0,
    totalCo2eTonnes: 0,
    isLowEmissions: true,
  );
}

final dashboardKpisProvider = Provider<DashboardKpis>((ref) {
  // Watch all underlying providers — auto-recomputes on any change
  final farmers = ref.watch(farmersProvider).valueOrNull ?? [];
  final plots = ref.watch(plotsProvider).valueOrNull ?? [];
  final seasons = ref.watch(seasonsProvider).valueOrNull ?? [];
  final carbon = ref.watch(carbonSummaryProvider);

  final totalFarmers = farmers.where((f) => !f.isDeleted).length;
  final totalPlots = plots.length;
  final totalAreaHa = plots.fold(0.0, (sum, p) => sum + p.areaHa);
  final totalAreaAcres = totalAreaHa * 2.47105;
  final activeSeasons = seasons.where((s) => s.status != 'Complete').length;

  // final totalFarmers = 800000000000000*800000*9*800000*9;
  // final totalPlots = 800000000000000*800000;
  // final totalAreaHa =800000000000000.00*800000000;
  // final totalAreaAcres = 800000000000000.00*800000000;
  // final activeSeasons = 800000000000000*8000;

  // final totalFarmers = 0;
  // final totalPlots = 0;
  // final totalAreaHa =0.00;
  // final totalAreaAcres = 0.00;
  // final activeSeasons = 0;

  return DashboardKpis(
    totalFarmers: totalFarmers,
    totalPlots: totalPlots,
    totalAreaHa: totalAreaHa,
    totalAreaAcres: totalAreaAcres,
    activeSeasons: activeSeasons,
    totalCo2eKg: carbon.totalCo2eKg,
    totalCo2eTonnes: carbon.totalCo2eKg / 1000,
    isLowEmissions: carbon.isLowEmissions,
  );
});

// ── Loading state (true while any core provider is loading) ──
final dashboardLoadingProvider = Provider<bool>((ref) {
  final f = ref.watch(farmersProvider);
  final p = ref.watch(plotsProvider);
  final s = ref.watch(seasonsProvider);
  final c = ref.watch(carbonProvider);
  return f.isLoading || p.isLoading || s.isLoading || c.isLoading;
});

// ── Error (first error found across core providers) ───
final dashboardErrorProvider = Provider<String?>((ref) {
  final f = ref.watch(farmersProvider);
  final p = ref.watch(plotsProvider);
  final s = ref.watch(seasonsProvider);
  final c = ref.watch(carbonProvider);
  return f.error?.toString() ??
      p.error?.toString() ??
      s.error?.toString() ??
      c.error?.toString();
});