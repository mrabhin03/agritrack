// features/plots/add_plot_screen.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/crop_constants.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/section_header.dart';

const _farmerNames = {
  'F001': 'Arun Menon',
  'F002': 'Priya Nair',
  'F003': 'Suresh Kumar',
  'F004': 'Latha Krishnan',
  'F005': 'Biju Thomas',
};

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

class AddPlotScreen extends StatefulWidget {
  const AddPlotScreen({super.key, this.farmerId});
  final String? farmerId;

  @override
  State<AddPlotScreen> createState() => _AddPlotScreenState();
}

class _AddPlotScreenState extends State<AddPlotScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _mapController = MapController();

  final List<LatLng> _points = [];
  String? _soilType;
  String? _irrigation;
  bool _loading = false;

  // ── Drag state ───────────────────────────────────────────
  int? _selectedIndex;
  bool _isDragging = false;
  Offset? _dragStartFinger;
  Offset? _dragStartScreen;

  static const _initialCenter = LatLng(9.297028, 76.670179);
  static const double _hitRadius = 28.0;

  double get _areaHa => polygonAreaHa(_points);

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Plot name is required';
    if (v.trim().length < 2) return 'At least 2 characters';
    return null;
  }

  Offset? _latLngToOffset(LatLng point, BoxConstraints mapConstraints) {
    try {
      final camera = _mapController.camera;
      final px = camera.latLngToScreenPoint(point);
      return Offset(px.x, px.y);
    } catch (_) {
      return null;
    }
  }

  int? _hitTestVertex(Offset tapOffset, BoxConstraints constraints) {
    int? best;
    double bestDist = _hitRadius;
    for (int i = 0; i < _points.length; i++) {
      final px = _latLngToOffset(_points[i], constraints);
      if (px == null) continue;
      final d = (tapOffset - px).distance;
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    return best;
  }

  void _onPointerDown(PointerDownEvent e, BoxConstraints constraints) {
    final hit = _hitTestVertex(e.localPosition, constraints);
    if (hit != null) {
      final screenPt = _latLngToOffset(_points[hit], constraints);
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

  void _onPointerMove(PointerMoveEvent e, BoxConstraints constraints) {
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

  void _onPointerUp(PointerUpEvent e, BoxConstraints constraints) {
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
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
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _loading = false);
    _showSnack('Plot saved successfully');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final farmerName = widget.farmerId != null
        ? (_farmerNames[widget.farmerId] ?? widget.farmerId)
        : null;

    final areaLabel = _points.length >= 3
        ? '${_areaHa.toStringAsFixed(2)} ha'
        : '— ha';
    final pointsLabel = '${_points.length} pt${_points.length == 1 ? '' : 's'}';

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
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Map — flex 5 (~55% of screen) ──────────────────
          Expanded(
            flex: 5,
            child: _buildMapSection(),
          ),

          // ── Form — flex 4, scrollable so it never overflows ─
          Expanded(
            flex: 4,
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: _buildCompactForm(farmerName),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactForm(String? farmerName) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Farmer pill (optional) ──────────────────────────
          if (farmerName != null) ...[
            _FarmerPill(name: farmerName, id: widget.farmerId!),
            const SizedBox(height: 8),
          ],

          // ── Fields card ─────────────────────────────────────
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
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
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
                            .map((i) =>
                                DropdownMenuItem(value: i, child: Text(i)))
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

          // ── Crop + Area info row ────────────────────────────
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
                  label: 'Area',
                  child: Text(
                    _points.length >= 3
                        ? '${_areaHa.toStringAsFixed(2)} ha'
                        : '— ha',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Save ────────────────────────────────────────────
          ElevatedButton.icon(
            onPressed: _loading ? null : _submit,
            icon: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check, size: 16),
            label: Text(_loading ? 'Saving…' : 'Save Plot'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
          const SizedBox(height: 6),

          // ── Cancel ──────────────────────────────────────────
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

  Widget _buildMapSection() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Listener(
            onPointerDown: (e) => _onPointerDown(e, constraints),
            onPointerMove: (e) => _onPointerMove(e, constraints),
            onPointerUp: (e) => _onPointerUp(e, constraints),
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
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.agritrack',
                    ),
                    if (_points.length >= 2)
                      PolygonLayer(
                        polygons: [
                          Polygon(
                            points: _points,
                            color: AppColors.primary.withOpacity(0.18),
                            borderColor: AppColors.primary,
                            borderStrokeWidth: 2.5,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: _points.asMap().entries.map((e) {
                        final isSelected = e.key == _selectedIndex;
                        return Marker(
                          point: e.value,
                          width: isSelected ? 36 : 26,
                          height: isSelected ? 36 : 26,
                          child: _VertexMarker(
                            index: e.key + 1,
                            isSelected: isSelected,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                // ── Hint / selection banner ──────────────────
                if (_selectedIndex != null)
                  Positioned(
                    bottom: 10,
                    left: 10,
                    right: 70,
                    child: _MapSelectedBanner(
                      index: _selectedIndex! + 1,
                      isDragging: _isDragging,
                    ),
                  )
                else if (_points.isEmpty)
                  const Positioned(
                    bottom: 10,
                    left: 10,
                    right: 70,
                    child: _MapHintBanner(),
                  ),

                // ── Undo / Clear controls ────────────────────
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Column(
                    children: [
                      _MapIconButton(
                        icon: Icons.undo,
                        tooltip: 'Undo last point',
                        enabled: _points.isNotEmpty,
                        onTap: _undoPoint,
                      ),
                      const SizedBox(height: 8),
                      _MapIconButton(
                        icon: Icons.delete_outline,
                        tooltip: 'Clear all points',
                        enabled: _points.isNotEmpty,
                        onTap: _clearPoints,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Stats chip in AppBar ────────────────────────────────────────
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
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── Farmer pill ─────────────────────────────────────────────────
class _FarmerPill extends StatelessWidget {
  const _FarmerPill({required this.name, required this.id});
  final String name;
  final String id;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person, size: 15, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(name, style: AppTextStyles.labelLarge),
          const SizedBox(width: 6),
          Text(id, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

// ── Info tile (crop / area) ─────────────────────────────────────
class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.child,
  });
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
        border: Border.all(color: AppColors.border),
      ),
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

// ── Selected point banner ───────────────────────────────────────
class _MapSelectedBanner extends StatelessWidget {
  const _MapSelectedBanner({
    required this.index,
    required this.isDragging,
  });
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isDragging ? Icons.open_with : Icons.touch_app,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isDragging
                  ? 'Dragging point $index…'
                  : 'Point $index selected — drag to reposition',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hint banner ─────────────────────────────────────────────────
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.touch_app_outlined,
              size: 16, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tap the map to mark each corner of the plot',
              style: AppTextStyles.caption,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Numbered vertex marker ──────────────────────────────────────
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
          width: isSelected ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isSelected ? 0.3 : 0.2),
            blurRadius: isSelected ? 8 : 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$index',
        style: AppTextStyles.badge.copyWith(
          color: Colors.white,
          fontSize: isSelected ? 12 : 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ── Small floating icon button ──────────────────────────────────
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
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? AppColors.textPrimary : AppColors.textDisabled,
          ),
        ),
      ),
    );
  }
}