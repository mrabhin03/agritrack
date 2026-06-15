// features/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_card.dart';
import 'providers/dashboard_provider.dart';

// ── Screen ────────────────────────────────────────────────
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkIn = ref.watch(checkInProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero banner (greeting + check-in) ─────
            _HeroBanner(checkIn: checkIn),
            // ── KPI grid ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Row(
                children: [
                  const Icon(Icons.bar_chart_outlined,
                      size: 15, color: AppColors.textDisabled),
                  const SizedBox(width: 6),
                  Text('Overview',
                      style: AppTextStyles.label
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const _KpiGrid(),
            // ── Quick actions ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
              child: Row(
                children: [
                  const Icon(Icons.bolt_outlined,
                      size: 15, color: AppColors.textDisabled),
                  const SizedBox(width: 6),
                  Text('Quick Actions',
                      style: AppTextStyles.label
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const _QuickActions(),
            // ── Plot teaser ────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
              child: Row(
                children: [
                  const Icon(Icons.map_outlined,
                      size: 15, color: AppColors.textDisabled),
                  const SizedBox(width: 6),
                  Text('Plot Overview',
                      style: AppTextStyles.label
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const _PlotOverviewTeaser(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Hero Banner ───────────────────────────────────────────
class _HeroBanner extends ConsumerWidget {
  const _HeroBanner({required this.checkIn});
  final CheckInState checkIn;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _todayLabel =>
      DateFormat('EEEE, d MMM yyyy').format(DateTime.now());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F), Color(0xFF40916C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting,
                          style: AppTextStyles.body.copyWith(
                            color: Colors.white.withOpacity(0.75),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Field Officer',
                          style: AppTextStyles.h1.copyWith(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 12, color: Colors.white54),
                            const SizedBox(width: 4),
                            Text(
                              _todayLabel,
                              style: AppTextStyles.caption
                                  .copyWith(color: Colors.white54),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Location badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          'Kothamangalam',
                          style: AppTextStyles.caption
                              .copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Check-in card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    // Status dot
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: checkIn.isCheckedIn
                            ? const Color(0xFF52B788)
                            : Colors.white38,
                        boxShadow: checkIn.isCheckedIn
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF52B788)
                                      .withOpacity(0.5),
                                  blurRadius: 6,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        checkIn.isCheckedIn
                            ? 'Checked in · ${checkIn.time}'
                            : 'Not checked in yet',
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // Check in / out button
                    GestureDetector(
                      onTap: checkIn.isCheckedIn
                          ? () => ref
                              .read(checkInProvider.notifier)
                              .checkOut()
                          : () =>
                              ref.read(checkInProvider.notifier).checkIn(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: checkIn.isCheckedIn
                              ? Colors.white.withOpacity(0.15)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          checkIn.isCheckedIn ? 'Check Out' : 'Check In',
                          style: AppTextStyles.label.copyWith(
                            color: checkIn.isCheckedIn
                                ? Colors.white
                                : AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── KPI Grid ──────────────────────────────────────────────
class _KpiGrid extends ConsumerWidget {
  const _KpiGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpis = ref.watch(dashboardKpisProvider);

    final areaAcres = kpis.totalAreaAcres.toStringAsFixed(1);
    final co2eT = kpis.totalCo2eTonnes.toStringAsFixed(1);
    final isNetNegative = kpis.totalCo2eKg <= 0;

    final items = [
      _KpiItem(
        value: '${kpis.totalFarmers}',
        label: 'Farmers',
        icon: Icons.people_outline,
        iconColor: AppColors.primary,
        iconBg: AppColors.successBg,
      ),
      _KpiItem(
        value: '${kpis.totalPlots}',
        label: 'Plots',
        icon: Icons.location_on_outlined,
        iconColor: AppColors.info,
        iconBg: AppColors.infoBg,
      ),
      _KpiItem(
        value: areaAcres,
        label: 'Acres',
        icon: Icons.terrain_outlined,
        iconColor: AppColors.warning,
        iconBg: AppColors.warningBg,
      ),
      _KpiItem(
        value: '${kpis.activeSeasons}',
        label: 'Seasons',
        icon: Icons.grass_outlined,
        iconColor: AppColors.stagePlanting,
        iconBg: AppColors.stagePlantingBg,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 4 mini KPI cards
          Row(
            children: items
                .map((k) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            right: k == items.last ? 0 : 10),
                        child: _KpiCard(item: k),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 10),
          // Carbon — full width hero KPI
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
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
                      color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Carbon Footprint',
                          style: AppTextStyles.caption),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            co2eT,
                            style: AppTextStyles.h1.copyWith(
                              color: isNetNegative
                                  ? AppColors.primary
                                  : AppColors.warning,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 3, left: 4),
                            child: Text(
                              'tCO₂e net',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppStatusBadge(
                  label: kpis.isLowEmissions
                      ? 'Low Emissions'
                      : 'High Emissions',
                  variant: kpis.isLowEmissions
                      ? BadgeVariant.success
                      : BadgeVariant.warning,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiItem {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  const _KpiItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.item});
  final _KpiItem item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: item.iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, size: 16, color: item.iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            item.value,
            style: AppTextStyles.h2.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(item.label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

// ── Quick Actions ─────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.people_outline,
        label: 'Farmers',
        sublabel: 'View & manage',
        iconColor: AppColors.primary,
        iconBg: AppColors.successBg,
        onTap: () => context.go('/farmers'),
      ),
      _QuickAction(
        icon: Icons.person_add_outlined,
        label: 'Add Farmer',
        sublabel: 'Register new',
        iconColor: AppColors.info,
        iconBg: AppColors.infoBg,
        onTap: () => context.push('/add-farmer'),
      ),
      _QuickAction(
        icon: Icons.grass_outlined,
        label: 'Crops',
        sublabel: 'Seasons & stages',
        iconColor: AppColors.stagePlanting,
        iconBg: AppColors.stagePlantingBg,
        onTap: () => context.go('/crops'),
      ),
      _QuickAction(
        icon: Icons.eco_outlined,
        label: 'Carbon',
        sublabel: 'Track emissions',
        iconColor: AppColors.stageHarvest,
        iconBg: AppColors.stageHarvestBg,
        onTap: () => context.go('/carbon'),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.75,
        children: actions.map((a) => _QuickActionCard(action: a)).toList(),
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: action.iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(action.icon, size: 20, color: action.iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  action.label,
                  style: AppTextStyles.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  action.sublabel,
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 12, color: AppColors.textDisabled),
        ],
      ),
    );
  }
}

// ── Plot Overview Teaser ──────────────────────────────────
class _PlotOverviewTeaser extends ConsumerWidget {
  const _PlotOverviewTeaser();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpis = ref.watch(dashboardKpisProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => context.go('/plots'),
        child: Container(
          height: 170,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative blobs
              Positioned(
                right: -20,
                top: -10,
                child: Opacity(
                  opacity: 0.15,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFF74C69D),
                      borderRadius: BorderRadius.circular(60),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 40,
                bottom: -20,
                child: Opacity(
                  opacity: 0.10,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF52B788),
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 80,
                top: 20,
                child: Opacity(
                  opacity: 0.08,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.satellite_alt_outlined,
                                  size: 12, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text('Live Map',
                                  style: AppTextStyles.caption
                                      .copyWith(color: Colors.white70)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.open_in_full,
                              size: 13, color: Colors.white),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Live stats from provider
                    Row(
                      children: [
                        _TeaserStat(
                          value: '${kpis.totalPlots}',
                          label: 'Plots mapped',
                        ),
                        const SizedBox(width: 24),
                        _TeaserStat(
                          value: kpis.totalAreaAcres.toStringAsFixed(0),
                          label: 'Acres covered',
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Open map',
                                style: AppTextStyles.label.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded,
                                  size: 13, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeaserStat extends StatelessWidget {
  const _TeaserStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTextStyles.h2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: Colors.white60),
        ),
      ],
    );
  }
}