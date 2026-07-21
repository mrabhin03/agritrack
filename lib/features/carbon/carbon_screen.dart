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

// Cap staggered items so a long record list doesn't push the tail
// end's pop-in several seconds out.
const int _maxStaggerItems = 8;

class CarbonScreen extends ConsumerStatefulWidget {
  const CarbonScreen({super.key});

  @override
  ConsumerState<CarbonScreen> createState() => _CarbonScreenState();
}

class _CarbonScreenState extends ConsumerState<CarbonScreen>
    with TickerProviderStateMixin {
  bool _showRecords = false;

  late final AnimationController _entrance;
  late final Animation<double> _kpiReveal;
  late final Animation<double> _breakdownReveal;
  late final Animation<double> _intensityReveal;
  late final Animation<double> _recordsReveal;

  @override
  void initState() {
    super.initState();
    // Kept fast/snappy — matches the plots/farmers screens, not the
    // slower dashboard hero timing.
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _kpiReveal = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    );
    _breakdownReveal = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.2, 0.75, curve: Curves.easeOutCubic),
    );
    _intensityReveal = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
    );
    _recordsReveal = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entrance.forward();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Widget _rise(Animation<double> anim, Widget child, {double dy = 16}) {
    return AnimatedBuilder(
      animation: anim,
      child: child,
      builder: (context, child) {
        final v = anim.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * dy),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final emissionsAsync = ref.watch(carbonProvider);
    final records = ref.watch(filteredEmissionsProvider);
    final summary = ref.watch(carbonSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: emissionsAsync.when(
        loading: () => const Center(child: _CarbonLoader()),
        error: (e, _) =>
            Center(child: Text('Error: $e', style: AppTextStyles.body)),
        data: (_) => ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            _rise(_kpiReveal, _buildKpiCards(summary), dy: -14),
            _rise(
              _breakdownReveal,
              SectionHeader(
                title: 'Emission Breakdown',
                icon: Icons.bar_chart_outlined,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _rise(
                _breakdownReveal,
                summary.totalCo2eKg > 0
                    ? _EmissionBreakdownChart(
                        summary: summary, reveal: _breakdownReveal)
                    : const _NoDataCard(message: 'No emissions logged yet'),
              ),
            ),
            _rise(
              _intensityReveal,
              SectionHeader(
                title: 'Emission Intensity',
                icon: Icons.speed_outlined,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _PopIn(
                      reveal: _intensityReveal,
                      index: 0,
                      total: 2,
                      child: _IntensityCard(
                        label: 'Avg Per Hectare',
                        value: summary.avgIntensityPerHa
                            .toStringAsFixed(1),
                        unit: 'kg CO₂e/ha',
                        icon: Icons.landscape_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PopIn(
                      reveal: _intensityReveal,
                      index: 1,
                      total: 2,
                      child: _IntensityCard(
                        label: 'Records Logged',
                        value: '${summary.recordCount}',
                        unit: 'entries',
                        icon: Icons.receipt_long_outlined,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _rise(
              _recordsReveal,
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
            ),
            if (records.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _rise(
                  _recordsReveal,
                  EmptyState.noEmissions(
                    onAction: () => context.push('/add-emission'),
                  ),
                ),
              )
            else
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _showRecords
                    ? Column(
                        children: List.generate(records.length, (i) {
                          final staggerIndex = i < _maxStaggerItems
                              ? i
                              : _maxStaggerItems - 1;
                          final staggerTotal =
                              records.length.clamp(1, _maxStaggerItems);
                          return Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 10),
                            child: _PopIn(
                              reveal: _recordsReveal,
                              index: staggerIndex,
                              total: staggerTotal,
                              child: _ShineSweep(
                                delay: Duration(
                                    milliseconds: 420 +
                                        staggerIndex.clamp(0, 6) * 80),
                                child: _EmissionRecordCard(
                                    record: records[i]),
                              ),
                            ),
                          );
                        }),
                      )
                    : Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: _rise(
                          _recordsReveal,
                          _ShineSweep(
                            delay: const Duration(milliseconds: 420),
                            child: _EmissionRecordCard(record: records[0]),
                          ),
                        ),
                      ),
              ),
            // ── IPCC footnote ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _rise(
                _recordsReveal,
                Row(
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
          _ShineSweep(
            delay: const Duration(milliseconds: 260),
            child: AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _BreathingIcon(
                    icon: Icons.eco_outlined,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Emissions', style: AppTextStyles.label),
                        const SizedBox(height: 3),
                        TweenAnimationBuilder<double>(
                          tween: Tween(
                              begin: 0, end: summary.totalCo2eKg / 1000),
                          duration: const Duration(milliseconds: 0),
                          curve: Curves.easeOutCubic,
                          builder: (context, v, _) => Text(
                            '${v.toStringAsFixed(2)} tCO₂e',
                            style: AppTextStyles.metricLarge
                                .copyWith(color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${summary.recordCount} record${summary.recordCount == 1 ? '' : 's'} logged',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOutBack,
                    builder: (context, v, child) => Transform.scale(
                        scale: v.clamp(0.0, 1.2), child: child),
                    child: EmissionBadge(isLow: summary.isLowEmissions),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // ── Mini KPI row ──────────────────────────
          Row(
            children: [
              Expanded(
                child: _MiniPopIn(
                  index: 0,
                  child: _MiniKpiCard(
                    label: 'N₂O',
                    sublabel: 'Fertiliser',
                    value: summary.n2oCo2eKg,
                    color: AppColors.primary,
                    icon: Icons.grass_outlined,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniPopIn(
                  index: 1,
                  child: _MiniKpiCard(
                    label: 'CO₂',
                    sublabel: 'Diesel',
                    value: summary.dieselCo2eKg,
                    color: AppColors.warning,
                    icon: Icons.local_gas_station_outlined,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniPopIn(
                  index: 2,
                  child: _MiniKpiCard(
                    label: 'CO₂',
                    sublabel: 'Grid',
                    value: summary.electricityCo2eKg,
                    color: AppColors.info,
                    icon: Icons.bolt_outlined,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Small pop-in used for the mini KPI row — quick, staggered by index.
class _MiniPopIn extends StatelessWidget {
  const _MiniPopIn({required this.child, required this.index});
  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 380 + index * 90),
      curve: Curves.easeOutBack,
      builder: (context, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - v).clamp(0.0, 1.0) * 14),
          child: Transform.scale(scale: v.clamp(0.0, 1.1), child: child),
        ),
      ),
      child: child,
    );
  }
}

// Breathing pulse loader while emissions load.
class _CarbonLoader extends StatefulWidget {
  const _CarbonLoader();
  @override
  State<_CarbonLoader> createState() => _CarbonLoaderState();
}

class _CarbonLoaderState extends State<_CarbonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_c.value);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: 0.9 + t * 0.15,
              child: Icon(Icons.eco_outlined,
                  size: 38,
                  color: AppColors.primary.withOpacity(0.5 + t * 0.5)),
            ),
            const SizedBox(height: 10),
            Text('Loading emissions…', style: AppTextStyles.caption),
          ],
        );
      },
    );
  }
}

// ── Pop-in wrapper: fade + slide + elastic scale, sliced into
// per-item stagger windows off a parent reveal animation.
class _PopIn extends StatelessWidget {
  const _PopIn({
    required this.reveal,
    required this.index,
    required this.total,
    required this.child,
  });
  final Animation<double> reveal;
  final int index;
  final int total;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final safeTotal = total <= 0 ? 1 : total;
    final start = (index / safeTotal).clamp(0.0, 1.0);
    final end = ((index + 1) / safeTotal).clamp(0.0, 1.0);
    final local = CurvedAnimation(
      parent: reveal,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    );
    final fade = CurvedAnimation(
      parent: reveal,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    return AnimatedBuilder(
      animation: reveal,
      child: child,
      builder: (context, child) {
        final v = local.value;
        final opacity = fade.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * 16),
            child: Transform.scale(
              scale: 0.9 + v * 0.1,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

// One-shot diagonal light sweep, played once after a delay.
class _ShineSweep extends StatefulWidget {
  const _ShineSweep({
    required this.child,
    required this.delay,
    this.borderRadius = 14,
  });
  final Widget child;
  final Duration delay;
  final double borderRadius;

  @override
  State<_ShineSweep> createState() => _ShineSweepState();
}

class _ShineSweepState extends State<_ShineSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth.isFinite ? constraints.maxWidth : 0.0;
          return Stack(
            children: [
              widget.child,
              if (w > 0)
                AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) {
                    final dx = -w * 0.6 + _c.value * (w * 1.6);
                    return Positioned(
                      top: -20,
                      bottom: -20,
                      left: dx,
                      width: w * 0.3,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: (1 - _c.value).clamp(0.0, 1.0) * 0.35,
                          child: Transform.rotate(
                            angle: -0.35,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.white.withOpacity(0),
                                    Colors.white.withOpacity(0.45),
                                    Colors.white.withOpacity(0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

// Slow, continuous scale+rotate pulse for a hero icon badge — ambient,
// not part of the entrance timing.
class _BreathingIcon extends StatefulWidget {
  const _BreathingIcon({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  State<_BreathingIcon> createState() => _BreathingIconState();
}

class _BreathingIconState extends State<_BreathingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final scale = 1.0 + _c.value * 0.06;
        return Transform.scale(
          scale: scale,
          child: Transform.rotate(
            angle: _c.value * 0.05,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: [
                    widget.color.withOpacity(0.15 + _c.value * 0.05),
                    widget.color.withOpacity(0.28 + _c.value * 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(widget.icon, color: widget.color, size: 26),
            ),
          ),
        );
      },
    );
  }
}

// ── Reusable press-scale wrapper ──────────────────────
class _PressableScale extends StatefulWidget {
  const _PressableScale({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  double _scale = 1.0;

  void _setScale(double s) => setState(() => _scale = s);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setScale(0.94),
      onTapUp: (_) => _setScale(1.0),
      onTapCancel: () => _setScale(1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// Slow vertical bob — keeps a small icon feeling gently "alive" at rest.
class _BobbingIcon extends StatefulWidget {
  const _BobbingIcon({required this.child});
  final Widget child;

  @override
  State<_BobbingIcon> createState() => _BobbingIconState();
}

class _BobbingIconState extends State<_BobbingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final dy = (0.5 -
                (0.5 - _c.value).abs()) *
            4.0 -
            1.0;
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
    );
  }
}

// ── Custom Log Emission Button (glow + bob, matches Add Plot button) ──
class _LogEmissionButton extends StatefulWidget {
  final VoidCallback onTap;
  const _LogEmissionButton({required this.onTap});

  @override
  State<_LogEmissionButton> createState() => _LogEmissionButtonState();
}

class _LogEmissionButtonState extends State<_LogEmissionButton>
    with TickerProviderStateMixin {
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _glow,
        builder: (context, child) {
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary
                      .withOpacity(0.28 + _glow.value * 0.15),
                  blurRadius: 14 + _glow.value * 8,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: child,
          );
        },
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BobbingIcon(
                child: const Icon(Icons.add_chart_outlined,
                    color: Colors.white, size: 20),
              ),
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
      ),
    );
  }
}

// ── Mini KPI Card (with count-up value) ───────────────
class _MiniKpiCard extends StatelessWidget {
  final String label;
  final String sublabel;
  final double value;
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
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Text('${v.toStringAsFixed(0)} kg',
                style: AppTextStyles.h3.copyWith(color: color)),
          ),
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

// ── Emission Breakdown Chart — the bar now fills in on load, each
// segment growing outward in sequence, and the legend rows/percentages
// count up alongside it instead of appearing static. ──────────────
class _EmissionBreakdownChart extends StatefulWidget {
  final CarbonSummary summary;
  final Animation<double> reveal;
  const _EmissionBreakdownChart(
      {required this.summary, required this.reveal});

  @override
  State<_EmissionBreakdownChart> createState() =>
      _EmissionBreakdownChartState();
}

class _EmissionBreakdownChartState extends State<_EmissionBreakdownChart>
    with SingleTickerProviderStateMixin {
  // Drives the bar-fill sweep. Kicked off once the section's reveal
  // animation passes its start threshold, so the bar fills right as
  // the card fades into view rather than before or long after.
  late final AnimationController _fill;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _fill = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    widget.reveal.addListener(_maybeStart);
    _maybeStart();
  }

  void _maybeStart() {
    if (!_started && widget.reveal.value > 0.05) {
      _started = true;
      _fill.forward();
    }
  }

  @override
  void dispose() {
    widget.reveal.removeListener(_maybeStart);
    _fill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
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
    final fractions = breakdown
        .map((b) => total > 0 ? (b['value'] as double) / total : 0.0)
        .toList();

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── Stacked bar: segments cascade in left-to-right ──
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fullWidth = constraints.maxWidth;
                return SizedBox(
                  height: 18,
                  width: fullWidth,
                  child: AnimatedBuilder(
                    animation: _fill,
                    builder: (context, _) {
                      return Row(
                        children: List.generate(breakdown.length, (i) {
                          final frac = fractions[i];
                          if (frac <= 0) return const SizedBox.shrink();
                          // Stagger each segment's own growth within
                          // the shared fill controller.
                          final start = i * 0.15;
                          final end = (start + 0.7).clamp(0.0, 1.0);
                          final local = Interval(start, end,
                                  curve: Curves.easeOutCubic)
                              .transform(_fill.value.clamp(0.0, 1.0));
                          return Container(
                            width: fullWidth * frac * local,
                            height: 18,
                            color: breakdown[i]['color'] as Color,
                          );
                        }),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          // ── Legend, staggered pop-in with count-up % and kg ──
          ...List.generate(breakdown.length, (i) {
            final b = breakdown[i];
            final value = b['value'] as double;
            final pct = total > 0 ? (value / total * 100) : 0.0;
            final color = b['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AnimatedBuilder(
                animation: _fill,
                builder: (context, child) {
                  final start = 0.1 + i * 0.12;
                  final end = (start + 0.5).clamp(0.0, 1.0);
                  final v = Interval(start, end, curve: Curves.easeOut)
                      .transform(_fill.value.clamp(0.0, 1.0));
                  return Opacity(
                    opacity: v,
                    child: Transform.translate(
                      offset: Offset((1 - v) * -12, 0),
                      child: child,
                    ),
                  );
                },
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
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: value),
                      duration: const Duration(milliseconds: 750),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => Text(
                        '${v.toStringAsFixed(0)} kg',
                        style: AppTextStyles.label
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 38,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: pct),
                        duration: const Duration(milliseconds: 750),
                        curve: Curves.easeOutCubic,
                        builder: (context, v, _) => Text(
                          '${v.toStringAsFixed(0)}%',
                          style: AppTextStyles.label.copyWith(color: color),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),
                  ],
                ),
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
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: record.totalCo2eKg),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => Text(
                    '${v.toStringAsFixed(1)} kg CO₂e',
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.primary),
                  ),
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