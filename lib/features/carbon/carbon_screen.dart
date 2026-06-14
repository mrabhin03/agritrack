// features/carbon/carbon_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_header.dart';

// ── Fake emission data ────────────────────────────────
const _fakeSummary = {
  'totalCO2e': 1240.5,
  'n2oCO2e': 890.2,
  'dieselCO2e': 268.0,
  'electricityCO2e': 82.3,
  'intensityPerHa': 413.5,
  'intensityPerTonne': 32.6,
  'totalAreaHa': 3.0,
  'isLowEmissions': true,
};

const _fakeRecords = [
  {
    'id': 'E001',
    'seasonId': 'S001',
    'farmerName': 'Arun Menon',
    'date': '15/03/2025',
    'nitrogenKg': 50.0,
    'dieselL': 10.0,
    'electricityKwh': 0.0,
    'n2oCO2e': 445.1,
    'dieselCO2e': 26.8,
    'totalCO2e': 471.9,
  },
  {
    'id': 'E002',
    'seasonId': 'S001',
    'farmerName': 'Arun Menon',
    'date': '30/04/2025',
    'nitrogenKg': 50.0,
    'dieselL': 10.0,
    'electricityKwh': 10.0,
    'n2oCO2e': 445.1,
    'dieselCO2e': 26.8,
    'totalCO2e': 480.1,
  },
  {
    'id': 'E003',
    'seasonId': 'S002',
    'farmerName': 'Priya Nair',
    'date': '10/02/2025',
    'nitrogenKg': 25.0,
    'dieselL': 5.0,
    'electricityKwh': 5.0,
    'n2oCO2e': 222.6,
    'dieselCO2e': 13.4,
    'totalCO2e': 240.1,
  },
];

const _breakdown = [
  {'label': 'N₂O (Fertiliser)', 'value': 890.2, 'color': Color(0xFF2D6A4F)},
  {'label': 'CO₂ (Diesel)',     'value': 268.0, 'color': Color(0xFFF4A261)},
  {'label': 'CO₂ (Grid)',       'value': 82.3,  'color': Color(0xFF2196F3)},
];

class CarbonScreen extends StatefulWidget {
  const CarbonScreen({super.key});

  @override
  State<CarbonScreen> createState() => _CarbonScreenState();
}

class _CarbonScreenState extends State<CarbonScreen> {
  bool _showRecords = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          _buildKpiCards(),

          SectionHeader(
            title: 'Emission Breakdown',
            icon: Icons.bar_chart_outlined,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _EmissionBreakdownChart(
              breakdown: _breakdown,
              total: _fakeSummary['totalCO2e'] as double,
            ),
          ),

