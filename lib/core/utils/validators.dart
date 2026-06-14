// core/utils/validators.dart

class Validators {
  Validators._();

  // ── Name ─────────────────────────────────────────
  static String? name(String? v) {
    if (v == null || v.trim().isEmpty) return 'Farmer name is required';
    if (v.trim().length < 2) return 'Name must be at least 2 characters';
    if (v.trim().length > 100) return 'Name must be under 100 characters';
    if (RegExp(r'\d').hasMatch(v)) return 'Name cannot contain numbers';
    return null;
  }

  // ── Phone ─────────────────────────────────────────
  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Mobile number is required';
    final clean = v.replaceAll(' ', '').replaceAll('-', '');
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(clean)) {
      return 'Enter a valid 10-digit Indian mobile number';
    }
    return null;
  }

  // ── Age ──────────────────────────────────────────
  static String? age(String? v) {
    if (v == null || v.trim().isEmpty) return 'Age is required';
    final n = int.tryParse(v.trim());
    if (n == null) return 'Enter a valid age';
    if (n < 18) return 'Age must be at least 18 years';
    if (n > 90) return 'Age must be under 90 years';
    return null;
  }

  // ── Area (hectares) ───────────────────────────────
  static String? area(String? v) {
    if (v == null || v.trim().isEmpty) return 'Landholding area is required';
    final n = double.tryParse(v.trim());
    if (n == null) return 'Enter a valid number';
    if (n <= 0) return 'Area must be greater than 0';
    if (n > 999) return 'Area must be under 999 ha';
    return null;
  }

  // ── Aadhaar (optional) ────────────────────────────
  static String? aadhaar(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional
    final clean = v.replaceAll(' ', '');
    if (!RegExp(r'^\d{12}$').hasMatch(clean)) {
      return 'Aadhaar must be exactly 12 digits';
    }
    return null;
  }

  // ── Required text ─────────────────────────────────
  static String? required(String? v, {String field = 'This field'}) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    return null;
  }

  // ── Non-negative number ───────────────────────────
  static String? nonNegative(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional
    final n = double.tryParse(v.trim());
    if (n == null) return 'Enter a valid number';
    if (n < 0) return 'Please enter a non-negative number';
    return null;
  }

  // ── Positive number (required) ────────────────────
  static String? positiveRequired(String? v) {
    if (v == null || v.trim().isEmpty) return 'This field is required';
    final n = double.tryParse(v.trim());
    if (n == null) return 'Enter a valid number';
    if (n <= 0) return 'Enter a value greater than 0';
    return null;
  }

  // ── Target yield ──────────────────────────────────
  static String? targetYield(String? v) {
    if (v == null || v.trim().isEmpty) return 'Target yield is required';
    final n = double.tryParse(v.trim());
    if (n == null) return 'Enter a valid number';
    if (n <= 0) return 'Yield must be greater than 0';
    if (n > 100) return 'Yield seems too high (max 100 t/ha)';
    return null;
  }

  // ── Plot name ─────────────────────────────────────
  static String? plotName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Plot name is required';
    if (v.trim().length < 2) return 'Name must be at least 2 characters';
    if (v.trim().length > 80) return 'Name must be under 80 characters';
    return null;
  }

  // ── Notes (optional, max length) ─────────────────
  static String? notes(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional
    if (v.trim().length > 500) return 'Notes must be under 500 characters';
    return null;
  }

  // ── Date not in future ────────────────────────────
  static String? notFutureDate(DateTime? d) {
    if (d == null) return 'Please select a date';
    if (d.isAfter(DateTime.now())) return 'Date cannot be in the future';
    return null;
  }

  // ── Harvest yield (tonnes) ────────────────────────
  static String? harvestYield(String? v) {
    if (v == null || v.trim().isEmpty) return 'Harvest yield is required';
    final n = double.tryParse(v.trim());
    if (n == null) return 'Enter a valid number';
    if (n <= 0) return 'Yield must be greater than 0';
    return null;
  }

  // ── Irrigation volume ─────────────────────────────
  static String? irrigationVolume(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional
    final n = double.tryParse(v.trim());
    if (n == null) return 'Enter a valid number';
    if (n < 0) return 'Volume cannot be negative';
    return null;
  }
}