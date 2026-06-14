// features/plots/plots_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_header.dart';

// ── Fake plots data ───────────────────────────────────
final _fakePlots = [
  {
    'id': 'P001',
    'farmerId': 'F001',
    'farmerName': 'Arun Menon',
    'name': 'South Field',
    'areaHa': 1.2,
    'soilType': 'Loamy',
    'irrigation': 'Drip',
    'crop': 'Turmeric',
    'boundary': [
      LatLng(10.0275, 76.3084),
      LatLng(10.0285, 76.3094),
      LatLng(10.0280, 76.3104),
      LatLng(10.0265, 76.3094),
    ],
    'center': LatLng(10.0276, 76.3094),
  },
  {
    'id': 'P002',
    'farmerId': 'F001',
    'farmerName': 'Arun Menon',
    'name': 'North Field',
    'areaHa': 0.8,
    'soilType': 'Red laterite',
    'irrigation': 'Rain-fed',
    'crop': 'Turmeric',
    'boundary': [
      LatLng(10.0310, 76.3070),
      LatLng(10.0320, 76.3080),
      LatLng(10.0315, 76.3090),
      LatLng(10.0305, 76.3080),
    ],
    'center': LatLng(10.0312, 76.3080),
  },
  {
    'id': 'P003',
    'farmerId': 'F002',
    'farmerName': 'Priya Nair',
    'name': 'Hill Plot',
    'areaHa': 1.8,
    'soilType': 'Sandy loam',
    'irrigation': 'Sprinkler',
    'crop': 'Turmeric',
    'boundary': [
      LatLng(10.0890, 77.0595),
      LatLng(10.0900, 77.0610),
      LatLng(10.0895, 77.0625),
      LatLng(10.0880, 77.0610),
    ],
    'center': LatLng(10.0891, 77.0610),
  },
];

// Plot polygon colors
const _plotColors = [
  Color(0xFF2D6A4F),
  Color(0xFF40916C),
  Color(0xFF74C69D),
];

class PlotsScreen extends StatefulWidget {
  const PlotsScreen({super.key});

  @override
  State<PlotsScreen> createState() => _PlotsScreenState();
}

class _PlotsScreenState extends State<PlotsScreen> {
  final _mapController = MapController();
  String? _selectedPlotId;
  bool _showList = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────
          _buildMap(),

          // ── Top summary bar ───────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: _buildSummaryBar(),
          ),

          // ── Bottom sheet toggle ───────────────────
          Positioned(
            bottom: 80, left: 16, right: 16,
            child: _buildBottomToggle(),
          ),

          // ── Plot list panel ───────────────────────
          if (_showList)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: _buildPlotListSheet(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-plot'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Add Plot'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: const MapOptions(
        initialCenter: LatLng(10.0275, 76.3084),
        initialZoom: 13,
      ),
      children: [
        // OSM tiles
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.agritrack',
        ),
        // Plot polygons
        PolygonLayer(
          polygons: _fakePlots.asMap().entries.map((e) {
            final plot = e.value;
            final color = _plotColors[e.key % _plotColors.length];
            final isSelected = _selectedPlotId == plot['id'];
            return Polygon(
              points: plot['boundary'] as List<LatLng>,
              color: color.withOpacity(isSelected ? 0.5 : 0.3),
              borderColor: isSelected ? AppColors.warning : color,
              borderStrokeWidth: isSelected ? 3 : 1.5,
            );
          }).toList(),
        ),
        // Plot labels
        MarkerLayer(
          markers: _fakePlots.map((plot) {
            return Marker(
              point: plot['center'] as LatLng,
              width: 120,
              height: 32,
              child: GestureDetector(
                onTap: () => _selectPlot(plot['id'] as String,
                    plot['center'] as LatLng),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    plot['name'] as String,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSummaryBar() {
    final totalArea = _fakePlots.fold<double>(
        0, (sum, p) => sum + (p['areaHa'] as double));
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.map_outlined,
              size: 16, color: AppColors.accent),
          const SizedBox(width: 8),
          Text(
            '${_fakePlots.length} Plots',
            style: AppTextStyles.label,
          ),
          const SizedBox(width: 4),
          Text('•',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textDisabled)),
          const SizedBox(width: 4),
          Text(
            '${totalArea.toStringAsFixed(1)} ha total',
            style: AppTextStyles.caption,
          ),
          const Spacer(),
          AppBadge(
            label: 'Turmeric',
            variant: BadgeVariant.success,
            icon: Icons.grass,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomToggle() {
    return GestureDetector(
      onTap: () => setState(() => _showList = !_showList),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(99),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _showList ? Icons.map_outlined : Icons.list,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              _showList ? 'Show Map' : 'Show Plot List',
              style: AppTextStyles.label
                  .copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlotListSheet() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.55,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SectionHeader(
            title: 'All Plots',
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          ),
          Flexible(
            child: _fakePlots.isEmpty
                ? const EmptyState.noPlots()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    shrinkWrap: true,
                    itemCount: _fakePlots.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) => _PlotListTile(
                      plot: _fakePlots[i],
                      isSelected:
                          _selectedPlotId == _fakePlots[i]['id'],
                      onTap: () => _selectPlot(
                        _fakePlots[i]['id'] as String,
                        _fakePlots[i]['center'] as LatLng,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _selectPlot(String id, LatLng center) {
    setState(() {
      _selectedPlotId = _selectedPlotId == id ? null : id;
      _showList = false;
    });
    _mapController.move(center, 15);
  }
}

// ── Plot List Tile ────────────────────────────────────
class _PlotListTile extends StatelessWidget {
  final Map<String, dynamic> plot;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlotListTile({
    required this.plot,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      borderColor: isSelected ? AppColors.primary : AppColors.border,
      onTap: onTap,
      child: Row(
        children: [
          // Color dot
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 10),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plot['name'] as String, style: AppTextStyles.h3),
                const SizedBox(height: 2),
                Text(
                  '${plot['farmerName']}  •  ${plot['soilType']}  •  ${plot['irrigation']}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          // Area badge
          AppFlatCard(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            child: Text(
              '${plot['areaHa']} ha',
              style: AppTextStyles.label.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}