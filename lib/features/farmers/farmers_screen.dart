// features/farmers/farmers_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/empty_state.dart';
import 'models/farmer_model.dart';
import 'providers/farmers_provider.dart';

const _stages = [
  'All',
  'Nursery',
  'Planting',
  'Growth',
  'Flowering',
  'Harvest'
];

// Cap how many list items get a staggered pop-in — beyond this, items
// still fade in, but at a flat delay so a long list doesn't make the
// tail end wait several seconds for its turn.
const int _maxStaggerItems = 10;

class FarmersScreen extends ConsumerStatefulWidget {
  const FarmersScreen({super.key});

  @override
  ConsumerState<FarmersScreen> createState() => _FarmersScreenState();
}

class _FarmersScreenState extends ConsumerState<FarmersScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  late final Animation<double> _searchAnim;
  late final Animation<double> _chipsAnim;
  late final Animation<double> _listAnim;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _searchAnim = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
    );
    _chipsAnim = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.20, 0.65, curve: Curves.easeOutCubic),
    );
    _listAnim = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
    );

    // Same reasoning as the dashboard: wait for the first post-frame
    // callback so the entrance doesn't start ticking while the route
    // transition is still settling, which would otherwise eat frames
    // and make the reveal look like it jumps partway through.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entrance.forward();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final farmersAsync = ref.watch(farmersProvider);
    final filtered = ref.watch(filteredFarmersProvider);
    final search = ref.watch(farmersSearchProvider);
    final stageFilter = ref.watch(farmersStageFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────
          AnimatedBuilder(
            animation: _searchAnim,
            child: _SearchBar(
              value: search,
              onChanged: (v) =>
                  ref.read(farmersSearchProvider.notifier).state = v,
              onClear: () =>
                  ref.read(farmersSearchProvider.notifier).state = '',
            ),
            builder: (context, child) {
              final v = _searchAnim.value.clamp(0.0, 1.0);
              return Opacity(
                opacity: v,
                child: Transform.translate(
                  offset: Offset(0, (1 - v) * -14),
                  child: child,
                ),
              );
            },
          ),
          // ── Stage filter chips ──────────────────────
          _StageFilterChips(
            selected: stageFilter,
            onSelect: (s) =>
                ref.read(farmersStageFilterProvider.notifier).state = s,
            reveal: _chipsAnim,
          ),
          const Divider(height: 1),
          // ── List ────────────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 100),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.985, end: 1.0).animate(anim),
                  child: child,
                ),
              ),
              child: farmersAsync.when(
                loading: () => const Center(
                  key: ValueKey('loading'),
                  child: _PulsingLoader(),
                ),
                error: (e, _) => Center(
                  key: const ValueKey('error'),
                  child: Text('Error: $e', style: AppTextStyles.body),
                ),
                data: (_) => filtered.isEmpty
                    ? KeyedSubtree(
                        key: ValueKey('empty-${search.isNotEmpty}-$stageFilter'),
                        child: search.isNotEmpty || stageFilter != 'All'
                            ? const EmptyState.noResults()
                            : EmptyState.noFarmers(
                                onAction: () => context.push('/add-farmer'),
                              ),
                      )
                    : ListView.separated(
                        key: ValueKey('list-${filtered.length}-$search-$stageFilter'),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final staggerIndex = i < _maxStaggerItems
                              ? i
                              : _maxStaggerItems - 1;
                          final staggerTotal = math.min(
                              filtered.length, _maxStaggerItems);
                          return _PopIn(
                            reveal: _listAnim,
                            index: staggerIndex,
                            total: staggerTotal,
                            child: _FarmerCard(
                              farmer: filtered[i],
                              shineDelay: Duration(
                                milliseconds:
                                    650 + staggerIndex.clamp(0, 6) * 90,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _entrance,
        child: _AddFarmerButton(
          onTap: () => context.push('/add-farmer'),
        ),
        builder: (context, child) {
          final v = Curves.elasticOut.transform(
            CurvedAnimation(
              parent: _entrance,
              curve: const Interval(0.55, 1.0),
            ).value,
          );
          return Transform.scale(scale: v.clamp(0.0, 1.3), child: child);
        },
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
    );
  }
}

// Simple breathing dots loader — feels more alive than a bare spinner
// while keeping the same footprint and not distracting from the list
// that's about to replace it.
class _PulsingLoader extends StatefulWidget {
  const _PulsingLoader();

  @override
  State<_PulsingLoader> createState() => _PulsingLoaderState();
}

class _PulsingLoaderState extends State<_PulsingLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
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
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = ((_c.value - i * 0.18) % 1.0 + 1.0) % 1.0;
            final scale = 0.6 + (math.sin(t * math.pi)).abs() * 0.6;
            final opacity = 0.35 + (math.sin(t * math.pi)).abs() * 0.65;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ── Search Bar ────────────────────────────────────────────
class _SearchBar extends StatefulWidget {
  const _SearchBar({
    required this.value,
    required this.onChanged,
    required this.onClear,
  });
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar>
    with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  late final AnimationController _focusAnim;

  @override
  void initState() {
    super.initState();
    _focusAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _focusAnim.forward();
      } else {
        _focusAnim.reverse();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _focusAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: AnimatedBuilder(
        animation: _focusAnim,
        builder: (context, child) {
          final f = _focusAnim.value;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.18 * f),
                  blurRadius: 4 + f * 10,
                  spreadRadius: f * 1.0,
                ),
              ],
            ),
            child: child,
          );
        },
        child: TextField(
          focusNode: _focusNode,
          onChanged: widget.onChanged,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: 'Search by name, village or phone...',
            hintStyle:
                AppTextStyles.body.copyWith(color: AppColors.textDisabled),
            prefixIcon: AnimatedBuilder(
              animation: _focusAnim,
              builder: (context, _) {
                return Transform.scale(
                  scale: 1.0 + _focusAnim.value * 0.12,
                  child: Icon(
                    Icons.search,
                    color: Color.lerp(
                      AppColors.textDisabled,
                      AppColors.primary,
                      _focusAnim.value,
                    ),
                  ),
                );
              },
            ),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            suffixIcon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim,
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: widget.value.isNotEmpty
                  ? IconButton(
                      key: const ValueKey('clear'),
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: widget.onClear,
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Stage Filter Chips ────────────────────────────────────
class _StageFilterChips extends StatelessWidget {
  const _StageFilterChips({
    required this.selected,
    required this.onSelect,
    required this.reveal,
  });
  final String selected;
  final ValueChanged<String> onSelect;
  final Animation<double> reveal;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _stages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final s = _stages[i];
          final isSelected = s == selected;
          return _PopIn(
            reveal: reveal,
            index: i,
            total: _stages.length,
            child: _AnimatedChip(
              label: s,
              isSelected: isSelected,
              onSelected: () => onSelect(s),
            ),
          );
        },
      ),
    );
  }
}

