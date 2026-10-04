import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskAttachmentType {
  image,
  video,
  screenRecording,
  pdf,
  document,
  other,
}

class TaskAttachment {
  final String attachmentId;
  final String taskId;
  final String projectId;
  final String uploadedBy;

  /// Optional when the attachment was uploaded as daily-work proof.
  final String? dailyUpdateId;

  final String fileName;
  final String fileType;
  final String mimeType;
  final int fileSize;

  final String downloadUrl;
  final String storagePath;

  final DateTime createdAt;

  const TaskAttachment({
    required this.attachmentId,
    required this.taskId,
    required this.projectId,
    required this.uploadedBy,
    this.dailyUpdateId,
    required this.fileName,
    required this.fileType,
    required this.mimeType,
    required this.fileSize,
    required this.downloadUrl,
    required this.storagePath,
    required this.createdAt,
  });

  factory TaskAttachment.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    return TaskAttachment(
      attachmentId: id,
      taskId: data['taskId']?.toString() ?? '',
      projectId: data['projectId']?.toString() ?? '',
      uploadedBy: data['uploadedBy']?.toString() ?? '',
      dailyUpdateId: _nullableString(
        data['dailyUpdateId'],
      ),
      fileName: data['fileName']?.toString() ?? '',
      fileType: data['fileType']?.toString() ?? 'other',
      mimeType: data['mimeType']?.toString() ??
          'application/octet-stream',
      fileSize: _intFromValue(
        data['fileSize'],
      ),
      downloadUrl: data['downloadUrl']?.toString() ?? '',
      storagePath: data['storagePath']?.toString() ?? '',
      createdAt:
          _dateFromValue(data['createdAt']) ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'projectId': projectId,
      'uploadedBy': uploadedBy,
      'dailyUpdateId': dailyUpdateId,
      'fileName': fileName,
      'fileType': fileType,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'downloadUrl': downloadUrl,
      'storagePath': storagePath,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  TaskAttachment copyWith({
    String? attachmentId,
    String? taskId,
    String? projectId,
    String? uploadedBy,
    String? dailyUpdateId,
    bool clearDailyUpdateId = false,
    String? fileName,
    String? fileType,
    String? mimeType,
    int? fileSize,
    String? downloadUrl,
    String? storagePath,
    DateTime? createdAt,
  }) {
    return TaskAttachment(
      attachmentId:
          attachmentId ?? this.attachmentId,
      taskId: taskId ?? this.taskId,
      projectId:
          projectId ?? this.projectId,
      uploadedBy:
          uploadedBy ?? this.uploadedBy,
      dailyUpdateId: clearDailyUpdateId
          ? null
          : (dailyUpdateId ?? this.dailyUpdateId),
      fileName:
          fileName ?? this.fileName,
      fileType:
          fileType ?? this.fileType,
      mimeType:
          mimeType ?? this.mimeType,
      fileSize:
          fileSize ?? this.fileSize,
      downloadUrl:
          downloadUrl ?? this.downloadUrl,
      storagePath:
          storagePath ?? this.storagePath,
      createdAt:
          createdAt ?? this.createdAt,
    );
  }

  TaskAttachmentType get type {
    switch (fileType) {
      case 'image':
        return TaskAttachmentType.image;

      case 'video':
        return TaskAttachmentType.video;

      case 'screenRecording':
        return TaskAttachmentType.screenRecording;

      case 'pdf':
        return TaskAttachmentType.pdf;

      case 'document':
        return TaskAttachmentType.document;

      default:
        return TaskAttachmentType.other;
    }
  }

  bool get isImage =>
      type == TaskAttachmentType.image;

  bool get isVideo =>
      type == TaskAttachmentType.video ||
      type == TaskAttachmentType.screenRecording;

  bool get isPdf =>
      type == TaskAttachmentType.pdf;

  bool get isDocument =>
      type == TaskAttachmentType.document;

  bool get isDailyProof =>
      dailyUpdateId != null &&
      dailyUpdateId!.isNotEmpty;

  String get formattedFileSize {
    if (fileSize <= 0) {
      return '0 KB';
    }

    if (fileSize < 1024) {
      return '$fileSize B';
    }

    if (fileSize < 1024 * 1024) {
      final kb = fileSize / 1024;
      return '${kb.toStringAsFixed(kb >= 100 ? 0 : 1)} KB';
    }

    if (fileSize < 1024 * 1024 * 1024) {
      final mb =
          fileSize / (1024 * 1024);

      return '${mb.toStringAsFixed(mb >= 100 ? 0 : 1)} MB';
    }

    final gb =
        fileSize / (1024 * 1024 * 1024);

    return '${gb.toStringAsFixed(2)} GB';
  }

  String get displayType {
    switch (type) {
      case TaskAttachmentType.image:
        return 'Image';

      case TaskAttachmentType.video:
        return 'Video';

      case TaskAttachmentType.screenRecording:
        return 'Screen Recording';

      case TaskAttachmentType.pdf:
        return 'PDF';

      case TaskAttachmentType.document:
        return 'Document';

      case TaskAttachmentType.other:
        return 'File';
    }
  }

  static String? _nullableString(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final stringValue = value.toString().trim();

    return stringValue.isEmpty
        ? null
        : stringValue;
  }

  static int _intFromValue(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static DateTime? _dateFromValue(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

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
}