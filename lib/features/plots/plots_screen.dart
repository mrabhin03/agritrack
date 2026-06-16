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

enum _MapLayer { street, satellite }

extension _MapLayerX on _MapLayer {
  String get label => this == _MapLayer.street ? 'Street' : 'Satellite';
  IconData get icon => this == _MapLayer.street
      ? Icons.map_outlined
      : Icons.satellite_alt_outlined;
  String get urlTemplate => this == _MapLayer.street
      ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
      : 'https://server.arcgisonline.com/ArcGIS/rest/services/'
          'World_Imagery/MapServer/tile/{z}/{y}/{x}';
  String get subtitle => this == _MapLayer.street
      ? 'OpenStreetMap — roads & labels'
      : 'Esri World Imagery — aerial view';
  bool get isDark => this == _MapLayer.satellite;
}

const _plotColors = [
  Color(0xFF2D6A4F),
  Color(0xFF40916C),
  Color(0xFF52B788),
  Color(0xFF1565C0),
  Color(0xFF6A1B9A),
];
Color _colorForIndex(int i) => _plotColors[i % _plotColors.length];

// ─────────────────────────────────────────────────────
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
        vsync: this, duration: const Duration(milliseconds: 260));
    _detailSlide =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
            CurvedAnimation(parent: _detailAnim, curve: Curves.easeOutCubic));
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

  // ── Manage sheet ──────────────────────────────────────
  void _openPlotSheet(
      BuildContext context, PlotModel plot, String farmerName, Color color) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (ctx) => _PlotManageSheet(
        plot: plot,
        farmerName: farmerName,
        plotColor: color,
        onEdit: () {
          Navigator.pop(ctx);
          _showEditDialog(context, plot);
        },
        onDelete: () {
          Navigator.pop(ctx);
          _confirmDelete(context, plot);
        },
      ),
    );
  }

  // ── Edit dialog ───────────────────────────────────────
  void _showEditDialog(BuildContext context, PlotModel plot) {
    final nameCtrl = TextEditingController(text: plot.name);
    String soilType = plot.soilType;
    String irrigation = plot.irrigation;
    final formKey = GlobalKey<FormState>();

    const soilTypes = [
      'Loamy',
      'Sandy',
      'Clay',
      'Sandy loam',
      'Red laterite'
    ];
    const irrigationTypes = ['Drip', 'Flood', 'Rain-fed', 'Sprinkler'];

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.edit_outlined,
                          color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Edit Plot Details', style: AppTextStyles.h3),
                          Text('Name, soil & irrigation only',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => ctx.pop(),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.close,
                            size: 14, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              // Form
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _RoundedField(
                        child: TextFormField(
                          controller: nameCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Plot Name',
                            prefixIcon:
                                Icon(Icons.label_outline, size: 18),
                            border: InputBorder.none,
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _RoundedField(
                        child: DropdownButtonFormField<String>(
                          value: soilType,
                          decoration: const InputDecoration(
                            labelText: 'Soil Type',
                            prefixIcon:
                                Icon(Icons.terrain_outlined, size: 18),
                            border: InputBorder.none,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          items: soilTypes
                              .map((s) => DropdownMenuItem(
                                  value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) =>
                              setDlg(() => soilType = v ?? soilType),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _RoundedField(
                        child: DropdownButtonFormField<String>(
                          value: irrigation,
                          decoration: const InputDecoration(
                            labelText: 'Irrigation Method',
                            prefixIcon: Icon(Icons.water_drop_outlined,
                                size: 18),
                            border: InputBorder.none,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          items: irrigationTypes
                              .map((i) => DropdownMenuItem(
                                  value: i, child: Text(i)))
                              .toList(),
                          onChanged: (v) =>
                              setDlg(() => irrigation = v ?? irrigation),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Read-only note
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.accent.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 13, color: AppColors.accent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Boundary & area are read-only. '
                                'Delete and re-draw to change them.',
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.accent, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => ctx.pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: BorderSide(color: AppColors.border),
                          padding:
                              const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          await ref
                              .read(plotsProvider.notifier)
                              .updatePlot(plot.id, {
                            'name': nameCtrl.text.trim(),
                            'soil_type': soilType,
                            'irrigation': irrigation,
                          });
                          if (!mounted) return;
                          ctx.pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Plot details updated'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          _clearSelection();
                        },
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Save Changes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Delete confirmation ───────────────────────────────
  void _confirmDelete(BuildContext context, PlotModel plot) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline,
                    color: AppColors.error, size: 26),
              ),
              const SizedBox(height: 16),
              Text('Delete Plot?', style: AppTextStyles.h3),
              const SizedBox(height: 8),
              Text(
                '"${plot.name}" will be permanently removed and cannot be recovered.',
                style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => ctx.pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: BorderSide(color: AppColors.border),
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await ref
                            .read(plotsProvider.notifier)
                            .deletePlot(plot.id);
                        if (!mounted) return;
                        ctx.pop();
                        _clearSelection();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('"${plot.name}" deleted'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final plotsAsync = ref.watch(plotsProvider);
    final plots = plotsAsync.valueOrNull ?? [];
    final farmers = ref.watch(farmersProvider).valueOrNull ?? [];
    final farmerNames = {for (final f in farmers) f.id: f.name};

    final selectedPlot = _selectedPlotId == null
        ? null
        : plots.where((p) => p.id == _selectedPlotId).firstOrNull;
    final selectedIndex =
        selectedPlot == null ? 0 : plots.indexOf(selectedPlot);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: plotsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
            child:
                Text('Error loading plots: $e', style: AppTextStyles.body)),
        data: (_) => Stack(
          children: [
            _buildMap(plots, farmerNames: farmerNames),

            // Top bar
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              right: 12,
              child: _buildTopBar(plots),
            ),

            // Selected plot detail card
            if (selectedPlot != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: bottomPad + 10,
                child: SlideTransition(
                  position: _detailSlide,
                  child: _PlotDetailCard(
                    plot: selectedPlot,
                    farmerName:
                        farmerNames[selectedPlot.farmerId] ?? 'Unknown',
                    plotColor: _colorForIndex(selectedIndex),
                    onClose: _clearSelection,
                    onView: () => _openPlotSheet(
                      context,
                      selectedPlot,
                      farmerNames[selectedPlot.farmerId] ?? 'Unknown',
                      _colorForIndex(selectedIndex),
                    ),
                  ),
                ),
              ),

            // Bottom action bar
            if (selectedPlot == null)
              Positioned(
                left: 12,
                right: 12,
                bottom: bottomPad + 12,
                child: _buildBottomActions(context, plots),
              ),

            // Plot list sheet
            AnimatedSlide(
              offset: _showList ? Offset.zero : const Offset(0, 1),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: _showList ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child:
                      _buildPlotListSheet(plots, farmerNames: farmerNames),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────
  Widget _buildTopBar(List<PlotModel> plots) {
    final totalArea = plots.fold(0.0, (s, p) => s + p.areaHa);
    final uniqueFarmers = plots.map((p) => p.farmerId).toSet().length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.97),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Row(
              children: [
                _StatPill(
                    icon: Icons.crop_square_rounded,
                    value: '${plots.length}',
                    label: 'plots',
                    color: AppColors.primary),
                _dot(),
                _StatPill(
                    icon: Icons.straighten_outlined,
                    value: totalArea.toStringAsFixed(1),
                    label: 'ha',
                    color: AppColors.accent),
                _dot(),
                _StatPill(
                    icon: Icons.people_outline,
                    value: '$uniqueFarmers',
                    label: 'farmers',
                    color: const Color(0xFF7B61FF)),
                const Spacer(),
                _CropPill(),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _LayerSwitcher(
          activeLayer: _activeLayer,
          onLayerChanged: (l) => setState(() => _activeLayer = l),
        ),
      ],
    );
  }

  Widget _dot() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text('·',
            style:
                TextStyle(color: AppColors.textDisabled, fontSize: 12)),
      );

  // ── Bottom action bar ─────────────────────────────────
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
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          if (plots.isNotEmpty) ...[
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _showList = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
                      Text('Plot List',
                          style: AppTextStyles.label.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/add-plot'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_location_alt_rounded,
                        size: 17, color: Colors.white),
                    const SizedBox(width: 6),
                    Text('Add Plot',
                        style: AppTextStyles.label.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Map ───────────────────────────────────────────────
  Widget _buildMap(List<PlotModel> plots,
      {required Map<String, String> farmerNames}) {
    final isDark = _activeLayer.isDark;
    final center = plots.isNotEmpty
        ? LatLng(plots.first.centroid[0], plots.first.centroid[1])
        : const LatLng(9.5916, 76.5222);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(initialCenter: center, initialZoom: 14),
      children: [
        TileLayer(
          key: ValueKey(_activeLayer),
          urlTemplate: _activeLayer.urlTemplate,
          userAgentPackageName: 'com.agritrack',
        ),
        PolygonLayer(
          polygons: plots.asMap().entries.map((e) {
            final plot = e.value;
            final color = isDark ? Colors.white : _colorForIndex(e.key);
            final isSelected = _selectedPlotId == plot.id;
//             _printLong('plot.id', plot.id);
//             _printLong('plot.boundary', plot.boundary);
//             print("\n\n");
            return Polygon(
              points:
                  plot.boundary.map((p) => LatLng(p[0], p[1])).toList(),
              color: color.withOpacity(isSelected ? 0.35 : 0.14),
              borderColor: isSelected
                  ? (isDark ? Colors.yellowAccent : AppColors.warning)
                  : color.withOpacity(0.85),
              borderStrokeWidth: isSelected ? 3.0 : 1.8,
            );
          }).toList(),
        ),
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
                        color:
                            isSelected ? color : color.withOpacity(0.5),
                        width: isSelected ? 0 : 1.5),
                    boxShadow: [
                      BoxShadow(
                          color: color
                              .withOpacity(isSelected ? 0.35 : 0.15),
                          blurRadius: isSelected ? 10 : 5,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                              color:
                                  isSelected ? Colors.white : color,
                              shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(plot.name,
                            style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis),
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

  // ── Plot list sheet ───────────────────────────────────
  Widget _buildPlotListSheet(List<PlotModel> plots,
      {required Map<String, String> farmerNames}) {
    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 24,
              offset: Offset(0, -4))
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
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 10, 0),
            child: Row(
              children: [
                Text('All Plots', style: AppTextStyles.h3),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: Text('${plots.length}',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700)),
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
                        border: Border.all(color: AppColors.border)),
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
                        MediaQuery.of(context).padding.bottom + 20),
                    shrinkWrap: true,
                    itemCount: plots.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final plot = plots[i];
                      final farmerName =
                          farmerNames[plot.farmerId] ?? 'Unknown';
                      final color = _colorForIndex(i);
                      return _PlotListTile(
                        plot: plot,
                        farmerName: farmerName,
                        plotColor: color,
                        isSelected: _selectedPlotId == plot.id,
                        onTap: () => _selectPlot(plot.id,
                            LatLng(plot.centroid[0], plot.centroid[1])),
                        onManage: () {
                          setState(() => _showList = false);
                          Future.microtask(() => _openPlotSheet(
                              context, plot, farmerName, color));
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Rounded field wrapper ─────────────────────────────
class _RoundedField extends StatelessWidget {
  const _RoundedField({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

// ── Crop pill ─────────────────────────────────────────
class _CropPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFD8F3DC),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.grass, size: 11, color: Color(0xFF2D6A4F)),
          const SizedBox(width: 4),
          Text('Turmeric',
              style: AppTextStyles.caption.copyWith(
                  color: const Color(0xFF2D6A4F),
                  fontWeight: FontWeight.w600,
                  fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Stat pill ─────────────────────────────────────────
class _StatPill extends StatelessWidget {
  const _StatPill(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 4),
      Text(value,
          style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700)),
      const SizedBox(width: 2),
      Text(label,
          style: AppTextStyles.caption
              .copyWith(color: AppColors.textSecondary)),
    ]);
  }
}

// ── Layer switcher ────────────────────────────────────
class _LayerSwitcher extends StatelessWidget {
  const _LayerSwitcher(
      {required this.activeLayer, required this.onLayerChanged});
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
            border: Border.all(color: AppColors.border)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2))),
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: Text('Map Style', style: AppTextStyles.h3)),
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
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(layer.icon,
                      size: 18,
                      color: isActive
                          ? AppColors.primary
                          : AppColors.textSecondary),
                ),
                title: Text(layer.label,
                    style: AppTextStyles.labelLarge.copyWith(
                        color: isActive
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.normal)),
                subtitle: Text(layer.subtitle,
                    style: AppTextStyles.caption),
                trailing: isActive
                    ? Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle),
                        child: const Icon(Icons.check,
                            size: 13, color: Colors.white))
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
                  offset: const Offset(0, 3))
            ]),
        child: const Icon(Icons.layers_outlined,
            size: 20, color: AppColors.textPrimary),
      ),
    );
  }
}

