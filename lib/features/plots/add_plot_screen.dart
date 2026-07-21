// features/plots/add_plot_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/crop_constants.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/section_header.dart';
import '../farmers/providers/farmers_provider.dart';
import 'models/plot_model.dart';
import 'providers/plots_provider.dart';

// ── Shoelace area calculation ─────────────────────────
double polygonAreaHa(List<LatLng> points) {
  if (points.length < 3) return 0;
  const r = 6371000.0;
  double area = 0;
  final n = points.length;
  for (int i = 0; i < n; i++) {
    final j = (i + 1) % n;
    final lat1 = points[i].latitude * math.pi / 180;
    final lat2 = points[j].latitude * math.pi / 180;
    final lng1 = points[i].longitude * math.pi / 180;
    final lng2 = points[j].longitude * math.pi / 180;
    final x1 = r * lng1 * math.cos(lat1);
    final y1 = r * lat1;
    final x2 = r * lng2 * math.cos(lat2);
    final y2 = r * lat2;
    area += x1 * y2 - x2 * y1;
  }
  return area.abs() / 2 / 10000;
}

class AddPlotScreen extends ConsumerStatefulWidget {
  const AddPlotScreen({super.key, this.farmerId});
  final String? farmerId;

  @override
  ConsumerState<AddPlotScreen> createState() => _AddPlotScreenState();
}

