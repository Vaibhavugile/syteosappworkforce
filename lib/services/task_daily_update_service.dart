import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';



import '../models/task_daily_update.dart';



class TaskDailyUpdateService {

  TaskDailyUpdateService._();



  static final TaskDailyUpdateService instance =

      TaskDailyUpdateService._();



  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;



  CollectionReference<Map<String, dynamic>> get _dailyUpdatesCollection =>

      _firestore.collection('taskDailyUpdates');



  CollectionReference<Map<String, dynamic>> get _tasksCollection =>

      _firestore.collection('tasks');



  CollectionReference<Map<String, dynamic>> get _projectsCollection =>

      _firestore.collection('projects');



  String get currentUserUid {

    final user = _auth.currentUser;



    if (user == null) {

      throw StateError('No authenticated user found.');

    }



    return user.uid;

  }



  // ---------------------------------------------------------------------------

  // CREATE

  // ---------------------------------------------------------------------------



  Future<String> createDailyUpdate({

    required String taskId,

    required String projectId,

    required DateTime date,

    required String description,

    required double completionPercentage,

    double? hoursSpent,

  }) async {

    final userId = currentUserUid;



    final cleanTaskId = taskId.trim();

    final cleanProjectId = projectId.trim();

    final cleanDescription = description.trim();



    if (cleanTaskId.isEmpty) {

      throw ArgumentError('Task is required.');

    }



    if (cleanProjectId.isEmpty) {

      throw ArgumentError('Project is required.');

    }



    if (cleanDescription.isEmpty) {

      throw ArgumentError('Please describe the work completed today.');

    }



    final percentage =

        completionPercentage.clamp(0, 100).toDouble();



    if (hoursSpent != null && hoursSpent < 0) {

      throw ArgumentError('Hours spent cannot be negative.');

    }



    // -----------------------------------------------------------------------

    // Verify task

    // -----------------------------------------------------------------------



    final taskSnapshot =

        await _tasksCollection.doc(cleanTaskId).get();



    if (!taskSnapshot.exists) {

      throw StateError('The selected task no longer exists.');

    }



    final taskData = taskSnapshot.data()!;



    final taskProjectId =

        taskData['projectId']?.toString() ?? '';



    if (taskProjectId != cleanProjectId) {

      throw StateError(

        'The selected task does not belong to the selected project.',

      );

    }



    // -----------------------------------------------------------------------

    // Verify assignment

    // -----------------------------------------------------------------------



    final assignedTo =

        taskData['assignedTo']?.toString();



    if (assignedTo != null &&

        assignedTo.isNotEmpty &&

        assignedTo != userId) {

      throw StateError(

        'You can only add daily work for a task assigned to you.',

      );

    }



    // -----------------------------------------------------------------------

    // Verify project

    // -----------------------------------------------------------------------



    final projectSnapshot =

        await _projectsCollection.doc(cleanProjectId).get();



    if (!projectSnapshot.exists) {

      throw StateError('The selected project no longer exists.');

    }



    // -----------------------------------------------------------------------

    // Create daily update

    // -----------------------------------------------------------------------



    final document =

        _dailyUpdatesCollection.doc();



    final now = DateTime.now();



    final dailyUpdate = TaskDailyUpdate(

      dailyUpdateId: document.id,

      taskId: cleanTaskId,

      projectId: cleanProjectId,

      userId: userId,

      date: _dateOnly(date),

      description: cleanDescription,

      completionPercentage: percentage,

      hoursSpent: hoursSpent,

      attachmentIds: const [],

      status: TaskDailyUpdateStatus.submitted,

      createdAt: now,

      updatedAt: now,

    );



    await document.set(

      dailyUpdate.toMap(),

    );



    return document.id;

  }



  // ---------------------------------------------------------------------------

  // GET ONE

  // ---------------------------------------------------------------------------



  Future<TaskDailyUpdate?> getDailyUpdate(

    String dailyUpdateId,

  ) async {

    final id = dailyUpdateId.trim();



    if (id.isEmpty) {

      return null;

    }



    final snapshot =

        await _dailyUpdatesCollection.doc(id).get();



    if (!snapshot.exists) {

      return null;

    }



    final data = snapshot.data();



    if (data == null) {

      return null;

    }



    return TaskDailyUpdate.fromMap(

      snapshot.id,

      data,

    );

  }



