// features/plots/models/plot_model.dart

import 'package:hive/hive.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/constants/crop_constants.dart';

part 'plot_model.g.dart';

@HiveType(typeId: 1)
class PlotModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String farmerId;
  @HiveField(2) final String name;
  // [[lat, lng], [lat, lng], ...] — lat-first for flutter_map
  @HiveField(3) final List<List<double>> boundary;
  @HiveField(4) final double areaHa;
  @HiveField(5) final String soilType;
  @HiveField(6) final String irrigation;
  @HiveField(7) final String crop;
  @HiveField(8) final DateTime createdAt;

  PlotModel({
    required this.id,
    required this.farmerId,
    required this.name,
    required this.boundary,
    required this.areaHa,
    required this.soilType,
    required this.irrigation,
    this.crop = 'Turmeric',
    required this.createdAt,
  });

  // ── Derived getters ───────────────────────────────────
  String get areaLabel => Formatters.ha(areaHa);

  String get areaAcresLabel => Formatters.acres(areaHa);

  String get registeredLabel => Formatters.dateLabel(createdAt);

  /// Centre-point of polygon (average of vertices) — for map marker
  List<double> get centroid {
    if (boundary.isEmpty) return [10.0275, 76.3084]; // fallback: Kochi
    final lat = boundary.map((p) => p[0]).reduce((a, b) => a + b) / boundary.length;
    final lng = boundary.map((p) => p[1]).reduce((a, b) => a + b) / boundary.length;
    return [lat, lng];
  }

  bool get hasValidBoundary => boundary.length >= 3;

  // ── fromJson (Supabase — Layer 7) ────────────────────
  // PostGIS returns GeoJSON: {type:'Polygon', coordinates:[[[lng,lat]...]]}
  // Flip to [lat,lng] for flutter_map (LatLng is lat-first)
  factory PlotModel.fromJson(Map<String, dynamic> j) {
    final List<List<double>> coords;
    final rawBoundary = j['boundary'];
    if (rawBoundary is Map && rawBoundary['type'] == 'Polygon') {
      final ring = rawBoundary['coordinates'][0] as List;
      coords = ring
          .map<List<double>>((p) => [(p[1] as num).toDouble(), (p[0] as num).toDouble()])
          .toList();
    } else {
      coords = [];
    }

    return PlotModel(
      id:         j['id']         as String,
      farmerId:   j['farmer_id']  as String,
      name:       j['name']       as String,
      boundary:   coords,
      areaHa:     (j['area_ha']   as num).toDouble(),
      soilType:   j['soil_type']  as String? ?? CropConstants.soilTypes.first,
      irrigation: j['irrigation'] as String? ?? CropConstants.irrigationTypes.first,
      crop:       j['crop']       as String? ?? 'Turmeric',
      createdAt:  DateTime.parse(j['created_at'] as String),
    );
  }

  // ── toJson (Supabase insert/update — Layer 7) ─────────
  // Converts [lat,lng] back to GeoJSON [lng,lat] (PostGIS expects lon-first)
  Map<String, dynamic> toJson() => {
    'farmer_id':  farmerId,
    'name':       name,
    'boundary':   boundaryGeoJson(),
    'area_ha':    areaHa,
    'soil_type':  soilType,
    'irrigation': irrigation,
    'crop':       crop,
  };

  /// GeoJSON Polygon for Supabase ST_GeomFromGeoJSON insert
  Map<String, dynamic> boundaryGeoJson() => {
    'type': 'Polygon',
    'coordinates': [
      boundary.map((p) => [p[1], p[0]]).toList(), // flip back to [lng, lat]
    ],
  };

  // ── copyWith ──────────────────────────────────────────
  PlotModel copyWith({
    String?             id,
    String?             farmerId,
    String?             name,
    List<List<double>>? boundary,
    double?             areaHa,
    String?             soilType,
    String?             irrigation,
    String?             crop,
    DateTime?           createdAt,
  }) {
    return PlotModel(
      id:         id         ?? this.id,
      farmerId:   farmerId   ?? this.farmerId,
      name:       name       ?? this.name,
      boundary:   boundary   ?? this.boundary,
      areaHa:     areaHa     ?? this.areaHa,
      soilType:   soilType   ?? this.soilType,
      irrigation: irrigation ?? this.irrigation,
      crop:       crop       ?? this.crop,
      createdAt:  createdAt  ?? this.createdAt,
    );
  }

  // ── Seed data (written to Hive on first install) ──────
  static List<PlotModel> seedList() => [
    PlotModel(
      id: 'PL001', farmerId: 'F001', name: 'South Field',
      boundary: [
        [10.0590, 76.7930], [10.0610, 76.7930],
        [10.0610, 76.7960], [10.0590, 76.7960],
        [10.0590, 76.7930],
      ],
      areaHa: 1.2, soilType: 'Loamy', irrigation: 'Drip',
      createdAt: DateTime(2025, 1, 12),
    ),
    PlotModel(
      id: 'PL002', farmerId: 'F001', name: 'North Ridge',
      boundary: [
        [10.0620, 76.7940], [10.0635, 76.7940],
        [10.0635, 76.7965], [10.0620, 76.7965],
        [10.0620, 76.7940],
      ],
      areaHa: 1.2, soilType: 'Red laterite', irrigation: 'Rain-fed',
      createdAt: DateTime(2025, 1, 15),
    ),
    PlotModel(
      id: 'PL003', farmerId: 'F002', name: 'Valley Plot',
      boundary: [
        [10.0880, 77.0590], [10.0900, 77.0590],
        [10.0900, 77.0615], [10.0880, 77.0615],
        [10.0880, 77.0590],
      ],
      areaHa: 1.8, soilType: 'Sandy loam', irrigation: 'Sprinkler',
      createdAt: DateTime(2024, 11, 8),
    ),
    PlotModel(
      id: 'PL004', farmerId: 'F003', name: 'East Block',
      boundary: [
        [9.7155, 76.7155], [9.7180, 76.7155],
        [9.7180, 76.7185], [9.7155, 76.7185],
        [9.7155, 76.7155],
      ],
      areaHa: 2.0, soilType: 'Clay', irrigation: 'Flood',
      createdAt: DateTime(2024, 9, 5),
    ),
    PlotModel(
      id: 'PL005', farmerId: 'F003', name: 'West Block',
      boundary: [
        [9.7155, 76.7120], [9.7180, 76.7120],
        [9.7180, 76.7150], [9.7155, 76.7150],
        [9.7155, 76.7120],
      ],
      areaHa: 1.2, soilType: 'Loamy', irrigation: 'Drip',
      createdAt: DateTime(2024, 9, 10),
    ),
  ];

  @override
  String toString() => 'PlotModel($id, $name, farmer: $farmerId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PlotModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}