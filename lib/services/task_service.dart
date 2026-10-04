import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/task.dart';
import '../models/task_activity.dart';

class TaskService {
  TaskService._();

  static final TaskService instance = TaskService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _tasksCollection =>
      _firestore.collection('tasks');

  CollectionReference<Map<String, dynamic>> get _activitiesCollection =>
      _firestore.collection('taskActivities');

  CollectionReference<Map<String, dynamic>> get _projectsCollection =>
      _firestore.collection('projects');

  String get currentUserUid {
    final uid = _auth.currentUser?.uid;

    if (uid == null || uid.isEmpty) {
      throw Exception('User is not authenticated.');
    }

    return uid;
  }

  // ============================================================
  // CREATE TASK
  // ============================================================

  Future<String> createTask({
    required String projectId,
    required String title,
    String? description,
    String? assignedTo,
    TaskStatus status = TaskStatus.todo,
    TaskPriority priority = TaskPriority.medium,
    DateTime? startDate,
    DateTime? dueDate,
    double completionPercentage = 0,
    double? estimatedHours,
    String? milestoneId,
    String? parentTaskId,
    List<String> watcherIds = const [],
  }) async {
    final uid = currentUserUid;

    if (projectId.trim().isEmpty) {
      throw Exception('Project ID is required.');
    }

    if (title.trim().isEmpty) {
      throw Exception('Task title is required.');
    }

    final projectSnapshot =
        await _projectsCollection.doc(projectId).get();

    if (!projectSnapshot.exists) {
      throw Exception('Project not found.');
    }

    final taskRef = _tasksCollection.doc();

    final now = DateTime.now();

    final task = Task(
      taskId: taskRef.id,
      projectId: projectId,
      title: title.trim(),
      description: _nullableString(description) ?? '',
      createdBy: uid,
      assignedTo: _nullableString(assignedTo),
      status: status,
      priority: priority,
      startDate: startDate,
      dueDate: dueDate,
      completedAt: null,
      completionPercentage:
          completionPercentage.clamp(0, 100).toDouble(),
      estimatedHours: estimatedHours,
      actualHours: null,
      milestoneId: _nullableString(milestoneId),
      parentTaskId: _nullableString(parentTaskId),
      watcherIds: watcherIds
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList(),
      attachmentIds: const [],
      createdAt: now,
      updatedAt: now,
    );

    final batch = _firestore.batch();

    batch.set(
      taskRef,
      task.toMap(),
    );

    final activityRef = _activitiesCollection.doc();

    final activity = TaskActivity(
      activityId: activityRef.id,
      taskId: task.taskId,
      projectId: task.projectId,
      userId: uid,
      type: TaskActivityType.created,
      message: 'Task created',
      previousValue: null,
      newValue: task.title,
      createdAt: now,
    );

    batch.set(
      activityRef,
      activity.toMap(),
    );

    await batch.commit();

    return task.taskId;
  }

  // ============================================================
  // GET TASK
  // ============================================================

  Future<Task?> getTask(String taskId) async {
    if (taskId.trim().isEmpty) {
      return null;
    }

    final snapshot = await _tasksCollection.doc(taskId).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return Task.fromMap(snapshot.id, snapshot.data()!);
  }

  Future<Task> getTaskOrThrow(String taskId) async {
    final task = await getTask(taskId);

    if (task == null) {
      throw Exception('Task not found.');
    }

    return task;
  }

  // ============================================================
  // WATCH TASK
  // ============================================================

