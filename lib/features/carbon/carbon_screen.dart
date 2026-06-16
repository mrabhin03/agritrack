// features/carbon/carbon_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_header.dart';
import '../crops/providers/crops_provider.dart';
import 'models/emission_model.dart';
import 'providers/carbon_provider.dart';

class CarbonScreen extends ConsumerStatefulWidget {
  const CarbonScreen({super.key});

  @override
  ConsumerState<CarbonScreen> createState() => _CarbonScreenState();
}

class _CarbonScreenState extends ConsumerState<CarbonScreen> {
  bool _showRecords = false;

  @override
  Widget build(BuildContext context) {
    final emissionsAsync = ref.watch(carbonProvider);
    final records = ref.watch(filteredEmissionsProvider);
    final summary = ref.watch(carbonSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: emissionsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) =>
            Center(child: Text('Error: $e', style: AppTextStyles.body)),
        data: (_) => ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            _buildKpiCards(summary),
            SectionHeader(
              title: 'Emission Breakdown',
              icon: Icons.bar_chart_outlined,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: summary.totalCo2eKg > 0
                  ? _EmissionBreakdownChart(summary: summary)
                  : const _NoDataCard(
                      message: 'No emissions logged yet'),
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
                      label: 'Avg Per Hectare',
                      value: summary.avgIntensityPerHa
                          .toStringAsFixed(1),
                      unit: 'kg CO₂e/ha',
                      icon: Icons.landscape_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _IntensityCard(
                      label: 'Records Logged',
                      value: '${summary.recordCount}',
                      unit: 'entries',
                      icon: Icons.receipt_long_outlined,
                    ),
                  ),
                ],
              ),
            ),
            SectionHeader(
              title: 'Emission Records',
              icon: Icons.receipt_long_outlined,
              actionLabel: records.length > 1
                  ? (_showRecords ? 'Hide' : 'Show all')
                  : null,
              onAction: records.length > 1
                  ? () => setState(() => _showRecords = !_showRecords)
                  : null,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            ),
            if (records.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: EmptyState.noEmissions(
                  onAction: () => context.push('/add-emission'),
                ),
              )
            else if (_showRecords)
              ...List.generate(
                records.length,
                (i) => Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: _EmissionRecordCard(record: records[i]),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _EmissionRecordCard(record: records[0]),
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
      ),
      floatingActionButton: _LogEmissionButton(
        onTap: () => context.push('/add-emission'),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildKpiCards(CarbonSummary summary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          // ── Hero card ─────────────────────────────
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
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
                        '${(summary.totalCo2eKg / 1000).toStringAsFixed(2)} tCO₂e',
                        style: AppTextStyles.metricLarge
                            .copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${summary.recordCount} record${summary.recordCount == 1 ? '' : 's'} logged',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                EmissionBadge(isLow: summary.isLowEmissions),
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
                  value: '${summary.n2oCo2eKg.toStringAsFixed(0)} kg',
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
                      '${summary.dieselCo2eKg.toStringAsFixed(0)} kg',
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
                      '${summary.electricityCo2eKg.toStringAsFixed(0)} kg',
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
          Text(value, style: AppTextStyles.h3.copyWith(color: color)),
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

// ── No-data fallback card ─────────────────────────────
class _NoDataCard extends StatelessWidget {
  final String message;
  const _NoDataCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Text(
          message,
          style: AppTextStyles.caption,
        ),
      ),
    );
  }
}

// ── Emission Breakdown Chart (live from CarbonSummary) ───
class _EmissionBreakdownChart extends StatelessWidget {
  final CarbonSummary summary;
  const _EmissionBreakdownChart({required this.summary});

  @override
  Widget build(BuildContext context) {
    final breakdown = [
      {
        'label': 'N₂O (Fertiliser)',
        'value': summary.n2oCo2eKg,
        'color': AppColors.primary,
      },
      {
        'label': 'CO₂ (Diesel)',
        'value': summary.dieselCo2eKg,
        'color': AppColors.warning,
      },
      {
        'label': 'CO₂ (Grid)',
        'value': summary.electricityCo2eKg,
        'color': AppColors.info,
      },
    ];
    final total = summary.totalCo2eKg;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: breakdown.map((b) {
                final value = b['value'] as double;
                final flex = total > 0
                    ? (value / total * 100).round().clamp(0, 100)
                    : 0;
                if (flex == 0) return const SizedBox.shrink();
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
          // Legend
          ...breakdown.map((b) {
            final value = b['value'] as double;
            final pct =
                total > 0 ? (value / total * 100).toStringAsFixed(0) : '0';
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
                    '${value.toStringAsFixed(0)} kg',
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

// ── Emission Record Card (live EmissionModel) ─────────
class _EmissionRecordCard extends ConsumerWidget {
  final EmissionModel record;
  const _EmissionRecordCard({required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final season = ref.watch(seasonByIdProvider(record.seasonId));
    final hasElectricity = record.electricityCo2eKg > 0;
    final hasDiesel = record.dieselCo2eKg > 0;
    final hasN2o = record.n2oCo2eKg > 0;

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
                    Text(
                      season != null
                          ? '${season.variety} season'
                          : 'Season ${record.seasonId}',
                      style: AppTextStyles.h3,
                    ),
                    Text(record.calculatedAtLabel,
                        style: AppTextStyles.caption),
                  ],
                ),
              ),
              AppFlatCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                child: Text(
                  '${record.totalCo2eKg.toStringAsFixed(1)} kg CO₂e',
                  style:
                      AppTextStyles.label.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          // CO2e breakdown chips — dim zero-value sources
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _InputChip(
                icon: Icons.grass_outlined,
                label: 'N₂O: ${record.n2oCo2eKg.toStringAsFixed(1)} kg',
                color: AppColors.primary,
                dimmed: !hasN2o,
              ),
              _InputChip(
                icon: Icons.local_gas_station_outlined,
                label:
                    'Diesel: ${record.dieselCo2eKg.toStringAsFixed(1)} kg',
                color: AppColors.warning,
                dimmed: !hasDiesel,
              ),
              _InputChip(
                icon: Icons.bolt_outlined,
                label:
                    'Grid: ${record.electricityCo2eKg.toStringAsFixed(1)} kg',
                color: AppColors.info,
                dimmed: !hasElectricity,
              ),
            ],
          ),
          if (record.intensityPerHa != null) ...[
            const SizedBox(height: 8),
            Text(
              '${record.intensityPerHaLabel} per hectare',
              style: AppTextStyles.caption,
            ),
          ],
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