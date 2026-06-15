// features/crops/models/crop_event_model.dart

import 'package:hive/hive.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/emission_calc.dart';
import '../../../core/constants/crop_constants.dart';

part 'crop_event_model.g.dart';

@HiveType(typeId: 3)
class CropEventModel extends HiveObject {
  @HiveField(0)  final String id;
  @HiveField(1)  final String seasonId;
  // 'Fertiliser' | 'Irrigation' | 'Harvest' | 'Monitoring'
  @HiveField(2)  final String eventType;
  @HiveField(3)  final DateTime eventDate;
  // Fertiliser fields (kg/ha)
  @HiveField(4)  final double nitrogenKg;
  @HiveField(5)  final double phosphorusKg;
  @HiveField(6)  final double potassiumKg;
  @HiveField(7)  final double organicNKg;
  // Energy / water
  @HiveField(8)  final double dieselL;
  @HiveField(9)  final double electricityKwh;
  @HiveField(10) final double irrigationL;
  // Harvest only
  @HiveField(11) final double? harvestYieldT;
  @HiveField(12) final String? notes;
  @HiveField(13) final DateTime createdAt;

  CropEventModel({
    required this.id,
    required this.seasonId,
    required this.eventType,
    required this.eventDate,
    this.nitrogenKg     = 0,
    this.phosphorusKg   = 0,
    this.potassiumKg    = 0,
    this.organicNKg     = 0,
    this.dieselL        = 0,
    this.electricityKwh = 0,
    this.irrigationL    = 0,
    this.harvestYieldT,
    this.notes,
    required this.createdAt,
  });

  // ── Derived getters ───────────────────────────────────
  bool get isFertiliser  => eventType == 'Fertiliser';
  bool get isIrrigation  => eventType == 'Irrigation';
  bool get isHarvest     => eventType == 'Harvest';
  bool get isMonitoring  => eventType == 'Monitoring';

  String get eventDateLabel  => Formatters.date(eventDate);
  String get npkLabel        => Formatters.npk(nitrogenKg, phosphorusKg, potassiumKg);
  String get dieselLabel     => Formatters.litres(dieselL);
  String get irrigationLabel => '${irrigationL.toStringAsFixed(0)} L';

  String get yieldLabel =>
      harvestYieldT != null ? Formatters.tonnes(harvestYieldT!) : '—';

  /// CO₂e emitted by this single event (kg)
  double get co2eKg => EmissionCalc.totalCO2e(
        nitrogenKg:     nitrogenKg,
        organicNKg:     organicNKg,
        dieselL:        dieselL,
        electricityKwh: electricityKwh,
      );

  String get co2eLabel  => Formatters.co2eKg(co2eKg);
  bool   get hasEmissions => co2eKg > 0;

  // ── fromJson (Supabase — Layer 7) ────────────────────
  factory CropEventModel.fromJson(Map<String, dynamic> j) {
    return CropEventModel(
      id:             j['id']               as String,
      seasonId:       j['season_id']        as String,
      eventType:      j['event_type']       as String,
      eventDate:      DateTime.parse(j['event_date'] as String),
      nitrogenKg:     (j['nitrogen_kg']     as num? ?? 0).toDouble(),
      phosphorusKg:   (j['phosphorus_kg']   as num? ?? 0).toDouble(),
      potassiumKg:    (j['potassium_kg']    as num? ?? 0).toDouble(),
      organicNKg:     (j['organic_n_kg']    as num? ?? 0).toDouble(),
      dieselL:        (j['diesel_l']        as num? ?? 0).toDouble(),
      electricityKwh: (j['electricity_kwh'] as num? ?? 0).toDouble(),
      irrigationL:    (j['irrigation_l']    as num? ?? 0).toDouble(),
      harvestYieldT:  (j['harvest_yield_t'] as num?)?.toDouble(),
      notes:          j['notes']            as String?,
      createdAt:      DateTime.parse(j['created_at'] as String),
    );
  }

  // ── toJson (Supabase insert/update — Layer 7) ─────────
  Map<String, dynamic> toJson() => {
    'season_id':       seasonId,
    'event_type':      eventType,
    'event_date':      eventDate.toIso8601String().split('T').first,
    'nitrogen_kg':     nitrogenKg,
    'phosphorus_kg':   phosphorusKg,
    'potassium_kg':    potassiumKg,
    'organic_n_kg':    organicNKg,
    'diesel_l':        dieselL,
    'electricity_kwh': electricityKwh,
    'irrigation_l':    irrigationL,
    'harvest_yield_t': harvestYieldT,
    'notes':           notes,
  };

