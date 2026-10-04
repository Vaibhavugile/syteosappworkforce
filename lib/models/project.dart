import 'package:cloud_firestore/cloud_firestore.dart';

enum ProjectStatus {
  draft,
  planning,
  active,
  onHold,
  completed,
  archived,
}

enum ProjectPriority {
  low,
  medium,
  high,
  critical,
}

class Project {
  final String projectId;
  final String name;
  final String description;
  final String? clientName;
  final String? clientId;

  final String createdBy;
  final String? projectManagerId;

  final List<String> memberIds;

  final ProjectStatus status;
  final ProjectPriority priority;

  final DateTime? startDate;
  final DateTime? targetDate;
  final DateTime? completedAt;

  final String? color;
  final String? icon;

  final double progress;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Project({
    required this.projectId,
    required this.name,
    this.description = '',
    this.clientName,
    this.clientId,
    required this.createdBy,
    this.projectManagerId,
    this.memberIds = const [],
    this.status = ProjectStatus.draft,
    this.priority = ProjectPriority.medium,
    this.startDate,
    this.targetDate,
    this.completedAt,
    this.color,
    this.icon,
    this.progress = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Project.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    return Project(
      projectId: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      clientName: data['clientName'],
      clientId: data['clientId'],
      createdBy: data['createdBy'] ?? '',
      projectManagerId: data['projectManagerId'],
      memberIds: List<String>.from(
        data['memberIds'] ?? const [],
      ),
      status: _statusFromString(data['status']),
      priority: _priorityFromString(data['priority']),
      startDate: _dateFromValue(data['startDate']),
      targetDate: _dateFromValue(data['targetDate']),
      completedAt: _dateFromValue(data['completedAt']),
      color: data['color'],
      icon: data['icon'],
      progress: _doubleFromValue(data['progress']),
      createdAt: _dateFromValue(data['createdAt']),
      updatedAt: _dateFromValue(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'clientName': clientName,
      'clientId': clientId,
      'createdBy': createdBy,
      'projectManagerId': projectManagerId,
      'memberIds': memberIds,
      'status': status.name,
      'priority': priority.name,
      'startDate': startDate == null
          ? null
          : Timestamp.fromDate(startDate!),
      'targetDate': targetDate == null
          ? null
          : Timestamp.fromDate(targetDate!),
      'completedAt': completedAt == null
          ? null
          : Timestamp.fromDate(completedAt!),
      'color': color,
      'icon': icon,
      'progress': progress,
      'createdAt': createdAt == null
          ? null
          : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null
          ? null
          : Timestamp.fromDate(updatedAt!),
    };
  }

  Project copyWith({
    String? projectId,
    String? name,
    String? description,
    String? clientName,
    String? clientId,
    String? createdBy,
    String? projectManagerId,
    List<String>? memberIds,
    ProjectStatus? status,
    ProjectPriority? priority,
    DateTime? startDate,
    DateTime? targetDate,
    DateTime? completedAt,
    String? color,
    String? icon,
    double? progress,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      description: description ?? this.description,
      clientName: clientName ?? this.clientName,
      clientId: clientId ?? this.clientId,
      createdBy: createdBy ?? this.createdBy,
      projectManagerId:
          projectManagerId ?? this.projectManagerId,
      memberIds: memberIds ?? this.memberIds,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      completedAt: completedAt ?? this.completedAt,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static ProjectStatus _statusFromString(
    String? value,
  ) {
    switch (value) {
      case 'planning':
        return ProjectStatus.planning;
      case 'active':
        return ProjectStatus.active;
      case 'onHold':
        return ProjectStatus.onHold;
      case 'completed':
        return ProjectStatus.completed;
      case 'archived':
        return ProjectStatus.archived;
      case 'draft':
      default:
        return ProjectStatus.draft;
    }
  }

  static ProjectPriority _priorityFromString(
    String? value,
  ) {
    switch (value) {
      case 'low':
        return ProjectPriority.low;
      case 'high':
        return ProjectPriority.high;
      case 'critical':
        return ProjectPriority.critical;
      case 'medium':
      default:
        return ProjectPriority.medium;
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
}