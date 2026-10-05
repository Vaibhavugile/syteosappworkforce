import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus {
  present,
  checkedOut,
  absent,
  onLeave,
}

extension AttendanceStatusX on AttendanceStatus {
  String get value {
    switch (this) {
      case AttendanceStatus.present:
        return 'present';
      case AttendanceStatus.checkedOut:
        return 'checkedOut';
      case AttendanceStatus.absent:
        return 'absent';
      case AttendanceStatus.onLeave:
        return 'onLeave';
    }
  }

  String get label {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.checkedOut:
        return 'Checked Out';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.onLeave:
        return 'On Leave';
    }
  }

  static AttendanceStatus fromValue(dynamic value) {
    switch (value?.toString()) {
      case 'checkedOut':
        return AttendanceStatus.checkedOut;
      case 'absent':
        return AttendanceStatus.absent;
      case 'onLeave':
        return AttendanceStatus.onLeave;
      case 'present':
      default:
        return AttendanceStatus.present;
    }
  }
}

class AttendanceRecord {
  final String attendanceId;
  final String userId;
  final String date;
  final String officeId;

  final AttendanceStatus status;

  final DateTime? checkInAt;
  final double? checkInLatitude;
  final double? checkInLongitude;
  final double? checkInAccuracy;
  final double? checkInDistanceMeters;
  final String? checkInAddress;
  final String? checkInPhotoUrl;
  final String? checkInPhotoPath;

  final DateTime? checkOutAt;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final double? checkOutAccuracy;
  final double? checkOutDistanceMeters;
  final String? checkOutAddress;
  final String? checkOutPhotoUrl;
  final String? checkOutPhotoPath;

  final int totalMinutes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AttendanceRecord({
    required this.attendanceId,
    required this.userId,
    required this.date,
    required this.officeId,
    required this.status,
    this.checkInAt,
    this.checkInLatitude,
    this.checkInLongitude,
    this.checkInAccuracy,
    this.checkInDistanceMeters,
    this.checkInAddress,
    this.checkInPhotoUrl,
    this.checkInPhotoPath,
    this.checkOutAt,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.checkOutAccuracy,
    this.checkOutDistanceMeters,
    this.checkOutAddress,
    this.checkOutPhotoUrl,
    this.checkOutPhotoPath,
    this.totalMinutes = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory AttendanceRecord.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    return AttendanceRecord(
      attendanceId: id,
      userId: (data['userId'] ?? '').toString(),
      date: (data['date'] ?? '').toString(),
      officeId: (data['officeId'] ?? '').toString(),
      status: AttendanceStatusX.fromValue(data['status']),
      checkInAt: _toDateTime(data['checkInAt']),
      checkInLatitude: _toNullableDouble(data['checkInLatitude']),
      checkInLongitude: _toNullableDouble(data['checkInLongitude']),
      checkInAccuracy: _toNullableDouble(data['checkInAccuracy']),
      checkInDistanceMeters:
          _toNullableDouble(data['checkInDistanceMeters']),
      checkInAddress: _toNullableString(data['checkInAddress']),
      checkInPhotoUrl: _toNullableString(data['checkInPhotoUrl']),
      checkInPhotoPath: _toNullableString(data['checkInPhotoPath']),
      checkOutAt: _toDateTime(data['checkOutAt']),
      checkOutLatitude: _toNullableDouble(data['checkOutLatitude']),
      checkOutLongitude: _toNullableDouble(data['checkOutLongitude']),
      checkOutAccuracy: _toNullableDouble(data['checkOutAccuracy']),
      checkOutDistanceMeters:
          _toNullableDouble(data['checkOutDistanceMeters']),
      checkOutAddress: _toNullableString(data['checkOutAddress']),
      checkOutPhotoUrl: _toNullableString(data['checkOutPhotoUrl']),
      checkOutPhotoPath: _toNullableString(data['checkOutPhotoPath']),
      totalMinutes: _toInt(data['totalMinutes']),
      createdAt: _toDateTime(data['createdAt']),
      updatedAt: _toDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': date,
      'officeId': officeId,
      'status': status.value,
      'checkInAt': _timestamp(checkInAt),
      'checkInLatitude': checkInLatitude,
      'checkInLongitude': checkInLongitude,
      'checkInAccuracy': checkInAccuracy,
      'checkInDistanceMeters': checkInDistanceMeters,
      'checkInAddress': checkInAddress,
      'checkInPhotoUrl': checkInPhotoUrl,
      'checkInPhotoPath': checkInPhotoPath,
      'checkOutAt': _timestamp(checkOutAt),
      'checkOutLatitude': checkOutLatitude,
      'checkOutLongitude': checkOutLongitude,
      'checkOutAccuracy': checkOutAccuracy,
      'checkOutDistanceMeters': checkOutDistanceMeters,
      'checkOutAddress': checkOutAddress,
      'checkOutPhotoUrl': checkOutPhotoUrl,
      'checkOutPhotoPath': checkOutPhotoPath,
      'totalMinutes': totalMinutes,
      'createdAt': _timestamp(createdAt),
      'updatedAt': _timestamp(updatedAt),
    };
  }

  bool get isCheckedIn => checkInAt != null;
  bool get isCheckedOut => checkOutAt != null;

  String get totalHoursLabel {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  static Timestamp? _timestamp(DateTime? value) {
    return value == null ? null : Timestamp.fromDate(value);
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static double? _toNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String? _toNullableString(dynamic value) {
    if (value == null) return null;
    final result = value.toString().trim();
    return result.isEmpty ? null : result;
  }
}
