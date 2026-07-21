// features/crops/crops_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_header.dart';
import '../../core/constants/crop_constants.dart';
import '../crops/models/season_model.dart';
import '../crops/providers/crops_provider.dart';
import '../farmers/providers/farmers_provider.dart';

const _statusFilters = ['All', 'On track', 'Delayed', 'Complete'];
const _stages = ['Nursery', 'Planting', 'Growth', 'Flowering', 'Harvest'];

// Cap how many cards get a staggered pop-in — keeps a long list from
// queueing up a slow cascade on the tail end.
const int _maxStaggerItems = 8;

class CropsScreen extends ConsumerStatefulWidget {
  const CropsScreen({super.key});

  @override
  ConsumerState<CropsScreen> createState() => _CropsScreenState();
}

class _CropsScreenState extends ConsumerState<CropsScreen>
    with SingleTickerProviderStateMixin {
  String _statusFilter = 'All';
  String? _expandedId;

  late final AnimationController _entrance;
  late final Animation<double> _chipsAnim;
  late final Animation<double> _listAnim;

  @override
  void initState() {
    super.initState();
    // Kept intentionally short — this screen is reached often (every
    // time someone checks on a season), so the entrance should read as
    // "snappy" rather than a show. Roughly a third of the dashboard's
    // timing.
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _chipsAnim = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _listAnim = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
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

  @override
  Widget build(BuildContext context) {
    final seasonsAsync = ref.watch(filteredSeasonsProvider);
    final farmersAsync = ref.watch(farmersProvider);

    // Build a quick id→name map for farmer name lookup
    final farmerNames = <String, String>{};
    if (farmersAsync.valueOrNull != null) {
      for (final f in farmersAsync.valueOrNull!) {
        farmerNames[f.id] = f.name;
      }
    }

    final allSeasons = seasonsAsync;
    final filtered = _statusFilter == 'All'
        ? allSeasons
        : allSeasons.where((s) => s.status == _statusFilter).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildFilterChips(),
          const Divider(height: 1),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: child,
              ),
              child: ref.watch(seasonsProvider).when(
                loading: () => const Center(
                  key: ValueKey('loading'),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => Center(
                  key: const ValueKey('error'),
                  child: Text('Error loading seasons: $e',
                      style: AppTextStyles.body),
                ),
                data: (_) {
                  if (filtered.isEmpty) {
                    return KeyedSubtree(
                      key: const ValueKey('empty'),
                      child: EmptyState.noSeasons(
                        onAction: () => context.push('/add-season'),
                      ),
                    );
                  }
                  return ListView.separated(
                    key: ValueKey('list-${filtered.length}-$_statusFilter'),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final season = filtered[i];
                      final farmerName =
                          farmerNames[season.farmerId] ?? 'Unknown Farmer';
                      final staggerIndex =
                          i < _maxStaggerItems ? i : _maxStaggerItems - 1;
                      final staggerTotal =
                          filtered.length < _maxStaggerItems
                              ? filtered.length
                              : _maxStaggerItems;
                      return _PopIn(
                        reveal: _listAnim,
                        index: staggerIndex,
                        total: staggerTotal,
                        child: _SeasonCard(
                          season: season,
                          farmerName: farmerName,
                          isExpanded: _expandedId == season.id,
                          onToggle: () => setState(() {
                            _expandedId =
                                _expandedId == season.id ? null : season.id;
                          }),
                          onLogEvent: () => context
                              .push('/add-event?seasonId=${season.id}'),
                          onUpdateStage: (newStage) async {
                            await ref
                                .read(seasonsProvider.notifier)
                                .updateSeasonStage(season.id, newStage);
                          },
                          onDelete: () async {
                            final confirm = await _showDeleteDialog(context);
                            if (confirm == true) {
                              await ref
                                  .read(seasonsProvider.notifier)
                                  .deleteSeason(season.id);
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _AddSeasonButton(
        onTap: () => context.push('/add-season'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _statusFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final s = _statusFilters[i];
          final selected = s == _statusFilter;
          return _PopIn(
            reveal: _chipsAnim,
            index: i,
            total: _statusFilters.length,
            child: _AnimatedChip(
              label: s,
              isSelected: selected,
              onSelected: () => setState(() => _statusFilter = s),
            ),
          );
        },
      ),
    );
  }

  Future<bool?> _showDeleteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Season?'),
        content: const Text(
            'This will remove the season and all logged events. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => ctx.pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Pop-in wrapper: fade + small upward slide + scale, sliced into
// per-item stagger windows off a parent reveal animation. Shorter
// travel distance and no elastic overshoot, to keep things quick.
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
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    return AnimatedBuilder(
      animation: reveal,
      child: child,
      builder: (context, child) {
        final v = local.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * 10),
            child: Transform.scale(
              scale: 0.96 + v * 0.04,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

// Wraps FilterChip with a quick bounce whenever it becomes selected.
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
      duration: const Duration(milliseconds: 220),
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
        final b = Curves.easeOutBack.transform(_bounce.value);
        final scale = widget.isSelected ? 1.0 + b * 0.05 : 1.0;
        return Transform.scale(scale: scale, child: child);
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

// Reusable press-scale wrapper — quick, low-travel tap feedback.
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
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// One-shot light sweep, played once shortly after mount — quick pass,
// no continuous loop, so it never competes for attention with the
// growth timeline or badges.
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
      duration: const Duration(milliseconds: 500),
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
                      width: w * 0.28,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: (1 - _c.value).clamp(0.0, 1.0) * 0.3,
                          child: Transform.rotate(
                            angle: -0.35,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.white.withOpacity(0),
                                    Colors.white.withOpacity(0.4),
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

// ── Custom Add Season Button ──────────────────────────
class _AddSeasonButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AddSeasonButton({required this.onTap});

  @override
  State<_AddSeasonButton> createState() => _AddSeasonButtonState();
}

class _AddSeasonButtonState extends State<_AddSeasonButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
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

  void _setScale(double s) => setState(() => _scale = s);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entrance,
      builder: (context, child) {
        final v = Curves.easeOutBack.transform(_entrance.value);
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.scale(scale: v.clamp(0.0, 1.15), child: child),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _setScale(0.95),
        onTapUp: (_) => _setScale(1.0),
        onTapCancel: () => _setScale(1.0),
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
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
                const Icon(Icons.yard_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Add Season',
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

// ── Season Card ───────────────────────────────────────
class _SeasonCard extends StatelessWidget {
  final SeasonModel season;
  final String farmerName;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onLogEvent;
  final Future<void> Function(String) onUpdateStage;
  final VoidCallback onDelete;

  const _SeasonCard({
    required this.season,
    required this.farmerName,
    required this.isExpanded,
    required this.onToggle,
    required this.onLogEvent,
    required this.onUpdateStage,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return _ShineSweep(
      delay: const Duration(milliseconds: 400),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // ── Header ───────────────────────────────
            _PressableScale(
              onTap: onToggle,
              child: InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(12),
                splashColor: AppColors.successBg,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      // Stage icon circle
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.stageBgColor(season.stage),
                              AppColors.stageColor(season.stage)
                                  .withOpacity(0.18),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Icon(
                          _stageIcon(season.stage),
                          color: AppColors.stageColor(season.stage),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(farmerName, style: AppTextStyles.h3),
                            const SizedBox(height: 3),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, anim) =>
                                  FadeTransition(opacity: anim, child: child),
                              child: Text(
                                '${season.variety} • ${season.stage} • ${season.dap} DAP',
                                key: ValueKey(season.stage),
                                style: AppTextStyles.caption,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SeasonStatusBadge(status: season.status),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.textDisabled,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // ── Expanded details ──────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? _ExpandedFade(
                      child: Column(
                        children: [
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Dates row
                                Row(
                                  children: [
                                    _DateChip(
                                      label: 'Planted',
                                      date: season.plantingLabel,
                                      icon: Icons.calendar_today,
                                    ),
                                    const SizedBox(width: 8),
                                    _DateChip(
                                      label: 'Harvest',
                                      date: season.harvestLabel,
                                      icon: Icons.event_available,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Target yield
                                AppFlatCard(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.agriculture,
                                          size: 16, color: AppColors.accent),
                                      const SizedBox(width: 8),
                                      Text('Target Yield',
                                          style: AppTextStyles.label),
                                      const Spacer(),
                                      Text(
                                        season.targetYieldLabel,
                                        style: AppTextStyles.body.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Growth timeline
                                SectionHeader(
                                  title: 'Growth Timeline',
                                  padding: const EdgeInsets.only(bottom: 8),
                                ),
                                _GrowthTimeline(currentStage: season.stage),
                                const SizedBox(height: 14),
                                // Advance stage (if not complete)
                                if (season.nextStage != null) ...[
                                  SizedBox(
                                    width: double.infinity,
                                    child: _PressableScale(
                                      onTap: () =>
                                          onUpdateStage(season.nextStage!),
                                      child: OutlinedButton.icon(
                                        onPressed: () =>
                                            onUpdateStage(season.nextStage!),
                                        icon: const Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 14),
                                        label: Text(
                                            'Advance to ${season.nextStage}'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.accent,
                                          side: BorderSide(
                                              color: AppColors.accent),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                // Log Event button
                                SizedBox(
                                  width: double.infinity,
                                  child: _PressableScale(
                                    onTap: onLogEvent,
                                    child: OutlinedButton.icon(
                                      onPressed: onLogEvent,
                                      icon: const Icon(Icons.edit_note,
                                          size: 18),
                                      label: const Text('Log Event'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                        side: BorderSide(
                                            color: AppColors.primary),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Delete button
                                SizedBox(
                                  width: double.infinity,
                                  child: TextButton.icon(
                                    onPressed: onDelete,
                                    icon: const Icon(Icons.delete_outline,
                                        size: 16),
                                    label: const Text('Delete Season'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  IconData _stageIcon(String stage) {
    switch (stage) {
      case 'Nursery':
        return Icons.grass;
      case 'Planting':
        return Icons.spa;
      case 'Growth':
        return Icons.trending_up;
      case 'Flowering':
        return Icons.local_florist;
      case 'Harvest':
        return Icons.agriculture;
      default:
        return Icons.grass;
    }
  }
}

// Quick fade-in for content revealed by AnimatedSize, so the details
// don't just snap into view once their box has finished resizing.
class _ExpandedFade extends StatefulWidget {
  const _ExpandedFade({required this.child});
  final Widget child;

  @override
  State<_ExpandedFade> createState() => _ExpandedFadeState();
}

class _ExpandedFadeState extends State<_ExpandedFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _c, child: widget.child);
  }
}

// ── Growth Timeline ───────────────────────────────────
class _GrowthTimeline extends StatelessWidget {
  final String currentStage;
  const _GrowthTimeline({required this.currentStage});

  @override
  Widget build(BuildContext context) {
    final currentIdx = _stages.indexOf(currentStage);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(_stages.length, (i) {
        final done = i < currentIdx;
        final active = i == currentIdx;
        final pending = i > currentIdx;
        final color = active
            ? AppColors.stageColor(_stages[i])
            : done
                ? AppColors.success
                : AppColors.border;

        return Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 220 + i * 40),
                      curve: Curves.easeOutBack,
                      builder: (context, v, child) => Transform.scale(
                        scale: v.clamp(0.0, 1.1),
                        child: child,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.stageBgColor(_stages[i])
                              : done
                                  ? AppColors.successBg
                                  : AppColors.surfaceVariant,
                          shape: BoxShape.circle,
                          border: Border.all(color: color, width: 2),
                        ),
                        child: Icon(
                          done ? Icons.check : _stageIcon(_stages[i]),
                          size: 14,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _stages[i],
                      style: AppTextStyles.caption.copyWith(
                        color: pending
                            ? AppColors.textDisabled
                            : AppColors.textPrimary,
                        fontWeight:
                            active ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 9,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.visible,
                    ),
                  ],
                ),
              ),
              if (i < _stages.length - 1)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 8,
                  height: 2,
                  margin: const EdgeInsets.only(top: 13),
                  color: done ? AppColors.success : AppColors.border,
                ),
            ],
          ),
        );
      }),
    );
  }

  IconData _stageIcon(String stage) {
    switch (stage) {
      case 'Nursery':
        return Icons.grass;
      case 'Planting':
        return Icons.spa;
      case 'Growth':
        return Icons.trending_up;
      case 'Flowering':
        return Icons.local_florist;
      case 'Harvest':
        return Icons.agriculture;
      default:
        return Icons.circle;
    }
  }
}

// ── Date Chip ─────────────────────────────────────────
class _DateChip extends StatelessWidget {
  final String label;
  final String date;
  final IconData icon;
  const _DateChip({
    required this.label,
    required this.date,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppFlatCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppColors.accent),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                Text(
                  date,
                  style: AppTextStyles.label
                      .copyWith(color: AppColors.textPrimary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Season Status Badge ───────────────────────────────
class SeasonStatusBadge extends StatelessWidget {
  final String status;
  const SeasonStatusBadge({super.key, required this.status});

  BadgeVariant get _variant {
    switch (status) {
      case 'On track':
        return BadgeVariant.success;
      case 'Delayed':
        return BadgeVariant.warning;
      case 'Complete':
        return BadgeVariant.info;
      default:
        return BadgeVariant.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppStatusBadge(label: status, variant: _variant);
  }
}