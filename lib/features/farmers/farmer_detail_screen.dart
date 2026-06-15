// features/farmers/farmer_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/section_header.dart';
import 'models/farmer_model.dart';
import 'providers/farmers_provider.dart';

class FarmerDetailScreen extends ConsumerWidget {
  final String farmerId;
  const FarmerDetailScreen({super.key, required this.farmerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmer = ref.watch(farmerByIdProvider(farmerId));
    final plotCount = ref.watch(farmerPlotCountProvider(farmerId));
    final activeStage = ref.watch(farmerActiveSeasonProvider(farmerId));

    if (farmer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Farmer Detail')),
        body: const Center(child: Text('Farmer not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(farmer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit farmer',
            onPressed: () => _showEditSheet(context, ref, farmer),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header card ──────────────────────────────
          _HeaderCard(farmer: farmer, activeStage: activeStage),
          const SizedBox(height: 16),
          // ── Stats row ────────────────────────────────
          _StatsRow(farmer: farmer, plotCount: plotCount),
          const SizedBox(height: 16),
          // ── Contact & Location ───────────────────────
          SectionHeader(title: 'Contact & Location'),
          const SizedBox(height: 10),
          _InfoCard(children: [
            _InfoRow(
              icon: Icons.phone,
              label: 'Mobile',
              value: farmer.phone,
            ),
            _InfoRow(
              icon: Icons.location_on,
              label: 'Village',
              value: farmer.village,
            ),
            _InfoRow(
              icon: Icons.my_location,
              label: 'GPS',
              value: farmer.gpsLat != null && farmer.gpsLng != null
                  ? '${farmer.gpsLat!.toStringAsFixed(4)}° N, '
                      '${farmer.gpsLng!.toStringAsFixed(4)}° E'
                  : 'Not captured',
            ),
          ]),
          const SizedBox(height: 16),
          // ── Farm Details ─────────────────────────────
          SectionHeader(title: 'Farm Details'),
          const SizedBox(height: 10),
          _InfoCard(children: [
            _InfoRow(
              icon: Icons.landscape,
              label: 'Total Area',
              value: '${farmer.areaHa} ha',
            ),
            _InfoRow(
              icon: Icons.person,
              label: 'Age',
              value: '${farmer.age} yrs',
            ),
            _InfoRow(
              icon: Icons.map,
              label: 'Plots',
              value: '$plotCount plot${plotCount == 1 ? '' : 's'}',
            ),
            _InfoRow(
              icon: Icons.grass,
              label: 'Current Stage',
              value: activeStage ?? farmer.stage,
            ),
          ]),
          const SizedBox(height: 16),
          // ── Notes ────────────────────────────────────
          if (farmer.notes != null && farmer.notes!.isNotEmpty) ...[
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
              child: Text(farmer.notes!, style: AppTextStyles.body),
            ),
            const SizedBox(height: 16),
          ],
          // ── Quick Actions ────────────────────────────
          SectionHeader(title: 'Quick Actions'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.agriculture,
                  label: 'Add Season',
                  onTap: () =>
                      context.push('/add-season?farmerId=${farmer.id}'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.map_outlined,
                  label: 'Add Plot',
                  onTap: () =>
                      context.push('/add-plot?farmerId=${farmer.id}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // ── Delete ───────────────────────────────────
          OutlinedButton.icon(
            onPressed: () => _confirmDelete(context, ref, farmer),
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

  // ── Edit bottom sheet ───────────────────────────────
  void _showEditSheet(
      BuildContext context, WidgetRef ref, FarmerModel farmer) {
    final nameCtrl = TextEditingController(text: farmer.name);
    final phoneCtrl = TextEditingController(text: farmer.phone);
    final villageCtrl = TextEditingController(text: farmer.village);
    final areaCtrl =
        TextEditingController(text: farmer.areaHa.toString());
    final notesCtrl = TextEditingController(text: farmer.notes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Farmer', style: AppTextStyles.h2),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Farmer Name *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: villageCtrl,
              decoration: const InputDecoration(labelText: 'Village *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: areaCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Area (ha) *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await ref
                      .read(farmersProvider.notifier)
                      .updateFarmer(farmer.id, {
                    'name': nameCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'village': villageCtrl.text.trim(),
                    'area_ha':
                        double.tryParse(areaCtrl.text.trim()) ??
                            farmer.areaHa,
                    'notes': notesCtrl.text.trim(),
                  });
                  if (ctx.mounted) ctx.pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Changes saved successfully')),
                    );
                  }
                },
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete confirmation ─────────────────────────────
  void _confirmDelete(
      BuildContext context, WidgetRef ref, FarmerModel farmer) {
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
            onPressed: () async {
              ctx.pop();
              await ref
                  .read(farmersProvider.notifier)
                  .deleteFarmer(farmer.id);
              if (context.mounted) {
                context.pop(); // back to farmers list
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Farmer removed')),
                );
              }
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

// ── Header Card ───────────────────────────────────────────
class _HeaderCard extends StatelessWidget {
  final FarmerModel farmer;
  final String? activeStage;
  const _HeaderCard({required this.farmer, required this.activeStage});

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
              farmer.initials,
              style: AppTextStyles.h2.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(farmer.name, style: AppTextStyles.h2),
                const SizedBox(height: 4),
                Text(
                  'ID: ${farmer.id} • Age: ${farmer.age}',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 8),
                AppBadge(label: activeStage ?? farmer.stage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final FarmerModel farmer;
  final int plotCount;
  const _StatsRow({required this.farmer, required this.plotCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatBox(label: 'Area', value: '${farmer.areaHa} ha'),
        const SizedBox(width: 10),
        _StatBox(label: 'Plots', value: '$plotCount'),
        const SizedBox(width: 10),
        _StatBox(label: 'Stage', value: farmer.stage),
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
                style:
                    AppTextStyles.h2.copyWith(color: AppColors.primary)),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

// ── Info Card ─────────────────────────────────────────────
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

// ── Info Row ──────────────────────────────────────────────
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

// ── Action Button ─────────────────────────────────────────
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
                style: AppTextStyles.label
                    .copyWith(color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}