// features/carbon/add_emission_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/crop_constants.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/section_header.dart';
import '../crops/providers/crops_provider.dart';
import '../plots/providers/plots_provider.dart';
import 'providers/carbon_provider.dart';

class AddEmissionScreen extends ConsumerStatefulWidget {
  final String? seasonId;
  const AddEmissionScreen({super.key, this.seasonId});

  @override
  ConsumerState<AddEmissionScreen> createState() =>
      _AddEmissionScreenState();
}

class _AddEmissionScreenState extends ConsumerState<AddEmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedSeasonId;
  DateTime? _entryDate;
  bool _loading = false;

  // Input controllers
  final _nCtrl = TextEditingController();
  final _organicNCtrl = TextEditingController();
  final _dieselCtrl = TextEditingController();
  final _elecCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.seasonId != null) {
      _selectedSeasonId = widget.seasonId;
    }
    _entryDate = DateTime.now();
  }

  @override
  void dispose() {
    _nCtrl.dispose();
    _organicNCtrl.dispose();
    _dieselCtrl.dispose();
    _elecCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Live emission preview ─────────────────────────
  double get _n2oCO2e {
    final n = double.tryParse(_nCtrl.text) ?? 0;
    final organicN = double.tryParse(_organicNCtrl.text) ?? 0;
    final synthetic =
        n * CropConstants.ipccN2oEmissionFactor * (44 / 28) *
            CropConstants.n2oGwp;
    final organic =
        organicN * 0.008 * (44 / 28) * CropConstants.n2oGwp;
    return synthetic + organic;
  }

  double get _dieselCO2e {
    final d = double.tryParse(_dieselCtrl.text) ?? 0;
    return d * CropConstants.dieselCo2eFactor;
  }

  double get _elecCO2e {
    final e = double.tryParse(_elecCtrl.text) ?? 0;
    return e * CropConstants.gridElectricityFactor;
  }

  double get _totalCO2e => _n2oCO2e + _dieselCO2e + _elecCO2e;

  bool get _isLow =>
      _totalCO2e < CropConstants.lowEmissionThresholdPerHa;

  // ── Date picker ───────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _entryDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select Entry Date',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _entryDate = picked);
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'Select date...';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  // ── Validators ───────────────────────────────────
  String? _validateNonNegative(String? v) {
    if (v == null || v.isEmpty) return null;
    final n = double.tryParse(v);
    if (n == null || n < 0) return 'Enter a non-negative number';
    return null;
  }

  // ── Submit → save to Hive via provider ────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSeasonId == null) {
      _showSnack('Please select a crop season');
      return;
    }
    if (_entryDate == null) {
      _showSnack('Please select an entry date');
      return;
    }
    if (_totalCO2e == 0) {
      _showSnack('Enter at least one input value');
      return;
    }

    setState(() => _loading = true);

    try {
      // Look up the season's plot to get area_ha (for intensity calc)
      final season = ref.read(seasonByIdProvider(_selectedSeasonId!));
      double areaHa = 0;
      if (season?.plotId != null) {
        final plot = ref.read(plotByIdProvider(season!.plotId!));
        areaHa = plot?.areaHa ?? 0;
      }

      await ref.read(carbonProvider.notifier).addEmission({
        'season_id': _selectedSeasonId,
        'nitrogen_kg': double.tryParse(_nCtrl.text) ?? 0,
        'organic_n_kg': double.tryParse(_organicNCtrl.text) ?? 0,
        'diesel_l': double.tryParse(_dieselCtrl.text) ?? 0,
        'electricity_kwh': double.tryParse(_elecCtrl.text) ?? 0,
        'area_ha': areaHa,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Emissions updated: ${_totalCO2e.toStringAsFixed(1)} kg CO₂e',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error saving emission: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final seasonsAsync = ref.watch(seasonsProvider);
    final seasons = seasonsAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Log Emission'),
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
            // ── Season selector ───────────────────────
            SectionHeader(
              title: 'Crop Season',
              icon: Icons.grass_outlined,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: seasons.isEmpty
                    ? Text(
                        'No seasons yet — add a season first',
                        style: AppTextStyles.caption,
                      )
                    : DropdownButtonFormField<String>(
                        value: _selectedSeasonId,
                        decoration: const InputDecoration(
                          labelText: 'Season *',
                          prefixIcon:
                              Icon(Icons.agriculture_outlined),
                        ),
                        hint: const Text('Select season...'),
                        isExpanded: true,
                        items: seasons
                            .map((s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(
                                    '${s.variety} — ${s.stage} (${s.farmerId})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedSeasonId = v),
                      ),
              ),
            ),
            // ── Entry date ────────────────────────────
            SectionHeader(
              title: 'Entry Date',
              icon: Icons.calendar_today_outlined,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: _pickDate,
                  child: AppFlatCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _formatDate(_entryDate),
                          style: AppTextStyles.body.copyWith(
                            color: _entryDate != null
                                ? AppColors.textPrimary
                                : AppColors.textDisabled,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: AppColors.textDisabled,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // ── Inputs ────────────────────────────────
            SectionHeader(
              title: 'Input Usage',
              icon: Icons.input_outlined,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Synthetic Nitrogen
                    TextFormField(
                      controller: _nCtrl,
                      validator: _validateNonNegative,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                              decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Synthetic Nitrogen (kg)',
                        hintText: 'e.g. 50',
                        prefixIcon: Icon(Icons.grass_outlined),
                        suffixText: 'kg',
                        helperText:
                            'IPCC EF: 1.25% of N → N₂O × 298 GWP',
                        helperStyle: TextStyle(fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Organic Nitrogen
                    TextFormField(
                      controller: _organicNCtrl,
                      validator: _validateNonNegative,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                              decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Organic Nitrogen (kg)',
                        hintText: 'e.g. 20 (compost/manure N)',
                        prefixIcon: Icon(Icons.eco_outlined),
                        suffixText: 'kg',
                        helperText:
                            'IPCC EF: 0.8% of organic N → N₂O × 298 GWP',
                        helperStyle: TextStyle(fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Diesel
                    TextFormField(
                      controller: _dieselCtrl,
                      validator: _validateNonNegative,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                              decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Diesel Used (L)',
                        hintText: 'e.g. 10',
                        prefixIcon:
                            Icon(Icons.local_gas_station_outlined),
                        suffixText: 'L',
                        helperText: '2.68 kg CO₂e per litre',
                        helperStyle: TextStyle(fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Electricity
                    TextFormField(
                      controller: _elecCtrl,
                      validator: _validateNonNegative,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                              decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Electricity (kWh)',
                        hintText: 'e.g. 5',
                        prefixIcon: Icon(Icons.bolt_outlined),
                        suffixText: 'kWh',
                        helperText:
                            '0.82 kg CO₂e per kWh (India grid)',
                        helperStyle: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ── Live emission preview ──────────────────
            if (_totalCO2e > 0) ...[
              SectionHeader(
                title: 'Emission Preview',
                icon: Icons.eco_outlined,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_totalCO2e.toStringAsFixed(1)} kg CO₂e',
                                  style: AppTextStyles.metricLarge
                                      .copyWith(
                                          color: AppColors.primary),
                                ),
                                Text(
                                  'Total estimated emissions',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                          EmissionBadge(isLow: _isLow),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 14),
                      _PreviewRow(
                        icon: Icons.grass_outlined,
                        label: 'N₂O (Fertiliser)',
                        value: _n2oCO2e,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 8),
                      _PreviewRow(
                        icon: Icons.local_gas_station_outlined,
                        label: 'CO₂ (Diesel)',
                        value: _dieselCO2e,
                        color: AppColors.warning,
                      ),
                      const SizedBox(height: 8),
                      _PreviewRow(
                        icon: Icons.bolt_outlined,
                        label: 'CO₂ (Grid)',
                        value: _elecCO2e,
                        color: AppColors.info,
                      ),
                      if (_totalCO2e > 0) ...[
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Row(
                            children: [
                              if (_n2oCO2e > 0)
                                Expanded(
                                  flex: (_n2oCO2e / _totalCO2e * 100)
                                      .round(),
                                  child: Container(
                                    height: 8,
                                    color: AppColors.primary,
                                  ),
                                ),
                              if (_dieselCO2e > 0)
                                Expanded(
                                  flex:
                                      (_dieselCO2e / _totalCO2e * 100)
                                          .round(),
                                  child: Container(
                                    height: 8,
                                    color: AppColors.warning,
                                  ),
                                ),
                              if (_elecCO2e > 0)
                                Expanded(
                                  flex: (_elecCO2e / _totalCO2e * 100)
                                      .round(),
                                  child: Container(
                                    height: 8,
                                    color: AppColors.info,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
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
                  maxLength: 300,
                  decoration: const InputDecoration(
                    hintText: 'Any additional context...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    counterText: '',
                  ),
                ),
              ),
            ),
            // ── IPCC note ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: AppFlatCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: AppColors.info),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Emission factors: IPCC 2006 defaults. '
                        'N₂O EF = 1.25% (synthetic) / 0.8% (organic) × N applied × 298 GWP. '
                        'Diesel = 2.68 kg CO₂e/L. '
                        'Grid = 0.82 kg CO₂e/kWh.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
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
                    : const Icon(Icons.eco_outlined, size: 18),
                label: Text(_loading ? 'Saving...' : 'Save Emission'),
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

// ── Preview Row ───────────────────────────────────────
class _PreviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final Color color;
  const _PreviewRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: AppTextStyles.caption),
        ),
        Text(
          '${value.toStringAsFixed(1)} kg',
          style: AppTextStyles.label.copyWith(color: color),
        ),
      ],
    );
  }
}