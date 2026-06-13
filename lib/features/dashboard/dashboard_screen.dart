// features/dashboard/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/loading_overlay.dart';

// ── Temporary hardcoded provider (replaced in Phase 6) ──
final _checkInProvider =
    StateNotifierProvider<_CheckInNotifier, _CheckInState>(
  (ref) => _CheckInNotifier(),
);

class _CheckInState {
  final bool isCheckedIn;
  final String? time;
  const _CheckInState({this.isCheckedIn = false, this.time});
}

class _CheckInNotifier extends StateNotifier<_CheckInState> {
  _CheckInNotifier() : super(const _CheckInState());

  void checkIn() {
    final now = DateFormat('hh:mm a').format(DateTime.now());
    state = _CheckInState(isCheckedIn: true, time: now);
  }

  void checkOut() {
    state = const _CheckInState();
  }
}

// ── Hardcoded KPIs (replaced with Supabase view in Phase 8) ─
class _Kpis {
  static const int totalFarmers    = 128;
  static const int plotsMapped     = 214;
  static const double totalAreaHa  = 144.2; // 356.8 acres
  static const int activeSeasons   = 5;
  static const int activeCrops     = 2;
  static const double totalCo2eT   = -1.2; // net tCO2e
}

// ── Screen ────────────────────────────────────────────────
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkIn = ref.watch(_checkInProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── KPI Section ────────────────────────────
              const SectionHeader(
                title: 'Overview',
                icon: Icons.bar_chart_outlined,
                padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
              ),
              _KpiGrid(),

              // ── Today's Field Activity ─────────────────
              const SectionHeader(
                title: "Today's Field Activity",
                icon: Icons.today_outlined,
                padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
              ),
              _CheckInCard(checkIn: checkIn),

              // ── Quick Actions ──────────────────────────
              const SectionHeader(
                title: 'Quick Actions',
                icon: Icons.bolt_outlined,
                padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
              ),
              _QuickActions(),

              // ── Plot Overview teaser ───────────────────
              const SectionHeader(
                title: 'Plot Overview',
                icon: Icons.map_outlined,
                actionLabel: 'View map',
                padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
              ),
              _PlotOverviewTeaser(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── KPI grid: 2-column, 3 rows ────────────────────────────
class _KpiGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final areaAcres = (_Kpis.totalAreaHa * 2.471).toStringAsFixed(1);
    final co2Label  = _Kpis.totalCo2eT < 0
        ? '${_Kpis.totalCo2eT} tCO₂e (Net)'
        : '${_Kpis.totalCo2eT} tCO₂e';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Row 1: Farmers + Plots
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Active farmers',
                  value: '${_Kpis.totalFarmers}',
                  icon: Icons.people_outline,
                  iconColor: AppColors.primary,
                  iconBgColor: AppColors.successBg,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Geo-tagged plots',
                  value: '${_Kpis.plotsMapped}',
                  icon: Icons.location_on_outlined,
                  iconColor: AppColors.info,
                  iconBgColor: AppColors.infoBg,
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Area + Crops/Season
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Mapped crop area',
                  value: '$areaAcres acres',
                  icon: Icons.terrain_outlined,
                  iconColor: AppColors.warning,
                  iconBgColor: AppColors.warningBg,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Crops / Season',
                  value:
                      '${_Kpis.activeSeasons} crops  ${_Kpis.activeCrops} season',
                  icon: Icons.grass_outlined,
                  iconColor: AppColors.stagePlanting,
                  iconBgColor: AppColors.stagePlantingBg,
                  badge: 'Low Emissions',
                  badgeVariant: BadgeVariant.success,
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 3: Carbon (full width for prominence)
          StatCard(
            label: 'Carbon Footprint',
            value: co2Label,
            icon: Icons.eco_outlined,
            iconColor: AppColors.primary,
            iconBgColor: AppColors.successBg,
            badge: 'Low Emissions',
            badgeVariant: BadgeVariant.success,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

// ── Check In card ─────────────────────────────────────────
class _CheckInCard extends StatelessWidget {
  const _CheckInCard({required this.checkIn});

  final _CheckInState checkIn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left: location + status ──────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location row
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Kothamangalam, Kerala',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Status row
                  Row(
                    children: [
                      Icon(
                        checkIn.isCheckedIn
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 16,
                        color: checkIn.isCheckedIn
                            ? AppColors.success
                            : AppColors.textDisabled,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        checkIn.isCheckedIn
                            ? 'Checked in at ${checkIn.time}'
                            : 'Not checked in',
                        style: AppTextStyles.body.copyWith(
                          color: checkIn.isCheckedIn
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Buttons row
                  Consumer(
                    builder: (context, ref, _) => Row(
                      children: [
                        SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            onPressed: checkIn.isCheckedIn
                                ? null
                                : () => ref
                                    .read(_checkInProvider.notifier)
                                    .checkIn(),
                            child: const Text('Check In'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 40,
                          child: OutlinedButton(
                            onPressed: checkIn.isCheckedIn
                                ? () => ref
                                    .read(_checkInProvider.notifier)
                                    .checkOut()
                                : null,
                            child: const Text('Check Out'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Right: field photo ───────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 90,
                height: 90,
                color: AppColors.stagePlantingBg,
                child: const Icon(
                  Icons.grass,
                  size: 40,
                  color: AppColors.stagePlanting,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick action cards ────────────────────────────────────
class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.people_outline,
        label: 'Farmers List',
        sublabel: 'View and Manage',
        iconColor: AppColors.primary,
        iconBg: AppColors.successBg,
        onTap: () => context.go('/farmers'),
      ),
      _QuickAction(
        icon: Icons.person_add_outlined,
        label: 'Add Farmer',
        sublabel: 'Register New Farmer',
        iconColor: AppColors.info,
        iconBg: AppColors.infoBg,
        onTap: () => context.push('/add-farmer'),
      ),
      _QuickAction(
        icon: Icons.grass_outlined,
        label: 'Crops & Season',
        sublabel: 'View Crop Details',
        iconColor: AppColors.stagePlanting,
        iconBg: AppColors.stagePlantingBg,
        onTap: () => context.go('/crops'),
      ),
      _QuickAction(
        icon: Icons.eco_outlined,
        label: 'Carbon Footprint',
        sublabel: 'Track Emissions',
        iconColor: AppColors.stageHarvest,
        iconBg: AppColors.stageHarvestBg,
        onTap: () => context.go('/carbon'),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.6,
        children: actions
            .map((a) => _QuickActionCard(action: a))
            .toList(),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.iconColor,
    required this.iconBg,
    required this.onTap,
  });
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action});
  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: action.onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: action.iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(action.icon, size: 18, color: action.iconColor),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                action.label,
                style: AppTextStyles.labelLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                action.sublabel,
                style: AppTextStyles.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Plot overview teaser ──────────────────────────────────
class _PlotOverviewTeaser extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: () => context.go('/plots'),
        child: Stack(
          children: [
            // ── Map placeholder background ───────────
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.stagePlantingBg,
                    AppColors.successBg,
                    AppColors.stageGrowthBg,
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.map_outlined,
                  size: 48,
                  color: AppColors.primary.withOpacity(0.3),
                ),
              ),
            ),

            // ── Stats overlay (bottom-right) ─────────
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _OverlayRow(
                      icon: Icons.location_on_outlined,
                      text: 'Plots:  ${_Kpis.plotsMapped}',
                    ),
                    const SizedBox(height: 4),
                    _OverlayRow(
                      icon: Icons.terrain_outlined,
                      text: 'Area:  ${(_Kpis.totalAreaHa * 2.471).toStringAsFixed(1)} acres',
                    ),
                  ],
                ),
              ),
            ),

            // ── Tap hint ────────────────────────────
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.open_in_full,
                      size: 12,
                      color: AppColors.textOnPrimary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Open map',
                      style: AppTextStyles.buttonSmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlayRow extends StatelessWidget {
  const _OverlayRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.primary),
        const SizedBox(width: 5),
        Text(text, style: AppTextStyles.caption.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        )),
      ],
    );
  }
}