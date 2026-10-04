import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus {
  backlog,
  todo,
  inProgress,
  inReview,
  changesRequested,
  completed,
  blocked,
  cancelled,
}

enum TaskPriority {
  low,
  medium,
  high,
  urgent,
}

class Task {
  final String taskId;
  final String projectId;

  final String title;
  final String description;

  final String createdBy;
  final String? assignedTo;

  final TaskStatus status;
  final TaskPriority priority;

  final DateTime? startDate;
  final DateTime? dueDate;
  final DateTime? completedAt;

  final double completionPercentage;

  final double? estimatedHours;
  final double? actualHours;

  final String? milestoneId;
  final String? parentTaskId;

  final List<String> watcherIds;
  final List<String> attachmentIds;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Task({
    required this.taskId,
    required this.projectId,
    required this.title,
    this.description = '',
    required this.createdBy,
    this.assignedTo,
    this.status = TaskStatus.backlog,
    this.priority = TaskPriority.medium,
    this.startDate,
    this.dueDate,
    this.completedAt,
    this.completionPercentage = 0,
    this.estimatedHours,
    this.actualHours,
    this.milestoneId,
    this.parentTaskId,
    this.watcherIds = const [],
    this.attachmentIds = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Task.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    return Task(
      taskId: id,
      projectId: data['projectId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      createdBy: data['createdBy'] ?? '',
      assignedTo: data['assignedTo'],
      status: _statusFromString(data['status']),
      priority: _priorityFromString(data['priority']),
      startDate: _dateFromValue(data['startDate']),
      dueDate: _dateFromValue(data['dueDate']),
      completedAt: _dateFromValue(data['completedAt']),
      completionPercentage:
          _doubleFromValue(
        data['completionPercentage'],
      ),
      estimatedHours:
          _nullableDouble(data['estimatedHours']),
      actualHours:
          _nullableDouble(data['actualHours']),
      milestoneId: data['milestoneId'],
      parentTaskId: data['parentTaskId'],
      watcherIds: List<String>.from(
        data['watcherIds'] ?? const [],
      ),
      attachmentIds: List<String>.from(
        data['attachmentIds'] ?? const [],
      ),
      createdAt: _dateFromValue(data['createdAt']),
      updatedAt: _dateFromValue(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'assignedTo': assignedTo,
      'status': status.name,
      'priority': priority.name,
      'startDate': startDate == null
          ? null
          : Timestamp.fromDate(startDate!),
      'dueDate': dueDate == null
          ? null
          : Timestamp.fromDate(dueDate!),
      'completedAt': completedAt == null
          ? null
          : Timestamp.fromDate(completedAt!),
      'completionPercentage':
          completionPercentage,
      'estimatedHours': estimatedHours,
      'actualHours': actualHours,
      'milestoneId': milestoneId,
      'parentTaskId': parentTaskId,
      'watcherIds': watcherIds,
      'attachmentIds': attachmentIds,
      'createdAt': createdAt == null
          ? null
          : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null
          ? null
          : Timestamp.fromDate(updatedAt!),
    };
  }

  Task copyWith({
    String? taskId,
    String? projectId,
    String? title,
    String? description,
    String? createdBy,
    String? assignedTo,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? startDate,
    DateTime? dueDate,
    DateTime? completedAt,
    double? completionPercentage,
    double? estimatedHours,
    double? actualHours,
    String? milestoneId,
    String? parentTaskId,
    List<String>? watcherIds,
    List<String>? attachmentIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      taskId: taskId ?? this.taskId,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description:
          description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      assignedTo:
          assignedTo ?? this.assignedTo,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      completedAt:
          completedAt ?? this.completedAt,
      completionPercentage:
          completionPercentage ??
              this.completionPercentage,
      estimatedHours:
          estimatedHours ?? this.estimatedHours,
      actualHours:
          actualHours ?? this.actualHours,
      milestoneId:
          milestoneId ?? this.milestoneId,
      parentTaskId:
          parentTaskId ?? this.parentTaskId,
      watcherIds:
          watcherIds ?? this.watcherIds,
      attachmentIds:
          attachmentIds ?? this.attachmentIds,
      createdAt:
          createdAt ?? this.createdAt,
      updatedAt:
          updatedAt ?? this.updatedAt,
    );
  }

  static TaskStatus _statusFromString(
    String? value,
  ) {
    switch (value) {
      case 'todo':
        return TaskStatus.todo;
      case 'inProgress':
        return TaskStatus.inProgress;
      case 'inReview':
        return TaskStatus.inReview;
      case 'changesRequested':
        return TaskStatus.changesRequested;
      case 'completed':
        return TaskStatus.completed;
      case 'blocked':
        return TaskStatus.blocked;
      case 'cancelled':
        return TaskStatus.cancelled;
      case 'backlog':
      default:
        return TaskStatus.backlog;
    }
  }

  static TaskPriority _priorityFromString(
    String? value,
  ) {
    switch (value) {
      case 'low':
        return TaskPriority.low;
      case 'high':
        return TaskPriority.high;
      case 'urgent':
        return TaskPriority.urgent;
      case 'medium':
      default:
        return TaskPriority.medium;
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

  static double? _nullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }
}