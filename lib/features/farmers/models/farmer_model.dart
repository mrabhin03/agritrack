// features/farmers/models/farmer_model.dart
import '../../../core/utils/formatters.dart';

class FarmerModel {
  final String id;
  final String name;
  final String phone;
  final int age;
  final String village;
  final double areaHa;
  final String? notes;
  final double? gpsLat;
  final double? gpsLng;
  final String? photoUrl;
  final String stage;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FarmerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.age,
    required this.village,
    required this.areaHa,
    this.notes,
    this.gpsLat,
    this.gpsLng,
    this.photoUrl,
    this.stage = 'Nursery',
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Derived getters ───────────────────────────────
  String get initials => name.trim().split(' ')
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();

  bool get hasGps => gpsLat != null && gpsLng != null;

  String get gpsLabel => hasGps
      ? '${gpsLat!.toStringAsFixed(4)}° N, '
        '${gpsLng!.toStringAsFixed(4)}° E'
      : 'No GPS captured';

  String get areaLabel => Formatters.haShort(areaHa);

  String get registeredLabel => Formatters.dateLabel(createdAt);

  // ── fromJson (Supabase response) ──────────────────
  factory FarmerModel.fromJson(Map<String, dynamic> j) {
    return FarmerModel(
      id:        j['id'] as String,
      name:      j['name'] as String,
      phone:     j['phone'] as String,
      age:       j['age'] as int,
      village:   j['village'] as String,
      areaHa:    (j['area_ha'] as num).toDouble(),
      notes:     j['notes'] as String?,
      gpsLat:    (j['gps_lat'] as num?)?.toDouble(),
      gpsLng:    (j['gps_lng'] as num?)?.toDouble(),
      photoUrl:  j['photo_url'] as String?,
      stage:     j['stage'] as String? ?? 'Nursery',
      isDeleted: j['is_deleted'] as bool? ?? false,
      createdAt: DateTime.parse(j['created_at'] as String),
      updatedAt: DateTime.parse(j['updated_at'] as String),
    );
  }

  // ── toJson (for Supabase insert/update) ───────────
  Map<String, dynamic> toJson() => {
    'name':      name,
    'phone':     phone,
    'age':       age,
    'village':   village,
    'area_ha':   areaHa,
    'notes':     notes,
    'gps_lat':   gpsLat,
    'gps_lng':   gpsLng,
    'is_deleted': isDeleted,
  };

  // ── copyWith ──────────────────────────────────────
  FarmerModel copyWith({
    String? id,
    String? name,
    String? phone,
    int? age,
    String? village,
    double? areaHa,
    String? notes,
    double? gpsLat,
    double? gpsLng,
    String? photoUrl,
    String? stage,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FarmerModel(
      id:        id        ?? this.id,
      name:      name      ?? this.name,
      phone:     phone     ?? this.phone,
      age:       age       ?? this.age,
      village:   village   ?? this.village,
      areaHa:    areaHa    ?? this.areaHa,
      notes:     notes     ?? this.notes,
      gpsLat:    gpsLat    ?? this.gpsLat,
      gpsLng:    gpsLng    ?? this.gpsLng,
      photoUrl:  photoUrl  ?? this.photoUrl,
      stage:     stage     ?? this.stage,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ── Fake data (used in Layer 6 providers) ─────────
  static List<FarmerModel> fakeList() => [
    FarmerModel(
      id: 'F001', name: 'Arun Menon', phone: '9876543210',
      age: 42, village: 'Kothamangalam', areaHa: 2.4,
      stage: 'Growth', notes: 'Experienced turmeric grower.',
      gpsLat: 10.0603, gpsLng: 76.7946,
      createdAt: DateTime(2025, 1, 10),
      updatedAt: DateTime(2025, 3, 15),
    ),
    FarmerModel(
      id: 'F002', name: 'Priya Nair', phone: '9845678901',
      age: 35, village: 'Munnar', areaHa: 1.8,
      stage: 'Flowering',
      createdAt: DateTime(2024, 11, 5),
      updatedAt: DateTime(2025, 2, 20),
    ),
    FarmerModel(
      id: 'F003', name: 'Suresh Kumar', phone: '9812345678',
      age: 51, village: 'Thodupuzha', areaHa: 3.2,
      stage: 'Harvest', notes: 'Ready for harvest this month.',
      gpsLat: 9.7167, gpsLng: 76.7167,
      createdAt: DateTime(2024, 9, 1),
      updatedAt: DateTime(2025, 3, 1),
    ),
    FarmerModel(
      id: 'F004', name: 'Latha Krishnan', phone: '9834567890',
      age: 38, village: 'Erattupetta', areaHa: 1.1,
      stage: 'Nursery',
      createdAt: DateTime(2025, 2, 20),
      updatedAt: DateTime(2025, 2, 20),
    ),
    FarmerModel(
      id: 'F005', name: 'Biju Thomas', phone: '9867890123',
      age: 46, village: 'Pala', areaHa: 2.0,
      stage: 'Planting', notes: 'New to turmeric cultivation.',
      gpsLat: 9.7167, gpsLng: 76.6833,
      createdAt: DateTime(2025, 3, 1),
      updatedAt: DateTime(2025, 3, 1),
    ),
  ];

  @override
  String toString() => 'FarmerModel($id, $name, $village)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FarmerModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}