// features/farmers/farmers_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/empty_state.dart';

// ── Fake data (replaced in Layer 6) ──────────────────
const _fakeFarmers = [
  {
    'id': 'F001',
    'name': 'Arun Menon',
    'village': 'Kothamangalam',
    'phone': '9876543210',
    'stage': 'Growth',
    'area': 2.4,
  },
  {
    'id': 'F002',
    'name': 'Priya Nair',
    'village': 'Munnar',
    'phone': '9845678901',
    'stage': 'Flowering',
    'area': 1.8,
  },
  {
    'id': 'F003',
    'name': 'Suresh Kumar',
    'village': 'Thodupuzha',
    'phone': '9812345678',
    'stage': 'Harvest',
    'area': 3.2,
  },
  {
    'id': 'F004',
    'name': 'Latha Krishnan',
    'village': 'Erattupetta',
    'phone': '9834567890',
    'stage': 'Nursery',
    'area': 1.1,
  },
  {
    'id': 'F005',
    'name': 'Biju Thomas',
    'village': 'Pala',
    'phone': '9867890123',
    'stage': 'Planting',
    'area': 2.0,
  },
];

const _stages = ['All', 'Nursery', 'Planting', 'Growth', 'Flowering', 'Harvest'];

class FarmersScreen extends StatefulWidget {
  const FarmersScreen({super.key});

  @override
  State<FarmersScreen> createState() => _FarmersScreenState();
}

class _FarmersScreenState extends State<FarmersScreen> {
  String _search = '';
  String _stageFilter = 'All';

  List<Map<String, dynamic>> get _filtered => _fakeFarmers.where((f) {
        final q = _search.toLowerCase();
        final matchQ = q.isEmpty ||
            (f['name'] as String).toLowerCase().contains(q) ||
            (f['village'] as String).toLowerCase().contains(q) ||
            (f['phone'] as String).contains(q);
        final matchS = _stageFilter == 'All' || f['stage'] == _stageFilter;
        return matchQ && matchS;
      }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          const Divider(height: 1),
          Expanded(
            child: _filtered.isEmpty
                ? const EmptyState.noResults()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) =>
                        _FarmerCard(farmer: _filtered[i]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-farmer'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Farmer'),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
        style: AppTextStyles.body,
        decoration: InputDecoration(
          hintText: 'Search by name, village or phone...',
          hintStyle: AppTextStyles.body.copyWith(color: AppColors.textDisabled),
          prefixIcon: const Icon(Icons.search, color: AppColors.textDisabled),
          suffixIcon: _search.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => setState(() => _search = ''),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _stages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final s = _stages[i];
          final selected = s == _stageFilter;
          return FilterChip(
            label: Text(s, style: AppTextStyles.label),
            selected: selected,
            onSelected: (_) => setState(() => _stageFilter = s),
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

// ── Farmer Card ───────────────────────────────────────
class _FarmerCard extends StatelessWidget {
  final Map<String, dynamic> farmer;
  const _FarmerCard({required this.farmer});

  String get _initials => (farmer['name'] as String)
      .trim()
      .split(' ')
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/farmers/${farmer['id']}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.successBg,
                child: Text(
                  _initials,
                  style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(farmer['name'] as String, style: AppTextStyles.h3),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 13, color: AppColors.textDisabled),
                        const SizedBox(width: 2),
                        Text(farmer['village'] as String,
                            style: AppTextStyles.caption),
                        const SizedBox(width: 10),
                        const Icon(Icons.landscape,
                            size: 13, color: AppColors.textDisabled),
                        const SizedBox(width: 2),
                        Text('${farmer['area']} ha',
                            style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                ),
              ),
              // Stage badge
              AppBadge(label: farmer['stage'] as String),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }
}