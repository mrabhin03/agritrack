// features/plots/plots_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
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

// Cap how many markers/list items get a staggered pop-in delay so a
// large plot set doesn't push the tail end's animation several
// seconds out — mirrors the farmers list's stagger cap.
const int _maxStaggerItems = 10;

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

  // ── My Location state ─────────────────────────────
  LatLng? _userPosition;
  bool _locLoading = false;

  late final AnimationController _detailAnim;
  late final Animation<Offset> _detailSlide;
  late final Animation<double> _detailScale;

  // ── Chrome entrance (top bar, FAB stack, bottom bar) ─
  late final AnimationController _entrance;
  late final Animation<double> _topBarReveal;
  late final Animation<double> _locBtnReveal;
  late final Animation<double> _bottomBarReveal;

  @override
  void initState() {
    super.initState();
    _detailAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260));
    _detailSlide =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
            CurvedAnimation(parent: _detailAnim, curve: Curves.easeOutCubic));
    _detailScale = Tween<double>(begin: 0.94, end: 1.0).animate(
        CurvedAnimation(parent: _detailAnim, curve: Curves.easeOutBack));

    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _topBarReveal = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    );
    _locBtnReveal = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.25, 0.75, curve: Curves.elasticOut),
    );
    _bottomBarReveal = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
    );

    // Wait for the first post-frame callback so the reveal doesn't
    // start ticking mid route-transition (same reasoning as the
    // farmers screen entrance).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entrance.forward();
    });
  }

  @override
  void dispose() {
    _detailAnim.dispose();
    _entrance.dispose();
    super.dispose();
  }

  // ── My Location logic ─────────────────────────────
  Future<void> _goToMyLocation() async {
    setState(() => _locLoading = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Location permission denied. Enable it in Settings.'),
          ));
          await Geolocator.openAppSettings();
        }
        return;
      }
      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        final latLng = LatLng(pos.latitude, pos.longitude);
        setState(() => _userPosition = latLng);
        _mapController.move(latLng, 15.5);
      }
    } finally {
      if (mounted) setState(() => _locLoading = false);
    }
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
        builder: (ctx, setDlg) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.9, end: 1.0),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          builder: (context, v, child) =>
              Transform.scale(scale: v, child: child),
          child: Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
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
                      _PressableScale(
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
      ),
    );
  }

  // ── Delete confirmation ───────────────────────────────
  void _confirmDelete(BuildContext context, PlotModel plot) {
    showDialog(
      context: context,
      builder: (ctx) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.9, end: 1.0),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        builder: (context, v, child) => Transform.scale(scale: v, child: child),
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  builder: (context, v, child) =>
                      Transform.scale(scale: v, child: child),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: AppColors.error, size: 26),
                  ),
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
        loading: () => const Center(child: _MapLoader()),
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
              child: AnimatedBuilder(
                animation: _topBarReveal,
                child: _buildTopBar(plots),
                builder: (context, child) {
                  final v = _topBarReveal.value.clamp(0.0, 1.0);
                  return Opacity(
                    opacity: v,
                    child: Transform.translate(
                      offset: Offset(0, (1 - v) * -16),
                      child: child,
                    ),
                  );
                },
              ),
            ),

            // ── My Location button ─────────────────────
            Positioned(
              right: 12,
              top: MediaQuery.of(context).padding.top + 72,
              child: AnimatedBuilder(
                animation: _locBtnReveal,
                builder: (context, _) {
                  final v = _locBtnReveal.value.clamp(0.0, 1.3);
                  return Opacity(
                    opacity: _locBtnReveal.value.clamp(0.0, 1.0),
                    child: Transform.scale(scale: v, child: _buildLocationButton()),
                  );
                },
              ),
            ),

            // Selected plot detail card
            if (selectedPlot != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: bottomPad + 10,
                child: SlideTransition(
                  position: _detailSlide,
                  child: ScaleTransition(
                    scale: _detailScale,
                    alignment: Alignment.bottomCenter,
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
              ),

            // Bottom action bar
            if (selectedPlot == null)
              Positioned(
                left: 12,
                right: 12,
                bottom: bottomPad + 12,
                child: AnimatedBuilder(
                  animation: _bottomBarReveal,
                  child: _buildBottomActions(context, plots),
                  builder: (context, child) {
                    final v = _bottomBarReveal.value.clamp(0.0, 1.0);
                    return Opacity(
                      opacity: v,
                      child: Transform.translate(
                        offset: Offset(0, (1 - v) * 24),
                        child: child,
                      ),
                    );
                  },
                ),
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

  // ── My location button (with pulse-glow while active) ─
  Widget _buildLocationButton() {
    return _LocationButtonGlow(
      active: _userPosition != null,
      child: _PressableScale(
        onTap: _locLoading ? () {} : _goToMyLocation,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.97),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _userPosition != null
                  ? Colors.blue.withOpacity(0.4)
                  : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.09),
                  blurRadius: 10,
                  offset: const Offset(0, 3))
            ],
          ),
          child: _locLoading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.blue),
                )
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: RotationTransition(
                        turns: Tween<double>(begin: 0.6, end: 1.0).animate(anim),
                        child: child),
                  ),
                  child: Icon(
                    _userPosition != null
                        ? Icons.my_location_rounded
                        : Icons.location_searching_rounded,
                    key: ValueKey(_userPosition != null),
                    size: 20,
                    color: _userPosition != null
                        ? Colors.blue
                        : AppColors.textPrimary,
                  ),
                ),
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
                _AnimatedStatPill(
                    icon: Icons.crop_square_rounded,
                    value: plots.length,
                    label: 'plots',
                    color: AppColors.primary),
                _dot(),
                _AnimatedStatPill(
                    icon: Icons.straighten_outlined,
                    value: totalArea,
                    decimals: 1,
                    label: 'ha',
                    color: AppColors.accent),
                _dot(),
                _AnimatedStatPill(
                    icon: Icons.people_outline,
                    value: uniqueFarmers,
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
              child: _PressableScale(
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
            child: _AddPlotButton(onTap: () => context.push('/add-plot')),
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

    final staggerTotal = math.min(plots.length, _maxStaggerItems);

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
            final index = e.key;
            final plot = e.value;
            final color = _colorForIndex(index);
            final isSelected = _selectedPlotId == plot.id;
            final staggerIndex =
                index < _maxStaggerItems ? index : _maxStaggerItems - 1;
            return Marker(
              point: LatLng(plot.centroid[0], plot.centroid[1]),
              width: 130,
              height: 40,
              child: GestureDetector(
                onTap: () => _selectPlot(
                    plot.id, LatLng(plot.centroid[0], plot.centroid[1])),
                child: _MarkerPopIn(
                  index: staggerIndex,
                  total: staggerTotal == 0 ? 1 : staggerTotal,
                  child: _PulseOnSelect(
                    isSelected: isSelected,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected ? color : AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: isSelected
                                ? color
                                : color.withOpacity(0.5),
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
                ),
              ),
            );
          }).toList(),
        ),
        // ── User location marker ───────────────────────
        if (_userPosition != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _userPosition!,
                width: 44,
                height: 44,
                child: const _PulsingLocationDot(),
              ),
            ],
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
                _PressableScale(
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
                      final staggerIndex =
                          i < _maxStaggerItems ? i : _maxStaggerItems - 1;
                      final staggerTotal =
                          math.min(plots.length, _maxStaggerItems);
                      return _ListPopIn(
                        index: staggerIndex,
                        total: staggerTotal,
                        child: _ShineSweep(
                          delay: Duration(
                              milliseconds:
                                  550 + staggerIndex.clamp(0, 6) * 90),
                          borderRadius: 14,
                          child: _PlotListTile(
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
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Map loading state: soft breathing pin ─────────────
class _MapLoader extends StatefulWidget {
  const _MapLoader();
  @override
  State<_MapLoader> createState() => _MapLoaderState();
}

class _MapLoaderState extends State<_MapLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_c.value);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: Offset(0, -6 * t),
              child: Icon(Icons.location_on,
                  size: 40,
                  color: AppColors.primary.withOpacity(0.5 + t * 0.5)),
            ),
            const SizedBox(height: 10),
            Text('Loading plots…', style: AppTextStyles.caption),
          ],
        );
      },
    );
  }
}

