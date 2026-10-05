import 'package:cloud_firestore/cloud_firestore.dart';

class OfficeLocation {
  final String officeId;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final bool isActive;
  final String address;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const OfficeLocation({
    required this.officeId,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 100,
    this.isActive = true,
    this.address = '',
    this.createdAt,
    this.updatedAt,
  });

  factory OfficeLocation.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    return OfficeLocation(
      officeId: id,
      name: (data['name'] ?? 'Office').toString(),
      latitude: _toDouble(data['latitude']),
      longitude: _toDouble(data['longitude']),
      radiusMeters: _toDouble(data['radiusMeters'], fallback: 100),
      isActive: data['isActive'] as bool? ?? true,
      address: (data['address'] ?? '').toString(),
      createdAt: _toDateTime(data['createdAt']),
      updatedAt: _toDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'isActive': isActive,
      'address': address,
      'createdAt': createdAt == null
          ? null
          : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null
          ? null
          : Timestamp.fromDate(updatedAt!),
    };
  }

  OfficeLocation copyWith({
    String? name,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    bool? isActive,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OfficeLocation(
      officeId: officeId,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      isActive: isActive ?? this.isActive,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static double _toDouble(
    dynamic value, {
    double fallback = 0,
  }) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
