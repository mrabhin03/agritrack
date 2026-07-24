// features/dashboard/dashboard_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_card.dart';
import 'providers/dashboard_provider.dart';


String Version='3.05';



String _compactNumber(double value, int decimals) {
  final abs = value.abs();
  if (abs == 0) return '0';
  String format(double v) =>
      v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(decimals);

  if (abs >= 1e303) return '${format(value / 1e303)}Ct';
  if (abs >= 1e300) return '${format(value / 1e300)}Nct';
  if (abs >= 1e297) return '${format(value / 1e297)}Oct';
  if (abs >= 1e294) return '${format(value / 1e294)}Sct';
  if (abs >= 1e291) return '${format(value / 1e291)}Sxct';
  if (abs >= 1e288) return '${format(value / 1e288)}Qct';
  if (abs >= 1e285) return '${format(value / 1e285)}Qtct';
  if (abs >= 1e282) return '${format(value / 1e282)}Trct';
  if (abs >= 1e279) return '${format(value / 1e279)}Doct';
  if (abs >= 1e276) return '${format(value / 1e276)}Udct';
  if (abs >= 1e273) return '${format(value / 1e273)}Dcct';
  if (abs >= 1e270) return '${format(value / 1e270)}Noct';
  if (abs >= 1e267) return '${format(value / 1e267)}Occt';
  if (abs >= 1e264) return '${format(value / 1e264)}Spct';
  if (abs >= 1e261) return '${format(value / 1e261)}Sxct2';
  if (abs >= 1e258) return '${format(value / 1e258)}Qtct2';
  if (abs >= 1e255) return '${format(value / 1e255)}Qdct';
  if (abs >= 1e252) return '${format(value / 1e252)}Trct2';
  if (abs >= 1e249) return '${format(value / 1e249)}Doct2';
  if (abs >= 1e246) return '${format(value / 1e246)}Udct2';
  if (abs >= 1e243) return '${format(value / 1e243)}Dcct2';
  if (abs >= 1e240) return '${format(value / 1e240)}Noct2';
  if (abs >= 1e237) return '${format(value / 1e237)}Occt2';
  if (abs >= 1e234) return '${format(value / 1e234)}Spct2';
  if (abs >= 1e231) return '${format(value / 1e231)}Sxct3';
  if (abs >= 1e228) return '${format(value / 1e228)}Qtct3';
  if (abs >= 1e225) return '${format(value / 1e225)}Qnct';
  if (abs >= 1e222) return '${format(value / 1e222)}Trct3';
  if (abs >= 1e219) return '${format(value / 1e219)}Doct3';
  if (abs >= 1e216) return '${format(value / 1e216)}Udct3';
  if (abs >= 1e213) return '${format(value / 1e213)}Dcct3';
  if (abs >= 1e210) return '${format(value / 1e210)}Noct3';
  if (abs >= 1e207) return '${format(value / 1e207)}Occt3';
  if (abs >= 1e204) return '${format(value / 1e204)}Spct3';
  if (abs >= 1e201) return '${format(value / 1e201)}Sxct4';
  if (abs >= 1e198) return '${format(value / 1e198)}Qtct4';
  if (abs >= 1e195) return '${format(value / 1e195)}Qnct2';
  if (abs >= 1e192) return '${format(value / 1e192)}Trct4';
  if (abs >= 1e189) return '${format(value / 1e189)}Doct4';
  if (abs >= 1e186) return '${format(value / 1e186)}Udct4';
  if (abs >= 1e183) return '${format(value / 1e183)}Dcct4';
  if (abs >= 1e180) return '${format(value / 1e180)}Noct4';
  if (abs >= 1e177) return '${format(value / 1e177)}Occt4';
  if (abs >= 1e174) return '${format(value / 1e174)}Spct4';
  if (abs >= 1e171) return '${format(value / 1e171)}Sxct5';
  if (abs >= 1e168) return '${format(value / 1e168)}Qtct5';
  if (abs >= 1e165) return '${format(value / 1e165)}Qnct3';
  if (abs >= 1e162) return '${format(value / 1e162)}Trct5';
  if (abs >= 1e159) return '${format(value / 1e159)}Doct5';
  if (abs >= 1e156) return '${format(value / 1e156)}Udct5';
  if (abs >= 1e153) return '${format(value / 1e153)}Dcct5';
  if (abs >= 1e150) return '${format(value / 1e150)}Noct5';
  if (abs >= 1e147) return '${format(value / 1e147)}Occt5';
  if (abs >= 1e144) return '${format(value / 1e144)}Spct5';
  if (abs >= 1e141) return '${format(value / 1e141)}Sxct6';
  if (abs >= 1e138) return '${format(value / 1e138)}Qtct6';
  if (abs >= 1e135) return '${format(value / 1e135)}Qnct4';
  if (abs >= 1e132) return '${format(value / 1e132)}Trct6';
  if (abs >= 1e129) return '${format(value / 1e129)}Doct6';
  if (abs >= 1e126) return '${format(value / 1e126)}Udct6';
  if (abs >= 1e123) return '${format(value / 1e123)}Dcct6';
  if (abs >= 1e120) return '${format(value / 1e120)}Noct6';
  if (abs >= 1e117) return '${format(value / 1e117)}Occt6';
  if (abs >= 1e114) return '${format(value / 1e114)}Spct6';
  if (abs >= 1e111) return '${format(value / 1e111)}Sxct7';
  if (abs >= 1e108) return '${format(value / 1e108)}Qtct7';
  if (abs >= 1e105) return '${format(value / 1e105)}Qnct5';
  if (abs >= 1e102) return '${format(value / 1e102)}Trct7';
  if (abs >= 1e100) return '${format(value / 1e100)}Gg';
  if (abs >= 1e63)  return '${format(value / 1e63)}Vg';
  if (abs >= 1e60)  return '${format(value / 1e60)}Nvg';
  if (abs >= 1e57)  return '${format(value / 1e57)}Og';
  if (abs >= 1e54)  return '${format(value / 1e54)}Spd';
  if (abs >= 1e51)  return '${format(value / 1e51)}Sxd';
  if (abs >= 1e48)  return '${format(value / 1e48)}Qnd';
  if (abs >= 1e45)  return '${format(value / 1e45)}Qtd';
  if (abs >= 1e42)  return '${format(value / 1e42)}Trd';
  if (abs >= 1e39)  return '${format(value / 1e39)}Dod';
  if (abs >= 1e36)  return '${format(value / 1e36)}Ud';
  if (abs >= 1e33)  return '${format(value / 1e33)}Dc';
  if (abs >= 1e30)  return '${format(value / 1e30)}No';
  if (abs >= 1e27)  return '${format(value / 1e27)}Oc';
  if (abs >= 1e24)  return '${format(value / 1e24)}Sp';
  if (abs >= 1e21)  return '${format(value / 1e21)}Sx';
  if (abs >= 1e18)  return '${format(value / 1e18)}Qt';
  if (abs >= 1e15)  return '${format(value / 1e15)}P';
  if (abs >= 1e12)  return '${format(value / 1e12)}T';
  if (abs >= 1e9)   return '${format(value / 1e9)}B';
  if (abs >= 1e6)   return '${format(value / 1e6)}M';
  if (abs >= 1e3)   return '${format(value / 1e3)}K';
  return value.toStringAsFixed(decimals);
}
// ── Screen ────────────────────────────────────────────────
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  late final Animation<double> _heroAnim;
  late final Animation<double> _overviewAnim;
  late final Animation<double> _actionsAnim;
  late final Animation<double> _plotAnim;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    );

    _heroAnim = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
    );
    _overviewAnim = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.15, 0.65, curve: Curves.easeOutCubic),
    );
    _actionsAnim = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
    );
    _plotAnim = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
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

  Widget _rise(Animation<double> anim, Widget child) {
    return AnimatedBuilder(
      animation: anim,
      child: child,
      builder: (context, child) {
        final v = anim.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * 24),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final checkIn = ref.watch(checkInProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedBuilder(
              animation: _heroAnim,
              child: _HeroBanner(checkIn: checkIn),
              builder: (context, child) {
                final v = _heroAnim.value.clamp(0.0, 1.0);
                return Opacity(
                  opacity: v,
                  child: Transform.translate(
                    offset: Offset(0, (1 - v) * -20),
                    child: child,
                  ),
                );
              },
            ),
            _SectionHeader(
              icon: Icons.bar_chart_outlined,
              label: 'Overview',
              reveal: _overviewAnim,
            ),
            const SizedBox(height: 12),
            _KpiGrid(reveal: _overviewAnim),
            _SectionHeader(
              icon: Icons.bolt_outlined,
              label: 'Quick Actions',
              reveal: _actionsAnim,
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
            ),
            _QuickActions(reveal: _actionsAnim),
            _SectionHeader(
              icon: Icons.map_outlined,
              label: 'Plot Overview',
              reveal: _plotAnim,
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
            ),
            _PlotOverviewTeaser(reveal: _plotAnim),
            const SizedBox(height: 40),

Padding(
  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
  child: Column(
    children: [
      const Divider(height: 1, thickness: 0.5),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.eco_outlined, size: 13, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            Version,
            style: AppTextStyles.caption.copyWith(
              fontFeatures: [const FontFeature.tabularFigures()],
              letterSpacing: 0.5,
              color: AppColors.textDisabled,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 3, height: 3,
            decoration: BoxDecoration(
              color: AppColors.textDisabled,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text('Software', style: AppTextStyles.caption.copyWith(
            color: AppColors.textDisabled,
          )),
        ],
      ),
    ],
  ),
),
          ],
        ),
      ),
    );
  }
}

