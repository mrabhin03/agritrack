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
        [9.298744005189713, 76.67024575070684], 
        [9.29844078160958, 76.669744529729], 
        [9.298063575959759, 76.66959702138645], 
        [9.297547985553049, 76.66938784949329], 
        [9.296823159452938, 76.66941125529335], 
        [9.296355402153504, 76.66936288195036], 
        [9.295941645525124, 76.6694319227985], 
        [9.295733289498646, 76.66972401738829], 
        [9.295629572215844, 76.67013589074102], 
        [9.29578577658173, 76.67041637721911], 
        [9.296068477276638, 76.67048847054963], 
        [9.296580719182911, 76.67076886654037], 
        [9.29663988229163, 76.6709365613444], 
        [9.296832326399004, 76.67074344631148], 
        [9.2973037980728, 76.67083262575163], 
        [9.297523728337628, 76.67065417411673], 
        [9.297833971912386, 76.67043080548338], 
        [9.29792557179439, 76.67061869320719], 
        [9.29832086767929, 76.67074488642758], 
        [9.298721417504403, 76.67051881752776]],
      areaHa: 1.2, soilType: 'Loamy', irrigation: 'Drip',
      createdAt: DateTime(2025, 1, 12),
    ),
    PlotModel(
      id: 'PL002', farmerId: 'F001', name: 'North Ridge',
      boundary: 
        [
          [9.375866255438797, 76.60475408412104], 
          [9.376450219644829, 76.6051413853347], 
          [9.3769595491169, 76.60540809099108], 
          [9.377122940554607, 76.60578756693253], 
          [9.377040327752079, 76.60602512181849], 
          [9.377292889758028, 76.60622011521232], 
          [9.37783505975171, 76.60608532832215], 
          [9.378064408088376, 76.60618122683516], 
          [9.378604772214711, 76.60614608377794], 
          [9.37876372942281, 76.60585106269225], 
          [9.378863891558302, 76.6054491463252], 
          [9.379108072932382, 76.6054477032831], 
          [9.37915159857149, 76.60511516377873], 
          [9.37928900686579, 76.60474297682325], 
          [9.379356315022262, 76.6043954786618], 
          [9.379207932102359, 76.60410065681415], 
          [9.378911760882833, 76.6038481077249], 
          [9.378685299963118, 76.60364961010404], 
          [9.37844306540353, 76.6034552646404], 
          [9.378157770038628, 76.60337529314165], 
          [9.377909827120398, 76.60332535762349], 
          [9.377665844308334, 76.60335204918461], 
          [9.377339663062882, 76.60345944894274], 
          [9.377289772865673, 76.60376416216344], 
          [9.377058017433177, 76.60389977279172], 
          [9.376749798744754, 76.60392844049765], 
          [9.37665351175729, 76.60419959832228], 
          [9.376504563868359, 76.60440941636209]
        ]
      ,
      areaHa: 1.2, soilType: 'Red laterite', irrigation: 'Rain-fed',
      createdAt: DateTime(2025, 1, 15),
    ),
    PlotModel(
      id: 'PL003', farmerId: 'F002', name: 'Valley Plot',
      boundary: [
          [9.395048712882783, 76.56750435514019], 
          [9.393419959322602, 76.56741360520671], 
          [9.393000638424567, 76.56663346034232], 
          [9.392612135777801, 76.56666134429393], 
          [9.392405472223144, 76.56697784045086], 
          [9.392312483759437, 76.56745039464883], 
          [9.392677231022619, 76.56760304812073], 
          [9.391730854349172, 76.56759958879528], 
          [9.391566380911254, 76.56814941845766], 
          [9.390734798752776, 76.56833671121188], 
          [9.39053495695383, 76.56870795772626], 
          [9.39112069681727, 76.56975730825077], 
          [9.392245860048892, 76.56980981038265], 
          [9.39213471842502, 76.57079243160825], 
          [9.392587507306386, 76.57092224637263], 
          [9.392723922112348, 76.57011853874343], 
          [9.393351090676603, 76.57031745665236], 
          [9.393709213550887, 76.56965140100885], 
          [9.39300614273218, 76.56893549816172], 
          [9.39436108221723, 76.56832620800986]
        ],
      areaHa: 1.8, soilType: 'Sandy loam', irrigation: 'Sprinkler',
      createdAt: DateTime(2024, 11, 8),
    ),
    PlotModel(
      id: 'PL004', farmerId: 'F003', name: 'East Block',
      boundary: [
          [9.383486834881184, 76.5682550156282], 
          [9.384975495264923, 76.56883673126617], 
          [9.384590356071337, 76.56995581939094], 
          [9.38534057008183, 76.57087718120115], 
          [9.386034132337047, 76.5708754317779], 
          [9.386628675350268, 76.5696587688146], 
          [9.388303173032272, 76.56908059666861],
          [9.387506414850039, 76.56825835260497], 
          [9.387675426746135, 76.56759879991117], 
          [9.387431680803322, 76.56643580707089], 
          [9.386030129892672, 76.56604001442031], 
          [9.384984704979132, 76.56571118983527], 
          [9.384208879814578, 76.56579501113828]
         ],
      areaHa: 2.0, soilType: 'Clay', irrigation: 'Flood',
      createdAt: DateTime(2024, 9, 5),
    ),
    PlotModel(
      id: 'PL005', farmerId: 'F003', name: 'West Block',
      boundary: [
          [10.076149923469954, 76.66201764556125], 
          [10.07492696659915, 76.66409877903533], 
          [10.075537285458887, 76.66668037136832], 
          [10.075238684436522, 76.66922680807745], 
          [10.072343874720117, 76.66897509545747], 
          [10.072721962636443, 76.66175132673945]
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