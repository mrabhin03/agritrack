// core/utils/emission_calc.dart
import '../constants/crop_constants.dart';

class EmissionCalc {
  EmissionCalc._();

  // ── N₂O from synthetic nitrogen (IPCC 2006 default) ──
  //    EF = 1.25% of N applied
  //    N₂O-N → N₂O: × (44/28)
  //    N₂O → CO₂e: × GWP 298
  static double n2oCO2e(double nitrogenKg) {
    if (nitrogenKg <= 0) return 0;
    final n2oN = nitrogenKg * CropConstants.ipccN2oEmissionFactor;
    final n2o  = n2oN * (44 / 28);
    return n2o * CropConstants.n2oGwp;
  }

  // ── N₂O from organic nitrogen (IPCC EF = 0.008) ──────
  static double n2oCO2eOrganic(double organicNKg) {
    if (organicNKg <= 0) return 0;
    const organicEf = 0.008;
    final n2oN = organicNKg * organicEf;
    final n2o  = n2oN * (44 / 28);
    return n2o * CropConstants.n2oGwp;
  }

  // ── CO₂ from diesel combustion ────────────────────────
  //    2.68 kg CO₂e per litre (Climatiq / IPCC)
  static double dieselCO2e(double litres) {
    if (litres <= 0) return 0;
    return litres * CropConstants.dieselCo2eFactor;
  }

  // ── CO₂ from grid electricity ─────────────────────────
  //    0.82 kg CO₂e per kWh (India grid average)
  static double electricityCO2e(double kwh) {
    if (kwh <= 0) return 0;
    return kwh * CropConstants.gridElectricityFactor;
  }

  // ── Total CO₂e for a single input entry ───────────────
  static double totalCO2e({
    double nitrogenKg      = 0,
    double organicNKg      = 0,
    double dieselL         = 0,
    double electricityKwh  = 0,
  }) {
    return n2oCO2e(nitrogenKg) +
        n2oCO2eOrganic(organicNKg) +
        dieselCO2e(dieselL) +
        electricityCO2e(electricityKwh);
  }

  // ── Intensity: CO₂e per hectare ───────────────────────
  static double intensityPerHa(double totalCO2eKg, double areaHa) {
    if (areaHa <= 0) return 0;
    return totalCO2eKg / areaHa;
  }

  // ── Intensity: CO₂e per tonne yield ──────────────────
  static double intensityPerTonne(
      double totalCO2eKg, double yieldTonnes) {
    if (yieldTonnes <= 0) return 0;
    return totalCO2eKg / yieldTonnes;
  }

  // ── Low emissions check ───────────────────────────────
  //    Threshold: < 500 kg CO₂e/ha = Low
  static bool isLowEmissions(double co2ePerHa) =>
      co2ePerHa < CropConstants.lowEmissionThresholdPerHa;

  // ── Breakdown map (for charts) ────────────────────────
  //    Returns each source's CO₂e contribution
  static Map<String, double> breakdown({
    double nitrogenKg     = 0,
    double organicNKg     = 0,
    double dieselL        = 0,
    double electricityKwh = 0,
  }) {
    return {
      'N₂O (Fertiliser)': n2oCO2e(nitrogenKg),
      'N₂O (Organic)':    n2oCO2eOrganic(organicNKg),
      'CO₂ (Diesel)':     dieselCO2e(dieselL),
      'CO₂ (Grid)':       electricityCO2e(electricityKwh),
    };
  }

  // ── Sum a list of emission records ────────────────────
  static double sumTotal(List<double> records) =>
      records.fold(0, (a, b) => a + b);

  // ── Format for display ────────────────────────────────
  //    Rounds to 2 decimal places
  static double round2(double v) =>
      double.parse(v.toStringAsFixed(2));
}