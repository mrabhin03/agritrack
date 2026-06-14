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

// ── Map layer definitions ─────────────────────────────
enum _MapLayer { street, satellite, terrain, topo }

extension _MapLayerX on _MapLayer {
  String get label {
    switch (this) {
      case _MapLayer.street:    return 'Street';
      case _MapLayer.satellite: return 'Satellite';
      case _MapLayer.terrain:   return 'Terrain';
      case _MapLayer.topo:      return 'Topo';
    }
  }

  IconData get icon {
    switch (this) {
      case _MapLayer.street:    return Icons.map_outlined;
      case _MapLayer.satellite: return Icons.satellite_alt_outlined;
      case _MapLayer.terrain:   return Icons.landscape_outlined;
      case _MapLayer.topo:      return Icons.terrain_outlined;
    }
  }

  String get urlTemplate {
    switch (this) {
      case _MapLayer.street:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case _MapLayer.satellite:
        // Esri World Imagery — free, no key required
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case _MapLayer.terrain:
        // Esri World Terrain Base
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Terrain_Base/MapServer/tile/{z}/{y}/{x}';
      case _MapLayer.topo:
        // OpenTopoMap
        return 'https://tile.opentopomap.org/{z}/{x}/{y}.png';
    }
  }

  String get attribution {
    switch (this) {
      case _MapLayer.street:
        return '© OpenStreetMap contributors';
      case _MapLayer.satellite:
      case _MapLayer.terrain:
        return '© Esri, Maxar, Earthstar Geographics';
      case _MapLayer.topo:
        return '© OpenTopoMap, © OpenStreetMap contributors';
    }
  }

