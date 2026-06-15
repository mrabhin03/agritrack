// features/plots/plots_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../farmers/providers/farmers_provider.dart';
import 'models/plot_model.dart';
import 'providers/plots_provider.dart';

// ── Map layer definitions ─────────────────────────────
// Terrain and Topo removed — not useful for field work.
// Street: OSM standard.  Satellite: Esri World Imagery (free, no key).
enum _MapLayer { street, satellite }

extension _MapLayerX on _MapLayer {
  String get label {
    switch (this) {
      case _MapLayer.street:
        return 'Street';
      case _MapLayer.satellite:
        return 'Satellite';
    }
  }

  IconData get icon {
    switch (this) {
      case _MapLayer.street:
        return Icons.map_outlined;
      case _MapLayer.satellite:
        return Icons.satellite_alt_outlined;
    }
  }

  String get urlTemplate {
    switch (this) {
      case _MapLayer.street:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case _MapLayer.satellite:
        // Esri World Imagery — free, no API key, global coverage
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/'
            'World_Imagery/MapServer/tile/{z}/{y}/{x}';
    }
  }

  // Satellite tiles are dark — use white/yellow marker accents
  bool get isDark => this == _MapLayer.satellite;
}

// ── Plot accent colours ───────────────────────────────
const _plotColors = [
  Color(0xFF2D6A4F),
  Color(0xFF40916C),
  Color(0xFF74C69D),
  Color(0xFF1565C0),
  Color(0xFF6A1B9A),
];

Color _colorForIndex(int i) => _plotColors[i % _plotColors.length];

// ── Screen ────────────────────────────────────────────
class PlotsScreen extends ConsumerStatefulWidget {
  const PlotsScreen({super.key});

  @override
  ConsumerState<PlotsScreen> createState() => _PlotsScreenState();
}