// ── Selected plot detail card (on map) ───────────────
class _PlotDetailCard extends StatelessWidget {
  const _PlotDetailCard({
    required this.plot,
    required this.farmerName,
    required this.plotColor,
    required this.onClose,
    required this.onView,
  });
  final PlotModel plot;
  final String farmerName;
  final Color plotColor;
  final VoidCallback onClose;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: plotColor.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
              color: plotColor.withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(0, 8)),
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
  borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Accent bar
            Container(
              height: 8,
              decoration: BoxDecoration(
                  color: plotColor,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20))),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + close
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: plotColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.crop_square_rounded,
                            color: plotColor, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(plot.name,
                                style: AppTextStyles.h3,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Row(children: [
                              const Icon(Icons.person_outline,
                                  size: 12,
                                  color: AppColors.textSecondary),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(farmerName,
                                    style: AppTextStyles.caption,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: onClose,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: AppColors.border)),
                          child: const Icon(Icons.close,
                              size: 14,
                              color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Stats bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        _MiniStat(
                            icon: Icons.straighten_outlined,
                            value: plot.areaLabel,
                            color: plotColor),
                        _vDivider(),
                        _MiniStat(
                            icon: Icons.terrain_outlined,
                            value: plot.soilType),
                        _vDivider(),
                        _MiniStat(
                            icon: Icons.water_drop_outlined,
                            value: plot.irrigation),
                        _vDivider(),
                        _MiniStat(
                            icon: Icons.grass,
                            value: plot.crop,
                            color: AppColors.success),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // View details button
                  GestureDetector(
                    onTap: onView,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: plotColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: plotColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3))
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.info_outline,
                              size: 15, color: Colors.white),
                          const SizedBox(width: 6),
                          Text('View Details',
                              style: AppTextStyles.label.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vDivider() => Container(
        width: 1,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: AppColors.border,
      );
}

// ── Mini stat ─────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.value, this.color});
  final IconData icon;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 10),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