class _AddPlotScreenState extends ConsumerState<AddPlotScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _mapController = MapController();

  final List<LatLng> _points = [];
  String? _soilType;
  String? _irrigation;
  String? _selectedFarmerId;
  bool _loading = false;

  // ── Vertex drag state ─────────────────────────────────
  int? _selectedIndex;
  bool _isDragging = false;
  Offset? _dragStartFinger;
  Offset? _dragStartScreen;
  bool _useSatellite = false;

  // ── Existing plots overlay ────────────────────────────
  bool _showExistingPlots = true;

  // ── My Location state ─────────────────────────────────
  LatLng? _userPosition;
  bool _locLoading = false;

  static const _initialCenter = LatLng(9.297028, 76.670179);
  static const double _hitRadius = 28.0;

  double get _areaHa => polygonAreaHa(_points);

  @override
  void initState() {
    super.initState();
    _selectedFarmerId = widget.farmerId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── My Location logic ─────────────────────────────────
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
          desiredAccuracy: LocationAccuracy.high,
        );
        final latLng = LatLng(pos.latitude, pos.longitude);
        setState(() => _userPosition = latLng);
        _mapController.move(latLng, 17);
      }
    } finally {
      if (mounted) setState(() => _locLoading = false);
    }
  }

  // ── Validators ────────────────────────────────────────
  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Plot name is required';
    if (v.trim().length < 2) return 'At least 2 characters';
    return null;
  }

  // ── Vertex drag helpers ───────────────────────────────
  Offset? _latLngToOffset(LatLng point) {
    try {
      final px = _mapController.camera.latLngToScreenPoint(point);
      return Offset(px.x, px.y);
    } catch (_) {
      return null;
    }
  }

  int? _hitTestVertex(Offset tapOffset) {
    int? best;
    double bestDist = _hitRadius;
    for (int i = 0; i < _points.length; i++) {
      final px = _latLngToOffset(_points[i]);
      if (px == null) continue;
      final d = (tapOffset - px).distance;
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    return best;
  }

  void _onPointerDown(PointerDownEvent e) {
    final hit = _hitTestVertex(e.localPosition);
    if (hit != null) {
      final screenPt = _latLngToOffset(_points[hit]);
      setState(() {
        _selectedIndex = hit;
        _isDragging = false;
        _dragStartFinger = e.localPosition;
        _dragStartScreen = screenPt;
      });
    } else {
      setState(() {
        _selectedIndex = null;
        _dragStartFinger = null;
        _dragStartScreen = null;
      });
    }
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (_selectedIndex == null) return;
    if (_dragStartFinger == null || _dragStartScreen == null) return;
    final fingerDelta = e.localPosition - _dragStartFinger!;
    final newScreen = _dragStartScreen! + fingerDelta;
    try {
      final camera = _mapController.camera;
      final origin = camera.pixelOrigin;
      final worldPoint = math.Point<double>(
        newScreen.dx + origin.x,
        newScreen.dy + origin.y,
      );
      final pt = camera.crs.pointToLatLng(worldPoint, camera.zoom);
      setState(() {
        _isDragging = true;
        _points[_selectedIndex!] = pt;
        _dragStartFinger = e.localPosition;
        _dragStartScreen = newScreen;
      });
    } catch (_) {}
  }

  void _onPointerUp(PointerUpEvent e) {
    setState(() {
      _isDragging = false;
      _dragStartFinger = null;
      _dragStartScreen = null;
    });
  }

  void _onMapTap(TapPosition _, LatLng point) {
    if (_selectedIndex != null || _isDragging) return;
    setState(() => _points.add(point));
  }

  void _undoPoint() {
    if (_points.isEmpty) return;
    setState(() {
      _points.removeLast();
      if (_selectedIndex != null && _selectedIndex! >= _points.length) {
        _selectedIndex = null;
      }
    });
  }

  void _clearPoints() {
    if (_points.isEmpty) return;
    setState(() {
      _points.clear();
      _selectedIndex = null;
      _dragStartFinger = null;
      _dragStartScreen = null;
    });
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
    ));
  }

  // ── Submit ────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFarmerId == null) {
      _showSnack('Please select a farmer', isError: true);
      return;
    }
    if (_points.length < 3) {
      _showSnack('Draw a plot boundary (min 3 points)', isError: true);
      return;
    }
    if (_soilType == null) {
      _showSnack('Please select a soil type', isError: true);
      return;
    }
    if (_irrigation == null) {
      _showSnack('Please select an irrigation method', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final boundary = _points
          .map((p) => [p.latitude, p.longitude])
          .toList();

      await ref.read(plotsProvider.notifier).addPlot({
        'farmer_id': _selectedFarmerId,
        'name': _nameCtrl.text.trim(),
        'boundary': boundary,
        'area_ha': _areaHa,
        'soil_type': _soilType,
        'irrigation': _irrigation,
        'crop': 'Turmeric',
      });

      if (!mounted) return;
      _showSnack('Plot saved and shown on map');
      context.pop();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to save plot. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final farmersAsync = ref.watch(farmersProvider);
    final farmers =
        farmersAsync.valueOrNull?.where((f) => !f.isDeleted).toList() ?? [];

    final existingPlots = ref.watch(plotsProvider).valueOrNull ?? [];

    final farmerName = _selectedFarmerId != null
        ? farmers
            .where((f) => f.id == _selectedFarmerId)
            .firstOrNull
            ?.name
        : null;

    final areaLabel =
        _points.length >= 3 ? '${_areaHa.toStringAsFixed(2)} ha' : '— ha';
    final pointsLabel =
        '${_points.length} pt${_points.length == 1 ? '' : 's'}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Add Plot'),
            const SizedBox(width: 10),
            _StatsChip(label: '$pointsLabel · $areaLabel'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : _submit,
            child: Text(
              'Save',
              style: AppTextStyles.body.copyWith(
                  color: AppColors.textOnPrimary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Map — 55% ────────────────────────────────
          Expanded(flex: 5, child: _buildMapSection(existingPlots)),
          // ── Form — 45%, scrollable ────────────────────
          Expanded(
            flex: 4,
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: _buildForm(farmerName, farmers, farmersAsync.isLoading),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Form ──────────────────────────────────────────────
  Widget _buildForm(String? farmerName, List farmers, bool loadingFarmers) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: loadingFarmers
                ? const SizedBox(
                    height: 48,
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary)))
                : DropdownButtonFormField<String>(
                    value: _selectedFarmerId,
                    decoration: const InputDecoration(
                      labelText: 'Farmer *',
                      prefixIcon: Icon(Icons.person_outline, size: 18),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                    ),
                    hint: const Text('Select farmer…',
                        overflow: TextOverflow.ellipsis),
                    items: farmers
                        .map((f) => DropdownMenuItem<String>(
                            value: f.id, child: Text(f.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedFarmerId = v),
                    validator: (v) =>
                        v == null ? 'Please select a farmer' : null,
                  ),
          ),
          const SizedBox(height: 8),

          AppCard(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Column(
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  validator: _validateName,
                  textCapitalization: TextCapitalization.words,
                  style: AppTextStyles.body,
                  decoration: const InputDecoration(
                    labelText: 'Plot Name *',
                    hintText: 'e.g. South Field',
                    prefixIcon: Icon(Icons.label_outline, size: 18),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _soilType,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Soil Type *',
                          prefixIcon:
                              Icon(Icons.terrain_outlined, size: 18),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 0),
                        ),
                        hint: const Text('Select…',
                            overflow: TextOverflow.ellipsis),
                        items: CropConstants.soilTypes
                            .map((s) => DropdownMenuItem(
                                value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) => setState(() => _soilType = v),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _irrigation,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Irrigation *',
                          prefixIcon:
                              Icon(Icons.water_drop_outlined, size: 18),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 0),
                        ),
                        hint: const Text('Select…',
                            overflow: TextOverflow.ellipsis),
                        items: CropConstants.irrigationTypes
                            .map((i) => DropdownMenuItem(
                                value: i, child: Text(i)))
                            .toList(),
                        onChanged: (v) => setState(() => _irrigation = v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.grass,
                  label: 'Crop',
                  child: const AppBadge(
                    label: 'Turmeric',
                    variant: BadgeVariant.success,
                    icon: Icons.grass,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoTile(
                  icon: Icons.straighten_outlined,
                  label: 'Calculated Area',
                  child: Text(
                    _points.length >= 3
                        ? '${_areaHa.toStringAsFixed(2)} ha'
                        : '— ha',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: _points.length >= 3
                          ? AppColors.primary
                          : AppColors.textDisabled,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          ElevatedButton.icon(
            onPressed: _loading ? null : _submit,
            icon: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check, size: 16),
            label: Text(_loading ? 'Saving…' : 'Save Plot'),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44)),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => context.pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              minimumSize: const Size(double.infinity, 36),
              padding: EdgeInsets.zero,
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // ── Map section ───────────────────────────────────────
  Widget _buildMapSection(List<PlotModel> existingPlots) {
    return Container(
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border))),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Listener(
            onPointerDown: _onPointerDown,
            onPointerMove: _onPointerMove,
            onPointerUp: _onPointerUp,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _initialCenter,
                    initialZoom: 16,
                    interactionOptions: InteractionOptions(
                      flags: _isDragging
                          ? InteractiveFlag.pinchZoom |
                              InteractiveFlag.doubleTapZoom
                          : InteractiveFlag.all,
                    ),
                    onTap: _onMapTap,
                  ),
                  children: [
                    TileLayer(
                      key: ValueKey(_useSatellite),
                      urlTemplate: _useSatellite
                          ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                          : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.agritrack',
                    ),

                    // ── Existing plots reference ──────────
                    if (_showExistingPlots && existingPlots.isNotEmpty)
                      PolygonLayer(
                        polygons: existingPlots
                            .where((p) => p.boundary.length >= 3)
                            .map(
                              (p) => Polygon(
                                points: p.boundary
                                    .map((pt) => LatLng(pt[0], pt[1]))
                                    .toList(),
                                color: const Color(0xFF616161)
                                    .withOpacity(0.35),
                                borderColor: const Color(0xFF424242)
                                    .withOpacity(0.9),
                                borderStrokeWidth: 2,
                                isDotted: true,
                                isFilled: true,
                              ),
                            )
                            .toList(),
                      ),
                    if (_showExistingPlots && existingPlots.isNotEmpty)
                      MarkerLayer(
                        markers: existingPlots
                            .where((p) => p.boundary.isNotEmpty)
                            .map(
                              (p) => Marker(
                                point:
                                    LatLng(p.centroid[0], p.centroid[1]),
                                width: 110,
                                height: 26,
                                child: IgnorePointer(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface
                                          .withOpacity(0.85),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                      border: Border.all(
                                          color: AppColors.textDisabled
                                              .withOpacity(0.5)),
                                    ),
                                    child: Text(
                                      p.name,
                                      style: AppTextStyles.caption
                                          .copyWith(
                                        fontSize: 10,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),

                    // ── New plot being drawn ──────────────
                    if (_points.length >= 2)
                      PolygonLayer(polygons: [
                        Polygon(
                          points: _points,
                          color: AppColors.primary.withOpacity(0.18),
                          borderColor: AppColors.primary,
                          borderStrokeWidth: 2.5,
                        ),
                      ]),
                    MarkerLayer(
                      markers: _points.asMap().entries.map((e) {
                        final isSelected = e.key == _selectedIndex;
                        return Marker(
                          point: e.value,
                          width: isSelected ? 36 : 26,
                          height: isSelected ? 36 : 26,
                          child: _VertexMarker(
                              index: e.key + 1, isSelected: isSelected),
                        );
                      }).toList(),
                    ),

                    // ── User location marker ──────────────
                    if (_userPosition != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _userPosition!,
                            width: 36,
                            height: 36,
                            child: IgnorePointer(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.18),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2.5),
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
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                // ── Hint / drag banner ────────────────────
                if (_selectedIndex != null)
                  Positioned(
                    bottom: 10,
                    left: 10,
                    right: 70,
                    child: _MapSelectedBanner(
                        index: _selectedIndex! + 1,
                        isDragging: _isDragging),
                  )
                else if (_points.isEmpty)
                  const Positioned(
                    bottom: 10,
                    left: 10,
                    right: 70,
                    child: _MapHintBanner(),
                  ),

                // ── Existing plots toggle ─────────────────
                Positioned(
                  top: 10,
                  left: 10,
                  child: _ExistingPlotsToggle(
                    count: existingPlots.length,
                    visible: _showExistingPlots,
                    onToggle: () => setState(
                        () => _showExistingPlots = !_showExistingPlots),
                  ),
                ),

                // ── Satellite toggle ──────────────────────
                Positioned(
                  top: 10,
                  right: 10,
                  child: _MapLayerToggle(
                    isSatellite: _useSatellite,
                    onToggle: () =>
                        setState(() => _useSatellite = !_useSatellite),
                  ),
                ),

                // ── My Location button ────────────────────
                Positioned(
                  top: 58,
                  right: 10,
                  child: GestureDetector(
                    onTap: _locLoading ? null : _goToMyLocation,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _userPosition != null
                              ? Colors.blue.withOpacity(0.4)
                              : AppColors.border,
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: _locLoading
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.blue),
                            )
                          : Icon(
                              _userPosition != null
                                  ? Icons.my_location_rounded
                                  : Icons.location_searching_rounded,
                              size: 18,
                              color: _userPosition != null
                                  ? Colors.blue
                                  : AppColors.textPrimary,
                            ),
                    ),
                  ),
                ),

                // ── Undo / Clear buttons ──────────────────
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Column(children: [
                    _MapIconButton(
                      icon: Icons.undo,
                      tooltip: 'Undo last point',
                      enabled: _points.isNotEmpty && !_loading,
                      onTap: _undoPoint,
                    ),
                    const SizedBox(height: 8),
                    _MapIconButton(
                      icon: Icons.delete_outline,
                      tooltip: 'Clear all points',
                      enabled: _points.isNotEmpty && !_loading,
                      onTap: _clearPoints,
                    ),
                  ]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Existing plots toggle chip ────────────────────────
class _ExistingPlotsToggle extends StatelessWidget {
  const _ExistingPlotsToggle({
    required this.count,
    required this.visible,
    required this.onToggle,
  });
  final int count;
  final bool visible;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: visible
                ? AppColors.textDisabled.withOpacity(0.6)
                : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: 15,
              color: visible
                  ? AppColors.textPrimary
                  : AppColors.textDisabled,
            ),
            const SizedBox(width: 5),
            Text(
              '$count plotted',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: visible
                    ? AppColors.textPrimary
                    : AppColors.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stats chip in AppBar ──────────────────────────────
class _StatsChip extends StatelessWidget {
  const _StatsChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(label,
          style: AppTextStyles.caption.copyWith(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }
}

// ── Info tile ─────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  const _InfoTile(
      {required this.icon, required this.label, required this.child});
  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.accent),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              const SizedBox(height: 2),
              child,
            ],
          ),
        ],
      ),
    );
  }
}

// ── Vertex marker ─────────────────────────────────────
class _VertexMarker extends StatelessWidget {
  const _VertexMarker({required this.index, this.isSelected = false});
  final int index;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? AppColors.accent : AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white,
            width: isSelected ? 3 : 2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.3 : 0.2),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 1))
        ],
      ),
      alignment: Alignment.center,
      child: Text('$index',
          style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontSize: isSelected ? 12 : 10,
              fontWeight: FontWeight.bold)),
    );
  }
}

