// core/utils/formatters.dart
import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  // ── Date formatters ───────────────────────────────

  /// DD/MM/YYYY — standard en-IN display format
  static String date(DateTime d) =>
      DateFormat('dd/MM/yyyy').format(d);

  /// DD/MM/YYYY from nullable — returns '—' if null
  static String dateOrDash(DateTime? d) =>
      d != null ? date(d) : '—';

  /// DD/MM/YYYY HH:MM
  static String dateTime(DateTime d) =>
      DateFormat('dd/MM/yyyy  HH:mm').format(d);

  /// "12 Jan 2025" — readable label
  static String dateLabel(DateTime d) =>
      DateFormat('dd MMM yyyy').format(d);

  /// "Jan 2025" — month + year only
  static String monthYear(DateTime d) =>
      DateFormat('MMM yyyy').format(d);

  /// "09:12 AM" — time only
  static String timeOnly(DateTime d) =>
      DateFormat('hh:mm a').format(d);

  /// Parse DD/MM/YYYY string → DateTime
  /// Returns null if invalid
  static DateTime? parseDate(String s) {
    try {
      return DateFormat('dd/MM/yyyy').parseStrict(s);
    } catch (_) {
      return null;
    }
  }

  // ── Area formatters ───────────────────────────────

  /// "2.40 ha"
  static String ha(double v) =>
      '${v.toStringAsFixed(2)} ha';

  /// "2.4 ha" — shorter version
  static String haShort(double v) =>
      '${v.toStringAsFixed(1)} ha';

  /// ha → acres (1 ha = 2.47105 acres)
  static double haToAcres(double ha) => ha * 2.47105;

  /// "5.93 acres"
  static String acres(double ha) =>
      '${haToAcres(ha).toStringAsFixed(2)} acres';

  // ── Yield formatters ──────────────────────────────

  /// "38.0 t/ha"
  static String yieldTha(double v) =>
      '${v.toStringAsFixed(1)} t/ha';

  /// "4.50 t"
  static String tonnes(double v) =>
      '${v.toStringAsFixed(2)} t';

  // ── Emission formatters ───────────────────────────

  /// "1,234.5 kg CO₂e"
  static String co2eKg(double v) =>
      '${_compact(v)} kg CO₂e';

  /// "1.23 tCO₂e" — tonnes version for hero card
  static String co2eTonnes(double v) =>
      '${(v / 1000).toStringAsFixed(2)} tCO₂e';

  /// "413.5 kg CO₂e/ha"
  static String co2ePerHa(double v) =>
      '${v.toStringAsFixed(1)} kg CO₂e/ha';

  /// "32.6 kg CO₂e/t"
  static String co2ePerTonne(double v) =>
      '${v.toStringAsFixed(1)} kg CO₂e/t';

  // ── Fertiliser formatters ─────────────────────────

  /// "N: 50 kg  P: 25 kg  K: 20 kg"
  static String npk(double n, double p, double k) =>
      'N: ${n.toInt()} kg  P: ${p.toInt()} kg  K: ${k.toInt()} kg';

  /// "50 kg/ha"
  static String kgHa(double v) =>
      '${v.toStringAsFixed(0)} kg/ha';

  /// "10.0 L"
  static String litres(double v) =>
      '${v.toStringAsFixed(1)} L';

  /// "5.0 kWh"
  static String kwh(double v) =>
      '${v.toStringAsFixed(1)} kWh';

  // ── Number formatters ─────────────────────────────

  /// Indian number format: 1,00,000
  static String inrNumber(double v) =>
      NumberFormat('#,##,##0.##', 'en_IN').format(v);

  /// Compact: 1234.5 → "1,234.5"
  static String _compact(double v) =>
      NumberFormat('#,##0.#', 'en_IN').format(v);

  /// Percentage: 0.856 → "85.6%"
  static String percent(double v) =>
      '${(v * 100).toStringAsFixed(1)}%';

  /// Count with label: pluralize
  static String count(int n, String singular, String plural) =>
      '$n ${n == 1 ? singular : plural}';

  // ── DAP formatter ─────────────────────────────────

  /// Days after planting from planting date
  static int dap(DateTime plantingDate) =>
      DateTime.now().difference(plantingDate).inDays.clamp(0, 999);

  /// "45 DAP"
  static String dapLabel(DateTime plantingDate) =>
      '${dap(plantingDate)} DAP';

  // ── Status helpers ────────────────────────────────

  /// Season progress 0.0 → 1.0 based on DAP vs total duration
  static double seasonProgress(
      DateTime plantingDate, int durationDays) {
    final elapsed = dap(plantingDate);
    return (elapsed / durationDays).clamp(0.0, 1.0);
  }
}