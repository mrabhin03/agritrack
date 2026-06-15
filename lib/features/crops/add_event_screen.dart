// features/crops/add_event_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/crop_constants.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/loading_overlay.dart';
import '../crops/providers/crops_provider.dart';

class AddEventScreen extends ConsumerStatefulWidget {
  final String? seasonId;
  const AddEventScreen({super.key, this.seasonId});

  @override
  ConsumerState<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends ConsumerState<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  String _eventType = 'Fertiliser';
  DateTime? _eventDate;
  bool _loading = false;

  // Fertiliser fields
  final _nCtrl = TextEditingController();
  final _pCtrl = TextEditingController();
  final _kCtrl = TextEditingController();
  final _organicNCtrl = TextEditingController();

  // Diesel / electricity
  final _dieselCtrl = TextEditingController();
  final _elecCtrl = TextEditingController();

  // Irrigation
  final _irrigationLCtrl = TextEditingController();
  String? _irrigationType;

  // Harvest
  final _yieldCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _nCtrl.dispose();
    _pCtrl.dispose();
    _kCtrl.dispose();
    _organicNCtrl.dispose();
    _dieselCtrl.dispose();
    _elecCtrl.dispose();
    _irrigationLCtrl.dispose();
    _yieldCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Date picker ───────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select Event Date',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'Select date...';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  // ── Validators ───────────────────────────────────
  String? _validateNonNegative(String? v) {
    if (v == null || v.isEmpty) return null; // optional
    final n = double.tryParse(v);
    if (n == null || n < 0) return 'Enter a non-negative number';
    return null;
  }

  String? _validateRequired(String? v) {
    if (v == null || v.isEmpty) return 'This field is required';
    final n = double.tryParse(v);
    if (n == null || n <= 0) return 'Enter a value greater than 0';
    return null;
  }

  // ── Emission preview ──────────────────────────────
  double get _previewN2o {
    final n = double.tryParse(_nCtrl.text) ?? 0;
    return n *
        CropConstants.ipccN2oEmissionFactor *
        (44 / 28) *
        CropConstants.n2oGwp;
  }

  double get _previewDiesel {
    final d = double.tryParse(_dieselCtrl.text) ?? 0;
    return d * CropConstants.dieselCo2eFactor;
  }

  double get _previewTotal => _previewN2o + _previewDiesel;