  // ── copyWith ──────────────────────────────────────────
  CropEventModel copyWith({
    String?   id,
    String?   seasonId,
    String?   eventType,
    DateTime? eventDate,
    double?   nitrogenKg,
    double?   phosphorusKg,
    double?   potassiumKg,
    double?   organicNKg,
    double?   dieselL,
    double?   electricityKwh,
    double?   irrigationL,
    double?   harvestYieldT,
    String?   notes,
    DateTime? createdAt,
  }) {
    return CropEventModel(
      id:             id             ?? this.id,
      seasonId:       seasonId       ?? this.seasonId,
      eventType:      eventType      ?? this.eventType,
      eventDate:      eventDate      ?? this.eventDate,
      nitrogenKg:     nitrogenKg     ?? this.nitrogenKg,
      phosphorusKg:   phosphorusKg   ?? this.phosphorusKg,
      potassiumKg:    potassiumKg    ?? this.potassiumKg,
      organicNKg:     organicNKg     ?? this.organicNKg,
      dieselL:        dieselL        ?? this.dieselL,
      electricityKwh: electricityKwh ?? this.electricityKwh,
      irrigationL:    irrigationL    ?? this.irrigationL,
      harvestYieldT:  harvestYieldT  ?? this.harvestYieldT,
      notes:          notes          ?? this.notes,
      createdAt:      createdAt      ?? this.createdAt,
    );
  }

  // ── Seed data (written to Hive on first install) ──────
  static List<CropEventModel> seedList() => [
    // Season S001 — Growth stage events
    CropEventModel(
      id: 'E001', seasonId: 'S001', eventType: 'Fertiliser',
      eventDate: DateTime(2025, 1, 15),
      phosphorusKg: 50, potassiumKg: 50,
      notes: 'Basal dose at planting.',
      createdAt: DateTime(2025, 1, 15),
    ),
    CropEventModel(
      id: 'E002', seasonId: 'S001', eventType: 'Fertiliser',
      eventDate: DateTime(2025, 3, 1),
      nitrogenKg: 50, dieselL: 4,
      notes: '1st top dress — 45 DAP.',
      createdAt: DateTime(2025, 3, 1),
    ),
    CropEventModel(
      id: 'E003', seasonId: 'S001', eventType: 'Irrigation',
      eventDate: DateTime(2025, 2, 10),
      irrigationL: 8000, electricityKwh: 6,
      notes: 'Drip irrigation cycle.',
      createdAt: DateTime(2025, 2, 10),
    ),
    CropEventModel(
      id: 'E004', seasonId: 'S001', eventType: 'Monitoring',
      eventDate: DateTime(2025, 3, 20),
      notes: 'Canopy cover 85%. No pest signs.',
      createdAt: DateTime(2025, 3, 20),
    ),
    // Season S003 — Flowering stage
    CropEventModel(
      id: 'E005', seasonId: 'S003', eventType: 'Fertiliser',
      eventDate: DateTime(2024, 11, 10),
      phosphorusKg: 50, potassiumKg: 50,
      createdAt: DateTime(2024, 11, 10),
    ),
    CropEventModel(
      id: 'E006', seasonId: 'S003', eventType: 'Fertiliser',
      eventDate: DateTime(2024, 12, 25),
      nitrogenKg: 50, dieselL: 3,
      notes: '1st top dress.',
      createdAt: DateTime(2024, 12, 25),
    ),
    CropEventModel(
      id: 'E007', seasonId: 'S003', eventType: 'Fertiliser',
      eventDate: DateTime(2025, 2, 8),
      nitrogenKg: 50, potassiumKg: 25,
      notes: '2nd top dress — 90 DAP.',
      createdAt: DateTime(2025, 2, 8),
    ),
    // Season S004 — Complete / Harvest
    CropEventModel(
      id: 'E008', seasonId: 'S004', eventType: 'Fertiliser',
      eventDate: DateTime(2024, 9, 5),
      phosphorusKg: 50, potassiumKg: 50,
      createdAt: DateTime(2024, 9, 5),
    ),
    CropEventModel(
      id: 'E009', seasonId: 'S004', eventType: 'Harvest',
      eventDate: DateTime(2025, 3, 28),
      harvestYieldT: 5.6, dieselL: 12,
      notes: 'Harvest complete. Good rhizome quality.',
      createdAt: DateTime(2025, 3, 28),
    ),
  ];

  @override
  String toString() => 'CropEventModel($id, $eventType, season: $seasonId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CropEventModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}