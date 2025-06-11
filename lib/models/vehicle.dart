import 'package:cloud_firestore/cloud_firestore.dart';

class Vehicle {
  final String id;
  final String make;
  final String model;
  final int year;
  final String color;
  final String? vin;
  final String? tag;
  final double startingOdometer;
  final String? bluetoothDeviceName;
  final String? bluetoothMacId;
  final String? photoPath;
  final String? nickname;

  Vehicle({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    this.vin,
    this.tag,
    required this.startingOdometer,
    this.bluetoothDeviceName,
    this.bluetoothMacId,
    this.photoPath,
    this.nickname,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'make': make,
      'model': model,
      'year': year,
      'color': color,
      'vin': vin,
      'tag': tag,
      'startingOdometer': startingOdometer,
      'bluetoothDeviceName': bluetoothDeviceName,
      'bluetoothMacId': bluetoothMacId,
      'photoPath': photoPath,
      'nickname': nickname,
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] ?? '',
      make: map['make'] ?? '',
      model: map['model'] ?? '',
      year: map['year'] ?? 0,
      color: map['color'] ?? '',
      vin: map['vin'],
      tag: map['tag'],
      startingOdometer: (map['startingOdometer'] ?? 0).toDouble(),
      bluetoothDeviceName: map['bluetoothDeviceName'],
      bluetoothMacId: map['bluetoothMacId'],
      photoPath: map['photoPath'],
      nickname: map['nickname'],
    );
  }

  factory Vehicle.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return Vehicle.fromMap(data);
  }

  Vehicle copyWith({
    String? id,
    String? make,
    String? model,
    int? year,
    String? color,
    String? vin,
    String? tag,
    double? startingOdometer,
    String? bluetoothDeviceName,
    String? bluetoothMacId,
    String? photoPath,
    String? nickname,
  }) {
    return Vehicle(
      id: id ?? this.id,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      color: color ?? this.color,
      vin: vin ?? this.vin,
      tag: tag ?? this.tag,
      startingOdometer: startingOdometer ?? this.startingOdometer,
      bluetoothDeviceName: bluetoothDeviceName ?? this.bluetoothDeviceName,
      bluetoothMacId: bluetoothMacId ?? this.bluetoothMacId,
      photoPath: photoPath ?? this.photoPath,
      nickname: nickname ?? this.nickname,
    );
  }
}
