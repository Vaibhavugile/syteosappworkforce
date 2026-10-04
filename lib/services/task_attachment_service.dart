import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';

import '../models/task_attachment.dart';

class TaskAttachmentService {
  TaskAttachmentService._();

  static final TaskAttachmentService instance =
      TaskAttachmentService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseStorage _storage =
      FirebaseStorage.instance;

  final Uuid _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>>
      get _attachmentsCollection =>
          _firestore.collection('taskAttachments');

  CollectionReference<Map<String, dynamic>>
      get _tasksCollection =>
          _firestore.collection('tasks');

  CollectionReference<Map<String, dynamic>>
      get _dailyUpdatesCollection =>
          _firestore.collection('taskDailyUpdates');

  String get currentUserUid {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError(
        'No authenticated user found.',
      );
    }

    return user.uid;
  }

  // ===========================================================================
  // UPLOAD TASK ATTACHMENT
  // ===========================================================================

  Future<TaskAttachment> uploadTaskAttachment({
    required String taskId,
    required String projectId,
    required File file,
    String? fileName,
  }) async {
    final userId = currentUserUid;

    final cleanTaskId = taskId.trim();
    final cleanProjectId = projectId.trim();

    if (cleanTaskId.isEmpty) {
      throw ArgumentError(
        'Task ID is required.',
      );
    }

    if (cleanProjectId.isEmpty) {
      throw ArgumentError(
        'Project ID is required.',
      );
    }

    if (!await file.exists()) {
      throw StateError(
        'Selected file could not be found.',
      );
    }

    await _verifyTask(
      taskId: cleanTaskId,
      projectId: cleanProjectId,
      userId: userId,
    );

    final attachmentId = _uuid.v4();

    final originalName =
        fileName?.trim().isNotEmpty == true
            ? fileName!.trim()
            : _fileNameFromPath(file.path);

    final mimeType =
        lookupMimeType(
          file.path,
        ) ??
        'application/octet-stream';

    final attachmentType =
        _resolveAttachmentType(
      mimeType: mimeType,
      fileName: originalName,
    );

    final extension =
        _extensionFromFile(
      file.path,
      originalName,
    );

    final storagePath =
        'task_attachments/'
        '$cleanProjectId/'
        '$cleanTaskId/'
        '$attachmentId'
        '${extension.isEmpty ? '' : '.$extension'}';

    final storageReference =
        _storage.ref().child(storagePath);

    try {
      final uploadTask =
          storageReference.putFile(
        file,
        SettableMetadata(
          contentType: mimeType,
          customMetadata: {
            'taskId': cleanTaskId,
            'projectId': cleanProjectId,
            'uploadedBy': userId,
            'attachmentId': attachmentId,
          },
        ),
      );

      final snapshot =
          await uploadTask;

      final downloadUrl =
          await snapshot.ref.getDownloadURL();

      final fileSize =
          await file.length();

      final now = DateTime.now();

      final attachment = TaskAttachment(
        attachmentId: attachmentId,
        taskId: cleanTaskId,
        projectId: cleanProjectId,
        uploadedBy: userId,
        dailyUpdateId: null,
        fileName: originalName,
        fileType: attachmentType,
        mimeType: mimeType,
        fileSize: fileSize,
        downloadUrl: downloadUrl,
        storagePath: storagePath,
        createdAt: now,
      );

      await _firestore.runTransaction(
        (transaction) async {
          final attachmentReference =
              _attachmentsCollection.doc(
            attachmentId,
          );

          final taskReference =
              _tasksCollection.doc(
            cleanTaskId,
          );

          transaction.set(
            attachmentReference,
            attachment.toMap(),
          );

          transaction.update(
            taskReference,
            {
              'attachmentIds':
                  FieldValue.arrayUnion([
                attachmentId,
              ]),
              'updatedAt':
                  Timestamp.fromDate(now),
            },
          );
        },
      );

      return attachment;
    } catch (e) {
      // If Firestore creation fails after Storage upload,
      // attempt to clean the uploaded file.
      try {
        await storageReference.delete();
      } catch (_) {}

      rethrow;
    }
  }

  // ===========================================================================
  // UPLOAD DAILY WORK PROOF
  // ===========================================================================

  Future<TaskAttachment> uploadDailyWorkAttachment({
    required String taskId,
    required String projectId,
    required String dailyUpdateId,
    required File file,
    String? fileName,
    DateTime? date,
  }) async {
    final userId = currentUserUid;

    final cleanTaskId = taskId.trim();
    final cleanProjectId = projectId.trim();
    final cleanDailyUpdateId =
        dailyUpdateId.trim();

    if (cleanTaskId.isEmpty) {
      throw ArgumentError(
        'Task ID is required.',
      );
    }

    if (cleanProjectId.isEmpty) {
      throw ArgumentError(
        'Project ID is required.',
      );
    }

    if (cleanDailyUpdateId.isEmpty) {
      throw ArgumentError(
        'Daily update ID is required.',
      );
    }

    if (!await file.exists()) {
      throw StateError(
        'Selected file could not be found.',
      );
    }

    // Verify task.
    await _verifyTask(
      taskId: cleanTaskId,
      projectId: cleanProjectId,
      userId: userId,
    );

    // Verify daily update ownership and relationship.
    final dailyUpdateReference =
        _dailyUpdatesCollection.doc(
      cleanDailyUpdateId,
    );

    final dailyUpdateSnapshot =
        await dailyUpdateReference.get();

    if (!dailyUpdateSnapshot.exists) {
      throw StateError(
        'Daily work entry was not found.',
      );
    }

    final dailyUpdateData =
        dailyUpdateSnapshot.data();

    if (dailyUpdateData == null) {
      throw StateError(
        'Daily work entry contains no data.',
      );
    }

    final dailyUpdateTaskId =
        dailyUpdateData['taskId']
                ?.toString() ??
            '';

    final dailyUpdateProjectId =
        dailyUpdateData['projectId']
                ?.toString() ??
            '';

    final dailyUpdateUserId =
        dailyUpdateData['userId']
                ?.toString() ??
            '';

    if (dailyUpdateUserId != userId) {
      throw StateError(
        'You can only upload proof to your own daily work.',
      );
    }

    if (dailyUpdateTaskId != cleanTaskId) {
      throw StateError(
        'Daily work does not belong to the selected task.',
      );
    }

    if (dailyUpdateProjectId !=
        cleanProjectId) {
      throw StateError(
        'Daily work does not belong to the selected project.',
      );
    }

    final attachmentId = _uuid.v4();

    final originalName =
        fileName?.trim().isNotEmpty == true
            ? fileName!.trim()
            : _fileNameFromPath(file.path);

    final mimeType =
        lookupMimeType(
          file.path,
        ) ??
        'application/octet-stream';

    final attachmentType =
        _resolveAttachmentType(
      mimeType: mimeType,
      fileName: originalName,
    );

    final extension =
        _extensionFromFile(
      file.path,
      originalName,
    );

    final workDate =
        date ??
        _dateFromValue(
          dailyUpdateData['date'],
        ) ??
        DateTime.now();

    final dateFolder =
        _formatDateFolder(workDate);

    final storagePath =
        'task_daily_proofs/'
        '$cleanProjectId/'
        '$cleanTaskId/'
        '$userId/'
        '$dateFolder/'
        '$attachmentId'
        '${extension.isEmpty ? '' : '.$extension'}';

    final storageReference =
        _storage.ref().child(storagePath);

    try {
      final uploadTask =
          storageReference.putFile(
        file,
        SettableMetadata(
          contentType: mimeType,
          customMetadata: {
            'taskId': cleanTaskId,
            'projectId': cleanProjectId,
            'dailyUpdateId':
                cleanDailyUpdateId,
            'uploadedBy': userId,
            'attachmentId': attachmentId,
          },
        ),
      );

      final snapshot =
          await uploadTask;

      final downloadUrl =
          await snapshot.ref.getDownloadURL();

      final fileSize =
          await file.length();

      final now = DateTime.now();

      final attachment = TaskAttachment(
        attachmentId: attachmentId,
        taskId: cleanTaskId,
        projectId: cleanProjectId,
        uploadedBy: userId,
        dailyUpdateId:
            cleanDailyUpdateId,
        fileName: originalName,
        fileType: attachmentType,
        mimeType: mimeType,
        fileSize: fileSize,
        downloadUrl: downloadUrl,
        storagePath: storagePath,
        createdAt: now,
      );

      await _firestore.runTransaction(
        (transaction) async {
          final attachmentReference =
              _attachmentsCollection.doc(
            attachmentId,
          );

          transaction.set(
            attachmentReference,
            attachment.toMap(),
          );

          transaction.update(
            dailyUpdateReference,
            {
              'attachmentIds':
                  FieldValue.arrayUnion([
                attachmentId,
              ]),
              'updatedAt':
                  Timestamp.fromDate(now),
            },
          );
        },
      );

      return attachment;
    } catch (e) {
      try {
        await storageReference.delete();
      } catch (_) {}

      rethrow;
    }
  }

  // ===========================================================================
  // GET ATTACHMENT
  // ===========================================================================

  Future<TaskAttachment?> getAttachment(
    String attachmentId,
  ) async {
    final id = attachmentId.trim();

    if (id.isEmpty) {
      return null;
    }

    final snapshot =
        await _attachmentsCollection
            .doc(id)
            .get();

    if (!snapshot.exists) {
      return null;
    }

    final data =
        snapshot.data();

    if (data == null) {
      return null;
    }

    return TaskAttachment.fromMap(
      snapshot.id,
      data,
    );
  }

  // ===========================================================================
  // WATCH ATTACHMENTS FOR TASK
  // ===========================================================================

  Stream<List<TaskAttachment>>
      watchTaskAttachments(
    String taskId,
  ) {
    final cleanTaskId =
        taskId.trim();

    if (cleanTaskId.isEmpty) {
      return Stream.value(
        const [],
      );
    }

    return _attachmentsCollection
        .where(
          'taskId',
          isEqualTo: cleanTaskId,
        )
        .where(
          'dailyUpdateId',
          isNull: true,
        )
        .snapshots()
        .map(
      (snapshot) {
        final attachments =
            snapshot.docs
                .map(
                  (doc) =>
                      TaskAttachment.fromMap(
                    doc.id,
                    doc.data(),
                  ),
                )
                .toList();

        attachments.sort(
          (a, b) => b.createdAt.compareTo(
            a.createdAt,
          ),
        );

        return attachments;
      },
    );
  }

  // ===========================================================================
  // WATCH DAILY WORK ATTACHMENTS
  // ===========================================================================

  Stream<List<TaskAttachment>>
      watchDailyWorkAttachments(
    String dailyUpdateId,
  ) {
    final cleanDailyUpdateId =
        dailyUpdateId.trim();

    if (cleanDailyUpdateId.isEmpty) {
      return Stream.value(
        const [],
      );
    }

    return _attachmentsCollection
        .where(
          'dailyUpdateId',
          isEqualTo: cleanDailyUpdateId,
        )
        .snapshots()
        .map(
      (snapshot) {
        final attachments =
            snapshot.docs
                .map(
                  (doc) =>
                      TaskAttachment.fromMap(
                    doc.id,
                    doc.data(),
                  ),
                )
                .toList();

        attachments.sort(
          (a, b) => b.createdAt.compareTo(
            a.createdAt,
          ),
        );

        return attachments;
      },
    );
  }

  // ===========================================================================
  // WATCH ALL ATTACHMENTS FOR A TASK
  // ===========================================================================

  Stream<List<TaskAttachment>>
      watchAllTaskAttachments(
    String taskId,
  ) {
    final cleanTaskId =
        taskId.trim();

    if (cleanTaskId.isEmpty) {
      return Stream.value(
        const [],
      );
    }

    return _attachmentsCollection
        .where(
          'taskId',
          isEqualTo: cleanTaskId,
        )
        .snapshots()
        .map(
      (snapshot) {
        final attachments =
            snapshot.docs
                .map(
                  (doc) =>
                      TaskAttachment.fromMap(
                    doc.id,
                    doc.data(),
                  ),
                )
                .toList();

        attachments.sort(
          (a, b) => b.createdAt.compareTo(
            a.createdAt,
          ),
        );

        return attachments;
      },
    );
  }

  // ===========================================================================
  // DELETE ATTACHMENT
  // ===========================================================================

  Future<void> deleteAttachment(
    String attachmentId,
  ) async {
    final userId = currentUserUid;

    final id = attachmentId.trim();

    if (id.isEmpty) {
      throw ArgumentError(
        'Attachment ID is required.',
      );
    }

    final attachmentReference =
        _attachmentsCollection.doc(id);

    final snapshot =
        await attachmentReference.get();

    if (!snapshot.exists) {
      return;
    }

    final data =
        snapshot.data();

    if (data == null) {
      return;
    }

    final attachment =
        TaskAttachment.fromMap(
      snapshot.id,
      data,
    );

    if (attachment.uploadedBy !=
        userId) {
      throw StateError(
        'You can only delete attachments uploaded by you.',
      );
    }

    // -----------------------------------------------------------------------
    // Delete Storage file
    // -----------------------------------------------------------------------

    if (attachment.storagePath
        .trim()
        .isNotEmpty) {
      try {
        await _storage
            .ref()
            .child(
              attachment.storagePath,
            )
            .delete();
      } catch (e) {
        // If the file is already gone from Storage,
        // we still remove the Firestore record.
        if (!_isStorageNotFoundError(e)) {
          rethrow;
        }
      }
    }

    // -----------------------------------------------------------------------
    // Remove attachment ID from Task / Daily Work
    // -----------------------------------------------------------------------

    final batch =
        _firestore.batch();

    final taskReference =
        _tasksCollection.doc(
      attachment.taskId,
    );

    batch.update(
      taskReference,
      {
        'attachmentIds':
            FieldValue.arrayRemove([
          attachment.attachmentId,
        ]),
        'updatedAt':
            Timestamp.fromDate(
          DateTime.now(),
        ),
      },
    );

    if (attachment.dailyUpdateId !=
            null &&
        attachment.dailyUpdateId!
            .isNotEmpty) {
      final dailyUpdateReference =
          _dailyUpdatesCollection.doc(
        attachment.dailyUpdateId!,
      );

      batch.update(
        dailyUpdateReference,
        {
          'attachmentIds':
              FieldValue.arrayRemove([
            attachment.attachmentId,
          ]),
          'updatedAt':
              Timestamp.fromDate(
            DateTime.now(),
          ),
        },
      );
    }

    batch.delete(
      attachmentReference,
    );

    await batch.commit();
  }

  // ===========================================================================
  // VERIFY TASK
  // ===========================================================================

  Future<void> _verifyTask({
    required String taskId,
    required String projectId,
    required String userId,
  }) async {
    final taskSnapshot =
        await _tasksCollection
            .doc(taskId)
            .get();

    if (!taskSnapshot.exists) {
      throw StateError(
        'The selected task no longer exists.',
      );
    }

    final taskData =
        taskSnapshot.data();

    if (taskData == null) {
      throw StateError(
        'The selected task contains no data.',
      );
    }

    final taskProjectId =
        taskData['projectId']
                ?.toString() ??
            '';

    if (taskProjectId !=
        projectId) {
      throw StateError(
        'The task does not belong to the selected project.',
      );
    }

    final assignedTo =
        taskData['assignedTo']
            ?.toString();

    if (assignedTo != null &&
        assignedTo.isNotEmpty &&
        assignedTo != userId) {
      throw StateError(
        'You can only upload files to a task assigned to you.',
      );
    }
  }

  // ===========================================================================
  // FILE TYPE
  // ===========================================================================

  String _resolveAttachmentType({
    required String mimeType,
    required String fileName,
  }) {
    final mime =
        mimeType.toLowerCase();

    final name =
        fileName.toLowerCase();

    if (mime.startsWith('image/')) {
      return 'image';
    }

    if (mime.startsWith('video/')) {
      if (_isLikelyScreenRecording(name)) {
        return 'screenRecording';
      }

      return 'video';
    }

    if (mime == 'application/pdf' ||
        name.endsWith('.pdf')) {
      return 'pdf';
    }

    if (_isDocumentMimeType(mime) ||
        _isDocumentExtension(name)) {
      return 'document';
    }

    return 'other';
  }

  bool _isLikelyScreenRecording(
    String fileName,
  ) {
    const keywords = [
      'screenrecord',
      'screen-record',
      'screen_record',
      'screen recording',
      'screencapture',
      'screen-capture',
      'screen_capture',
    ];

    return keywords.any(
      fileName.contains,
    );
  }

  bool _isDocumentMimeType(
    String mimeType,
  ) {
    const documentTypes = [
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/vnd.ms-powerpoint',
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'text/plain',
      'text/csv',
    ];

    return documentTypes.contains(
      mimeType,
    );
  }

  bool _isDocumentExtension(
    String fileName,
  ) {
    const extensions = [
      '.doc',
      '.docx',
      '.xls',
      '.xlsx',
      '.ppt',
      '.pptx',
      '.txt',
      '.csv',
    ];

    return extensions.any(
      fileName.endsWith,
    );
  }

  // ===========================================================================
  // FILE NAME
  // ===========================================================================

  String _fileNameFromPath(
    String path,
  ) {
    final normalized =
        path.replaceAll('\\', '/');

    final parts =
        normalized.split('/');

    if (parts.isEmpty) {
      return 'attachment';
    }

    final name =
        parts.last.trim();

    return name.isEmpty
        ? 'attachment'
        : name;
  }

  // ===========================================================================
  // EXTENSION
  // ===========================================================================

  String _extensionFromFile(
    String path,
    String fileName,
  ) {
    String source =
        fileName.trim();

    if (source.isEmpty) {
      source = path.trim();
    }

    final lastDot =
        source.lastIndexOf('.');

    if (lastDot == -1 ||
        lastDot == source.length - 1) {
      return '';
    }

    return source
        .substring(lastDot + 1)
        .toLowerCase();
  }

  // ===========================================================================
  // DATE FOLDER
  // ===========================================================================

  String _formatDateFolder(
    DateTime date,
  ) {
    final month =
        date.month.toString().padLeft(
              2,
              '0',
            );

    final day =
        date.day.toString().padLeft(
              2,
              '0',
            );

    return '${date.year}-$month-$day';
  }

  // ===========================================================================
  // FIRESTORE DATE
  // ===========================================================================

  DateTime? _dateFromValue(
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
      return DateTime.tryParse(
        value,
      );
    }

    return null;
  }

  // ===========================================================================
  // STORAGE ERROR
  // ===========================================================================

  bool _isStorageNotFoundError(
    Object error,
  ) {
    if (error is FirebaseException) {
      return error.code ==
          'object-not-found';
    }

    return false;
  }
}