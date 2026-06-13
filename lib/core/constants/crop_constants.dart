// core/constants/crop_constants.dart

class CropConstants {
  CropConstants._();

  // ── Turmeric Varieties ─────────────────────────────
  static const List<String> varieties = [
    'IISR Pragati',
    'IISR Prabha',
    'Co-1',
    'BSS-1',
    'Rajendra Sonia',
  ];

  // ── Target yield (t/ha) per variety ───────────────
  static const Map<String, double> varietyYields = {
    'IISR Pragati':    38.0,
    'IISR Prabha':     32.0,
    'Co-1':            25.0,
    'BSS-1':           28.0,
    'Rajendra Sonia':  35.0,
  };

  // ── Crop Growth Stages ─────────────────────────────
  static const List<String> stages = [
    'Nursery',
    'Planting',
    'Growth',
    'Flowering',
    'Harvest',
  ];

  // ── Stage DAP (Days After Planting) ranges ─────────
  static const Map<String, String> stageDapRange = {
    'Nursery':   '0 – 14 DAP',
    'Planting':  '14 – 30 DAP',
    'Growth':    '30 – 120 DAP',
    'Flowering': '120 – 150 DAP',
    'Harvest':   '150 – 210 DAP',
  };

  // ── Stage descriptions ─────────────────────────────
  static const Map<String, String> stageDescription = {
    'Nursery':   'Rhizome preparation and bed setup',
    'Planting':  'Field planting and spacing',
    'Growth':    'Vegetative growth, N/P/K application',
    'Flowering': 'Flowering and canopy monitoring',
    'Harvest':   'Rhizome harvest and yield measurement',
  };

  // ── Crop season duration (days) ────────────────────
  static const int seasonDurationDays = 210;

  // ── Soil Types ─────────────────────────────────────
  static const List<String> soilTypes = [
    'Loamy',
    'Sandy',
    'Clay',
    'Sandy loam',
    'Red laterite',
  ];

  // ── Irrigation Methods ─────────────────────────────
  static const List<String> irrigationTypes = [
    'Drip',
    'Flood',
    'Rain-fed',
    'Sprinkler',
  ];

  // ── Event Types ────────────────────────────────────
  static const List<String> eventTypes = [
    'Fertiliser',
    'Irrigation',
    'Harvest',
    'Monitoring',
  ];

  // ── Season Statuses ────────────────────────────────
  static const List<String> seasonStatuses = [
    'On track',
    'Delayed',
    'Complete',
  ];

  // ── Villages (Kerala — Idukki / Ernakulam dist.) ───
  static const List<String> villages = [
    'Kothamangalam',
    'Munnar',
    'Thodupuzha',
    'Erattupetta',
    'Kattappana',
    'Adimali',
    'Nedumkandam',
    'Vandiperiyar',
    'Kumily',
    'Moovattupuzha',
    'Perumbavoor',
    'Aluva',
    'Muvattupuzha',
    'Pothanicad',
    'Kalady',
    'Angamaly',
    'Piravom',
    'Kolenchery',
    'Pala',
    'Ettumanoor',
    'Kanjirappally',
    'Ponkunnam',
    'Poonjar',
    'Uzhavoor',
    'Meenachil',
  ];

  // ── Emission thresholds ────────────────────────────
  static const double lowEmissionThresholdPerHa = 500.0; // kg CO2e/ha

  // ── IPCC Emission Factors ──────────────────────────
  static const double ipccN2oEmissionFactor     = 0.0125; // 1.25% of N
  static const double n2oGwp                    = 298.0;  // GWP100
  static const double dieselCo2eFactor          = 2.68;   // kg CO2e/litre
  static const double gridElectricityFactor     = 0.82;   // kg CO2e/kWh (India)

  // ── UI helpers ────────────────────────────────────

  /// Default yield for a variety (fallback 30 t/ha)
  static double defaultYield(String variety) =>
      varietyYields[variety] ?? 30.0;

  /// Index of stage in pipeline (0-4)
  static int stageIndex(String stage) =>
      stages.indexOf(stage).clamp(0, 4);

  /// Next stage after current
  static String? nextStage(String stage) {
    final i = stageIndex(stage);
    return i < stages.length - 1 ? stages[i + 1] : null;
  }

  /// True if stage is the final one
  static bool isFinalStage(String stage) => stage == 'Harvest';
}