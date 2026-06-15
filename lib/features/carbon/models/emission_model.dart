// features/carbon/models/emission_model.dart

import 'package:hive/hive.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/emission_calc.dart';

part 'emission_model.g.dart';

@HiveType(typeId: 4)
class EmissionModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String seasonId;
  @HiveField(2) final String? eventId; // linked crop_event if triggered from event log
  @HiveField(3) final double n2oCo2eKg;
  @HiveField(4) final double dieselCo2eKg;
  @HiveField(5) final double electricityCo2eKg;
  @HiveField(6) final double areaHa;
  @HiveField(7) final double? intensityPerHa;
  @HiveField(8) final double? intensityPerTonne;
  @HiveField(9) final DateTime calculatedAt;

  EmissionModel({
    required this.id,
    required this.seasonId,
    this.eventId,
    required this.n2oCo2eKg,
    required this.dieselCo2eKg,
    required this.electricityCo2eKg,
    required this.areaHa,
    this.intensityPerHa,
    this.intensityPerTonne,
    required this.calculatedAt,
  });

  // ── Derived getters ───────────────────────────────────

  /// Total CO₂e = sum of all three sources (mirrors Supabase generated column)
  double get totalCo2eKg => n2oCo2eKg + dieselCo2eKg + electricityCo2eKg;

  String get totalLabel => Formatters.co2eKg(totalCo2eKg);

  String get totalTonnesLabel => Formatters.co2eTonnes(totalCo2eKg);

  String get n2oLabel => Formatters.co2eKg(n2oCo2eKg);

  String get dieselLabel => Formatters.co2eKg(dieselCo2eKg);

  String get electricityLabel => Formatters.co2eKg(electricityCo2eKg);

  String get intensityPerHaLabel =>
      intensityPerHa != null ? Formatters.co2ePerHa(intensityPerHa!) : '—';

  String get intensityPerTonneLabel => intensityPerTonne != null
      ? Formatters.co2ePerTonne(intensityPerTonne!)
      : '—';

  String get calculatedAtLabel => Formatters.dateLabel(calculatedAt);

  bool get isLowEmissions =>
      intensityPerHa != null && EmissionCalc.isLowEmissions(intensityPerHa!);

  bool get isLinkedToEvent => eventId != null;

  /// Percentage breakdown for charts (0.0–1.0 share of total)
  double get n2oShare => totalCo2eKg > 0 ? n2oCo2eKg / totalCo2eKg : 0;
  double get dieselShare => totalCo2eKg > 0 ? dieselCo2eKg / totalCo2eKg : 0;
  double get electricityShare =>
      totalCo2eKg > 0 ? electricityCo2eKg / totalCo2eKg : 0;

  // ── Factory: compute from raw inputs ──────────────────
  // Call this when creating a new record from the Add Emission form
  factory EmissionModel.compute({
    required String id,
    required String seasonId,
    String? eventId,
    required double nitrogenKg,
    double organicNKg = 0,
    required double dieselL,
    required double electricityKwh,
    required double areaHa,
    double? harvestYieldT,
    DateTime? calculatedAt,
  }) {
    final n2o = EmissionCalc.n2oCO2e(nitrogenKg) +
        EmissionCalc.n2oCO2eOrganic(organicNKg);
    final diesel = EmissionCalc.dieselCO2e(dieselL);
    final electricity = EmissionCalc.electricityCO2e(electricityKwh);
    final total = n2o + diesel + electricity;

    return EmissionModel(
      id: id,
      seasonId: seasonId,
      eventId: eventId,
      n2oCo2eKg: EmissionCalc.round2(n2o),
      dieselCo2eKg: EmissionCalc.round2(diesel),
      electricityCo2eKg: EmissionCalc.round2(electricity),
      areaHa: areaHa,
      intensityPerHa: areaHa > 0
          ? EmissionCalc.round2(EmissionCalc.intensityPerHa(total, areaHa))
          : null,
      intensityPerTonne: harvestYieldT != null && harvestYieldT > 0
          ? EmissionCalc.round2(
              EmissionCalc.intensityPerTonne(total, harvestYieldT))
          : null,
      calculatedAt: calculatedAt ?? DateTime.now(),
    );
  }

  // ── fromJson (Supabase — Layer 7) ─────────────────────
  factory EmissionModel.fromJson(Map<String, dynamic> j) {
    return EmissionModel(
      id: j['id'] as String,
      seasonId: j['season_id'] as String,
      eventId: j['event_id'] as String?,
      n2oCo2eKg: (j['n2o_co2e_kg'] as num).toDouble(),
      dieselCo2eKg: (j['diesel_co2e_kg'] as num).toDouble(),
      electricityCo2eKg: (j['electricity_co2e_kg'] as num).toDouble(),
      areaHa: (j['area_ha'] as num? ?? 0).toDouble(),
      intensityPerHa: (j['intensity_per_ha'] as num?)?.toDouble(),
      intensityPerTonne: (j['intensity_per_tonne'] as num?)?.toDouble(),
      calculatedAt: DateTime.parse(j['calculated_at'] as String),
    );
  }

  // ── toJson (Supabase insert — Layer 7) ────────────────
  // Note: total_co2e_kg is a Supabase GENERATED column — do NOT send it
  Map<String, dynamic> toJson() => {
        'season_id': seasonId,
        'event_id': eventId,
        'n2o_co2e_kg': n2oCo2eKg,
        'diesel_co2e_kg': dieselCo2eKg,
        'electricity_co2e_kg': electricityCo2eKg,
        'area_ha': areaHa,
        'intensity_per_ha': intensityPerHa,
        'intensity_per_tonne': intensityPerTonne,
      };

  // ── copyWith ───────────────────────────────────────────
  EmissionModel copyWith({
    String? id,
    String? seasonId,
    String? eventId,
    double? n2oCo2eKg,
    double? dieselCo2eKg,
    double? electricityCo2eKg,
    double? areaHa,
    double? intensityPerHa,
    double? intensityPerTonne,
    DateTime? calculatedAt,
  }) {
    return EmissionModel(
      id: id ?? this.id,
      seasonId: seasonId ?? this.seasonId,
      eventId: eventId ?? this.eventId,
      n2oCo2eKg: n2oCo2eKg ?? this.n2oCo2eKg,
      dieselCo2eKg: dieselCo2eKg ?? this.dieselCo2eKg,
      electricityCo2eKg: electricityCo2eKg ?? this.electricityCo2eKg,
      areaHa: areaHa ?? this.areaHa,
      intensityPerHa: intensityPerHa ?? this.intensityPerHa,
      intensityPerTonne: intensityPerTonne ?? this.intensityPerTonne,
      calculatedAt: calculatedAt ?? this.calculatedAt,
    );
  }

  // ── Seed data (written to Hive on first install) ──────
  static List<EmissionModel> seedList() => [
        // S001 — two fertiliser events logged
        EmissionModel.compute(
          id: 'EM001',
          seasonId: 'S001',
          eventId: 'E002',
          nitrogenKg: 50,
          dieselL: 4,
          electricityKwh: 0,
          areaHa: 1.2,
          calculatedAt: DateTime(2025, 3, 1),
        ),
        EmissionModel.compute(
          id: 'EM002',
          seasonId: 'S001',
          eventId: 'E003',
          nitrogenKg: 0,
          dieselL: 0,
          electricityKwh: 6,
          areaHa: 1.2,
          calculatedAt: DateTime(2025, 2, 10),
        ),

        // S003 — multiple fertiliser events
        EmissionModel.compute(
          id: 'EM003',
          seasonId: 'S003',
          eventId: 'E006',
          nitrogenKg: 50,
          dieselL: 3,
          electricityKwh: 0,
          areaHa: 1.8,
          calculatedAt: DateTime(2024, 12, 25),
        ),
        EmissionModel.compute(
          id: 'EM004',
          seasonId: 'S003',
          eventId: 'E007',
          nitrogenKg: 50,
          dieselL: 0,
          electricityKwh: 0,
          areaHa: 1.8,
          calculatedAt: DateTime(2025, 2, 8),
        ),

        // S004 — harvest season with yield
        EmissionModel.compute(
          id: 'EM005',
          seasonId: 'S004',
          eventId: 'E009',
          nitrogenKg: 100, // total N across the season
          dieselL: 12,
          electricityKwh: 0,
          areaHa: 2.0,
          harvestYieldT: 5.6,
          calculatedAt: DateTime(2025, 3, 28),
        ),
      ];

  @override
  String toString() => 'EmissionModel($id, $totalLabel, season: $seasonId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is EmissionModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}