  // ── Submit ────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_eventDate == null) {
      _showSnack('Please select an event date');
      return;
    }
    if (_eventType == 'Irrigation' && _irrigationType == null) {
      _showSnack('Please select irrigation type');
      return;
    }
    if (widget.seasonId == null) {
      _showSnack('No season selected — cannot save event');
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(cropEventsProvider.notifier).addEvent({
        'season_id': widget.seasonId,
        'event_type': _eventType,
        'event_date': _eventDate,
        'nitrogen_kg': double.tryParse(_nCtrl.text) ?? 0,
        'phosphorus_kg': double.tryParse(_pCtrl.text) ?? 0,
        'potassium_kg': double.tryParse(_kCtrl.text) ?? 0,
        'organic_n_kg': double.tryParse(_organicNCtrl.text) ?? 0,
        'diesel_l': double.tryParse(_dieselCtrl.text) ?? 0,
        'electricity_kwh': double.tryParse(_elecCtrl.text) ?? 0,
        'irrigation_l': double.tryParse(_irrigationLCtrl.text) ?? 0,
        'harvest_yield_t': _eventType == 'Harvest'
            ? double.tryParse(_yieldCtrl.text)
            : null,
        'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      });
      if (!mounted) return;
      final msg = _eventType == 'Harvest'
          ? 'Harvest recorded — emissions updated'
          : '$_eventType entry saved';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to save event. Please try again.');
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
    return LoadingOverlay(
      isLoading: _loading,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
            title: const Text('Log Event'),
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
                // ── Season context banner ──────────────
                if (widget.seasonId != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: AppFlatCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.yard_rounded,
                              size: 16, color: AppColors.accent),
                          const SizedBox(width: 8),
                          Text(
                            'Season: ${widget.seasonId}',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Event Type selector ───────────────────
                SectionHeader(
                  title: 'Event Type',
                  icon: Icons.category_outlined,
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: CropConstants.eventTypes.map((type) {
                        final selected = type == _eventType;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _eventType = type;
                            // clear fields on type switch
                            _nCtrl.clear();
                            _pCtrl.clear();
                            _kCtrl.clear();
                            _organicNCtrl.clear();
                            _dieselCtrl.clear();
                            _elecCtrl.clear();
                            _yieldCtrl.clear();
                            _irrigationLCtrl.clear();
                            _irrigationType = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.successBg
                                  : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _typeIcon(type),
                                  size: 14,
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.textDisabled,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  type,
                                  style: AppTextStyles.label.copyWith(
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // ── Event Date ────────────────────────────
                SectionHeader(
                  title: 'Event Date',
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
                              _formatDate(_eventDate),
                              style: AppTextStyles.body.copyWith(
                                color: _eventDate != null
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

                // ── Dynamic fields by event type ──────────
                if (_eventType == 'Fertiliser') ...[
                  SectionHeader(
                    title: 'Fertiliser Details',
                    icon: Icons.grass_outlined,
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // N / P / K row
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _nCtrl,
                                  validator: _validateNonNegative,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  onChanged: (_) => setState(() {}),
                                  decoration: const InputDecoration(
                                    labelText: 'N (kg/ha)',
                                    hintText: '0',
                                    suffixText: 'kg',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _pCtrl,
                                  validator: _validateNonNegative,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'P (kg/ha)',
                                    hintText: '0',
                                    suffixText: 'kg',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _kCtrl,
                                  validator: _validateNonNegative,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'K (kg/ha)',
                                    hintText: '0',
                                    suffixText: 'kg',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Organic N (separate EF per spec)
                          TextFormField(
                            controller: _organicNCtrl,
                            validator: _validateNonNegative,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Organic N (kg/ha)',
                              hintText: '0',
                              helperText: 'EF = 0.008 (IPCC organic)',
                              prefixIcon:
                                  Icon(Icons.eco_outlined),
                              suffixText: 'kg',
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
                              prefixIcon: Icon(
                                  Icons.local_gas_station_outlined),
                              suffixText: 'L',
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
                            decoration: const InputDecoration(
                              labelText: 'Electricity (kWh)',
                              hintText: 'e.g. 5',
                              prefixIcon: Icon(Icons.bolt_outlined),
                              suffixText: 'kWh',
                            ),
                          ),
                          // Emission preview
                          if (_previewTotal > 0) ...[
                            const SizedBox(height: 14),
                            AppFlatCard(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  const Icon(Icons.eco_outlined,
                                      size: 16,
                                      color: AppColors.accent),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Estimated emissions',
                                      style: AppTextStyles.label,
                                    ),
                                  ),
                                  Text(
                                    '${_previewTotal.toStringAsFixed(1)} kg CO₂e',
                                    style: AppTextStyles.label.copyWith(
                                      color: AppColors.primary,
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

                if (_eventType == 'Irrigation') ...[
                  SectionHeader(
                    title: 'Irrigation Details',
                    icon: Icons.water_drop_outlined,
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _irrigationType,
                            decoration: const InputDecoration(
                              labelText: 'Irrigation Type *',
                              prefixIcon:
                                  Icon(Icons.water_drop_outlined),
                            ),
                            hint: const Text('Select type...'),
                            items: CropConstants.irrigationTypes
                                .map((t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _irrigationType = v),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _irrigationLCtrl,
                            validator: _validateNonNegative,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Volume (L)',
                              hintText: 'e.g. 500',
                              prefixIcon: Icon(Icons.water_outlined),
                              suffixText: 'L',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                if (_eventType == 'Harvest') ...[
                  SectionHeader(
                    title: 'Harvest Details',
                    icon: Icons.agriculture_outlined,
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _yieldCtrl,
                            validator: _validateRequired,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Fresh Yield (tonnes) *',
                              hintText: 'e.g. 4.5',
                              prefixIcon:
                                  Icon(Icons.agriculture_outlined),
                              suffixText: 't',
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _dieselCtrl,
                            validator: _validateNonNegative,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Diesel Used (L)',
                              hintText: 'e.g. 12',
                              prefixIcon: Icon(
                                  Icons.local_gas_station_outlined),
                              suffixText: 'L',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                if (_eventType == 'Monitoring') ...[
                  SectionHeader(
                    title: 'Monitoring Notes',
                    icon: Icons.visibility_outlined,
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AppCard(
                      padding: const EdgeInsets.all(16),
                      child: TextFormField(
                        controller: _notesCtrl,
                        maxLines: 4,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          hintText:
                              'Describe what was observed in the field...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          counterText: '',
                        ),
                      ),
                    ),
                  ),
                ],

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
                        : Icon(_typeIcon(_eventType), size: 18),
                    label: Text(
                        _loading ? 'Saving...' : 'Save $_eventType'),
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
        ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Fertiliser':
        return Icons.grass_outlined;
      case 'Irrigation':
        return Icons.water_drop_outlined;
      case 'Harvest':
        return Icons.agriculture_outlined;
      case 'Monitoring':
        return Icons.visibility_outlined;
      default:
        return Icons.event_outlined;
    }
  }
}