class SavedLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? notes;
  final DateTime createdAt;

  SavedLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SavedLocation.fromMap(Map<String, dynamic> map) {
    return SavedLocation(
      id: map['id'] as String,
      name: map['name'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  SavedLocation copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    String? notes,
    DateTime? createdAt,
  }) {
    return SavedLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
