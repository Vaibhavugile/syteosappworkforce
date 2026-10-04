import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskActivityType {
  created,
  assigned,
  reassigned,
  statusChanged,
  priorityChanged,
  dueDateChanged,
  descriptionUpdated,
  commentAdded,
  attachmentAdded,
  submittedForReview,
  changesRequested,
  approved,
  completed,
  blocked,
  unblocked,
  reopened,
}

class TaskActivity {
  final String activityId;

  final String taskId;
  final String projectId;

  final String userId;

  final TaskActivityType type;

  final String message;

  final String? previousValue;
  final String? newValue;

  final DateTime? createdAt;

  const TaskActivity({
    required this.activityId,
    required this.taskId,
    required this.projectId,
    required this.userId,
    required this.type,
    required this.message,
    this.previousValue,
    this.newValue,
    this.createdAt,
  });

  factory TaskActivity.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    return TaskActivity(
      activityId: id,
      taskId: data['taskId'] ?? '',
      projectId: data['projectId'] ?? '',
      userId: data['userId'] ?? '',
      type: _typeFromString(data['type']),
      message: data['message'] ?? '',
      previousValue:
          data['previousValue'],
      newValue:
          data['newValue'],
      createdAt:
          _dateFromValue(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'projectId': projectId,
      'userId': userId,
      'type': type.name,
      'message': message,
      'previousValue': previousValue,
      'newValue': newValue,
      'createdAt': createdAt == null
          ? null
          : Timestamp.fromDate(createdAt!),
    };
  }

  static TaskActivityType _typeFromString(
    String? value,
  ) {
    switch (value) {
      case 'assigned':
        return TaskActivityType.assigned;
      case 'reassigned':
        return TaskActivityType.reassigned;
      case 'statusChanged':
        return TaskActivityType.statusChanged;
      case 'priorityChanged':
        return TaskActivityType.priorityChanged;
      case 'dueDateChanged':
        return TaskActivityType.dueDateChanged;
      case 'descriptionUpdated':
        return TaskActivityType.descriptionUpdated;
      case 'commentAdded':
        return TaskActivityType.commentAdded;
      case 'attachmentAdded':
        return TaskActivityType.attachmentAdded;
      case 'submittedForReview':
        return TaskActivityType.submittedForReview;
      case 'changesRequested':
        return TaskActivityType.changesRequested;
      case 'approved':
        return TaskActivityType.approved;
      case 'completed':
        return TaskActivityType.completed;
      case 'blocked':
        return TaskActivityType.blocked;
      case 'unblocked':
        return TaskActivityType.unblocked;
      case 'reopened':
        return TaskActivityType.reopened;
      case 'created':
      default:
        return TaskActivityType.created;
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
}