  Stream<Task?> watchTask(String taskId) {
    if (taskId.trim().isEmpty) {
      return Stream.value(null);
    }

    return _tasksCollection.doc(taskId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }

      return Task.fromMap(snapshot.id, snapshot.data()!);
    });
  }

  // ============================================================
  // ALL TASKS
  // ============================================================

  Future<List<Task>> getAllTasks() async {
    final snapshot = await _tasksCollection.get();

    final tasks = snapshot.docs
        .map((doc) => Task.fromMap(doc.id, doc.data()))
        .toList();

    tasks.sort(_sortByUpdatedAtDescending);

    return tasks;
  }

  Stream<List<Task>> watchAllTasks() {
    return _tasksCollection.snapshots().map((snapshot) {
      final tasks = snapshot.docs
          .map((doc) => Task.fromMap(doc.id, doc.data()))
          .toList();

      tasks.sort(_sortByUpdatedAtDescending);

      return tasks;
    });
  }

  // ============================================================
  // PROJECT TASKS
  // ============================================================

  Future<List<Task>> getProjectTasks(String projectId) async {
    final snapshot = await _tasksCollection
        .where('projectId', isEqualTo: projectId)
        .get();

    final tasks = snapshot.docs
        .map((doc) => Task.fromMap(doc.id, doc.data()))
        .toList();

    tasks.sort(_sortByUpdatedAtDescending);

    return tasks;
  }

  Stream<List<Task>> watchProjectTasks(String projectId) {
    return _tasksCollection
        .where('projectId', isEqualTo: projectId)
        .snapshots()
        .map((snapshot) {
      final tasks = snapshot.docs
          .map((doc) => Task.fromMap(doc.id, doc.data()))
          .toList();

      tasks.sort(_sortByUpdatedAtDescending);

      return tasks;
    });
  }

  // ============================================================
  // MY TASKS
  // ============================================================

  Future<List<Task>> getMyTasks() async {
    final uid = currentUserUid;

    final snapshot = await _tasksCollection
        .where('assignedTo', isEqualTo: uid)
        .get();

    final tasks = snapshot.docs
        .map((doc) => Task.fromMap(doc.id, doc.data()))
        .toList();

    tasks.sort(_sortByDueDateAscending);

    return tasks;
  }

  Stream<List<Task>> watchMyTasks() {
    final uid = currentUserUid;

    return _tasksCollection
        .where('assignedTo', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final tasks = snapshot.docs
          .map((doc) => Task.fromMap(doc.id, doc.data()))
          .toList();

      tasks.sort(_sortByDueDateAscending);

      return tasks;
    });
  }

  // ============================================================
  // TASKS CREATED BY ME
  // ============================================================

  Future<List<Task>> getTasksCreatedByMe() async {
    final uid = currentUserUid;

    final snapshot = await _tasksCollection
        .where('createdBy', isEqualTo: uid)
        .get();

    final tasks = snapshot.docs
        .map((doc) => Task.fromMap(doc.id, doc.data()))
        .toList();

    tasks.sort(_sortByUpdatedAtDescending);

    return tasks;
  }

  Stream<List<Task>> watchTasksCreatedByMe() {
    final uid = currentUserUid;

    return _tasksCollection
        .where('createdBy', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final tasks = snapshot.docs
          .map((doc) => Task.fromMap(doc.id, doc.data()))
          .toList();

      tasks.sort(_sortByUpdatedAtDescending);

      return tasks;
    });
  }

  // ============================================================
  // ASSIGNED TASKS
  // ============================================================

  Future<List<Task>> getTasksAssignedTo(
    String employeeUid,
  ) async {
    final uid = employeeUid.trim();

    if (uid.isEmpty) {
      return [];
    }

    final snapshot = await _tasksCollection
        .where('assignedTo', isEqualTo: uid)
        .get();

    final tasks = snapshot.docs
        .map((doc) => Task.fromMap(doc.id, doc.data()))
        .toList();

    tasks.sort(_sortByDueDateAscending);

    return tasks;
  }

  Stream<List<Task>> watchTasksAssignedTo(
    String employeeUid,
  ) {
    final uid = employeeUid.trim();

    if (uid.isEmpty) {
      return Stream.value(const []);
    }

    return _tasksCollection
        .where('assignedTo', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final tasks = snapshot.docs
          .map((doc) => Task.fromMap(doc.id, doc.data()))
          .toList();

      tasks.sort(_sortByDueDateAscending);

      return tasks;
    });
  }

  // ============================================================
  // TASKS BY STATUS
  // ============================================================

  Future<List<Task>> getTasksByStatus(
    TaskStatus status,
  ) async {
    final snapshot = await _tasksCollection
        .where('status', isEqualTo: status.name)
        .get();

    final tasks = snapshot.docs
        .map((doc) => Task.fromMap(doc.id, doc.data()))
        .toList();

    tasks.sort(_sortByDueDateAscending);

    return tasks;
  }

  Stream<List<Task>> watchTasksByStatus(
    TaskStatus status,
  ) {
    return _tasksCollection
        .where('status', isEqualTo: status.name)
        .snapshots()
        .map((snapshot) {
      final tasks = snapshot.docs
          .map((doc) => Task.fromMap(doc.id, doc.data()))
          .toList();

      tasks.sort(_sortByDueDateAscending);

      return tasks;
    });
  }

  // ============================================================
  // TASKS BY PRIORITY
  // ============================================================

  Future<List<Task>> getTasksByPriority(
    TaskPriority priority,
  ) async {
    final snapshot = await _tasksCollection
        .where('priority', isEqualTo: priority.name)
        .get();

    final tasks = snapshot.docs
        .map((doc) => Task.fromMap(doc.id, doc.data()))
        .toList();

    tasks.sort(_sortByDueDateAscending);

    return tasks;
  }

  // ============================================================
  // UPDATE TASK
  // ============================================================

  Future<void> updateTask({
    required String taskId,
    String? title,
    String? description,
    TaskPriority? priority,
    DateTime? startDate,
    DateTime? dueDate,
    double? completionPercentage,
    double? estimatedHours,
    double? actualHours,
    String? milestoneId,
    String? parentTaskId,
    List<String>? watcherIds,
  }) async {
    if (taskId.trim().isEmpty) {
      throw Exception('Task ID is required.');
    }

    final task = await getTaskOrThrow(taskId);
    final data = <String, dynamic>{
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };

    final activities = <TaskActivity>[];
    final uid = currentUserUid;

    if (title != null) {
      final newTitle = title.trim();

      if (newTitle.isEmpty) {
        throw Exception('Task title cannot be empty.');
      }

      if (newTitle != task.title) {
        data['title'] = newTitle;

        activities.add(
          _buildActivity(
            task: task,
            userId: uid,
            type: TaskActivityType.descriptionUpdated,
            message: 'Task title updated',
            previousValue: task.title,
            newValue: newTitle,
          ),
        );
      }
    }

    if (description != null) {
      data['description'] =
          description.trim().isEmpty ? null : description.trim();

      activities.add(
        _buildActivity(
          task: task,
          userId: uid,
          type: TaskActivityType.descriptionUpdated,
          message: 'Task description updated',
        ),
      );
    }

    if (priority != null && priority != task.priority) {
      data['priority'] = priority.name;

      activities.add(
        _buildActivity(
          task: task,
          userId: uid,
          type: TaskActivityType.priorityChanged,
          message: 'Task priority changed',
          previousValue: task.priority.name,
          newValue: priority.name,
        ),
      );
    }

    if (startDate != null) {
      data['startDate'] = Timestamp.fromDate(startDate);
    }

    if (dueDate != null) {
      data['dueDate'] = Timestamp.fromDate(dueDate);

      activities.add(
        _buildActivity(
          task: task,
          userId: uid,
          type: TaskActivityType.dueDateChanged,
          message: 'Task due date changed',
          newValue: dueDate.toIso8601String(),
        ),
      );
    }

    if (completionPercentage != null) {
      final percentage =
          completionPercentage.clamp(0, 100).toDouble();

      data['completionPercentage'] = percentage;
    }

    if (estimatedHours != null) {
      data['estimatedHours'] = estimatedHours;
    }

    if (actualHours != null) {
      data['actualHours'] = actualHours;
    }

    if (milestoneId != null) {
      data['milestoneId'] =
          milestoneId.trim().isEmpty ? null : milestoneId.trim();
    }

    if (parentTaskId != null) {
      data['parentTaskId'] =
          parentTaskId.trim().isEmpty ? null : parentTaskId.trim();
    }

    if (watcherIds != null) {
      data['watcherIds'] = watcherIds
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
    }

    final batch = _firestore.batch();

    batch.update(
      _tasksCollection.doc(taskId),
      data,
    );

    for (final activity in activities) {
      batch.set(
        _activitiesCollection.doc(activity.activityId),
        activity.toMap(),
      );
    }

    await batch.commit();
  }

  // ============================================================
  // ASSIGN TASK
  // ============================================================

  Future<void> assignTask({
    required String taskId,
    required String employeeUid,
  }) async {
    final uid = employeeUid.trim();

    if (uid.isEmpty) {
      throw Exception('Employee ID is required.');
    }

    final task = await getTaskOrThrow(taskId);
    final currentUid = currentUserUid;
    final now = DateTime.now();

    final batch = _firestore.batch();

    batch.update(
      _tasksCollection.doc(taskId),
      {
        'assignedTo': uid,
        'updatedAt': Timestamp.fromDate(now),
      },
    );

    final activityRef = _activitiesCollection.doc();

    final activity = TaskActivity(
      activityId: activityRef.id,
      taskId: task.taskId,
      projectId: task.projectId,
      userId: currentUid,
      type: task.assignedTo == null
          ? TaskActivityType.assigned
          : TaskActivityType.reassigned,
      message: task.assignedTo == null
          ? 'Task assigned'
          : 'Task reassigned',
      previousValue: task.assignedTo,
      newValue: uid,
      createdAt: now,
    );

    batch.set(
      activityRef,
      activity.toMap(),
    );

    await batch.commit();
  }

  Future<void> unassignTask(String taskId) async {
    final task = await getTaskOrThrow(taskId);

    if (task.assignedTo == null) {
      return;
    }

    final uid = currentUserUid;
    final now = DateTime.now();

    final batch = _firestore.batch();

    batch.update(
      _tasksCollection.doc(taskId),
      {
        'assignedTo': null,
        'updatedAt': Timestamp.fromDate(now),
      },
    );

    final activityRef = _activitiesCollection.doc();

    final activity = TaskActivity(
      activityId: activityRef.id,
      taskId: task.taskId,
      projectId: task.projectId,
      userId: uid,
      type: TaskActivityType.reassigned,
      message: 'Task unassigned',
      previousValue: task.assignedTo,
      newValue: null,
      createdAt: now,
    );

    batch.set(
      activityRef,
      activity.toMap(),
    );

    await batch.commit();
  }

  // ============================================================
  // STATUS WORKFLOW
  // ============================================================

  Future<void> updateStatus({
    required String taskId,
    required TaskStatus status,
    String? note,
  }) async {
    final task = await getTaskOrThrow(taskId);

    if (task.status == status) {
      return;
    }

    final uid = currentUserUid;
    final now = DateTime.now();

    final data = <String, dynamic>{
      'status': status.name,
      'updatedAt': Timestamp.fromDate(now),
    };

    TaskActivityType activityType =
        TaskActivityType.statusChanged;

    String message = 'Task status changed';

    if (status == TaskStatus.inReview) {
      activityType = TaskActivityType.submittedForReview;
      message = 'Task submitted for review';
    }

    if (status == TaskStatus.changesRequested) {
      activityType = TaskActivityType.changesRequested;
      message = 'Changes requested';
    }

    if (status == TaskStatus.completed) {
      activityType = TaskActivityType.completed;
      message = 'Task completed';

      data['completionPercentage'] = 100;
      data['completedAt'] = Timestamp.fromDate(now);
    }

    if (status == TaskStatus.blocked) {
      activityType = TaskActivityType.blocked;
      message = 'Task blocked';
    }

    if (task.status == TaskStatus.blocked &&
        status != TaskStatus.blocked) {
      activityType = TaskActivityType.unblocked;
      message = 'Task unblocked';
    }

    if (status == TaskStatus.todo &&
        task.status == TaskStatus.completed) {
      activityType = TaskActivityType.reopened;
      message = 'Task reopened';

      data['completedAt'] = null;
    }

    if (status != TaskStatus.completed &&
        task.status == TaskStatus.completed) {
      data['completedAt'] = null;
    }

    final batch = _firestore.batch();

    batch.update(
      _tasksCollection.doc(taskId),
      data,
    );

    final activityRef = _activitiesCollection.doc();

    final activity = TaskActivity(
      activityId: activityRef.id,
      taskId: task.taskId,
      projectId: task.projectId,
      userId: uid,
      type: activityType,
      message: note == null || note.trim().isEmpty
          ? message
          : '$message: ${note.trim()}',
      previousValue: task.status.name,
      newValue: status.name,
      createdAt: now,
    );

    batch.set(
      activityRef,
      activity.toMap(),
    );

    await batch.commit();

    await _recalculateProjectProgress(task.projectId);
  }

  // ============================================================
  // QUICK STATUS METHODS
  // ============================================================

  Future<void> startTask(String taskId) async {
    await updateStatus(
      taskId: taskId,
      status: TaskStatus.inProgress,
    );
  }

  Future<void> submitForReview(
    String taskId, {
    String? note,
  }) async {
    final task = await getTaskOrThrow(taskId);

    final percentage =
        task.completionPercentage.clamp(0, 100).toDouble();

    if (percentage < 100) {
      await updateTask(
        taskId: taskId,
        completionPercentage: 100,
      );
    }

    await updateStatus(
      taskId: taskId,
      status: TaskStatus.inReview,
      note: note,
    );
  }

  Future<void> requestChanges(
    String taskId, {
    required String note,
  }) async {
    if (note.trim().isEmpty) {
      throw Exception('Please provide a reason for the changes.');
    }

    await updateStatus(
      taskId: taskId,
      status: TaskStatus.changesRequested,
      note: note,
    );
  }

  Future<void> approveTask(
    String taskId, {
    String? note,
  }) async {
    await updateStatus(
      taskId: taskId,
      status: TaskStatus.completed,
      note: note,
    );
  }

  Future<void> completeTask(
    String taskId, {
    String? note,
  }) async {
    await updateStatus(
      taskId: taskId,
      status: TaskStatus.completed,
      note: note,
    );
  }

  Future<void> reopenTask(
    String taskId, {
    String? note,
  }) async {
    await updateStatus(
      taskId: taskId,
      status: TaskStatus.todo,
      note: note,
    );
  }

  Future<void> blockTask(
    String taskId, {
    required String note,
  }) async {
    if (note.trim().isEmpty) {
      throw Exception('Please provide a reason for blocking.');
    }

    await updateStatus(
      taskId: taskId,
      status: TaskStatus.blocked,
      note: note,
    );
  }

  Future<void> cancelTask(
    String taskId, {
    String? note,
  }) async {
    await updateStatus(
      taskId: taskId,
      status: TaskStatus.cancelled,
      note: note,
    );
  }

  // ============================================================
  // COMPLETION PERCENTAGE
  // ============================================================

  Future<void> updateCompletionPercentage({
    required String taskId,
    required double percentage,
  }) async {
    final value = percentage.clamp(0, 100).toDouble();

    final task = await getTaskOrThrow(taskId);
    final uid = currentUserUid;
    final now = DateTime.now();

    final data = <String, dynamic>{
      'completionPercentage': value,
      'updatedAt': Timestamp.fromDate(now),
    };

    if (value >= 100 &&
        task.status != TaskStatus.completed &&
        task.status != TaskStatus.inReview) {
      data['status'] = TaskStatus.inReview.name;
    }

    await _tasksCollection.doc(taskId).update(data);

    if (value != task.completionPercentage) {
      await _createActivity(
        task: task,
        userId: uid,
        type: TaskActivityType.statusChanged,
        message: 'Completion updated to ${value.toStringAsFixed(0)}%',
        previousValue:
            task.completionPercentage.toStringAsFixed(0),
        newValue: value.toStringAsFixed(0),
      );
    }

    await _recalculateProjectProgress(task.projectId);
  }

  // ============================================================
  // WATCHERS
  // ============================================================

  Future<void> addWatcher({
    required String taskId,
    required String employeeUid,
  }) async {
    final uid = employeeUid.trim();

    if (uid.isEmpty) {
      throw Exception('Employee ID is required.');
    }

    await _tasksCollection.doc(taskId).update({
      'watcherIds': FieldValue.arrayUnion([uid]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> removeWatcher({
    required String taskId,
    required String employeeUid,
  }) async {
    final uid = employeeUid.trim();

    if (uid.isEmpty) {
      return;
    }

    await _tasksCollection.doc(taskId).update({
      'watcherIds': FieldValue.arrayRemove([uid]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ============================================================
  // DUE DATE / OVERDUE
  // ============================================================

  Future<List<Task>> getOverdueTasks() async {
    final tasks = await getAllTasks();

    final now = DateTime.now();

    return tasks.where((task) {
      final dueDate = task.dueDate;

      if (dueDate == null) {
        return false;
      }

      if (task.status == TaskStatus.completed ||
          task.status == TaskStatus.cancelled) {
        return false;
      }

      return dueDate.isBefore(now);
    }).toList();
  }

  Future<List<Task>> getMyOverdueTasks() async {
    final tasks = await getMyTasks();

    final now = DateTime.now();

    return tasks.where((task) {
      final dueDate = task.dueDate;

      if (dueDate == null) {
        return false;
      }

      if (task.status == TaskStatus.completed ||
          task.status == TaskStatus.cancelled) {
        return false;
      }

      return dueDate.isBefore(now);
    }).toList();
  }

  Future<List<Task>> getTasksDueToday() async {
    final tasks = await getAllTasks();

    final now = DateTime.now();

    return tasks.where((task) {
      final dueDate = task.dueDate;

      if (dueDate == null) {
        return false;
      }

      if (task.status == TaskStatus.completed ||
          task.status == TaskStatus.cancelled) {
        return false;
      }

      return _isSameDay(dueDate, now);
    }).toList();
  }

  Future<List<Task>> getMyTasksDueToday() async {
    final tasks = await getMyTasks();

    final now = DateTime.now();

    return tasks.where((task) {
      final dueDate = task.dueDate;

      if (dueDate == null) {
        return false;
      }

      if (task.status == TaskStatus.completed ||
          task.status == TaskStatus.cancelled) {
        return false;
      }

      return _isSameDay(dueDate, now);
    }).toList();
  }

  // ============================================================
  // TASK ACTIVITIES
  // ============================================================

  Future<List<TaskActivity>> getTaskActivities(
    String taskId,
  ) async {
    final snapshot = await _activitiesCollection
        .where('taskId', isEqualTo: taskId)
        .get();

    final activities = snapshot.docs
        .map((doc) => TaskActivity.fromMap(doc.id, doc.data()))
        .toList();

    activities.sort(_sortActivitiesAscending);

    return activities;
  }

  Stream<List<TaskActivity>> watchTaskActivities(
    String taskId,
  ) {
    return _activitiesCollection
        .where('taskId', isEqualTo: taskId)
        .snapshots()
        .map((snapshot) {
      final activities = snapshot.docs
          .map((doc) => TaskActivity.fromMap(doc.id, doc.data()))
          .toList();

      activities.sort(_sortActivitiesAscending);

      return activities;
    });
  }

  Future<void> addActivity({
    required String taskId,
    required TaskActivityType type,
    required String message,
    String? previousValue,
    String? newValue,
  }) async {
    final task = await getTaskOrThrow(taskId);
    final uid = currentUserUid;

    await _createActivity(
      task: task,
      userId: uid,
      type: type,
      message: message,
      previousValue: previousValue,
      newValue: newValue,
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteTask(String taskId) async {
    final task = await getTaskOrThrow(taskId);

    final activitiesSnapshot = await _activitiesCollection
        .where('taskId', isEqualTo: taskId)
        .get();

    final batch = _firestore.batch();

    batch.delete(_tasksCollection.doc(taskId));

    for (final activity in activitiesSnapshot.docs) {
      batch.delete(activity.reference);
    }

    await batch.commit();

    await _recalculateProjectProgress(task.projectId);
  }

  // ============================================================
  // TASK COUNTS
  // ============================================================

  Future<TaskStats> getTaskStats({
    String? projectId,
    String? employeeUid,
  }) async {
    Query<Map<String, dynamic>> query = _tasksCollection;

    if (projectId != null && projectId.trim().isNotEmpty) {
      query = query.where(
        'projectId',
        isEqualTo: projectId.trim(),
      );
    }

    if (employeeUid != null && employeeUid.trim().isNotEmpty) {
      query = query.where(
        'assignedTo',
        isEqualTo: employeeUid.trim(),
      );
    }

    final snapshot = await query.get();

    int backlog = 0;
    int todo = 0;
    int inProgress = 0;
    int inReview = 0;
    int changesRequested = 0;
    int completed = 0;
    int blocked = 0;
    int cancelled = 0;

    for (final doc in snapshot.docs) {
      final status = doc.data()['status']?.toString();

      switch (status) {
        case 'backlog':
          backlog++;
          break;

        case 'todo':
          todo++;
          break;

        case 'inProgress':
          inProgress++;
          break;

        case 'inReview':
          inReview++;
          break;

        case 'changesRequested':
          changesRequested++;
          break;

        case 'completed':
          completed++;
          break;

        case 'blocked':
          blocked++;
          break;

        case 'cancelled':
          cancelled++;
          break;
      }
    }

    final total = snapshot.docs.length;

    return TaskStats(
      total: total,
      backlog: backlog,
      todo: todo,
      inProgress: inProgress,
      inReview: inReview,
      changesRequested: changesRequested,
      completed: completed,
      blocked: blocked,
      cancelled: cancelled,
    );
  }

  // ============================================================
  // INTERNAL ACTIVITY
  // ============================================================

  Future<void> _createActivity({
    required Task task,
    required String userId,
    required TaskActivityType type,
    required String message,
    String? previousValue,
    String? newValue,
  }) async {
    final ref = _activitiesCollection.doc();

    final activity = TaskActivity(
      activityId: ref.id,
      taskId: task.taskId,
      projectId: task.projectId,
      userId: userId,
      type: type,
      message: message,
      previousValue: previousValue,
      newValue: newValue,
      createdAt: DateTime.now(),
    );

    await ref.set(activity.toMap());
  }

  TaskActivity _buildActivity({
    required Task task,
    required String userId,
    required TaskActivityType type,
    required String message,
    String? previousValue,
    String? newValue,
  }) {
    return TaskActivity(
      activityId: _activitiesCollection.doc().id,
      taskId: task.taskId,
      projectId: task.projectId,
      userId: userId,
      type: type,
      message: message,
      previousValue: previousValue,
      newValue: newValue,
      createdAt: DateTime.now(),
    );
  }

  // ============================================================
  // PROJECT PROGRESS
  // ============================================================

  Future<void> _recalculateProjectProgress(
    String projectId,
  ) async {
    final snapshot = await _tasksCollection
        .where('projectId', isEqualTo: projectId)
        .get();

    if (snapshot.docs.isEmpty) {
      await _projectsCollection.doc(projectId).update({
        'progress': 0,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return;
    }

    double totalProgress = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final raw = data['completionPercentage'];

      double percentage = 0;

      if (raw is num) {
        percentage = raw.toDouble();
      } else if (raw is String) {
        percentage = double.tryParse(raw) ?? 0;
      }

      totalProgress += percentage.clamp(0, 100);
    }

    final progress =
        (totalProgress / snapshot.docs.length).clamp(0, 100).toDouble();

    await _projectsCollection.doc(projectId).update({
      'progress': progress,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String? _nullableString(String? value) {
    if (value == null) {
      return null;
    }

    final trimmed = value.trim();

    return trimmed.isEmpty ? null : trimmed;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  int _sortByUpdatedAtDescending(
    Task a,
    Task b,
  ) {
    final aDate = a.updatedAt;
    final bDate = b.updatedAt;

    if (aDate == null && bDate == null) {
      return 0;
    }

    if (aDate == null) {
      return 1;
    }

    if (bDate == null) {
      return -1;
    }

    return bDate.compareTo(aDate);
  }

  int _sortByDueDateAscending(
    Task a,
    Task b,
  ) {
    final aDate = a.dueDate;
    final bDate = b.dueDate;

    if (aDate == null && bDate == null) {
      return 0;
    }

    if (aDate == null) {
      return 1;
    }

    if (bDate == null) {
      return -1;
    }

    return aDate.compareTo(bDate);
  }

  int _sortActivitiesAscending(
    TaskActivity a,
    TaskActivity b,
  ) {
    final aDate = a.createdAt;
    final bDate = b.createdAt;

    if (aDate == null && bDate == null) {
      return 0;
    }

    if (aDate == null) {
      return 1;
    }

    if (bDate == null) {
      return -1;
    }

    return aDate.compareTo(bDate);
  }
}

// ================================================================
// TASK STATS
// ================================================================

class TaskStats {
  final int total;
  final int backlog;
  final int todo;
  final int inProgress;
  final int inReview;
  final int changesRequested;
  final int completed;
  final int blocked;
  final int cancelled;

  const TaskStats({
    required this.total,
    required this.backlog,
    required this.todo,
    required this.inProgress,
    required this.inReview,
    required this.changesRequested,
    required this.completed,
    required this.blocked,
    required this.cancelled,
  });

  int get active =>
      todo + inProgress + inReview + changesRequested;

  int get unfinished =>
      total - completed - cancelled;

  double get completionPercentage {
    if (total == 0) {
      return 0;
    }

    return (completed / total) * 100;
  }

  bool get hasTasks => total > 0;

  bool get allCompleted =>
      total > 0 && completed == total;
}