          SectionHeader(
            title: 'Emission Intensity',
            icon: Icons.speed_outlined,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _IntensityCard(
                    label: 'Per Hectare',
                    value:
                        '${(_fakeSummary['intensityPerHa'] as double).toStringAsFixed(1)}',
                    unit: 'kg CO₂e/ha',
                    icon: Icons.landscape_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _IntensityCard(
                    label: 'Per Tonne',
                    value:
                        '${(_fakeSummary['intensityPerTonne'] as double).toStringAsFixed(1)}',
                    unit: 'kg CO₂e/t',
                    icon: Icons.agriculture_outlined,
                  ),
                ),
              ],
            ),
          ),

          SectionHeader(
            title: 'Emission Records',
            icon: Icons.receipt_long_outlined,
            actionLabel: _showRecords ? 'Hide' : 'Show all',
            onAction: () => setState(() => _showRecords = !_showRecords),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          ),

          if (_fakeRecords.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: EmptyState.noEmissions(),
            )
          else if (_showRecords)
            ...List.generate(
              _fakeRecords.length,
              (i) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _EmissionRecordCard(record: _fakeRecords[i]),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _EmissionRecordCard(record: _fakeRecords[0]),
            ),

          // ── IPCC footnote ─────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    size: 13, color: AppColors.textDisabled),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'IPCC defaults: N₂O = 1.25% of N × 298 GWP · Diesel = 2.68 kg CO₂e/L',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textDisabled),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _LogEmissionButton(
        onTap: () => context.push('/add-emission'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildKpiCards() {
    final isLow = _fakeSummary['isLowEmissions'] as bool;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          // ── Hero card ─────────────────────────────
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Gradient icon container
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.15),
                        AppColors.primary.withOpacity(0.28),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.eco_outlined,
                      color: AppColors.primary, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Emissions', style: AppTextStyles.label),
                      const SizedBox(height: 3),
                      Text(
                        '${((_fakeSummary['totalCO2e'] as double) / 1000).toStringAsFixed(2)} tCO₂e',
                        style: AppTextStyles.metricLarge
                            .copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(_fakeSummary['totalAreaHa'] as double).toStringAsFixed(1)} ha mapped',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                EmissionBadge(isLow: isLow),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // ── Mini KPI row ──────────────────────────
          Row(
            children: [
              Expanded(
                child: _MiniKpiCard(
                  label: 'N₂O',
                  sublabel: 'Fertiliser',
                  value:
                      '${(_fakeSummary['n2oCO2e'] as double).toStringAsFixed(0)} kg',
                  color: AppColors.primary,
                  icon: Icons.grass_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniKpiCard(
                  label: 'CO₂',
                  sublabel: 'Diesel',
                  value:
                      '${(_fakeSummary['dieselCO2e'] as double).toStringAsFixed(0)} kg',
                  color: AppColors.warning,
                  icon: Icons.local_gas_station_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniKpiCard(
                  label: 'CO₂',
                  sublabel: 'Grid',
                  value:
                      '${(_fakeSummary['electricityCO2e'] as double).toStringAsFixed(0)} kg',
                  color: AppColors.info,
                  icon: Icons.bolt_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Custom Log Emission Button ────────────────────────
class _LogEmissionButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogEmissionButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_chart_outlined,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              'Log Emission',
              style: AppTextStyles.label.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mini KPI Card ─────────────────────────────────────
class _MiniKpiCard extends StatelessWidget {
  final String label;
  final String sublabel;
  final String value;
  final Color color;
  final IconData icon;

  const _MiniKpiCard({
    required this.label,
    required this.sublabel,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tinted icon pill
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: AppTextStyles.h3.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.label
                  .copyWith(color: AppColors.textPrimary)),
          Text(sublabel, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

// ── Intensity Card ────────────────────────────────────
class _IntensityCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;

  const _IntensityCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.accent),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: AppTextStyles.h2.copyWith(color: AppColors.primary)),
          Text(unit, style: AppTextStyles.caption),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.label),
        ],
      ),
    );
  }
}

// ── Emission Breakdown Chart ──────────────────────────
class _EmissionBreakdownChart extends StatelessWidget {
  final List<Map<String, dynamic>> breakdown;
  final double total;

  const _EmissionBreakdownChart({
    required this.breakdown,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: breakdown.map((b) {
                final flex = ((b['value'] as double) / total * 100).round();
                return Expanded(
                  flex: flex,
                  child: Container(
                    height: 18,
                    color: b['color'] as Color,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          // Legend — one row per source, cleaner than cramped columns
          ...breakdown.map((b) {
            final pct =
                ((b['value'] as double) / total * 100).toStringAsFixed(0);
            final color = b['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(b['label'] as String,
                      style: AppTextStyles.label
                          .copyWith(color: AppColors.textPrimary)),
                  const Spacer(),
                  Text(
                    '${(b['value'] as double).toStringAsFixed(0)} kg',
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 38,
                    child: Text(
                      '$pct%',
                      style: AppTextStyles.label.copyWith(color: color),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Emission Record Card ──────────────────────────────
class _EmissionRecordCard extends StatelessWidget {
  final Map<String, dynamic> record;
  const _EmissionRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final electricityKwh = record['electricityKwh'] as double;
    final hasElectricity = electricityKwh > 0;

    return AppAccentCard(
      accentColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record['farmerName'] as String,
                        style: AppTextStyles.h3),
                    Text(record['date'] as String,
                        style: AppTextStyles.caption),
                  ],
                ),
              ),
              AppFlatCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                child: Text(
                  '${(record['totalCO2e'] as double).toStringAsFixed(1)} kg CO₂e',
                  style: AppTextStyles.label
                      .copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          // Input chips — always show all three, dim zero values
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _InputChip(
                icon: Icons.grass_outlined,
                label: 'N: ${record['nitrogenKg']} kg',
                color: AppColors.primary,
                dimmed: false,
              ),
              _InputChip(
                icon: Icons.local_gas_station_outlined,
                label: 'Diesel: ${record['dieselL']} L',
                color: AppColors.warning,
                dimmed: false,
              ),
              _InputChip(
                icon: Icons.bolt_outlined,
                label: 'Grid: ${electricityKwh.toStringAsFixed(0)} kWh',
                color: AppColors.info,
                dimmed: !hasElectricity,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Input Chip ────────────────────────────────────────
class _InputChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool dimmed;

  const _InputChip({
    required this.icon,
    required this.label,
    required this.color,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = dimmed ? AppColors.textDisabled : color;
    return AppFlatCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: effectiveColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: effectiveColor),
          ),
        ],
      ),
    );
  }
}