// Wraps FilterChip with a small bounce whenever it becomes selected,
// so the active stage feels like it "pops" into place rather than
// just recoloring.
class _AnimatedChip extends StatefulWidget {
  const _AnimatedChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  State<_AnimatedChip> createState() => _AnimatedChipState();
}

class _AnimatedChipState extends State<_AnimatedChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    if (widget.isSelected) _bounce.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant _AnimatedChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _bounce.forward(from: 0);
    } else if (!widget.isSelected) {
      _bounce.value = 0;
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounce,
      builder: (context, child) {
        final b = _bounce.value;
        final bump = b < 1.0 ? 1.0 + Curves.easeOutBack.transform(b) * 0.08 : 1.0;
        return Transform.scale(scale: widget.isSelected ? bump : 1.0, child: child);
      },
      child: FilterChip(
        label: Text(widget.label, style: AppTextStyles.label),
        selected: widget.isSelected,
        onSelected: (_) => widget.onSelected(),
        selectedColor: AppColors.successBg,
        checkmarkColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        side: BorderSide(
          color: widget.isSelected ? AppColors.primary : AppColors.border,
        ),
      ),
    );
  }
}

// ── Add Farmer FAB ────────────────────────────────────────
class _AddFarmerButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AddFarmerButton({required this.onTap});

  @override
  State<_AddFarmerButton> createState() => _AddFarmerButtonState();
}

class _AddFarmerButtonState extends State<_AddFarmerButton>
    with TickerProviderStateMixin {
  late final AnimationController _glow;
  double _scale = 1.0;

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
        child: AnimatedBuilder(
          animation: _glow,
          builder: (context, child) {
            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary
                        .withOpacity(0.35 + _glow.value * 0.15),
                    blurRadius: 16 + _glow.value * 8,
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
                  child: const Icon(Icons.eco_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'Add Farmer',
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
      ),
    );
  }
}

// Slow vertical bob — makes a small icon feel gently "alive" at rest.
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
        final dy = math.sin(_c.value * 2 * math.pi) * 2.0;
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
    );
  }
}

// ── Pop-in wrapper: fade + upward slide + elastic scale + a touch of
// rotation, sliced into per-item stagger windows off a parent reveal
// animation — mirrors the dashboard's entrance treatment.
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
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * 18),
            child: Transform.scale(
              scale: 0.85 + v * 0.15,
              child: child,
            ),
          ),
        );
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
    this.borderRadius = 12,
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
      duration: const Duration(milliseconds: 800),
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

// Reusable press-scale wrapper, matching the dashboard's tap feedback.
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
      onTapDown: (_) => _setScale(0.97),
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

// ── Farmer Card ───────────────────────────────────────────
class _FarmerCard extends StatefulWidget {
  final FarmerModel farmer;
  final Duration shineDelay;
  const _FarmerCard({required this.farmer, required this.shineDelay});

  @override
  State<_FarmerCard> createState() => _FarmerCardState();
}

class _FarmerCardState extends State<_FarmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _avatarPulse;

  @override
  void initState() {
    super.initState();
    _avatarPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _avatarPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final farmer = widget.farmer;
    return _ShineSweep(
      delay: widget.shineDelay,
      child: Card(
        child: _PressableScale(
          onTap: () => context.push('/farmers/${farmer.id}'),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            splashColor: AppColors.successBg,
            onTap: () => context.push('/farmers/${farmer.id}'),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Avatar — a very slow, subtle breathing scale keeps
                  // the list from feeling completely static at rest.
                  AnimatedBuilder(
                    animation: _avatarPulse,
                    builder: (context, child) {
                      final scale = 1.0 + _avatarPulse.value * 0.03;
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.15),
                            AppColors.primary.withOpacity(0.28),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        farmer.initials,
                        style: AppTextStyles.h3
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(farmer.name, style: AppTextStyles.h3),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 13, color: AppColors.textDisabled),
                            const SizedBox(width: 2),
                            Text(farmer.village,
                                style: AppTextStyles.caption),
                            const SizedBox(width: 10),
                            const Icon(Icons.landscape,
                                size: 13, color: AppColors.textDisabled),
                            const SizedBox(width: 2),
                            Text('${farmer.areaHa} ha',
                                style: AppTextStyles.caption),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Stage badge
                  AppBadge(label: farmer.stage),
                  const SizedBox(width: 2),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 200),
                    builder: (context, v, child) => Transform.translate(
                      offset: Offset((1 - v) * -4, 0),
                      child: child,
                    ),
                    child: const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.textDisabled),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}