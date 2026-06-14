// features/farmers/add_farmer_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/crop_constants.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/section_header.dart';

class AddFarmerScreen extends StatefulWidget {
  const AddFarmerScreen({super.key});

  @override
  State<AddFarmerScreen> createState() => _AddFarmerScreenState();
}

class _AddFarmerScreenState extends State<AddFarmerScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _ageCtrl     = TextEditingController();
  final _areaCtrl    = TextEditingController();
  final _aadhaarCtrl = TextEditingController();
  final _notesCtrl   = TextEditingController();

  String? _village;
  bool _gpsLoading = false;
  double? _gpsLat;
  double? _gpsLng;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _ageCtrl.dispose();
    _areaCtrl.dispose();
    _aadhaarCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Validators ───────────────────────────────────
  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Farmer name is required';
    if (v.trim().length < 2) return 'Name must be at least 2 characters';
    if (RegExp(r'\d').hasMatch(v)) return 'Name cannot contain numbers';
    return null;
  }

  String? _validatePhone(String? v) {
    if (v == null || v.isEmpty) return 'Mobile number is required';
    final clean = v.replaceAll(' ', '');
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(clean)) {
      return 'Enter a valid 10-digit Indian mobile number';
    }
    return null;
  }

  String? _validateAge(String? v) {
    if (v == null || v.isEmpty) return 'Age is required';
    final n = int.tryParse(v);
    if (n == null || n < 18 || n > 90) return 'Age must be between 18 and 90';
    return null;
  }

  String? _validateArea(String? v) {
    if (v == null || v.isEmpty) return 'Landholding area is required';
    final n = double.tryParse(v);
    if (n == null || n <= 0 || n > 999) return 'Enter a valid area (0–999 ha)';
    return null;
  }

  String? _validateAadhaar(String? v) {
    if (v == null || v.isEmpty) return null; // optional
    final clean = v.replaceAll(' ', '');
    if (!RegExp(r'^\d{12}$').hasMatch(clean)) return 'Aadhaar must be 12 digits';
    return null;
  }

  // ── GPS capture (mock for now) ────────────────────
  Future<void> _captureGps() async {
    setState(() => _gpsLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // Phase 8: real geolocator
    setState(() {
      _gpsLat = 10.0275;
      _gpsLng = 76.3084;
      _gpsLoading = false;
    });
  }

  // ── Submit ────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_village == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a village')),
      );
      return;
    }
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800)); // Phase 8: real save
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('New farmer profile created'),
        backgroundColor: AppColors.success,
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Farmer'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _submit,
            child: Text(
              'Save',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            // ── Personal Info ─────────────────────────
            SectionHeader(
              title: 'Personal Information',
              icon: Icons.person_outline,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Name
                    TextFormField(
                      controller: _nameCtrl,
                      validator: _validateName,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Farmer Name *',
                        hintText: 'e.g. Arun Menon',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Phone
                    TextFormField(
                      controller: _phoneCtrl,
                      validator: _validatePhone,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number *',
                        hintText: 'e.g. 98765 43210',
                        prefixIcon: Icon(Icons.phone_outlined),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Age
                    TextFormField(
                      controller: _ageCtrl,
                      validator: _validateAge,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Age *',
                        hintText: 'e.g. 42',
                        prefixIcon: Icon(Icons.cake_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Location ──────────────────────────────
            SectionHeader(
              title: 'Location',
              icon: Icons.location_on_outlined,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Village dropdown
                    DropdownButtonFormField<String>(
                      value: _village,
                      decoration: const InputDecoration(
                        labelText: 'Village / Taluka *',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                      hint: const Text('Select village...'),
                      items: CropConstants.villages
                          .map((v) => DropdownMenuItem(
                                value: v,
                                child: Text(v),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _village = v),
                    ),
                    const SizedBox(height: 14),
                    // GPS
                    _GpsCaptureTile(
                      isLoading: _gpsLoading,
                      lat: _gpsLat,
                      lng: _gpsLng,
                      onCapture: _captureGps,
                    ),
                  ],
                ),
              ),
            ),

            // ── Farm Details ──────────────────────────
            SectionHeader(
              title: 'Farm Details',
              icon: Icons.landscape_outlined,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Area
                    TextFormField(
                      controller: _areaCtrl,
                      validator: _validateArea,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Landholding (ha) *',
                        hintText: 'e.g. 2.4',
                        prefixIcon: Icon(Icons.straighten_outlined),
                        suffixText: 'ha',
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Aadhaar
                    TextFormField(
                      controller: _aadhaarCtrl,
                      validator: _validateAadhaar,
                      keyboardType: TextInputType.number,
                      maxLength: 12,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Aadhaar Number',
                        hintText: 'XXXX XXXX XXXX (optional)',
                        prefixIcon: Icon(Icons.badge_outlined),
                        counterText: '',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Notes ─────────────────────────────────
            SectionHeader(
              title: 'Notes',
              icon: Icons.notes_outlined,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    hintText: 'Additional information about this farmer...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    counterText: '',
                  ),
                ),
              ),
            ),

            // ── Save button ───────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check, size: 18),
                label: Text(_loading ? 'Saving...' : 'Save Farmer'),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── GPS Capture Tile ──────────────────────────────────
class _GpsCaptureTile extends StatelessWidget {
  final bool isLoading;
  final double? lat;
  final double? lng;
  final VoidCallback onCapture;

  const _GpsCaptureTile({
    required this.isLoading,
    required this.lat,
    required this.lng,
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    final captured = lat != null && lng != null;
    return AppFlatCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(
            captured ? Icons.my_location : Icons.location_searching,
            color: captured ? AppColors.success : AppColors.textDisabled,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GPS Location', style: AppTextStyles.label),
                const SizedBox(height: 2),
                Text(
                  captured
                      ? '${lat!.toStringAsFixed(4)}° N, ${lng!.toStringAsFixed(4)}° E'
                      : 'Tap to capture current location',
                  style: AppTextStyles.caption.copyWith(
                    color: captured
                        ? AppColors.success
                        : AppColors.textDisabled,
                  ),
                ),
              ],
            ),
          ),
          isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : TextButton(
                  onPressed: onCapture,
                  child: Text(
                    captured ? 'Re-capture' : 'Capture',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}