// ── Map hint banner ───────────────────────────────────
class _MapHintBanner extends StatelessWidget {
  const _MapHintBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.96),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ]),
      child: Row(
        children: [
          const Icon(Icons.touch_app_outlined,
              size: 16, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
              child: Text('Tap the map to mark each corner of the plot',
                  style: AppTextStyles.caption)),
        ],
      ),
    );
  }
}

// ── Selected/dragging banner ──────────────────────────
class _MapSelectedBanner extends StatelessWidget {
  const _MapSelectedBanner(
      {required this.index, required this.isDragging});
  final int index;
  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.96),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ]),
      child: Row(
        children: [
          Icon(isDragging ? Icons.open_with : Icons.touch_app,
              size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isDragging
                  ? 'Dragging point $index…'
                  : 'Point $index selected — drag to reposition',
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Map icon button ───────────────────────────────────
class _MapIconButton extends StatelessWidget {
  const _MapIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.enabled = true,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ]),
          child: Icon(icon,
              size: 18,
              color: enabled
                  ? AppColors.textPrimary
                  : AppColors.textDisabled),
        ),
      ),
    );
  }
}

// ── Map layer toggle ──────────────────────────────────
class _MapLayerToggle extends StatelessWidget {
  const _MapLayerToggle({required this.isSatellite, required this.onToggle});
  final bool isSatellite;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surface,
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSatellite ? Icons.map_outlined : Icons.satellite_alt_outlined,
              size: 15,
              color: AppColors.textPrimary,
            ),
            const SizedBox(width: 5),
            Text(
              isSatellite ? 'Street' : 'Satellite',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}