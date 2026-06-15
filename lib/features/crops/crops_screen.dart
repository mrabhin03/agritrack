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

class CropsScreen extends ConsumerStatefulWidget {
  const CropsScreen({super.key});

  @override
  ConsumerState<CropsScreen> createState() => _CropsScreenState();
}

class _CropsScreenState extends ConsumerState<CropsScreen> {
  String _statusFilter = 'All';
  String? _expandedId;

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
            child: ref.watch(seasonsProvider).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Error loading seasons: $e',
                    style: AppTextStyles.body),
              ),
              data: (_) {
                if (filtered.isEmpty) {
                  return EmptyState.noSeasons(
                    onAction: () => context.push('/add-season'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final season = filtered[i];
                    final farmerName =
                        farmerNames[season.farmerId] ?? 'Unknown Farmer';
                    return _SeasonCard(
                      season: season,
                      farmerName: farmerName,
                      isExpanded: _expandedId == season.id,
                      onToggle: () => setState(() {
                        _expandedId =
                            _expandedId == season.id ? null : season.id;
                      }),
                      onLogEvent: () =>
                          context.push('/add-event?seasonId=${season.id}'),
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
                    );
                  },
                );
              },
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
          return FilterChip(
            label: Text(s, style: AppTextStyles.label),
            selected: selected,
            onSelected: (_) => setState(() => _statusFilter = s),
            selectedColor: AppColors.successBg,
            checkmarkColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.border,
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

// ── Custom Add Season Button ──────────────────────────
class _AddSeasonButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddSeasonButton({required this.onTap});

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
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // ── Header ───────────────────────────────
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            splashColor: AppColors.successBg,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Stage icon circle
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.stageBgColor(season.stage),
                          AppColors.stageColor(season.stage).withOpacity(0.18),
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
                        Text(
                          '${season.variety} • ${season.stage} • ${season.dap} DAP',
                          style: AppTextStyles.caption,
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
          // ── Expanded details ──────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Column(
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
                              const SizedBox(height: 8),
                            ],
                            // Log Event button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: onLogEvent,
                                icon: const Icon(Icons.edit_note, size: 18),
                                label: const Text('Log Event'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side:
                                      BorderSide(color: AppColors.primary),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
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
                  )
                : const SizedBox.shrink(),
          ),
        ],
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
                    Container(
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
                Container(
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