class _PlotsScreenState extends ConsumerState<PlotsScreen>
    with TickerProviderStateMixin {
  final _mapController = MapController();
  String? _selectedPlotId;
  bool _showList = false;
  _MapLayer _activeLayer = _MapLayer.street;

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
    final plotsAsync = ref.watch(plotsProvider);
    final plots = plotsAsync.valueOrNull ?? [];
    final farmers = ref.watch(farmersProvider).valueOrNull ?? [];

    // Build id → name map for farmer lookup
    final farmerNames = {for (final f in farmers) f.id: f.name};

    final selectedPlot =
        _selectedPlotId == null ? null : plots.where((p) => p.id == _selectedPlotId).firstOrNull;
    final selectedIndex =
        selectedPlot == null ? 0 : plots.indexOf(selectedPlot);

    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: plotsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text('Error loading plots: $e', style: AppTextStyles.body),
        ),
        data: (_) => Stack(
          children: [
            // ── Full-screen map ─────────────────────────
            _buildMap(plots, farmers: farmerNames),

            // ── Top bar ─────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              right: 12,
              child: _buildTopBar(plots),
            ),

            // ── Selected plot detail card ────────────────
            if (selectedPlot != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: bottomPad + 80,
                child: SlideTransition(
                  position: _detailSlide,
                  child: _PlotDetailCard(
                    plot: selectedPlot,
                    farmerName: farmerNames[selectedPlot.farmerId] ?? 'Unknown',
                    plotColor: _colorForIndex(selectedIndex),
                    onClose: _clearSelection,
                    onNavigate: () {
                      // TODO Phase 7: push to plot detail screen
                    },
                  ),
                ),
              ),

            // ── Bottom action bar ────────────────────────
            if (selectedPlot == null)
              Positioned(
                left: 12,
                right: 12,
                bottom: bottomPad + 12,
                child: _buildBottomActions(context, plots),
              ),

            // ── Plot list sheet ──────────────────────────
            AnimatedSlide(
              offset: _showList ? Offset.zero : const Offset(0, 1),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: _showList ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: _buildPlotListSheet(plots, farmerNames: farmerNames),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar: summary chips + layer toggle ────────────
  Widget _buildTopBar(List<PlotModel> plots) {
    final totalArea = plots.fold(0.0, (sum, p) => sum + p.areaHa);
    final uniqueFarmers = plots.map((p) => p.farmerId).toSet().length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary pill
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
                _StatPill(
                  icon: Icons.crop_square_rounded,
                  value: '${plots.length}',
                  label: 'plots',
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text('·',
                    style: TextStyle(
                        color: AppColors.textDisabled, fontSize: 12)),
                const SizedBox(width: 6),
                _StatPill(
                  icon: Icons.straighten_outlined,
                  value: totalArea.toStringAsFixed(1),
                  label: 'ha',
                  color: AppColors.accent,
                ),
                const SizedBox(width: 6),
                Text('·',
                    style: TextStyle(
                        color: AppColors.textDisabled, fontSize: 12)),
                const SizedBox(width: 6),
                _StatPill(
                  icon: Icons.people_outline,
                  value: '$uniqueFarmers',
                  label: 'farmers',
                  color: const Color(0xFF7B61FF),
                ),
                const Spacer(),
                // Turmeric crop chip
                Container(
                  constraints: const BoxConstraints(maxWidth: 88),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8F3DC),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.grass,
                          size: 11, color: Color(0xFF2D6A4F)),
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
        // Layer switcher button
        _LayerSwitcher(
          activeLayer: _activeLayer,
          onLayerChanged: (l) => setState(() => _activeLayer = l),
        ),
      ],
    );
  }

  // ── Bottom action bar ────────────────────────────────
  Widget _buildBottomActions(BuildContext context, List<PlotModel> plots) {
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
          // Plot list button (hidden when no plots)
          if (plots.isNotEmpty) ...[
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
          ],
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

  // ── Map ──────────────────────────────────────────────
  Widget _buildMap(List<PlotModel> plots,
      {required Map<String, String> farmers}) {
    final isDark = _activeLayer.isDark;

    // Default centre: Kerala (Kottayam area — turmeric belt)
    final center = plots.isNotEmpty
        ? LatLng(plots.first.centroid[0], plots.first.centroid[1])
        : const LatLng(9.5916, 76.5222);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14,
      ),
      children: [
        // Tile layer — key forces rebuild when layer changes
        TileLayer(
          key: ValueKey(_activeLayer),
          urlTemplate: _activeLayer.urlTemplate,
          userAgentPackageName: 'com.agritrack',
        ),

        // Plot polygons
        PolygonLayer(
          polygons: plots.asMap().entries.map((e) {
            final plot = e.value;
            final color = isDark ? Colors.white : _colorForIndex(e.key);
            final isSelected = _selectedPlotId == plot.id;
            return Polygon(
              points: plot.boundary
                  .map((p) => LatLng(p[0], p[1]))
                  .toList(),
              color: color.withOpacity(isSelected ? 0.38 : 0.15),
              borderColor: isSelected
                  ? (isDark ? Colors.yellowAccent : AppColors.warning)
                  : color.withOpacity(0.8),
              borderStrokeWidth: isSelected ? 3.0 : 1.8,
            );
          }).toList(),
        ),

        // Plot name markers
        MarkerLayer(
          markers: plots.asMap().entries.map((e) {
            final plot = e.value;
            final color = _colorForIndex(e.key);
            final isSelected = _selectedPlotId == plot.id;
            return Marker(
              point: LatLng(plot.centroid[0], plot.centroid[1]),
              width: 130,
              height: 40,
              child: GestureDetector(
                onTap: () => _selectPlot(
                    plot.id, LatLng(plot.centroid[0], plot.centroid[1])),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected ? color : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? color : color.withOpacity(0.5),
                      width: isSelected ? 0 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            color.withOpacity(isSelected ? 0.35 : 0.15),
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
                          plot.name,
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

  // ── Plot list bottom sheet ────────────────────────────
  Widget _buildPlotListSheet(List<PlotModel> plots,
      {required Map<String, String> farmerNames}) {
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
                    '${plots.length}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
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
            child: plots.isEmpty
                ? EmptyState.noPlots(
                    onAction: () => context.push('/add-plot'))
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      12,
                      12,
                      12,
                      MediaQuery.of(context).padding.bottom + 20,
                    ),
                    shrinkWrap: true,
                    itemCount: plots.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _PlotListTile(
                      plot: plots[i],
                      farmerName:
                          farmerNames[plots[i].farmerId] ?? 'Unknown',
                      plotColor: _colorForIndex(i),
                      isSelected: _selectedPlotId == plots[i].id,
                      onTap: () => _selectPlot(
                        plots[i].id,
                        LatLng(plots[i].centroid[0],
                            plots[i].centroid[1]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Stat pill ─────────────────────────────────────────
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

// ── Layer switcher button ─────────────────────────────
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
            ..._MapLayer.values.map((layer) {
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
                subtitle: Text(
                  layer == _MapLayer.street
                      ? 'OpenStreetMap — detailed roads & labels'
                      : 'Esri World Imagery — high-res aerial view',
                  style: AppTextStyles.caption,
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
            }),
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
    required this.farmerName,
    required this.plotColor,
    required this.onClose,
    required this.onNavigate,
  });
  final PlotModel plot;
  final String farmerName;
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
          // Coloured accent bar at top
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
                // Name + close
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(plot.name, style: AppTextStyles.h3),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.person_outline,
                                  size: 12,
                                  color: AppColors.textSecondary),
                              const SizedBox(width: 3),
                              Text(farmerName,
                                  style: AppTextStyles.caption),
                            ],
                          ),
                        ],
                      ),
                    ),
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
                // Stat chips row
                Row(
                  children: [
                    _DetailChip(
                      icon: Icons.straighten_outlined,
                      label: plot.areaLabel,
                      color: plotColor,
                    ),
                    const SizedBox(width: 6),
                    _DetailChip(
                      icon: Icons.terrain_outlined,
                      label: plot.soilType,
                    ),
                    const SizedBox(width: 6),
                    _DetailChip(
                      icon: Icons.water_drop_outlined,
                      label: plot.irrigation,
                    ),
                    const Spacer(),
                    // View button
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
  const _PlotListTile({
    required this.plot,
    required this.farmerName,
    required this.plotColor,
    required this.isSelected,
    required this.onTap,
  });
  final PlotModel plot;
  final String farmerName;
  final Color plotColor;
  final bool isSelected;
  final VoidCallback onTap;

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
              // Colour bar
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
              // Farmer avatar initial
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: plotColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    farmerName.isNotEmpty ? farmerName[0] : '?',
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(plot.name,
                                style: AppTextStyles.h3),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Text(
                              plot.areaLabel,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: plotColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(farmerName, style: AppTextStyles.caption),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _MiniTag(plot.soilType),
                          const SizedBox(width: 5),
                          _MiniTag(plot.irrigation),
                          const SizedBox(width: 5),
                          _MiniTag(plot.crop,
                              color: AppColors.success),
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