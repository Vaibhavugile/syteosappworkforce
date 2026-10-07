import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceBreakType {
  lunch,
  tea,
  coffee,
  shortBreak,
  personal,
  prayer,
  meeting,
  medical,
  other,
}

extension AttendanceBreakTypeX on AttendanceBreakType {
  String get value {
    switch (this) {
      case AttendanceBreakType.lunch:
        return 'lunch';
      case AttendanceBreakType.tea:
        return 'tea';
      case AttendanceBreakType.coffee:
        return 'coffee';
      case AttendanceBreakType.shortBreak:
        return 'shortBreak';
      case AttendanceBreakType.personal:
        return 'personal';
      case AttendanceBreakType.prayer:
        return 'prayer';
      case AttendanceBreakType.meeting:
        return 'meeting';
      case AttendanceBreakType.medical:
        return 'medical';
      case AttendanceBreakType.other:
        return 'other';
    }
  }

  String get label {
    switch (this) {
      case AttendanceBreakType.lunch:
        return 'Lunch Break';
      case AttendanceBreakType.tea:
        return 'Tea Break';
      case AttendanceBreakType.coffee:
        return 'Coffee Break';
      case AttendanceBreakType.shortBreak:
        return 'Short Break';
      case AttendanceBreakType.personal:
        return 'Personal Break';
      case AttendanceBreakType.prayer:
        return 'Prayer Break';
      case AttendanceBreakType.meeting:
        return 'Meeting Break';
      case AttendanceBreakType.medical:
        return 'Medical Break';
      case AttendanceBreakType.other:
        return 'Other Break';
    }
  }

  static AttendanceBreakType fromValue(dynamic value) {
    switch (value?.toString()) {
      case 'lunch':
        return AttendanceBreakType.lunch;
      case 'tea':
        return AttendanceBreakType.tea;
      case 'coffee':
        return AttendanceBreakType.coffee;
      case 'shortBreak':
        return AttendanceBreakType.shortBreak;
      case 'personal':
        return AttendanceBreakType.personal;
      case 'prayer':
        return AttendanceBreakType.prayer;
      case 'meeting':
        return AttendanceBreakType.meeting;
      case 'medical':
        return AttendanceBreakType.medical;
      case 'other':
      default:
        return AttendanceBreakType.other;
    }
  }
}

class AttendanceBreak {
  final String breakId;
  final String attendanceId;
  final String userId;
  final String date;
  final AttendanceBreakType type;
  final String? customLabel;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int durationMinutes;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AttendanceBreak({
    required this.breakId,
    required this.attendanceId,
    required this.userId,
    required this.date,
    required this.type,
    this.customLabel,
    this.startedAt,
    this.endedAt,
    this.durationMinutes = 0,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive => startedAt != null && endedAt == null;

  String get displayLabel {
    final custom = customLabel?.trim() ?? '';
    return custom.isNotEmpty ? custom : type.label;
  }

  String get durationLabel {
    final minutes = durationMinutes;
    if (minutes <= 0 && isActive) return 'Running';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) return '${hours}h ${mins.toString().padLeft(2, '0')}m';
    return '${mins}m';
  }

  factory AttendanceBreak.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    return AttendanceBreak(
      breakId: id,
      attendanceId: (data['attendanceId'] ?? '').toString(),
      userId: (data['userId'] ?? '').toString(),
      date: (data['date'] ?? '').toString(),
      type: AttendanceBreakTypeX.fromValue(data['type']),
      customLabel: _string(data['customLabel']),
      startedAt: _date(data['startedAt']),
      endedAt: _date(data['endedAt']),
      durationMinutes: _int(data['durationMinutes']),
      note: _string(data['note']),
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'attendanceId': attendanceId,
      'userId': userId,
      'date': date,
      'type': type.value,
      'customLabel': customLabel,
      'startedAt': startedAt == null ? null : Timestamp.fromDate(startedAt!),
      'endedAt': endedAt == null ? null : Timestamp.fromDate(endedAt!),
      'durationMinutes': durationMinutes,
      'note': note,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  static String? _string(dynamic value) {
    if (value == null) return null;
    final result = value.toString().trim();
    return result.isEmpty ? null : result;
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static int _int(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
