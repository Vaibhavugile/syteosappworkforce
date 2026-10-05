import 'package:cloud_firestore/cloud_firestore.dart';

enum OfficePresenceStatus {
  atOffice,
  checkedOut,
  outsideOffice,
  unknown,
}

extension OfficePresenceStatusX on OfficePresenceStatus {
  String get value {
    switch (this) {
      case OfficePresenceStatus.atOffice:
        return 'atOffice';
      case OfficePresenceStatus.checkedOut:
        return 'checkedOut';
      case OfficePresenceStatus.outsideOffice:
        return 'outsideOffice';
      case OfficePresenceStatus.unknown:
        return 'unknown';
    }
  }

  String get label {
    switch (this) {
      case OfficePresenceStatus.atOffice:
        return 'At Office';
      case OfficePresenceStatus.checkedOut:
        return 'Checked Out';
      case OfficePresenceStatus.outsideOffice:
        return 'Outside Office';
      case OfficePresenceStatus.unknown:
        return 'Unknown';
    }
  }

  static OfficePresenceStatus fromValue(dynamic value) {
    switch (value?.toString()) {
      case 'atOffice':
        return OfficePresenceStatus.atOffice;
      case 'checkedOut':
        return OfficePresenceStatus.checkedOut;
      case 'outsideOffice':
        return OfficePresenceStatus.outsideOffice;
      case 'unknown':
      default:
        return OfficePresenceStatus.unknown;
    }
  }
}

class OfficePresence {
  final String userId;
  final String attendanceId;
  final String officeId;
  final OfficePresenceStatus status;
  final String lastAction;
  final DateTime? lastActionAt;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final double? distanceFromOffice;
  final DateTime? updatedAt;

  const OfficePresence({
    required this.userId,
    required this.attendanceId,
    required this.officeId,
    required this.status,
    required this.lastAction,
    this.lastActionAt,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.distanceFromOffice,
    this.updatedAt,
  });

  factory OfficePresence.fromMap(
    String userId,
    Map<String, dynamic> data,
  ) {
    return OfficePresence(
      userId: userId,
      attendanceId: (data['attendanceId'] ?? '').toString(),
      officeId: (data['officeId'] ?? '').toString(),
      status: OfficePresenceStatusX.fromValue(data['status']),
      lastAction: (data['lastAction'] ?? '').toString(),
      lastActionAt: _toDateTime(data['lastActionAt']),
      latitude: _toDouble(data['latitude']),
      longitude: _toDouble(data['longitude']),
      accuracy: _toDouble(data['accuracy']),
      distanceFromOffice: _toDouble(data['distanceFromOffice']),
      updatedAt: _toDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'attendanceId': attendanceId,
      'officeId': officeId,
      'status': status.value,
      'lastAction': lastAction,
      'lastActionAt': _timestamp(lastActionAt),
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'distanceFromOffice': distanceFromOffice,
      'updatedAt': _timestamp(updatedAt),
    };
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static Timestamp? _timestamp(DateTime? value) {
    return value == null ? null : Timestamp.fromDate(value);
  }
}