  // ---------------------------------------------------------------------------

  // WATCH ONE

  // ---------------------------------------------------------------------------



  Stream<TaskDailyUpdate?> watchDailyUpdate(

    String dailyUpdateId,

  ) {

    final id = dailyUpdateId.trim();



    if (id.isEmpty) {

      return Stream.value(null);

    }



    return _dailyUpdatesCollection

        .doc(id)

        .snapshots()

        .map((snapshot) {

      if (!snapshot.exists) {

        return null;

      }



      final data = snapshot.data();



      if (data == null) {

        return null;

      }



      return TaskDailyUpdate.fromMap(

        snapshot.id,

        data,

      );

    });

  }



  // ---------------------------------------------------------------------------

  // WATCH MY DAILY WORK

  // ---------------------------------------------------------------------------



  Stream<List<TaskDailyUpdate>> watchMyDailyWork({

    DateTime? startDate,

    DateTime? endDate,

  }) {

    final userId = currentUserUid;



    Query<Map<String, dynamic>> query =

        _dailyUpdatesCollection

            .where(

              'userId',

              isEqualTo: userId,

            );



    if (startDate != null) {

      query = query.where(

        'date',

        isGreaterThanOrEqualTo:

            Timestamp.fromDate(

          _dateOnly(startDate),

        ),

      );

    }



    if (endDate != null) {

      final endExclusive = _dateOnly(endDate)

          .add(const Duration(days: 1));



      query = query.where(

        'date',

        isLessThan:

            Timestamp.fromDate(endExclusive),

      );

    }



    return query.snapshots().map(

      (snapshot) {

        final updates = snapshot.docs

            .map(

              (doc) => TaskDailyUpdate.fromMap(

                doc.id,

                doc.data(),

              ),

            )

            .toList();



        updates.sort(

          (a, b) => b.date.compareTo(a.date),

        );



        return updates;

      },

    );

  }



  // ---------------------------------------------------------------------------

  // WATCH MY DAILY WORK FOR ONE DATE

  // ---------------------------------------------------------------------------



  Stream<List<TaskDailyUpdate>> watchMyDailyWorkForDate(

    DateTime date,

  ) {

    final userId = currentUserUid;



    final start =

        _dateOnly(date);



    final end =

        start.add(const Duration(days: 1));



    return _dailyUpdatesCollection

        .where(

          'userId',

          isEqualTo: userId,

        )

        .where(

          'date',

          isGreaterThanOrEqualTo:

              Timestamp.fromDate(start),

        )

        .where(

          'date',

          isLessThan:

              Timestamp.fromDate(end),

        )

        .snapshots()

        .map(

      (snapshot) {

        final updates = snapshot.docs

            .map(

              (doc) => TaskDailyUpdate.fromMap(

                doc.id,

                doc.data(),

              ),

            )

            .toList();



        updates.sort(

          (a, b) => b.createdAt.compareTo(a.createdAt),

        );



        return updates;

      },

    );

  }




  // ---------------------------------------------------------------------------
  // MANAGEMENT ACCESS
  // ---------------------------------------------------------------------------

