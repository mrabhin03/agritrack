// features/farmers/farmers_screen.dart
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

class FarmersScreen extends ConsumerWidget {
  const FarmersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmersAsync = ref.watch(farmersProvider);
    final filtered = ref.watch(filteredFarmersProvider);
    final search = ref.watch(farmersSearchProvider);
    final stageFilter = ref.watch(farmersStageFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────
          _SearchBar(
            value: search,
            onChanged: (v) =>
                ref.read(farmersSearchProvider.notifier).state = v,
            onClear: () =>
                ref.read(farmersSearchProvider.notifier).state = '',
          ),
          // ── Stage filter chips ──────────────────────
          _StageFilterChips(
            selected: stageFilter,
            onSelect: (s) =>
                ref.read(farmersStageFilterProvider.notifier).state = s,
          ),
          const Divider(height: 1),
          // ── List ────────────────────────────────────
          Expanded(
            child: farmersAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Text('Error: $e', style: AppTextStyles.body),
              ),
              data: (_) => filtered.isEmpty
                  ? search.isNotEmpty || stageFilter != 'All'
                      ? const EmptyState.noResults()
                      : EmptyState.noFarmers(
                          onAction: () => context.push('/add-farmer'),
                        )
                  : ListView.separated(
                      padding:
                          const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, i) =>
                          _FarmerCard(farmer: filtered[i]),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: _AddFarmerButton(
        onTap: () => context.push('/add-farmer'),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ── Search Bar ────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.value,
    required this.onChanged,
    required this.onClear,
  });
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        onChanged: onChanged,
        style: AppTextStyles.body,
        decoration: InputDecoration(
          hintText: 'Search by name, village or phone...',
          hintStyle:
              AppTextStyles.body.copyWith(color: AppColors.textDisabled),
          prefixIcon:
              const Icon(Icons.search, color: AppColors.textDisabled),
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
          suffixIcon: value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: onClear,
                )
              : null,
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
  });
  final String selected;
  final ValueChanged<String> onSelect;

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
          return FilterChip(
            label: Text(s, style: AppTextStyles.label),
            selected: isSelected,
            onSelected: (_) => onSelect(s),
            selectedColor: AppColors.successBg,
            checkmarkColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          );
        },
      ),
    );
  }
}

// ── Add Farmer FAB ────────────────────────────────────────
class _AddFarmerButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddFarmerButton({required this.onTap});

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
            const Icon(Icons.eco_rounded, color: Colors.white, size: 20),
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
    );
  }
}

// ── Farmer Card ───────────────────────────────────────────
class _FarmerCard extends StatelessWidget {
  final FarmerModel farmer;
  const _FarmerCard({required this.farmer});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.successBg,
        onTap: () => context.push('/farmers/${farmer.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              Container(
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
                  style:
                      AppTextStyles.h3.copyWith(color: AppColors.primary),
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
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }
}