// ── Plot manage sheet ─────────────────────────────────
class _PlotManageSheet extends StatelessWidget {
  const _PlotManageSheet({
    required this.plot,
    required this.farmerName,
    required this.plotColor,
    required this.onEdit,
    required this.onDelete,
  });
  final PlotModel plot;
  final String farmerName;
  final Color plotColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    // ✅ Key fix: constrain max height so sheet never overflows screen
    final screenH = MediaQuery.of(context).size.height;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      // Leave ~15% of screen visible above sheet so user knows they can dismiss
      constraints: BoxConstraints(maxHeight: screenH * 0.85),
      margin: EdgeInsets.fromLTRB(12, 0, 12, bottomPad + 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: plotColor.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 28,
              offset: const Offset(0, -4)),
        ],
      ),
      // ✅ SingleChildScrollView so content scrolls if screen is tiny
      child: ClipRRect(
  borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Accent bar
              Container(
                height: 0,
                decoration: BoxDecoration(
                    color: plotColor,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24))),
              ),
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
              // Header row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                          color: plotColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.crop_square_rounded,
                          color: plotColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(plot.name,
                              style: AppTextStyles.h3,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Row(children: [
                            const Icon(Icons.person_outline,
                                size: 12,
                                color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(farmerName,
                                  style: AppTextStyles.caption,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ]),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: AppColors.border)),
                        child: const Icon(Icons.close,
                            size: 14,
                            color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
        
              // ── Info tiles ────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Row 1: Area + Soil
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _SheetInfoTile(
                              icon: Icons.straighten_outlined,
                              label: 'Area',
                              value: plot.areaLabel,
                              color: plotColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SheetInfoTile(
                              icon: Icons.terrain_outlined,
                              label: 'Soil Type',
                              value: plot.soilType,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Row 2: Irrigation + Crop
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _SheetInfoTile(
                              icon: Icons.water_drop_outlined,
                              label: 'Irrigation',
                              value: plot.irrigation,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SheetInfoTile(
                              icon: Icons.grass,
                              label: 'Crop',
                              value: plot.crop,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Row 3: Boundary (full width, optional)
                    if (plot.boundary.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _SheetInfoTile(
                        icon: Icons.place_outlined,
                        label: 'Boundary',
                        value:
                            '${plot.boundary.length} vertices · '
                            '${plot.hasValidBoundary ? 'valid polygon' : 'incomplete'}',
                        fullWidth: true,
                      ),
                    ],
                  ],
                ),
              ),
        
              const SizedBox(height: 16),
              const Divider(height: 1),
        
              // ── Action buttons ────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Primary: Edit
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit Plot Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Info note
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.accent.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 13, color: AppColors.accent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'To edit the boundary, delete this plot '
                              'and create a new one.',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.accent, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Secondary: Delete
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onDelete,
                        icon:
                            const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Delete Plot'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(
                              color: AppColors.error.withOpacity(0.4)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sheet info tile ───────────────────────────────────
class _SheetInfoTile extends StatelessWidget {
  const _SheetInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    this.fullWidth = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
          color: c.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withOpacity(0.15))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // ✅ never tries to expand
        children: [
          Row(children: [
            Icon(icon, size: 12, color: c),
            const SizedBox(width: 5),
            Text(label,
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary, fontSize: 10)),
          ]),
          const SizedBox(height: 5),
          Text(value,
              style: AppTextStyles.labelLarge
                  .copyWith(color: AppColors.textPrimary, fontSize: 13)),
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
    required this.onManage,
  });
  final PlotModel plot;
  final String farmerName;
  final Color plotColor;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onManage;

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
              width: isSelected ? 1.5 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: plotColor.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ]
              : [],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left colour bar
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: plotColor,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      bottomLeft: Radius.circular(14)),
                ),
              ),
              // Avatar
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                      color: plotColor.withOpacity(0.12),
                      shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    farmerName.isNotEmpty
                        ? farmerName[0].toUpperCase()
                        : '?',
                    style: AppTextStyles.labelLarge.copyWith(
                        color: plotColor,
                        fontWeight: FontWeight.w800),
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
                      Row(children: [
                        Expanded(
                            child: Text(plot.name,
                                style: AppTextStyles.h3)),
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(plot.areaLabel,
                              style: AppTextStyles.labelLarge.copyWith(
                                  color: plotColor,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ]),
                      const SizedBox(height: 3),
                      Text(farmerName,
                          style: AppTextStyles.caption),
                      const SizedBox(height: 6),
                      Row(children: [
                        _MiniTag(plot.soilType),
                        const SizedBox(width: 5),
                        _MiniTag(plot.irrigation),
                        const SizedBox(width: 5),
                        _MiniTag(plot.crop,
                            color: AppColors.success),
                      ]),
                    ],
                  ),
                ),
              ),
              // Manage button
              GestureDetector(
                onTap: onManage,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 12),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: AppColors.border)),
                    child: const Icon(Icons.more_vert,
                        size: 16,
                        color: AppColors.textSecondary),
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
          borderRadius: BorderRadius.circular(5)),
      child: Text(label,
          style: AppTextStyles.caption.copyWith(
              fontSize: 10,
              color: c,
              fontWeight: FontWeight.w600)),
    );
  }
}
void _printLong(String label, Object? value) {
  final str = value.toString();
  const chunkSize = 800;
  print('── $label ──');
  for (int i = 0; i < str.length; i += chunkSize) {
    print(str.substring(i, (i + chunkSize).clamp(0, str.length)));
  }
}