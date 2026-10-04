import 'package:cloud_firestore/cloud_firestore.dart';

enum MilestoneStatus {
  upcoming,
  inProgress,
  completed,
  delayed,
  cancelled,
}

class Milestone {
  final String milestoneId;
  final String projectId;

  final String name;
  final String description;

  final MilestoneStatus status;

  final DateTime? startDate;
  final DateTime? dueDate;
  final DateTime? completedAt;

  final double progress;

  final int taskCount;
  final int completedTaskCount;

  final String createdBy;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Milestone({
    required this.milestoneId,
    required this.projectId,
    required this.name,
    this.description = '',
    this.status = MilestoneStatus.upcoming,
    this.startDate,
    this.dueDate,
    this.completedAt,
    this.progress = 0,
    this.taskCount = 0,
    this.completedTaskCount = 0,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Milestone.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    return Milestone(
      milestoneId: id,
      projectId: data['projectId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      status: _statusFromString(data['status']),
      startDate: _dateFromValue(data['startDate']),
      dueDate: _dateFromValue(data['dueDate']),
      completedAt:
          _dateFromValue(data['completedAt']),
      progress:
          _doubleFromValue(data['progress']),
      taskCount:
          _intFromValue(data['taskCount']),
      completedTaskCount:
          _intFromValue(
        data['completedTaskCount'],
      ),
      createdBy: data['createdBy'] ?? '',
      createdAt:
          _dateFromValue(data['createdAt']),
      updatedAt:
          _dateFromValue(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'name': name,
      'description': description,
      'status': status.name,
      'startDate': startDate == null
          ? null
          : Timestamp.fromDate(startDate!),
      'dueDate': dueDate == null
          ? null
          : Timestamp.fromDate(dueDate!),
      'completedAt': completedAt == null
          ? null
          : Timestamp.fromDate(completedAt!),
      'progress': progress,
      'taskCount': taskCount,
      'completedTaskCount':
          completedTaskCount,
      'createdBy': createdBy,
      'createdAt': createdAt == null
          ? null
          : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null
          ? null
          : Timestamp.fromDate(updatedAt!),
    };
  }

  Milestone copyWith({
    String? milestoneId,
    String? projectId,
    String? name,
    String? description,
    MilestoneStatus? status,
    DateTime? startDate,
    DateTime? dueDate,
    DateTime? completedAt,
    double? progress,
    int? taskCount,
    int? completedTaskCount,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Milestone(
      milestoneId:
          milestoneId ?? this.milestoneId,
      projectId:
          projectId ?? this.projectId,
      name: name ?? this.name,
      description:
          description ?? this.description,
      status: status ?? this.status,
      startDate:
          startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      completedAt:
          completedAt ?? this.completedAt,
      progress:
          progress ?? this.progress,
      taskCount:
          taskCount ?? this.taskCount,
      completedTaskCount:
          completedTaskCount ??
              this.completedTaskCount,
      createdBy:
          createdBy ?? this.createdBy,
      createdAt:
          createdAt ?? this.createdAt,
      updatedAt:
          updatedAt ?? this.updatedAt,
    );
  }

  static MilestoneStatus _statusFromString(
    String? value,
  ) {
    switch (value) {
      case 'inProgress':
        return MilestoneStatus.inProgress;
      case 'completed':
        return MilestoneStatus.completed;
      case 'delayed':
        return MilestoneStatus.delayed;
      case 'cancelled':
        return MilestoneStatus.cancelled;
      case 'upcoming':
      default:
        return MilestoneStatus.upcoming;
    }
  }

  static DateTime? _dateFromValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  static double _doubleFromValue(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static int _intFromValue(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}