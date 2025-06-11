import 'package:cloud_firestore/cloud_firestore.dart';

enum TripPurpose { business, personal }

class PausePeriod {
  final DateTime pauseTime;
  final DateTime? resumeTime;

  PausePeriod({
    required this.pauseTime,
    this.resumeTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'pauseTime': pauseTime.toIso8601String(),
      'resumeTime': resumeTime?.toIso8601String(),
    };
  }

  factory PausePeriod.fromMap(Map<String, dynamic> map) {
    return PausePeriod(
      pauseTime: DateTime.parse(map['pauseTime']),
      resumeTime:
          map['resumeTime'] != null ? DateTime.parse(map['resumeTime']) : null,
    );
  }
}

class Trip {
  final String id;
  final String vehicleId;
  final DateTime startTime;
  final DateTime? endTime;
  final double distance;
  final TripPurpose purpose;
  final String? memo;
  final GeoPoint startLocation;
  final GeoPoint? endLocation;
  final bool isManualEntry;
  final String? deviceName;
  final List<PausePeriod> pausePeriods;

  Trip({
    required this.id,
    required this.vehicleId,
    required this.startTime,
    this.endTime,
    required this.distance,
    required this.purpose,
    this.memo,
    required this.startLocation,
    this.endLocation,
    required this.isManualEntry,
    this.deviceName,
    this.pausePeriods = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'distance': distance,
      'purpose': purpose.toString().split('.').last,
      'memo': memo,
      'startLocation': startLocation,
      'endLocation': endLocation,
      'isManualEntry': isManualEntry,
      'deviceName': deviceName,
      'pausePeriods': pausePeriods.map((p) => p.toMap()).toList(),
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'] ?? '',
      vehicleId: map['vehicleId'] ?? '',
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      distance: (map['distance'] ?? 0).toDouble(),
      purpose: TripPurpose.values.firstWhere(
        (e) => e.toString().split('.').last == map['purpose'],
        orElse: () => TripPurpose.personal,
      ),
      memo: map['memo'],
      startLocation: map['startLocation'] as GeoPoint,
      endLocation: map['endLocation'] as GeoPoint?,
      isManualEntry: map['isManualEntry'] ?? false,
      deviceName: map['deviceName'],
      pausePeriods: (map['pausePeriods'] as List<dynamic>?)
              ?.map((p) => PausePeriod.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  factory Trip.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return Trip.fromMap(data);
  }

  Trip copyWith({
    String? id,
    String? vehicleId,
    DateTime? startTime,
    DateTime? endTime,
    double? distance,
    TripPurpose? purpose,
    String? memo,
    GeoPoint? startLocation,
    GeoPoint? endLocation,
    bool? isManualEntry,
    String? deviceName,
    List<PausePeriod>? pausePeriods,
  }) {
    return Trip(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      distance: distance ?? this.distance,
      purpose: purpose ?? this.purpose,
      memo: memo ?? this.memo,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      isManualEntry: isManualEntry ?? this.isManualEntry,
      deviceName: deviceName ?? this.deviceName,
      pausePeriods: pausePeriods ?? this.pausePeriods,
    );
  }

  // Helper methods for pause functionality
  bool get isPaused =>
      pausePeriods.isNotEmpty && pausePeriods.last.resumeTime == null;

  Duration get totalPausedDuration {
    Duration total = Duration.zero;
    for (final pause in pausePeriods) {
      if (pause.resumeTime != null) {
        total += pause.resumeTime!.difference(pause.pauseTime);
      } else {
        // If currently paused, calculate up to now
        total += DateTime.now().difference(pause.pauseTime);
      }
    }
    return total;
  }
}
