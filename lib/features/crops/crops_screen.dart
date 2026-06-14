// features/crops/crops_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_header.dart';

// ── Fake data ─────────────────────────────────────────
const _fakeSeasons = [
  {
    'id': 'S001',
    'farmerId': 'F001',
    'farmerName': 'Arun Menon',
    'variety': 'IISR Pragati',
    'plantingDate': '12/01/2025',
    'harvestDate': '10/07/2025',
    'targetYield': 38.0,
    'status': 'On track',
    'stage': 'Growth',
    'dap': 45,
  },
  {
    'id': 'S002',
    'farmerId': 'F002',
    'farmerName': 'Priya Nair',
    'variety': 'IISR Prabha',
    'plantingDate': '05/11/2024',
    'harvestDate': '23/06/2025',
    'targetYield': 32.0,
    'status': 'On track',
    'stage': 'Flowering',
    'dap': 120,
  },
  {
    'id': 'S003',
    'farmerId': 'F003',
    'farmerName': 'Suresh Kumar',
    'variety': 'Co-1',
    'plantingDate': '01/09/2024',
    'harvestDate': '29/03/2025',
    'targetYield': 25.0,
    'status': 'Complete',
    'stage': 'Harvest',
    'dap': 210,
  },
  {
    'id': 'S004',
    'farmerId': 'F004',
    'farmerName': 'Latha Krishnan',
    'variety': 'BSS-1',
    'plantingDate': '20/02/2025',
    'harvestDate': '28/08/2025',
    'targetYield': 28.0,
    'status': 'Delayed',
    'stage': 'Nursery',
    'dap': 10,
  },
];

const _statusFilters = ['All', 'On track', 'Delayed', 'Complete'];
const _stages = ['Nursery', 'Planting', 'Growth', 'Flowering', 'Harvest'];

class CropsScreen extends StatefulWidget {
  const CropsScreen({super.key});

  @override
  State<CropsScreen> createState() => _CropsScreenState();
}

class _CropsScreenState extends State<CropsScreen> {
  String _statusFilter = 'All';
  String? _expandedId;

  List<Map<String, dynamic>> get _filtered => _fakeSeasons
      .where((s) => _statusFilter == 'All' || s['status'] == _statusFilter)
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildFilterChips(),
          const Divider(height: 1),
          Expanded(
            child: _filtered.isEmpty
                ? const EmptyState.noSeasons()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _SeasonCard(
                      season: _filtered[i],
                      isExpanded: _expandedId == _filtered[i]['id'],
                      onToggle: () => setState(() {
                        _expandedId = _expandedId == _filtered[i]['id']
                            ? null
                            : _filtered[i]['id'] as String;
                      }),
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
  final Map<String, dynamic> season;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _SeasonCard({
    required this.season,
    required this.isExpanded,
    required this.onToggle,
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
                  // Stage icon circle with gradient
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.stageBgColor(season['stage'] as String),
                          AppColors.stageColor(season['stage'] as String)
                              .withOpacity(0.18),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Icon(
                      _stageIcon(season['stage'] as String),
                      color: AppColors.stageColor(season['stage'] as String),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          season['farmerName'] as String,
                          style: AppTextStyles.h3,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${season['variety']}  •  ${season['stage']}  •  ${season['dap']} DAP',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  SeasonStatusBadge(status: season['status'] as String),
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
                                  date: season['plantingDate'] as String,
                                  icon: Icons.calendar_today,
                                ),
                                const SizedBox(width: 8),
                                _DateChip(
                                  label: 'Harvest',
                                  date: season['harvestDate'] as String,
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
                                    '${season['targetYield']} t/ha',
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
                            _GrowthTimeline(
                                currentStage: season['stage'] as String),
                            const SizedBox(height: 14),

                            // Action button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => context.push(
                                  '/add-event?seasonId=${season['id']}',
                                ),
                                icon: const Icon(Icons.edit_note, size: 18),
                                label: const Text('Log Event'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: BorderSide(color: AppColors.primary),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
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
      case 'Nursery':   return Icons.grass;
      case 'Planting':  return Icons.spa;
      case 'Growth':    return Icons.trending_up;
      case 'Flowering': return Icons.local_florist;
      case 'Harvest':   return Icons.agriculture;
      default:          return Icons.grass;
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
        final done    = i < currentIdx;
        final active  = i == currentIdx;
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
                    // Circle node
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
              // Connector line between nodes, vertically centred on the circles
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
      case 'Nursery':   return Icons.grass;
      case 'Planting':  return Icons.spa;
      case 'Growth':    return Icons.trending_up;
      case 'Flowering': return Icons.local_florist;
      case 'Harvest':   return Icons.agriculture;
      default:          return Icons.circle;
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
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textPrimary,
                  ),
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
      case 'On track': return BadgeVariant.success;
      case 'Delayed':  return BadgeVariant.warning;
      case 'Complete': return BadgeVariant.info;
      default:         return BadgeVariant.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppStatusBadge(label: status, variant: _variant);
  }
}