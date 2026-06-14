// features/farmers/farmer_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/section_header.dart';

// ── Fake data (replaced in Layer 6) ──────────────────
const _fakeDetails = {
  'F001': {
    'id': 'F001',
    'name': 'Arun Menon',
    'village': 'Kothamangalam',
    'phone': '9876543210',
    'age': 42,
    'area': 2.4,
    'stage': 'Growth',
    'notes': 'Experienced turmeric grower. Prefers drip irrigation.',
    'gpsLat': 10.0603,
    'gpsLng': 76.7946,
    'variety': 'IISR Pragati',
    'plots': 3,
    'seasons': 2,
  },
  'F002': {
    'id': 'F002',
    'name': 'Priya Nair',
    'village': 'Munnar',
    'phone': '9845678901',
    'age': 35,
    'area': 1.8,
    'stage': 'Flowering',
    'notes': '',
    'gpsLat': 10.0889,
    'gpsLng': 77.0595,
    'variety': 'IISR Prabha',
    'plots': 2,
    'seasons': 1,
  },
  'F003': {
    'id': 'F003',
    'name': 'Suresh Kumar',
    'village': 'Thodupuzha',
    'phone': '9812345678',
    'age': 51,
    'area': 3.2,
    'stage': 'Harvest',
    'notes': 'Ready for harvest this month.',
    'gpsLat': 9.7167,
    'gpsLng': 76.7167,
    'variety': 'Co-1',
    'plots': 4,
    'seasons': 3,
  },
  'F004': {
    'id': 'F004',
    'name': 'Latha Krishnan',
    'village': 'Erattupetta',
    'phone': '9834567890',
    'age': 38,
    'area': 1.1,
    'stage': 'Nursery',
    'notes': '',
    'gpsLat': 9.8833,
    'gpsLng': 76.7833,
    'variety': 'BSS-1',
    'plots': 1,
    'seasons': 1,
  },
  'F005': {
    'id': 'F005',
    'name': 'Biju Thomas',
    'village': 'Pala',
    'phone': '9867890123',
    'age': 46,
    'area': 2.0,
    'stage': 'Planting',
    'notes': 'New to turmeric cultivation.',
    'gpsLat': 9.7167,
    'gpsLng': 76.6833,
    'variety': 'IISR Pragati',
    'plots': 2,
    'seasons': 1,
  },
};

class FarmerDetailScreen extends StatelessWidget {
  final String farmerId;
  const FarmerDetailScreen({super.key, required this.farmerId});

  @override
  Widget build(BuildContext context) {
    final f = _fakeDetails[farmerId];

    if (f == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Farmer Detail')),
        body: const Center(child: Text('Farmer not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(f['name'] as String),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit farmer',
            onPressed: () {
              // Phase 6: wire edit
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit coming in Phase 6')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header card ────────────────────────────
          _HeaderCard(farmer: f),
          const SizedBox(height: 16),

          // ── Stats row ──────────────────────────────
          _StatsRow(farmer: f),
          const SizedBox(height: 16),

          // ── Contact & Location ─────────────────────
          SectionHeader(title: 'Contact & Location'),
          const SizedBox(height: 10),
          _InfoCard(children: [
            _InfoRow(
              icon: Icons.phone,
              label: 'Mobile',
              value: f['phone'] as String,
            ),
            _InfoRow(
              icon: Icons.location_on,
              label: 'Village',
              value: f['village'] as String,
            ),
            _InfoRow(
              icon: Icons.my_location,
              label: 'GPS',
              value:
                  '${f['gpsLat']}° N, ${f['gpsLng']}° E',
            ),
          ]),
          const SizedBox(height: 16),

          // ── Farm Details ───────────────────────────
          SectionHeader(title: 'Farm Details'),
          const SizedBox(height: 10),
          _InfoCard(children: [
            _InfoRow(
              icon: Icons.landscape,
              label: 'Total Area',
              value: '${f['area']} ha',
            ),
            _InfoRow(
              icon: Icons.grass,
              label: 'Variety',
              value: f['variety'] as String,
            ),
            _InfoRow(
              icon: Icons.map,
              label: 'Plots',
              value: '${f['plots']} plots',
            ),
            _InfoRow(
              icon: Icons.calendar_month,
              label: 'Seasons',
              value: '${f['seasons']} seasons',
            ),
          ]),
          const SizedBox(height: 16),

          // ── Notes ──────────────────────────────────
          if ((f['notes'] as String).isNotEmpty) ...[
            SectionHeader(title: 'Notes'),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                f['notes'] as String,
                style: AppTextStyles.body,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Actions ────────────────────────────────
          SectionHeader(title: 'Quick Actions'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.agriculture,
                  label: 'Add Season',
                  onTap: () => context.push(
                    '/add-season?farmerId=${f['id']}',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.map_outlined,
                  label: 'Add Plot',
                  onTap: () => context.push(
                    '/add-plot?farmerId=${f['id']}',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Delete ─────────────────────────────────
          OutlinedButton.icon(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            label: Text(
              'Remove Farmer',
              style: AppTextStyles.body.copyWith(color: AppColors.error),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Farmer'),
        content: const Text(
          'Are you sure you want to remove this farmer? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ctx.pop();
              context.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Farmer removed')),
              );
            },
            child: Text(
              'Remove',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final Map<String, dynamic> farmer;
  const _HeaderCard({required this.farmer});

  String get _initials => (farmer['name'] as String)
      .trim()
      .split(' ')
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.successBg,
            child: Text(
              _initials,
              style: AppTextStyles.h2.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(farmer['name'] as String, style: AppTextStyles.h2),
                const SizedBox(height: 4),
                Text(
                  'ID: ${farmer['id']}  •  Age: ${farmer['age']}',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 8),
                AppBadge(label: farmer['stage'] as String),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final Map<String, dynamic> farmer;
  const _StatsRow({required this.farmer});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatBox(label: 'Area', value: '${farmer['area']} ha'),
        const SizedBox(width: 10),
        _StatBox(label: 'Plots', value: '${farmer['plots']}'),
        const SizedBox(width: 10),
        _StatBox(label: 'Seasons', value: '${farmer['seasons']}'),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.successBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: AppTextStyles.h2.copyWith(color: AppColors.primary)),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: children
            .asMap()
            .entries
            .map(
              (e) => Column(
                children: [
                  e.value,
                  if (e.key < children.length - 1)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(label,
              style: AppTextStyles.label
                  .copyWith(color: AppColors.textSecondary)),
          const Spacer(),
          Text(value, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.successBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 6),
            Text(label,
                style:
                    AppTextStyles.label.copyWith(color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}