// ── Marker pop-in: one-shot elastic scale + fade, staggered by index
class _MarkerPopIn extends StatelessWidget {
  const _MarkerPopIn(
      {required this.child, required this.index, required this.total});
  final Widget child;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final delay = (index / total).clamp(0.0, 1.0) * 260;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 420 + delay.round()),
      curve: Curves.elasticOut,
      builder: (context, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.scale(scale: v, child: child),
      ),
      child: child,
    );
  }
}

// ── A short bounce whenever a marker becomes selected ──
class _PulseOnSelect extends StatefulWidget {
  const _PulseOnSelect({required this.child, required this.isSelected});
  final Widget child;
  final bool isSelected;

  @override
  State<_PulseOnSelect> createState() => _PulseOnSelectState();
}

class _PulseOnSelectState extends State<_PulseOnSelect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260));
    if (widget.isSelected) _c.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant _PulseOnSelect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _c.forward(from: 0);
    } else if (!widget.isSelected) {
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final b = _c.value;
        final bump =
            b < 1.0 ? 1.0 + Curves.easeOutBack.transform(b) * 0.18 : 1.0;
        return Transform.scale(
            scale: widget.isSelected ? bump : 1.0, child: child);
      },
      child: widget.child,
    );
  }
}

// ── Pulsing blue location dot ─────────────────────────
class _PulsingLocationDot extends StatefulWidget {
  const _PulsingLocationDot();
  @override
  State<_PulsingLocationDot> createState() => _PulsingLocationDotState();
}

class _PulsingLocationDotState extends State<_PulsingLocationDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final ringScale = 0.4 + t * 1.0;
        final ringOpacity = (1 - t).clamp(0.0, 1.0) * 0.5;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Expanding pulse ring
            Transform.scale(
              scale: ringScale,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(ringOpacity),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Static soft halo
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
            ),
            // Blue dot
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.4),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Glow wrapper for the My Location button while active ─
class _LocationButtonGlow extends StatefulWidget {
  const _LocationButtonGlow({required this.child, required this.active});
  final Widget child;
  final bool active;

