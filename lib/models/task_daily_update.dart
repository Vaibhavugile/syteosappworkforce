import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskDailyUpdateStatus {
  draft,
  submitted,
  underReview,
  approved,
  changesRequested,
}

class TaskDailyUpdate {
  final String dailyUpdateId;

  /// Task this daily work belongs to.
  final String taskId;

  /// Project this task belongs to.
  final String projectId;

  /// Employee who submitted the daily work.
  final String userId;

  /// Date for which this work was recorded.
  final DateTime date;

  /// What the employee worked on or completed.
  final String description;

  /// Task completion percentage after this update.
  final double completionPercentage;

  /// Hours spent working on this task for this update.
  final double? hoursSpent;

  /// IDs of attachments/proof files belonging
  /// to this daily work update.
  final List<String> attachmentIds;

  /// Review state of this daily work update.
  final TaskDailyUpdateStatus status;

  /// When this daily work entry was created.
  final DateTime createdAt;

  /// When this daily work entry was last updated.
  final DateTime updatedAt;

  const TaskDailyUpdate({
    required this.dailyUpdateId,
    required this.taskId,
    required this.projectId,
    required this.userId,
    required this.date,
    required this.description,
    this.completionPercentage = 0,
    this.hoursSpent,
    this.attachmentIds = const [],
    this.status = TaskDailyUpdateStatus.draft,
    required this.createdAt,
    required this.updatedAt,
  });

  // ============================================================
  // FROM FIRESTORE
  // ============================================================

  factory TaskDailyUpdate.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    return TaskDailyUpdate(
      dailyUpdateId: id,
      taskId: data['taskId']?.toString() ?? '',
      projectId: data['projectId']?.toString() ?? '',
      userId: data['userId']?.toString() ?? '',
      date: _dateFromValue(data['date']) ?? DateTime.now(),
      description: data['description']?.toString() ?? '',
      completionPercentage: _doubleFromValue(
        data['completionPercentage'],
      ).clamp(0, 100).toDouble(),
      hoursSpent: _nullableDouble(
        data['hoursSpent'],
      ),
      attachmentIds: _stringList(
        data['attachmentIds'],
      ),
      status: _statusFromString(
        data['status'],
      ),
      createdAt: _dateFromValue(
            data['createdAt'],
          ) ??
          DateTime.now(),
      updatedAt: _dateFromValue(
            data['updatedAt'],
          ) ??
          DateTime.now(),
    );
  }

  // ============================================================
  // TO FIRESTORE
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'projectId': projectId,
      'userId': userId,

      'date': Timestamp.fromDate(date),

      'description': description.trim(),

      'completionPercentage': completionPercentage
          .clamp(0, 100)
          .toDouble(),

      'hoursSpent': hoursSpent,

      'attachmentIds': List<String>.from(
        attachmentIds,
      ),

      'status': status.name,

      'createdAt': Timestamp.fromDate(
        createdAt,
      ),

      'updatedAt': Timestamp.fromDate(
        updatedAt,
      ),
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  TaskDailyUpdate copyWith({
    String? dailyUpdateId,
    String? taskId,
    String? projectId,
    String? userId,
    DateTime? date,
    String? description,
    double? completionPercentage,
    double? hoursSpent,
    List<String>? attachmentIds,
    TaskDailyUpdateStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskDailyUpdate(
      dailyUpdateId:
          dailyUpdateId ?? this.dailyUpdateId,

      taskId:
          taskId ?? this.taskId,

      projectId:
          projectId ?? this.projectId,

      userId:
          userId ?? this.userId,

      date:
          date ?? this.date,

      description:
          description ?? this.description,

      completionPercentage:
          completionPercentage ??
              this.completionPercentage,

      hoursSpent:
          hoursSpent ?? this.hoursSpent,

      attachmentIds:
          attachmentIds ??
              this.attachmentIds,

      status:
          status ?? this.status,

      createdAt:
          createdAt ?? this.createdAt,

      updatedAt:
          updatedAt ?? this.updatedAt,
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  static TaskDailyUpdateStatus _statusFromString(
    dynamic value,
  ) {
    switch (value?.toString()) {
      case 'submitted':
        return TaskDailyUpdateStatus.submitted;

      case 'underReview':
        return TaskDailyUpdateStatus.underReview;

      case 'approved':
        return TaskDailyUpdateStatus.approved;

      case 'changesRequested':
        return TaskDailyUpdateStatus.changesRequested;

      case 'draft':
      default:
        return TaskDailyUpdateStatus.draft;
    }
  }

  // ============================================================
  // DATE
  // ============================================================

  static DateTime? _dateFromValue(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  // ============================================================
  // DOUBLE
  // ============================================================

  static double _doubleFromValue(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static double? _nullableDouble(
    dynamic value,
  ) {
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

  // ============================================================
  // STRING LIST
  // ============================================================

  static List<String> _stringList(
    dynamic value,
  ) {
    if (value is! List) {
      return const [];
    }

    return value
        .map(
          (item) => item.toString().trim(),
        )
        .where(
          (item) => item.isNotEmpty,
        )
        .toList();
  }

  // ============================================================
  // BASIC HELPERS
  // ============================================================

  bool get hasAttachments =>
      attachmentIds.isNotEmpty;

  bool get hasHours =>
      hoursSpent != null &&
      hoursSpent! > 0;

  bool get isDraft =>
      status ==
      TaskDailyUpdateStatus.draft;

  bool get isSubmitted =>
      status ==
      TaskDailyUpdateStatus.submitted;

  bool get isUnderReview =>
      status ==
      TaskDailyUpdateStatus.underReview;

  bool get isApproved =>
      status ==
      TaskDailyUpdateStatus.approved;

  bool get changesRequested =>
      status ==
      TaskDailyUpdateStatus.changesRequested;

  bool get isReviewed =>
      isApproved ||
      changesRequested;

  String get statusLabel {
    switch (status) {
      case TaskDailyUpdateStatus.draft:
        return 'Draft';

      case TaskDailyUpdateStatus.submitted:
        return 'Submitted';

      case TaskDailyUpdateStatus.underReview:
        return 'Under Review';

      case TaskDailyUpdateStatus.approved:
        return 'Approved';

      case TaskDailyUpdateStatus.changesRequested:
        return 'Changes Requested';
    }
  }

  String get completionLabel =>
      '${completionPercentage.toStringAsFixed(0)}%';

  String get hoursLabel {
    if (hoursSpent == null) {
      return 'Not recorded';
    }

    return '${hoursSpent!.toStringAsFixed(1)} hrs';
  }
}