// ── Section header: fades + slides in, icon spins into place ──
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.reveal,
    this.padding = const EdgeInsets.fromLTRB(16, 24, 16, 0),
  });

  final IconData icon;
  final String label;
  final Animation<double> reveal;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: AnimatedBuilder(
        animation: reveal,
        builder: (context, _) {
          final v = reveal.value.clamp(0.0, 1.0);
          return Opacity(
            opacity: v,
            child: Transform.translate(
              offset: Offset((1 - v) * -18, 0),
              child: Row(
                children: [
                  Transform.rotate(
                    angle: (1 - v) * -1.1,
                    child: Icon(icon, size: 15, color: AppColors.textDisabled),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Hero Banner ───────────────────────────────────────────
class _HeroBanner extends ConsumerStatefulWidget {
  const _HeroBanner({required this.checkIn});
  final CheckInState checkIn;

  @override
  ConsumerState<_HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends ConsumerState<_HeroBanner>
    with TickerProviderStateMixin {
  late final AnimationController _gradientShift;
  late final AnimationController _ping;
  late final AnimationController _confirm;
  late final AnimationController _blobFloat;

  bool _prevCheckedIn = false;

  @override
  void initState() {
    super.initState();
    _prevCheckedIn = widget.checkIn.isCheckedIn;

    _gradientShift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);

    _ping = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _confirm = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _blobFloat = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _HeroBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    final justCheckedIn = widget.checkIn.isCheckedIn && !_prevCheckedIn;
    if (justCheckedIn) {
      _confirm.forward(from: 0);
    }
    _prevCheckedIn = widget.checkIn.isCheckedIn;
  }

  @override
  void dispose() {
    _gradientShift.dispose();
    _ping.dispose();
    _confirm.dispose();
    _blobFloat.dispose();
    super.dispose();
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _todayLabel =>
      DateFormat('EEEE, d MMM yyyy').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final checkIn = widget.checkIn;
    return AnimatedBuilder(
      animation: _gradientShift,
      builder: (context, child) {
        final t = _gradientShift.value; // 0..1..0
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: const [
                Color(0xFF1B4332),
                Color(0xFF2D6A4F),
                Color(0xFF40916C),
              ],
              begin: Alignment(-1.0 + t * 0.6, -1.0 - t * 0.3),
              end: Alignment(1.0 - t * 0.3, 1.0 + t * 0.3),
            ),
          ),
          child: child,
        );
      },
      child: ClipRect(
        child: Stack(
          children: [
            // ── Ambient drifting blobs, purely decorative ──
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _blobFloat,
                  builder: (context, _) {
                    final t = _blobFloat.value;
                    return Stack(
                      children: [
                        Positioned(
                          right: -40 + t * 18,
                          top: -50 - t * 14,
                          child: Opacity(
                            opacity: 0.10,
                            child: Container(
                              width: 170,
                              height: 170,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(85),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: -30 - t * 10,
                          bottom: -60 + t * 16,
                          child: Opacity(
                            opacity: 0.09,
                            child: Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                color: const Color(0xFF74C69D),
                                borderRadius: BorderRadius.circular(65),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 60 - t * 10,
                          bottom: -30 - t * 8,
                          child: Opacity(
                            opacity: 0.07,
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: const Color(0xFF52B788),
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOut,
                                builder: (context, v, child) => Opacity(
                                  opacity: v,
                                  child: Transform.translate(
                                    offset: Offset((1 - v) * -14, 0),
                                    child: child,
                                  ),
                                ),
                                child: Text(
                                  _greeting,
                                  style: AppTextStyles.body.copyWith(
                                    color: Colors.white.withOpacity(0.75),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: const Duration(milliseconds: 650),
                                curve: Curves.easeOutBack,
                                builder: (context, v, child) => Opacity(
                                  opacity: v.clamp(0.0, 1.0),
                                  child: Transform.translate(
                                    offset: Offset((1 - v).clamp(0.0, 1.0) * -18, 0),
                                    child: child,
                                  ),
                                ),
                                child: Text(
                                  'Field Officer',
                                  style: AppTextStyles.h1.copyWith(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: const Duration(milliseconds: 750),
                                curve: Curves.easeOut,
                                builder: (context, v, child) => Opacity(
                                  opacity: v,
                                  child: child,
                                ),
                                child: Row(
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
                              ),
                            ],
                          ),
                        ),
                        _Breathe(
                          amount: 0.035,
                          duration: const Duration(milliseconds: 2200),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutBack,
                            builder: (context, v, child) => Opacity(
                              opacity: v.clamp(0.0, 1.0),
                              child: Transform.scale(
                                scale: v.clamp(0.0, 1.2),
                                child: child,
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.2)),
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
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Check-in card — bounces once when you check in
                    AnimatedBuilder(
                      animation: _confirm,
                      builder: (context, child) {
                        final b = _confirm.value;
                        final bump = b < 0.5
                            ? 1.0 + (b / 0.5) * 0.045
                            : 1.045 - ((b - 0.5) / 0.5) * 0.045;
                        final scale = _confirm.isAnimating ? bump : 1.0;
                        return Transform.scale(scale: scale, child: child);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: checkIn.isCheckedIn
                                ? const Color(0xFF52B788).withOpacity(0.4)
                                : Colors.white.withOpacity(0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: AnimatedBuilder(
                                animation: _ping,
                                builder: (context, _) {
                                  if (!checkIn.isCheckedIn) {
                                    return const Center(
                                      child: _StatusDot(active: false),
                                    );
                                  }
                                  return Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      _RadarRing(progress: _ping.value),
                                      _RadarRing(
                                        progress: (_ping.value + 0.5) % 1.0,
                                      ),
                                      const _StatusDot(active: true),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                transitionBuilder: (child, anim) =>
                                    FadeTransition(
                                  opacity: anim,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.25),
                                      end: Offset.zero,
                                    ).animate(anim),
                                    child: child,
                                  ),
                                ),
                                child: Text(
                                  checkIn.isCheckedIn
                                      ? 'Checked in · ${checkIn.time}'
                                      : 'Not checked in yet',
                                  key: ValueKey(checkIn.isCheckedIn),
                                  style: AppTextStyles.body.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            _InviteGlow(
                              active: !checkIn.isCheckedIn,
                              child: _PressableScale(
                                onTap: checkIn.isCheckedIn
                                    ? () => ref
                                        .read(checkInProvider.notifier)
                                        .checkOut()
                                    : () => ref
                                        .read(checkInProvider.notifier)
                                        .checkIn(),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: checkIn.isCheckedIn
                                        ? Colors.white.withOpacity(0.15)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 250),
                                        transitionBuilder: (child, anim) =>
                                            ScaleTransition(
                                                scale: anim, child: child),
                                        child: Icon(
                                          checkIn.isCheckedIn
                                              ? Icons.logout_rounded
                                              : Icons
                                                  .check_circle_outline_rounded,
                                          key: ValueKey(checkIn.isCheckedIn),
                                          size: 15,
                                          color: checkIn.isCheckedIn
                                              ? Colors.white
                                              : AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        child: Text(
                                          checkIn.isCheckedIn
                                              ? 'Check Out'
                                              : 'Check In',
                                          key: ValueKey(checkIn.isCheckedIn),
                                          style: AppTextStyles.label.copyWith(
                                            color: checkIn.isCheckedIn
                                                ? Colors.white
                                                : AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? const Color(0xFF52B788) : Colors.white38,
      ),
    );
  }
}

// Expanding, fading ring — classic "live/active" radar-ping effect.
class _RadarRing extends StatelessWidget {
  const _RadarRing({required this.progress});
  final double progress; // 0..1

  @override
  Widget build(BuildContext context) {
    final size = 10.0 + progress * 16;
    final opacity = (1 - progress).clamp(0.0, 1.0) * 0.55;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF52B788).withOpacity(opacity),
          width: 1.4,
        ),
      ),
    );
  }
}

// Soft pulsing glow, used to nudge the eye toward an actionable button
// while it hasn't been used yet (e.g. "Check In" before you've checked in).
class _InviteGlow extends StatefulWidget {
  const _InviteGlow({required this.child, required this.active});
  final Widget child;
  final bool active;

  @override
  State<_InviteGlow> createState() => _InviteGlowState();
}

class _InviteGlowState extends State<_InviteGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.30 * _c.value),
                blurRadius: 4 + _c.value * 10,
                spreadRadius: _c.value * 1.5,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}

// Gentle, continuous scale "breathing" — keeps an element feeling alive
// even once its entrance animation has finished.
class _Breathe extends StatefulWidget {
  const _Breathe({
    required this.child,
    this.amount = 0.05,
    this.duration = const Duration(milliseconds: 1600),
  });
  final Widget child;
  final double amount;
  final Duration duration;

  @override
  State<_Breathe> createState() => _BreatheState();
}

class _BreatheState extends State<_Breathe> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
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
        final scale = 1.0 + _c.value * widget.amount;
        return Transform.scale(scale: scale, child: child);
      },
    );
  }
}

// One-shot diagonal light sweep, played once after a delay — a small
// "polish" pass across a card once it has settled into place.
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
      duration: const Duration(milliseconds: 900),
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
                      width: w * 0.35,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: (1 - _c.value).clamp(0.0, 1.0) * 0.5,
                          child: Transform.rotate(
                            angle: -0.35,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.white.withOpacity(0),
                                    Colors.white.withOpacity(0.55),
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

// Slow vertical bob — makes small icons feel gently "alive" at rest.
class _BobbingIcon extends StatefulWidget {
  const _BobbingIcon({required this.child, this.phase = 0});
  final Widget child;
  final double phase; // 0..1

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
      duration: const Duration(milliseconds: 2600),
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
        final t = (_c.value + widget.phase) % 1.0;
        final dy = math.sin(t * 2 * math.pi) * 2.5;
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
    );
  }
}

// ── Reusable press-scale wrapper ───────────────────────────
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

// ── Pop-in wrapper: fade + upward slide + elastic scale + a touch of
// rotation, sliced into per-item stagger windows off a parent reveal
// animation. This is the "real" entrance animation, not just a fade.
class _PopIn extends StatelessWidget {
  const _PopIn({
    required this.reveal,
    required this.index,
    required this.total,
    required this.child,
    this.fromLeft = false,
  });
  final Animation<double> reveal;
  final int index;
  final int total;
  final Widget child;
  final bool fromLeft;

  @override
  Widget build(BuildContext context) {
    final start = (index / total).clamp(0.0, 1.0);
    final end = ((index + 1) / total).clamp(0.0, 1.0);
    final local = CurvedAnimation(
      parent: reveal,
      curve: Interval(start, end, curve: Curves.elasticOut),
    );
    final fade = CurvedAnimation(
      parent: reveal,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    return AnimatedBuilder(
      animation: reveal,
      child: child,
      builder: (context, child) {
        final v = local.value; // unclamped — allowed to overshoot
        final opacity = fade.value.clamp(0.0, 1.0);
        final dx = fromLeft ? (1 - v) * -40 : (1 - v) * 40;
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(dx, (1 - v) * 18),
            child: Transform.scale(
              scale: 0.7 + v * 0.3,
              child: Transform.rotate(
                angle: (1 - v) * (fromLeft ? -0.06 : 0.06),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── KPI Grid ──────────────────────────────────────────────
class _KpiGrid extends ConsumerWidget {
  const _KpiGrid({required this.reveal});
  final Animation<double> reveal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpis = ref.watch(dashboardKpisProvider);

    final areaAcres = kpis.totalAreaAcres;
    final co2eT = kpis.totalCo2eTonnes;
    final isNetNegative = kpis.totalCo2eKg <= 0;

    final items = [
      _KpiItem(
        value: kpis.totalFarmers.toDouble(),
        decimals: 0,
        label: 'Farmers',
        icon: Icons.people_outline,
        iconColor: AppColors.primary,
        iconBg: AppColors.successBg,
      ),
      _KpiItem(
        value: kpis.totalPlots.toDouble(),
        decimals: 0,
        label: 'Plots',
        icon: Icons.location_on_outlined,
        iconColor: AppColors.info,
        iconBg: AppColors.infoBg,
      ),
      _KpiItem(
        value: areaAcres,
        decimals: 1,
        label: 'Acres',
        icon: Icons.terrain_outlined,
        iconColor: AppColors.warning,
        iconBg: AppColors.warningBg,
      ),
      _KpiItem(
        value: kpis.activeSeasons.toDouble(),
        decimals: 0,
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
          Row(
            children: List.generate(items.length, (i) {
              final k = items[i];
              return Expanded(
                child: Padding(
                  padding:
                      EdgeInsets.only(right: i == items.length - 1 ? 0 : 10),
                  child: _PopIn(
                    reveal: reveal,
                    index: i,
                    total: items.length,
                    fromLeft: i.isEven,
                    child: _ShineSweep(
                      delay: Duration(milliseconds: 750 + i * 130),
                      child: _KpiCard(item: k, reveal: reveal, index: i),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          _PopIn(
            reveal: reveal,
            index: items.length,
            total: items.length + 1,
            child: _ShineSweep(
              delay: const Duration(milliseconds: 1250),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: Row(
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    _BreathingIcon(
      icon: Icons.eco_outlined,
      color: AppColors.primary,
    ),
    const SizedBox(width: 14),
    // Number + label — takes all remaining space, never pushes badge off
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Carbon Footprint', style: AppTextStyles.caption),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Shrinks font to fit, never overflows
              Flexible(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: 0,
                    end: co2eT
                  ),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutBack,
                  builder: (context, value, _) {
                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _compactNumber(value, 1),
                        style: AppTextStyles.h1.copyWith(
                          color: isNetNegative
                              ? AppColors.primary
                              : AppColors.warning,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  'tCO₂e net',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    const SizedBox(width: 10),
    // Badge pinned to right, never grows or shrinks
    _Breathe(
      amount: 0.045,
      duration: const Duration(milliseconds: 8700),
      child: AppStatusBadge(
        label: kpis.isLowEmissions ? 'Low Emissions' : 'High Emissions',
        variant: kpis.isLowEmissions
            ? BadgeVariant.success
            : BadgeVariant.warning,
      ),
    ),
  ],
),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Slow, continuous scale pulse — used on icon badges that should feel
// "alive" even once the entrance animation has finished.
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
              width: 48,
              height: 48,
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
              child: Icon(widget.icon, color: widget.color, size: 24),
            ),
          ),
        );
      },
    );
  }
}


class _KpiItem {
  final double value;
  final int decimals;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  const _KpiItem({
    required this.value,
    required this.decimals,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });
}

class _KpiCard extends StatelessWidget {
  const _KpiCard(
      {required this.item, required this.reveal, required this.index});
  final _KpiItem item;
  final Animation<double> reveal;
  final int index;

  @override
  Widget build(BuildContext context) {
    final iconAnim = CurvedAnimation(
      parent: reveal,
      curve: Interval(
        (0.15 + index * 0.05).clamp(0.0, 1.0),
        1.0,
        curve: Curves.elasticOut,
      ),
    );

    return SizedBox(
      height: 110, // ← fixed height so all cards are uniform
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon badge — spins + scales in
            AnimatedBuilder(
              animation: iconAnim,
              builder: (context, _) {
                final v = iconAnim.value;
                return Transform.rotate(
                  angle: (1 - v) * 0.5,
                  child: Transform.scale(
                    scale: v.clamp(0.0, 1.4),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: item.iconBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.icon, size: 16, color: item.iconColor),
                    ),
                  ),
                );
              },
            ),

            // Number — counts up, compact-formatted, shrinks to fit
            // Number — counts up, compact-formatted, shrinks to fit
TweenAnimationBuilder<double>(
  tween: Tween(begin: 0, end: item.value),
  duration: const Duration(milliseconds: 1000),
  curve: Curves.easeOutBack,
  builder: (context, value, _) {
    return SizedBox(
      width: double.infinity,   // ← always fills card width
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          _compactNumber(value, item.decimals),
          style: AppTextStyles.h2.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  },
),

            // Label
            Text(
              item.label,
              style: AppTextStyles.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Actions ─────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.reveal});
  final Animation<double> reveal;

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
        children: List.generate(actions.length, (i) {
          return _PopIn(
            reveal: reveal,
            index: i,
            total: actions.length,
            fromLeft: i.isEven,
            child: _ShineSweep(
              delay: Duration(milliseconds: 850 + i * 110),
              child: _QuickActionCard(action: actions[i], phase: i / 4.0),
            ),
          );
        }),
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
  const _QuickActionCard({required this.action, this.phase = 0});
  final _QuickAction action;
  final double phase;

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: action.onTap,
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _BobbingIcon(
              phase: phase,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: action.iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(action.icon, size: 20, color: action.iconColor),
              ),
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
      ),
    );
  }
}

// ── Plot Overview Teaser ──────────────────────────────────
class _PlotOverviewTeaser extends ConsumerStatefulWidget {
  const _PlotOverviewTeaser({required this.reveal});
  final Animation<double> reveal;

  @override
  ConsumerState<_PlotOverviewTeaser> createState() =>
      _PlotOverviewTeaserState();
}

class _PlotOverviewTeaserState extends ConsumerState<_PlotOverviewTeaser>
    with TickerProviderStateMixin {
  late final AnimationController _float;
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _float.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kpis = ref.watch(dashboardKpisProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _PopIn(
        reveal: widget.reveal,
        index: 0,
        total: 1,
        child: _PressableScale(
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  return Stack(
                    children: [
                      AnimatedBuilder(
                        animation: _float,
                        builder: (context, _) {
                          final t = _float.value;
                          return Stack(
                            children: [
                              Positioned(
                                right: -20 + t * 10,
                                top: -10 - t * 8,
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
                                right: 40 - t * 12,
                                bottom: -20 + t * 10,
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
                                left: 80 + t * 8,
                                top: 20 - t * 6,
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
                            ],
                          );
                        },
                      ),
                      AnimatedBuilder(
                        animation: _shimmer,
                        builder: (context, _) {
                          final t = _shimmer.value;
                          final dx = -0.5 * w + t * (w * 1.8);
                          // Positioned must be a direct child of Stack —
                          // IgnorePointer goes *inside* it, not around it.
                          return Positioned(
                            top: -40,
                            bottom: -40,
                            left: dx,
                            width: 70,
                            child: IgnorePointer(
                              child: Transform.rotate(
                                angle: -0.4,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Colors.white.withOpacity(0),
                                        Colors.white.withOpacity(0.10),
                                        Colors.white.withOpacity(0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _Breathe(
                                  amount: 0.04,
                                  duration:
                                      const Duration(milliseconds: 8900),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color:
                                              Colors.white.withOpacity(0.2)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                            Icons.satellite_alt_outlined,
                                            size: 12,
                                            color: Colors.white70),
                                        const SizedBox(width: 4),
                                        Text('Live Map',
                                            style: AppTextStyles.caption
                                                .copyWith(
                                                    color: Colors.white70)),
                                      ],
                                    ),
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
                            Row(
                              children: [
                                _TeaserStat(
                                  value: kpis.totalPlots.toDouble(),
                                  decimals: 0,
                                  label: 'Plots mapped',
                                ),
                                const SizedBox(width: 24),
                                _TeaserStat(
                                  value: kpis.totalAreaAcres,
                                  decimals: 0,
                                  label: 'Acres covered',
                                ),
                                const Spacer(),
                                _Breathe(
                                  amount: 0.045,
                                  duration:
                                      const Duration(milliseconds: 8700),
                                  child: Container(
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
                                        const Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 13,
                                            color: AppColors.primary),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TeaserStat extends StatelessWidget {
  const _TeaserStat({
    required this.value,
    required this.decimals,
    required this.label,
  });
  final double value;
  final int decimals;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutBack,
          builder: (context, v, _) {
            return Text(
              v.toStringAsFixed(decimals),
              style: AppTextStyles.h2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
            );
          },
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: Colors.white60),
        ),
      ],
    );
  }
}