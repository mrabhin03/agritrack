// features/plots/plots_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';

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
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case _MapLayer.terrain:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Terrain_Base/MapServer/tile/{z}/{y}/{x}';
      case _MapLayer.topo:
        return 'https://tile.opentopomap.org/{z}/{x}/{y}.png';
    }
  }

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

class _PlotsScreenState extends State<PlotsScreen>
    with TickerProviderStateMixin {
  final _mapController = MapController();
  String? _selectedPlotId;
  bool _showList = false;
  _MapLayer _activeLayer = _MapLayer.street;

  // For animating the selected plot detail card
  late final AnimationController _detailAnim;
  late final Animation<Offset> _detailSlide;

  @override
  void initState() {
    super.initState();
    _detailAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _detailSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _detailAnim, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _detailAnim.dispose();
    super.dispose();
  }

  Map<String, dynamic>? get _selectedPlot => _selectedPlotId == null
      ? null
      : _fakePlots.firstWhere((p) => p['id'] == _selectedPlotId,
          orElse: () => {});

  double get _totalArea =>
      _fakePlots.fold(0.0, (sum, p) => sum + (p['areaHa'] as double));

  int get _uniqueFarmerCount =>
      _fakePlots.map((p) => p['farmerId']).toSet().length;

  void _selectPlot(String id, LatLng center) {
    final isSame = _selectedPlotId == id;
    setState(() {
      _selectedPlotId = isSame ? null : id;
      _showList = false;
    });
    if (isSame) {
      _detailAnim.reverse();
    } else {
      _mapController.move(center, 15.5);
      _detailAnim.forward(from: 0);
    }
  }

  void _clearSelection() {
    setState(() => _selectedPlotId = null);
    _detailAnim.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Full-screen map ───────────────────────
          _buildMap(),

          // ── Top bar ───────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: _buildTopBar(),
          ),

          // ── Selected plot detail card ─────────────
          if (_selectedPlot != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: bottomPad + 80,
              child: SlideTransition(
                position: _detailSlide,
                child: _PlotDetailCard(
                  plot: _selectedPlot!,
                  plotColor: _plotColors[
                      _fakePlots.indexWhere((p) => p['id'] == _selectedPlotId) %
                          _plotColors.length],
                  onClose: _clearSelection,
                  onNavigate: () {
                    // TODO: navigate to plot detail screen
                  },
                ),
              ),
            ),

          // ── Bottom action bar ─────────────────────
          if (_selectedPlot == null)
            Positioned(
              left: 12,
              right: 12,
              bottom: bottomPad + 12,
              child: _buildBottomActions(),
            ),

          // ── Plot list sheet ───────────────────────
          AnimatedSlide(
            offset: _showList ? Offset.zero : const Offset(0, 1),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: _showList ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _buildPlotListSheet(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top bar: summary + layer switcher ────────────
  Widget _buildTopBar() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary chip
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.97),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.09),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Plots count
                _StatPill(
                  icon: Icons.crop_square_rounded,
                  value: '${_fakePlots.length}',
                  label: 'plots',
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text('·', style: TextStyle(color: AppColors.textDisabled, fontSize: 12)),
                const SizedBox(width: 6),
                // Total area
                _StatPill(
                  icon: Icons.straighten_outlined,
                  value: '${_totalArea.toStringAsFixed(1)}',
                  label: 'ha',
                  color: AppColors.accent,
                ),
                const SizedBox(width: 6),
                Text('·', style: TextStyle(color: AppColors.textDisabled, fontSize: 12)),
                const SizedBox(width: 6),
                // Farmers
                _StatPill(
                  icon: Icons.people_outline,
                  value: '$_uniqueFarmerCount',
                  label: 'farmers',
                  color: const Color(0xFF7B61FF),
                ),
                const Spacer(),
                // Inline crop chip — handles tight width without overflowing
                Container(
                  constraints: const BoxConstraints(maxWidth: 88),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8F3DC),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.grass, size: 11, color: Color(0xFF2D6A4F)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Turmeric',
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFF2D6A4F),
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Layer switcher
        _LayerSwitcher(
          activeLayer: _activeLayer,
          onLayerChanged: (l) => setState(() => _activeLayer = l),
        ),
      ],
    );
  }

  // ── Bottom action bar ─────────────────────────────
  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.97),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Show list button
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showList = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.view_list_rounded,
                        size: 17, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'Plot List',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Add plot button
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/add-plot'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_location_alt_rounded,
                        size: 17, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'Add Plot',
                      style: AppTextStyles.label.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Map ───────────────────────────────────────────
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
            final color = isDark
                ? Colors.white
                : _plotColors[e.key % _plotColors.length];
            final isSelected = _selectedPlotId == plot['id'];
            return Polygon(
              points: plot['boundary'] as List<LatLng>,
              color: color.withOpacity(isSelected ? 0.38 : 0.15),
              borderColor: isSelected
                  ? (isDark ? Colors.yellowAccent : AppColors.warning)
                  : color.withOpacity(isSelected ? 1 : 0.8),
              borderStrokeWidth: isSelected ? 3 : 1.8,
            );
          }).toList(),
        ),
        MarkerLayer(
          markers: _fakePlots.asMap().entries.map((e) {
            final plot = e.value;
            final color = _plotColors[e.key % _plotColors.length];
            final isSelected = _selectedPlotId == plot['id'];
            return Marker(
              point: plot['center'] as LatLng,
              width: 130,
              height: 40,
              child: GestureDetector(
                onTap: () => _selectPlot(
                    plot['id'] as String, plot['center'] as LatLng),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected ? color : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? color : color.withOpacity(0.5),
                      width: isSelected ? 0 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(isSelected ? 0.35 : 0.15),
                        blurRadius: isSelected ? 10 : 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          plot['name'] as String,
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Plot list bottom sheet ────────────────────────
  Widget _buildPlotListSheet() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.58,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                Text('All Plots', style: AppTextStyles.h3),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_fakePlots.length}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                // Close
                GestureDetector(
                  onTap: () => setState(() => _showList = false),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.close,
                        size: 16, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          Flexible(
            child: _fakePlots.isEmpty
                ? const EmptyState.noPlots()
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      12, 12, 12,
                      MediaQuery.of(context).padding.bottom + 20,
                    ),
                    shrinkWrap: true,
                    itemCount: _fakePlots.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _PlotListTile(
                      plot: _fakePlots[i],
                      plotColor: _plotColors[i % _plotColors.length],
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
}

// ── Stat pill widget ──────────────────────────────────
class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ── Layer switcher ────────────────────────────────────
class _LayerSwitcher extends StatelessWidget {
  const _LayerSwitcher({
    required this.activeLayer,
    required this.onLayerChanged,
  });

  final _MapLayer activeLayer;
  final ValueChanged<_MapLayer> onLayerChanged;

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: Text('Map Style', style: AppTextStyles.h3),
            ),
            const Divider(height: 1),
            ...(_MapLayer.values.map((layer) {
              final isActive = layer == activeLayer;
              return ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    layer.icon,
                    size: 18,
                    color: isActive
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
                title: Text(
                  layer.label,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: isActive
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontWeight: isActive
                        ? FontWeight.w700
                        : FontWeight.normal,
                  ),
                ),
                trailing: isActive
                    ? Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            size: 13, color: Colors.white),
                      )
                    : null,
                onTap: () {
                  onLayerChanged(layer);
                  Navigator.pop(context);
                },
              );
            })),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.97),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.09),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(
          Icons.layers_outlined,
          size: 20,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

// ── Selected plot detail card ─────────────────────────
class _PlotDetailCard extends StatelessWidget {
  const _PlotDetailCard({
    required this.plot,
    required this.plotColor,
    required this.onClose,
    required this.onNavigate,
  });

  final Map<String, dynamic> plot;
  final Color plotColor;
  final VoidCallback onClose;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: plotColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: plotColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Coloured top accent bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: plotColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: name + close
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(plot['name'] as String,
                              style: AppTextStyles.h3),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.person_outline,
                                  size: 12,
                                  color: AppColors.textSecondary),
                              const SizedBox(width: 3),
                              Text(
                                plot['farmerName'] as String,
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Close
                    GestureDetector(
                      onTap: onClose,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.close,
                            size: 14,
                            color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Row 2: stat chips
                Row(
                  children: [
                    _DetailChip(
                      icon: Icons.straighten_outlined,
                      label: '${plot['areaHa']} ha',
                      color: plotColor,
                    ),
                    const SizedBox(width: 6),
                    _DetailChip(
                      icon: Icons.terrain_outlined,
                      label: plot['soilType'] as String,
                    ),
                    const SizedBox(width: 6),
                    _DetailChip(
                      icon: Icons.water_drop_outlined,
                      label: plot['irrigation'] as String,
                    ),
                    const Spacer(),
                    // Navigate arrow
                    GestureDetector(
                      onTap: onNavigate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: plotColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'View',
                              style: AppTextStyles.label.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_rounded,
                                size: 13, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: c),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: c,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Plot list tile ────────────────────────────────────
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? plotColor.withOpacity(0.06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? plotColor : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: plotColor.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Color bar
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: plotColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),
              // Farmer avatar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: plotColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    (plot['farmerName'] as String)[0],
                    style: AppTextStyles.labelLarge.copyWith(
                      color: plotColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + area
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              plot['name'] as String,
                              style: AppTextStyles.h3,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Text(
                              '${plot['areaHa']} ha',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: plotColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Farmer name
                      Text(
                        plot['farmerName'] as String,
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: 6),
                      // Tags row
                      Row(
                        children: [
                          _MiniTag(plot['soilType'] as String),
                          const SizedBox(width: 5),
                          _MiniTag(plot['irrigation'] as String),
                          const SizedBox(width: 5),
                          _MiniTag(
                            plot['crop'] as String,
                            color: AppColors.success,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag(this.label, {this.color});
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textDisabled;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          fontSize: 10,
          color: c,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}