  @override
  State<_LocationButtonGlow> createState() => _LocationButtonGlowState();
}

class _LocationButtonGlowState extends State<_LocationButtonGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.18 + _c.value * 0.12),
                blurRadius: 8 + _c.value * 6,
                spreadRadius: _c.value * 0.5,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
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

// ── Stat pill with count-up number animation ──────────
class _AnimatedStatPill extends StatelessWidget {
  const _AnimatedStatPill({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.decimals = 0,
  });
  final IconData icon;
  final num value;
  final String label;
  final Color color;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 4),
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.toDouble()),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, v, child) => Text(
          v.toStringAsFixed(decimals),
          style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
      ),
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
                    ? TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.elasticOut,
                        builder: (context, v, child) =>
                            Transform.scale(scale: v, child: child),
                        child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle),
                            child: const Icon(Icons.check,
                                size: 13, color: Colors.white)),
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
    return _PressableScale(
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

// ── Add Plot button with pulsing glow + bobbing icon ──
class _AddPlotButton extends StatefulWidget {
  const _AddPlotButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_AddPlotButton> createState() => _AddPlotButtonState();
}

class _AddPlotButtonState extends State<_AddPlotButton>
    with TickerProviderStateMixin {
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _glow,
        builder: (context, child) {
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary
                      .withOpacity(0.28 + _glow.value * 0.15),
                  blurRadius: 8 + _glow.value * 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _BobbingIcon(
                child: const Icon(Icons.add_location_alt_rounded,
                    size: 17, color: Colors.white),
              ),
              const SizedBox(width: 6),
              Text('Add Plot',
                  style: AppTextStyles.label.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// Slow vertical bob — keeps a small icon feeling gently "alive" at rest.
class _BobbingIcon extends StatefulWidget {
  const _BobbingIcon({required this.child});
  final Widget child;

  @override
  State<_BobbingIcon> createState() => _BobbingIconState();
}

class _BobbingIconState extends State<_BobbingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final dy = math.sin(_c.value * 2 * math.pi) * 2.0;
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
    );
  }
}

// Reusable press-scale wrapper.
class _PressableScale extends StatefulWidget {
  const _PressableScale({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  double _scale = 1.0;

  void _setScale(double s) => setState(() => _scale = s);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setScale(0.94),
      onTapUp: (_) => _setScale(1.0),
      onTapCancel: () => _setScale(1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ── Pop-in wrapper for plot list tiles: fade + slide + elastic scale
class _ListPopIn extends StatelessWidget {
  const _ListPopIn(
      {required this.child, required this.index, required this.total});
  final Widget child;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final safeTotal = total <= 0 ? 1 : total;
    final delayMs = (index / safeTotal).clamp(0.0, 1.0) * 220;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 380 + delayMs.round()),
      curve: Curves.easeOutCubic,
      builder: (context, fade, child) {
        return Opacity(
          opacity: fade.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - fade) * 16),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

// One-shot diagonal light sweep, played once after a delay.
class _ShineSweep extends StatefulWidget {
  const _ShineSweep({
    required this.child,
    required this.delay,
    this.borderRadius = 12,
  });
  final Widget child;
  final Duration delay;
  final double borderRadius;

  @override
  State<_ShineSweep> createState() => _ShineSweepState();
}

class _ShineSweepState extends State<_ShineSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth.isFinite ? constraints.maxWidth : 0.0;
          return Stack(
            children: [
              widget.child,
              if (w > 0)
                AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) {
                    final dx = -w * 0.6 + _c.value * (w * 1.6);
                    return Positioned(
                      top: -20,
                      bottom: -20,
                      left: dx,
                      width: w * 0.3,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: (1 - _c.value).clamp(0.0, 1.0) * 0.35,
                          child: Transform.rotate(
                            angle: -0.35,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.white.withOpacity(0),
                                    Colors.white.withOpacity(0.45),
                                    Colors.white.withOpacity(0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
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
                      _PressableScale(
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
                  _PressableScale(
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
    final screenH = MediaQuery.of(context).size.height;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 0,
                decoration: BoxDecoration(
                    color: plotColor,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24))),
              ),
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.elasticOut,
                      builder: (context, v, child) =>
                          Transform.scale(scale: v, child: child),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                            color: plotColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.crop_square_rounded,
                            color: plotColor, size: 22),
                      ),
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
                    _PressableScale(
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: _PressableScale(
                        onTap: onEdit,
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
                    ),
                    const SizedBox(height: 10),
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
                    SizedBox(
                      width: double.infinity,
                      child: _PressableScale(
                        onTap: onDelete,
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
        mainAxisSize: MainAxisSize.min,
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
    return _PressableScale(
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
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: plotColor,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      bottomLeft: Radius.circular(14)),
                ),
              ),
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
              _PressableScale(
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