  Future<void> _requireManagementAccess() async {
    final userId = currentUserUid;

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .get();

    if (!snapshot.exists) {
      throw StateError('Your user profile was not found.');
    }

    final data = snapshot.data();
    final role = data?['role']?.toString().trim();

    const managementRoles = <String>{
      'ceo',
      'cto',
      'admin',
    };

    if (!managementRoles.contains(role)) {
      throw StateError(
        'You do not have permission to view team daily work.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // GET DAILY WORK FOR ONE EMPLOYEE AND DATE
  // ---------------------------------------------------------------------------

  Future<List<TaskDailyUpdate>> getDailyWorkForEmployeeForDate({
    required String employeeUid,
    required DateTime date,
  }) async {
    await _requireManagementAccess();

    final uid = employeeUid.trim();

    if (uid.isEmpty) {
      return [];
    }

    final start = _dateOnly(date);
    final end = start.add(const Duration(days: 1));

    final snapshot = await _dailyUpdatesCollection
        .where(
          'userId',
          isEqualTo: uid,
        )
        .where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
        )
        .where(
          'date',
          isLessThan: Timestamp.fromDate(end),
        )
        .get();

    final updates = snapshot.docs
        .map(
          (doc) => TaskDailyUpdate.fromMap(
            doc.id,
            doc.data(),
          ),
        )
        .toList();

    updates.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );

    return updates;
  }

  // ---------------------------------------------------------------------------
  // WATCH DAILY WORK FOR ONE EMPLOYEE AND DATE
  // ---------------------------------------------------------------------------

  Stream<List<TaskDailyUpdate>> watchDailyWorkForEmployeeForDate({
    required String employeeUid,
    required DateTime date,
  }) async* {
    await _requireManagementAccess();

    final uid = employeeUid.trim();

    if (uid.isEmpty) {
      yield const [];
      return;
    }

    final start = _dateOnly(date);
    final end = start.add(const Duration(days: 1));

    yield* _dailyUpdatesCollection
        .where(
          'userId',
          isEqualTo: uid,
        )
        .where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
        )
        .where(
          'date',
          isLessThan: Timestamp.fromDate(end),
        )
        .snapshots()
        .map(
      (snapshot) {
        final updates = snapshot.docs
            .map(
              (doc) => TaskDailyUpdate.fromMap(
                doc.id,
                doc.data(),
              ),
            )
            .toList();

        updates.sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
        );

        return updates;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // WATCH ALL EMPLOYEE DAILY WORK FOR ONE DATE
  // ---------------------------------------------------------------------------

  Stream<List<TaskDailyUpdate>> watchAllDailyWorkForDate(
    DateTime date,
  ) async* {
    await _requireManagementAccess();

    final start = _dateOnly(date);
    final end = start.add(const Duration(days: 1));

    yield* _dailyUpdatesCollection
        .where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
        )
        .where(
          'date',
          isLessThan: Timestamp.fromDate(end),
        )
        .snapshots()
        .map(
      (snapshot) {
        final updates = snapshot.docs
            .map(
              (doc) => TaskDailyUpdate.fromMap(
                doc.id,
                doc.data(),
              ),
            )
            .toList();

        updates.sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
        );

        return updates;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // WATCH ALL DAILY WORK
  // ---------------------------------------------------------------------------

  Stream<List<TaskDailyUpdate>> watchAllDailyWork() async* {
    await _requireManagementAccess();

    yield* _dailyUpdatesCollection
        .snapshots()
        .map(
      (snapshot) {
        final updates = snapshot.docs
            .map(
              (doc) => TaskDailyUpdate.fromMap(
                doc.id,
                doc.data(),
              ),
            )
            .toList();

        updates.sort(
          (a, b) => b.date.compareTo(a.date),
        );

        return updates;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // GET ALL DAILY WORK FOR ONE DATE
  // ---------------------------------------------------------------------------

  Future<List<TaskDailyUpdate>> getAllDailyWorkForDate(
    DateTime date,
  ) async {
    await _requireManagementAccess();

    final start = _dateOnly(date);
    final end = start.add(const Duration(days: 1));

    final snapshot = await _dailyUpdatesCollection
        .where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
        )
        .where(
          'date',
          isLessThan: Timestamp.fromDate(end),
        )
        .get();

    final updates = snapshot.docs
        .map(
          (doc) => TaskDailyUpdate.fromMap(
            doc.id,
            doc.data(),
          ),
        )
        .toList();

    updates.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );

    return updates;
  }

  // ---------------------------------------------------------------------------

  // WATCH DAILY WORK FOR A TASK

  // ---------------------------------------------------------------------------



  Stream<List<TaskDailyUpdate>> watchTaskDailyWork(

    String taskId,

  ) {

    final cleanTaskId = taskId.trim();



    if (cleanTaskId.isEmpty) {

      return Stream.value(const []);

    }



    return _dailyUpdatesCollection

        .where(

          'taskId',

          isEqualTo: cleanTaskId,

        )

        .snapshots()

        .map(

      (snapshot) {

        final updates = snapshot.docs

            .map(

              (doc) => TaskDailyUpdate.fromMap(

                doc.id,

                doc.data(),

              ),

            )

            .toList();



        updates.sort(

          (a, b) => b.date.compareTo(a.date),

        );



        return updates;

      },

    );

  }



  // ---------------------------------------------------------------------------

  // WATCH DAILY WORK FOR PROJECT

  // ---------------------------------------------------------------------------



  Stream<List<TaskDailyUpdate>> watchProjectDailyWork(

    String projectId,

  ) {

    final cleanProjectId = projectId.trim();



    if (cleanProjectId.isEmpty) {

      return Stream.value(const []);

    }



    return _dailyUpdatesCollection

        .where(

          'projectId',

          isEqualTo: cleanProjectId,

        )

        .snapshots()

        .map(

      (snapshot) {

        final updates = snapshot.docs

            .map(

              (doc) => TaskDailyUpdate.fromMap(

                doc.id,

                doc.data(),

              ),

            )

            .toList();



        updates.sort(

          (a, b) => b.date.compareTo(a.date),

        );



        return updates;

      },

    );

  }



  // ---------------------------------------------------------------------------

  // UPDATE DAILY WORK

  // ---------------------------------------------------------------------------



  Future<void> updateDailyUpdate({

    required String dailyUpdateId,

    String? description,

    double? completionPercentage,

    double? hoursSpent,

    DateTime? date,

    TaskDailyUpdateStatus? status,

    List<String>? attachmentIds,

  }) async {

    final userId = currentUserUid;



    final id = dailyUpdateId.trim();



    if (id.isEmpty) {

      throw ArgumentError('Daily update ID is required.');

    }



    final document =

        _dailyUpdatesCollection.doc(id);



    final snapshot =

        await document.get();



    if (!snapshot.exists) {

      throw StateError('Daily work entry was not found.');

    }



    final data = snapshot.data();



    if (data == null) {

      throw StateError('Daily work entry contains no data.');

    }



    final existing =

        TaskDailyUpdate.fromMap(

      snapshot.id,

      data,

    );



    // -----------------------------------------------------------------------

    // Ownership check

    // -----------------------------------------------------------------------



    if (existing.userId != userId) {

      throw StateError(

        'You can only update your own daily work.',

      );

    }



    final updates = <String, dynamic>{

      'updatedAt': Timestamp.fromDate(

        DateTime.now(),

      ),

    };



    // -----------------------------------------------------------------------

    // Description

    // -----------------------------------------------------------------------



    if (description != null) {

      final cleanDescription =

          description.trim();



      if (cleanDescription.isEmpty) {

        throw ArgumentError(

          'Work description cannot be empty.',

        );

      }



      updates['description'] =

          cleanDescription;

    }



    // -----------------------------------------------------------------------

    // Completion

    // -----------------------------------------------------------------------



    if (completionPercentage != null) {

      updates['completionPercentage'] =

          completionPercentage

              .clamp(0, 100)

              .toDouble();

    }



    // -----------------------------------------------------------------------

    // Hours

    // -----------------------------------------------------------------------



    if (hoursSpent != null) {

      if (hoursSpent < 0) {

        throw ArgumentError(

          'Hours spent cannot be negative.',

        );

      }



      updates['hoursSpent'] =

          hoursSpent;

    }



    // -----------------------------------------------------------------------

    // Date

    // -----------------------------------------------------------------------



    if (date != null) {

      updates['date'] = Timestamp.fromDate(

        _dateOnly(date),

      );

    }



    // -----------------------------------------------------------------------

    // Status

    // -----------------------------------------------------------------------



    if (status != null) {

      updates['status'] =

          status.name;

    }



    // -----------------------------------------------------------------------

    // Attachments

    // -----------------------------------------------------------------------



    if (attachmentIds != null) {

      updates['attachmentIds'] =

          attachmentIds

              .map((id) => id.trim())

              .where((id) => id.isNotEmpty)

              .toList();

    }



    await document.update(

      updates,

    );

  }



  // ---------------------------------------------------------------------------

  // ADD ATTACHMENT ID

  // ---------------------------------------------------------------------------



  Future<void> addAttachmentId({

    required String dailyUpdateId,

    required String attachmentId,

  }) async {

    final userId = currentUserUid;



    final cleanDailyUpdateId =

        dailyUpdateId.trim();



    final cleanAttachmentId =

        attachmentId.trim();



    if (cleanDailyUpdateId.isEmpty) {

      throw ArgumentError(

        'Daily update ID is required.',

      );

    }



    if (cleanAttachmentId.isEmpty) {

      throw ArgumentError(

        'Attachment ID is required.',

      );

    }



    final document =

        _dailyUpdatesCollection.doc(

      cleanDailyUpdateId,

    );



    final snapshot =

        await document.get();



    if (!snapshot.exists) {

      throw StateError(

        'Daily work entry was not found.',

      );

    }



    final data = snapshot.data();



    if (data == null) {

      throw StateError(

        'Daily work entry contains no data.',

      );

    }



    final existing =

        TaskDailyUpdate.fromMap(

      snapshot.id,

      data,

    );



    if (existing.userId != userId) {

      throw StateError(

        'You can only modify your own daily work.',

      );

    }



    await document.update({

      'attachmentIds':

          FieldValue.arrayUnion([

        cleanAttachmentId,

      ]),

      'updatedAt':

          Timestamp.fromDate(

        DateTime.now(),

      ),

    });

  }



  // ---------------------------------------------------------------------------

  // REMOVE ATTACHMENT ID

  // ---------------------------------------------------------------------------



  Future<void> removeAttachmentId({

    required String dailyUpdateId,

    required String attachmentId,

  }) async {

    final userId = currentUserUid;



    final cleanDailyUpdateId =

        dailyUpdateId.trim();



    final cleanAttachmentId =

        attachmentId.trim();



    if (cleanDailyUpdateId.isEmpty) {

      throw ArgumentError(

        'Daily update ID is required.',

      );

    }



    if (cleanAttachmentId.isEmpty) {

      throw ArgumentError(

        'Attachment ID is required.',

      );

    }



    final document =

        _dailyUpdatesCollection.doc(

      cleanDailyUpdateId,

    );



    final snapshot =

        await document.get();



    if (!snapshot.exists) {

      throw StateError(

        'Daily work entry was not found.',

      );

    }



    final data = snapshot.data();



    if (data == null) {

      throw StateError(

        'Daily work entry contains no data.',

      );

    }



    final existing =

        TaskDailyUpdate.fromMap(

      snapshot.id,

      data,

    );



    if (existing.userId != userId) {

      throw StateError(

        'You can only modify your own daily work.',

      );

    }



    await document.update({

      'attachmentIds':

          FieldValue.arrayRemove([

        cleanAttachmentId,

      ]),

      'updatedAt':

          Timestamp.fromDate(

        DateTime.now(),

      ),

    });

  }



  // ---------------------------------------------------------------------------

  // SUBMIT

  // ---------------------------------------------------------------------------



  Future<void> submitDailyUpdate(

    String dailyUpdateId,

  ) async {

    final userId = currentUserUid;



    final id = dailyUpdateId.trim();



    if (id.isEmpty) {

      throw ArgumentError(

        'Daily update ID is required.',

      );

    }



    final document =

        _dailyUpdatesCollection.doc(id);



    final snapshot =

        await document.get();



    if (!snapshot.exists) {

      throw StateError(

        'Daily work entry was not found.',

      );

    }



    final data = snapshot.data();



    if (data == null) {

      throw StateError(

        'Daily work entry contains no data.',

      );

    }



    final existing =

        TaskDailyUpdate.fromMap(

      snapshot.id,

      data,

    );



    if (existing.userId != userId) {

      throw StateError(

        'You can only submit your own daily work.',

      );

    }



    if (existing.description.trim().isEmpty) {

      throw StateError(

        'Please add a description before submitting.',

      );

    }



    await document.update({

      'status':

          TaskDailyUpdateStatus.submitted.name,

      'updatedAt':

          Timestamp.fromDate(

        DateTime.now(),

      ),

    });

  }



  // ---------------------------------------------------------------------------

  // DELETE

  // ---------------------------------------------------------------------------



  Future<void> deleteDailyUpdate(

    String dailyUpdateId,

  ) async {

    final userId = currentUserUid;



    final id = dailyUpdateId.trim();



    if (id.isEmpty) {

      throw ArgumentError(

        'Daily update ID is required.',

      );

    }



    final document =

        _dailyUpdatesCollection.doc(id);



    final snapshot =

        await document.get();



    if (!snapshot.exists) {

      return;

    }



    final data = snapshot.data();



    if (data == null) {

      return;

    }



    final existing =

        TaskDailyUpdate.fromMap(

      snapshot.id,

      data,

    );



    if (existing.userId != userId) {

      throw StateError(

        'You can only delete your own daily work.',

      );

    }



    await document.delete();

  }



  // ---------------------------------------------------------------------------

  // HELPER

  // ---------------------------------------------------------------------------



  DateTime _dateOnly(DateTime date) {

    return DateTime(

      date.year,

      date.month,

      date.day,

    );

  }

}
