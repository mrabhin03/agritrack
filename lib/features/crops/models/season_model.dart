// features/crops/models/season_model.dart

import 'package:hive/hive.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/constants/crop_constants.dart';

part 'season_model.g.dart';

@HiveType(typeId: 2)
class SeasonModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String farmerId;
  @HiveField(2) final String? plotId;
  @HiveField(3) final String variety;
  @HiveField(4) final DateTime plantingDate;
  @HiveField(5) final DateTime harvestDate;
  @HiveField(6) final double targetYieldTHa;
  @HiveField(7) final String status; // 'On track' | 'Delayed' | 'Complete'
  @HiveField(8) final String stage;  // 'Nursery' | 'Planting' | 'Growth' | 'Flowering' | 'Harvest'
  @HiveField(9) final DateTime createdAt;

  SeasonModel({
    required this.id,
    required this.farmerId,
    this.plotId,
    required this.variety,
    required this.plantingDate,
    required this.harvestDate,
    required this.targetYieldTHa,
    this.status = 'On track',
    this.stage = 'Nursery',
    required this.createdAt,
  });

  // ── Derived getters ───────────────────────────────────
  String get plantingLabel     => Formatters.date(plantingDate);
  String get harvestLabel      => Formatters.date(harvestDate);
  String get statusLabel       => status;
  String get stageLabel        => stage;
  String get targetYieldLabel  => Formatters.yieldTha(targetYieldTHa);

  /// Days after planting
  int get dap => Formatters.dap(plantingDate);

  String get dapLabel => Formatters.dapLabel(plantingDate);

  /// Progress 0.0 → 1.0 through the season
  double get progress =>
      Formatters.seasonProgress(plantingDate, CropConstants.seasonDurationDays);

  /// True once harvest date has passed or status is Complete
  bool get isComplete =>
      status == 'Complete' || DateTime.now().isAfter(harvestDate);

  bool get isDelayed => status == 'Delayed';

  int get stageIndex => CropConstants.stageIndex(stage);

  String? get nextStage => CropConstants.nextStage(stage);

  // ── fromJson (Supabase — Layer 7) ────────────────────
  factory SeasonModel.fromJson(Map<String, dynamic> j) {
    return SeasonModel(
      id:              j['id']               as String,
      farmerId:        j['farmer_id']        as String,
      plotId:          j['plot_id']          as String?,
      variety:         j['variety']          as String,
      plantingDate:    DateTime.parse(j['planting_date'] as String),
      harvestDate:     DateTime.parse(j['harvest_date']  as String),
      targetYieldTHa:  (j['target_yield_t_ha'] as num).toDouble(),
      status:          j['status']           as String? ?? 'On track',
      stage:           j['stage']            as String? ?? 'Nursery',
      createdAt:       DateTime.parse(j['created_at']    as String),
    );
  }

  // ── toJson (Supabase insert/update — Layer 7) ─────────
  Map<String, dynamic> toJson() => {
    'farmer_id':          farmerId,
    'plot_id':            plotId,
    'variety':            variety,
    'planting_date':      plantingDate.toIso8601String().split('T').first,
    'harvest_date':       harvestDate.toIso8601String().split('T').first,
    'target_yield_t_ha':  targetYieldTHa,
    'status':             status,
    'stage':              stage,
  };

  // ── copyWith ──────────────────────────────────────────
  SeasonModel copyWith({
    String?   id,
    String?   farmerId,
    String?   plotId,
    String?   variety,
    DateTime? plantingDate,
    DateTime? harvestDate,
    double?   targetYieldTHa,
    String?   status,
    String?   stage,
    DateTime? createdAt,
  }) {
    return SeasonModel(
      id:             id             ?? this.id,
      farmerId:       farmerId       ?? this.farmerId,
      plotId:         plotId         ?? this.plotId,
      variety:        variety        ?? this.variety,
      plantingDate:   plantingDate   ?? this.plantingDate,
      harvestDate:    harvestDate    ?? this.harvestDate,
      targetYieldTHa: targetYieldTHa ?? this.targetYieldTHa,
      status:         status         ?? this.status,
      stage:          stage          ?? this.stage,
      createdAt:      createdAt      ?? this.createdAt,
    );
  }

  // ── Seed data (written to Hive on first install) ──────
  static List<SeasonModel> seedList() => [
    SeasonModel(
      id: 'S001', farmerId: 'F001', plotId: 'PL001',
      variety: 'IISR Pragati',
      plantingDate: DateTime(2025, 1, 15),
      harvestDate: DateTime(2025, 8, 13),
      targetYieldTHa: 38.0, status: 'On track', stage: 'Growth',
      createdAt: DateTime(2025, 1, 15),
    ),
    SeasonModel(
      id: 'S002', farmerId: 'F001', plotId: 'PL002',
      variety: 'BSS-1',
      plantingDate: DateTime(2025, 2, 1),
      harvestDate: DateTime(2025, 8, 30),
      targetYieldTHa: 28.0, status: 'On track', stage: 'Planting',
      createdAt: DateTime(2025, 2, 1),
    ),
    SeasonModel(
      id: 'S003', farmerId: 'F002', plotId: 'PL003',
      variety: 'IISR Prabha',
      plantingDate: DateTime(2024, 11, 10),
      harvestDate: DateTime(2025, 6, 8),
      targetYieldTHa: 32.0, status: 'On track', stage: 'Flowering',
      createdAt: DateTime(2024, 11, 10),
    ),
    SeasonModel(
      id: 'S004', farmerId: 'F003', plotId: 'PL004',
      variety: 'Rajendra Sonia',
      plantingDate: DateTime(2024, 9, 5),
      harvestDate: DateTime(2025, 4, 3),
      targetYieldTHa: 35.0, status: 'Complete', stage: 'Harvest',
      createdAt: DateTime(2024, 9, 5),
    ),
    SeasonModel(
      id: 'S005', farmerId: 'F004', plotId: null,
      variety: 'Co-1',
      plantingDate: DateTime(2025, 2, 25),
      harvestDate: DateTime(2025, 9, 23),
      targetYieldTHa: 25.0, status: 'Delayed', stage: 'Nursery',
      createdAt: DateTime(2025, 2, 25),
    ),
  ];

  @override
  String toString() => 'SeasonModel($id, $variety, farmer: $farmerId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SeasonModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}