  // Polygon opacity looks better on dark satellite tiles
  bool get isDark => this == _MapLayer.satellite;
}

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
      LatLng(9.295890, 76.669594),
      LatLng(9.296886, 76.669404),
      LatLng(9.298390, 76.669782),
      LatLng(9.298559, 76.670392),
      LatLng(9.297821, 76.671003),
      LatLng(9.295806, 76.670577),
    ],
    'center': LatLng(9.297028, 76.670179),
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
  _MapLayer _activeLayer = _MapLayer.street;
  bool _showLayerPicker = false;

  double get _totalArea =>
      _fakePlots.fold(0.0, (sum, p) => sum + (p['areaHa'] as double));

  Set<String> get _uniqueCrops =>
      _fakePlots.map((p) => p['crop'] as String).toSet();

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

          // ── Layer picker (top-right) ──────────────
          Positioned(
            top: 12, right: 16,
            child: _buildLayerToggle(),
          ),

          // ── Layer picker popup ────────────────────
          if (_showLayerPicker)
            Positioned(
              top: 60, right: 16,
              child: _buildLayerPicker(),
            ),

          // ── Bottom toggle ─────────────────────────
          if (!_showList)
            Positioned(
              bottom: 88, left: 16, right: 16,
              child: _buildBottomToggle(),
            ),

          // ── Plot list panel ───────────────────────
          AnimatedSlide(
            offset: _showList ? Offset.zero : const Offset(0, 1),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: _showList ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _buildPlotListSheet(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _AddPlotButton(
        onTap: () => context.push('/add-plot'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildMap() {
    final isDark = _activeLayer.isDark;
    return FlutterMap(
      mapController: _mapController,
      options: const MapOptions(
        initialCenter: LatLng(9.297028, 76.670179),
        initialZoom: 14,
      ),
      children: [
        TileLayer(
          key: ValueKey(_activeLayer),
          urlTemplate: _activeLayer.urlTemplate,
          userAgentPackageName: 'com.agritrack',
        ),
        PolygonLayer(
          polygons: _fakePlots.asMap().entries.map((e) {
            final plot = e.value;
            final color = isDark ? Colors.white : _plotColors[e.key % _plotColors.length];
            final isSelected = _selectedPlotId == plot['id'];
            return Polygon(
              points: plot['boundary'] as List<LatLng>,
              color: color.withOpacity(isSelected ? 0.35 : 0.18),
              borderColor: isSelected
                  ? (isDark ? Colors.yellowAccent : AppColors.warning)
                  : color,
              borderStrokeWidth: isSelected ? 3 : 1.5,
            );
          }).toList(),
        ),
        MarkerLayer(
          markers: _fakePlots.map((plot) {
            final isSelected = _selectedPlotId == plot['id'];
            return Marker(
              point: plot['center'] as LatLng,
              width: 120,
              height: 32,
              child: GestureDetector(
                onTap: () => _selectPlot(
                    plot['id'] as String, plot['center'] as LatLng),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                            ? Colors.black.withOpacity(0.65)
                            : AppColors.surface),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? Colors.white30 : AppColors.border),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    plot['name'] as String,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white : AppColors.textPrimary),
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

  // Small icon button that opens the picker
  Widget _buildLayerToggle() {
    return GestureDetector(
      onTap: () => setState(() => _showLayerPicker = !_showLayerPicker),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _showLayerPicker ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.layers_outlined,
          size: 20,
          color: _showLayerPicker ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }

  // Dropdown card with all layer options
  Widget _buildLayerPicker() {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _MapLayer.values.map((layer) {
          final isActive = layer == _activeLayer;
          final isLast = layer == _MapLayer.values.last;
          return GestureDetector(
            onTap: () {
              setState(() {
                _activeLayer = layer;
                _showLayerPicker = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.successBg
                    : Colors.transparent,
                borderRadius: BorderRadius.vertical(
                  top: layer == _MapLayer.values.first
                      ? const Radius.circular(12)
                      : Radius.zero,
                  bottom: isLast ? const Radius.circular(12) : Radius.zero,
                ),
                border: isLast
                    ? null
                    : const Border(
                        bottom: BorderSide(color: AppColors.border, width: 0.5),
                      ),
              ),
              child: Row(
                children: [
                  Icon(
                    layer.icon,
                    size: 16,
                    color: isActive ? AppColors.primary : AppColors.textDisabled,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    layer.label,
                    style: AppTextStyles.label.copyWith(
                      color: isActive
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (isActive) ...[
                    const Spacer(),
                    const Icon(Icons.check,
                        size: 14, color: AppColors.primary),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      // leave right side clear for the layer toggle button
      margin: const EdgeInsets.fromLTRB(16, 12, 64, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.map_outlined, size: 16, color: AppColors.accent),
          const SizedBox(width: 8),
          Text(
            '${_fakePlots.length} Plot${_fakePlots.length == 1 ? '' : 's'}',
            style: AppTextStyles.label,
          ),
          const SizedBox(width: 6),
          Text('·',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textDisabled)),
          const SizedBox(width: 6),
          Text(
            '${_totalArea.toStringAsFixed(1)} ha',
            style: AppTextStyles.caption,
          ),
          const Spacer(),
          ..._uniqueCrops.map(
            (crop) => Padding(
              padding: const EdgeInsets.only(left: 6),
              child: AppBadge(
                label: crop,
                variant: BadgeVariant.success,
                icon: Icons.grass,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomToggle() {
    return GestureDetector(
      onTap: () => setState(() {
        _showList = true;
        _showLayerPicker = false;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.view_list_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'Show Plot List',
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
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
            child: Row(
              children: [
                Text('All Plots', style: AppTextStyles.h3),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.map_rounded,
                      color: AppColors.textDisabled, size: 20),
                  tooltip: 'Back to map',
                  onPressed: () => setState(() => _showList = false),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: _fakePlots.isEmpty
                ? const EmptyState.noPlots()
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      16, 12, 16,
                      MediaQuery.of(context).padding.bottom + 16,
                    ),
                    shrinkWrap: true,
                    itemCount: _fakePlots.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _PlotListTile(
                      plot: _fakePlots[i],
                      plotColor: _plotColors[i % _plotColors.length],
                      isSelected: _selectedPlotId == _fakePlots[i]['id'],
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
      _showLayerPicker = false;
    });
    _mapController.move(center, 15);
  }
}

// ── Custom Add Plot Button ────────────────────────────
class _AddPlotButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPlotButton({required this.onTap});

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
            const Icon(Icons.add_location_alt_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              'Add Plot',
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

// ── Plot List Tile ────────────────────────────────────
class _PlotListTile extends StatelessWidget {
  final Map<String, dynamic> plot;
  final Color plotColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlotListTile({
    required this.plot,
    required this.plotColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      borderColor: isSelected ? AppColors.primary : AppColors.border,
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 4,
              decoration: BoxDecoration(
                color: isSelected ? plotColor : plotColor.withOpacity(0.4),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(plot['name'] as String,
                              style: AppTextStyles.h3),
                          const SizedBox(height: 3),
                          Text(
                            '${plot['farmerName']}  ·  ${plot['soilType']}  ·  ${plot['irrigation']}',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}