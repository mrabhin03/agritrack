// features/crops/add_season_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/crop_constants.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/section_header.dart';

class AddSeasonScreen extends StatefulWidget {
  final String? farmerId;
  const AddSeasonScreen({super.key, this.farmerId});

  @override
  State<AddSeasonScreen> createState() => _AddSeasonScreenState();
}

class _AddSeasonScreenState extends State<AddSeasonScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedFarmerId;
  String? _selectedVariety;
  DateTime? _plantingDate;
  DateTime? _harvestDate;
  double? _targetYield;
  bool _loading = false;

  final _farmerOptions = const [
    {'id': 'F001', 'name': 'Arun Menon'},
    {'id': 'F002', 'name': 'Priya Nair'},
    {'id': 'F003', 'name': 'Suresh Kumar'},
    {'id': 'F004', 'name': 'Latha Krishnan'},
    {'id': 'F005', 'name': 'Biju Thomas'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.farmerId != null) {
      _selectedFarmerId = widget.farmerId;
    }
  }

  void _onVarietyChanged(String? variety) {
    setState(() {
      _selectedVariety = variety;
      _targetYield = variety != null
          ? CropConstants.defaultYield(variety)
          : null;
      if (_plantingDate != null) {
        _harvestDate = _plantingDate!.add(
          const Duration(days: CropConstants.seasonDurationDays),
        );
      }
    });
  }

  void _onPlantingDateChanged(DateTime date) {
    setState(() {
      _plantingDate = date;
      _harvestDate = date.add(
        const Duration(days: CropConstants.seasonDurationDays),
      );
    });
  }

  Future<void> _pickPlantingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select Planting Date',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) _onPlantingDateChanged(picked);
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'Select date...';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFarmerId == null) {
      _showSnack('Please select a farmer');
      return;
    }
    if (_selectedVariety == null) {
      _showSnack('Please select a variety');
      return;
    }
    if (_plantingDate == null) {
      _showSnack('Please select a planting date');
      return;
    }
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Crop season started — timeline is live'),
        backgroundColor: AppColors.success,
      ),
    );
    context.pop();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Season'),
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
            // ── Farmer ───────────────────────────────
            SectionHeader(
              title: 'Farmer',
              icon: Icons.person_outline,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<String>(
                  value: _selectedFarmerId,
                  decoration: const InputDecoration(
                    labelText: 'Farmer *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  hint: const Text('Select farmer...'),
                  items: _farmerOptions
                      .map((f) => DropdownMenuItem(
                            value: f['id'],
                            child: Text(f['name']!),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedFarmerId = v),
                ),
              ),
            ),

            // ── Crop Details ──────────────────────────
            SectionHeader(
              title: 'Crop Details',
              icon: Icons.grass_outlined,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Variety
                    DropdownButtonFormField<String>(
                      value: _selectedVariety,
                      decoration: const InputDecoration(
                        labelText: 'Turmeric Variety *',
                        prefixIcon:
                            Icon(Icons.local_florist_outlined),
                      ),
                      hint: const Text('Select variety...'),
                      items: CropConstants.varieties
                          .map((v) => DropdownMenuItem(
                                value: v,
                                child: Text(v),
                              ))
                          .toList(),
                      onChanged: _onVarietyChanged,
                    ),
                    const SizedBox(height: 14),

                    // Planting date
                    GestureDetector(
                      onTap: _pickPlantingDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Planting Date *',
                            hintText: 'DD/MM/YYYY',
                            prefixIcon: const Icon(
                                Icons.calendar_today_outlined),
                            suffixIcon: const Icon(
                                Icons.arrow_drop_down),
                          ),
                          controller: TextEditingController(
                            text: _plantingDate != null
                                ? _formatDate(_plantingDate)
                                : '',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Harvest date auto-filled
                    AppFlatCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.event_available_outlined,
                            size: 18,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text('Expected Harvest Date',
                                  style: AppTextStyles.label),
                              const SizedBox(height: 2),
                              Text(
                                _formatDate(_harvestDate),
                                style: AppTextStyles.body.copyWith(
                                  color: _harvestDate != null
                                      ? AppColors.primary
                                      : AppColors.textDisabled,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            'Auto • ${CropConstants.seasonDurationDays} days',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Target Yield ──────────────────────────
            SectionHeader(
              title: 'Target Yield',
              icon: Icons.agriculture_outlined,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _targetYield != null
                                ? '${_targetYield!.toStringAsFixed(0)} t/ha'
                                : '— t/ha',
                            style: AppTextStyles.metricLarge
                                .copyWith(color: AppColors.primary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedVariety != null
                                ? 'Default for $_selectedVariety'
                                : 'Select variety to auto-fill',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.textDisabled,
                    ),
                  ],
                ),
              ),
            ),

            // ── Fertiliser Schedule ───────────────────
            SectionHeader(
              title: 'Recommended Fertiliser Schedule',
              icon: Icons.tips_and_updates_outlined,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: CropConstants.fertSchedule.entries
                      .map((e) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    e.key,
                                    style: AppTextStyles.caption,
                                  ),
                                ),
                                Text(
                                  'N:${e.value['N']!.toInt()}  '
                                  'P:${e.value['P']!.toInt()}  '
                                  'K:${e.value['K']!.toInt()} kg/ha',
                                  style: AppTextStyles.caption
                                      .copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),

            // ── Growth Stages info ────────────────────
            SectionHeader(
              title: 'Growth Stages',
              icon: Icons.timeline_outlined,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: CropConstants.stages.map((stage) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.stageColor(stage),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              stage,
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            CropConstants.stageDapRange[stage] ??
                                '',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
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
                label: Text(
                    _loading ? 'Saving...' : 'Start Season'),
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