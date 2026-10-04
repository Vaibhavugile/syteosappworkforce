import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/project.dart';

class ProjectService {
  ProjectService._();

  static final ProjectService instance = ProjectService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _projectsCollection =>
      _firestore.collection('projects');

  CollectionReference<Map<String, dynamic>> get _tasksCollection =>
      _firestore.collection('tasks');

  String get currentUserUid {
    final uid = _auth.currentUser?.uid;

    if (uid == null || uid.isEmpty) {
      throw Exception('User is not authenticated.');
    }

    return uid;
  }

  // ============================================================
  // CREATE
  // ============================================================

  Future<String> createProject({
    required String name,
    String? description,
    String? clientName,
    String? clientId,
    String? projectManagerId,
    List<String> memberIds = const [],
    ProjectStatus status = ProjectStatus.draft,
    ProjectPriority priority = ProjectPriority.medium,
    DateTime? startDate,
    DateTime? targetDate,
    String? color,
    String? icon,
  }) async {
    final uid = currentUserUid;

    final projectRef = _projectsCollection.doc();

    final now = DateTime.now();

    final members = <String>{
      uid,
      ...memberIds,
      if (projectManagerId != null && projectManagerId.isNotEmpty)
        projectManagerId,
    }.toList();

    final project = Project(
      projectId: projectRef.id,
      name: name.trim(),
      description: _nullableString(description) ?? '',
      clientName: _nullableString(clientName),
      clientId: _nullableString(clientId),
      createdBy: uid,
      projectManagerId: _nullableString(projectManagerId),
      memberIds: members,
      status: status,
      priority: priority,
      startDate: startDate,
      targetDate: targetDate,
      color: _nullableString(color),
      icon: _nullableString(icon),
      progress: 0,
      createdAt: now,
      updatedAt: now,
    );

    await projectRef.set(project.toMap());

    return projectRef.id;
  }

  // ============================================================
  // GET PROJECT
  // ============================================================

  Future<Project?> getProject(String projectId) async {
    if (projectId.trim().isEmpty) {
      return null;
    }

    final snapshot = await _projectsCollection.doc(projectId).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return Project.fromMap(snapshot.id, snapshot.data()!);
  }

  Future<Project> getProjectOrThrow(String projectId) async {
    final project = await getProject(projectId);

    if (project == null) {
      throw Exception('Project not found.');
    }

    return project;
  }

  // ============================================================
  // WATCH PROJECT
  // ============================================================

  Stream<Project?> watchProject(String projectId) {
    if (projectId.trim().isEmpty) {
      return Stream.value(null);
    }

    return _projectsCollection.doc(projectId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }

      return Project.fromMap(snapshot.id, snapshot.data()!);
    });
  }

  // ============================================================
  // ALL PROJECTS
  // ============================================================

  Future<List<Project>> getAllProjects() async {
    final snapshot = await _projectsCollection
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Project.fromMap(doc.id, doc.data()))
        .toList();
  }

  Stream<List<Project>> watchAllProjects() {
    return _projectsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Project.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // ============================================================
  // MY PROJECTS
  // ============================================================

  Future<List<Project>> getMyProjects() async {
    final uid = currentUserUid;

    final snapshot = await _projectsCollection
        .where('memberIds', arrayContains: uid)
        .get();

    final projects = snapshot.docs
        .map((doc) => Project.fromMap(doc.id, doc.data()))
        .toList();

    projects.sort(_sortByCreatedAtDescending);

    return projects;
  }

  Stream<List<Project>> watchMyProjects() {
    final uid = currentUserUid;

    return _projectsCollection
        .where('memberIds', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
      final projects = snapshot.docs
          .map((doc) => Project.fromMap(doc.id, doc.data()))
          .toList();

      projects.sort(_sortByCreatedAtDescending);

      return projects;
    });
  }

  // ============================================================
  // PROJECTS CREATED BY ME
  // ============================================================

  Future<List<Project>> getProjectsCreatedByMe() async {
    final uid = currentUserUid;

    final snapshot =
        await _projectsCollection.where('createdBy', isEqualTo: uid).get();

    final projects = snapshot.docs
        .map((doc) => Project.fromMap(doc.id, doc.data()))
        .toList();

    projects.sort(_sortByCreatedAtDescending);

    return projects;
  }

  Stream<List<Project>> watchProjectsCreatedByMe() {
    final uid = currentUserUid;

    return _projectsCollection
        .where('createdBy', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final projects = snapshot.docs
          .map((doc) => Project.fromMap(doc.id, doc.data()))
          .toList();

      projects.sort(_sortByCreatedAtDescending);

      return projects;
    });
  }

  // ============================================================
  // PROJECTS MANAGED BY ME
  // ============================================================

  Future<List<Project>> getProjectsManagedByMe() async {
    final uid = currentUserUid;

    final snapshot = await _projectsCollection
        .where('projectManagerId', isEqualTo: uid)
        .get();

    final projects = snapshot.docs
        .map((doc) => Project.fromMap(doc.id, doc.data()))
        .toList();

    projects.sort(_sortByCreatedAtDescending);

    return projects;
  }

  Stream<List<Project>> watchProjectsManagedByMe() {
    final uid = currentUserUid;

    return _projectsCollection
        .where('projectManagerId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final projects = snapshot.docs
          .map((doc) => Project.fromMap(doc.id, doc.data()))
          .toList();

      projects.sort(_sortByCreatedAtDescending);

      return projects;
    });
  }

  // ============================================================
  // FILTER BY STATUS
  // ============================================================

  Future<List<Project>> getProjectsByStatus(
    ProjectStatus status,
  ) async {
    final snapshot = await _projectsCollection
        .where('status', isEqualTo: status.name)
        .get();

    final projects = snapshot.docs
        .map((doc) => Project.fromMap(doc.id, doc.data()))
        .toList();

    projects.sort(_sortByCreatedAtDescending);

    return projects;
  }

  Stream<List<Project>> watchProjectsByStatus(
    ProjectStatus status,
  ) {
    return _projectsCollection
        .where('status', isEqualTo: status.name)
        .snapshots()
        .map((snapshot) {
      final projects = snapshot.docs
          .map((doc) => Project.fromMap(doc.id, doc.data()))
          .toList();

      projects.sort(_sortByCreatedAtDescending);

      return projects;
    });
  }

  // ============================================================
  // FILTER BY PRIORITY
  // ============================================================

  Future<List<Project>> getProjectsByPriority(
    ProjectPriority priority,
  ) async {
    final snapshot = await _projectsCollection
        .where('priority', isEqualTo: priority.name)
        .get();

    final projects = snapshot.docs
        .map((doc) => Project.fromMap(doc.id, doc.data()))
        .toList();

    projects.sort(_sortByCreatedAtDescending);

    return projects;
  }

  Stream<List<Project>> watchProjectsByPriority(
    ProjectPriority priority,
  ) {
    return _projectsCollection
        .where('priority', isEqualTo: priority.name)
        .snapshots()
        .map((snapshot) {
      final projects = snapshot.docs
          .map((doc) => Project.fromMap(doc.id, doc.data()))
          .toList();

      projects.sort(_sortByCreatedAtDescending);

      return projects;
    });
  }

  // ============================================================
  // UPDATE PROJECT
  // ============================================================

  Future<void> updateProject({
    required String projectId,
    String? name,
    String? description,
    String? clientName,
    String? clientId,
    ProjectStatus? status,
    ProjectPriority? priority,
    String? projectManagerId,
    DateTime? startDate,
    DateTime? targetDate,
    DateTime? completedAt,
    String? color,
    String? icon,
    double? progress,
  }) async {
    if (projectId.trim().isEmpty) {
      throw Exception('Project ID is required.');
    }

    final data = <String, dynamic>{
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };

    if (name != null) {
      data['name'] = name.trim();
    }

    if (description != null) {
      data['description'] = description.trim();
    }

    if (clientName != null) {
      data['clientName'] = clientName.trim();
    }

    if (clientId != null) {
      data['clientId'] = clientId.trim();
    }

    if (status != null) {
      data['status'] = status.name;
    }

    if (priority != null) {
      data['priority'] = priority.name;
    }

    if (projectManagerId != null) {
      data['projectManagerId'] =
          projectManagerId.trim().isEmpty ? null : projectManagerId.trim();
    }

    if (startDate != null) {
      data['startDate'] = Timestamp.fromDate(startDate);
    }

    if (targetDate != null) {
      data['targetDate'] = Timestamp.fromDate(targetDate);
    }

    if (completedAt != null) {
      data['completedAt'] = Timestamp.fromDate(completedAt);
    }

    if (color != null) {
      data['color'] = color.trim().isEmpty ? null : color.trim();
    }

    if (icon != null) {
      data['icon'] = icon.trim().isEmpty ? null : icon.trim();
    }

    if (progress != null) {
      data['progress'] = progress.clamp(0, 100);
    }

    await _projectsCollection.doc(projectId).update(data);
  }

  // ============================================================
  // UPDATE STATUS
  // ============================================================

  Future<void> updateStatus(
    String projectId,
    ProjectStatus status,
  ) async {
    final data = <String, dynamic>{
      'status': status.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };

    if (status == ProjectStatus.completed) {
      data['progress'] = 100;
      data['completedAt'] = Timestamp.fromDate(DateTime.now());
    }

    if (status != ProjectStatus.completed) {
      data['completedAt'] = null;
    }

    await _projectsCollection.doc(projectId).update(data);
  }

  Future<void> startProject(String projectId) async {
    await updateStatus(
      projectId,
      ProjectStatus.active,
    );
  }

  Future<void> putProjectOnHold(String projectId) async {
    await updateStatus(
      projectId,
      ProjectStatus.onHold,
    );
  }

  /// Compatibility alias used by project management screens.
  Future<void> holdProject(String projectId) async {
    await putProjectOnHold(projectId);
  }

  Future<void> completeProject(String projectId) async {
    await updateStatus(
      projectId,
      ProjectStatus.completed,
    );
  }

  Future<void> archiveProject(String projectId) async {
    await updateStatus(
      projectId,
      ProjectStatus.archived,
    );
  }

  Future<void> reopenProject(String projectId) async {
    await updateStatus(
      projectId,
      ProjectStatus.active,
    );
  }

  // ============================================================
  // UPDATE PRIORITY
  // ============================================================

  Future<void> updatePriority(
    String projectId,
    ProjectPriority priority,
  ) async {
    await _projectsCollection.doc(projectId).update({
      'priority': priority.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ============================================================
  // PROJECT MANAGER
  // ============================================================

  Future<void> assignProjectManager({
    required String projectId,
    required String employeeUid,
  }) async {
    final uid = employeeUid.trim();

    if (uid.isEmpty) {
      throw Exception('Employee ID is required.');
    }

    await _projectsCollection.doc(projectId).update({
      'projectManagerId': uid,
      'memberIds': FieldValue.arrayUnion([uid]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> removeProjectManager(String projectId) async {
    await _projectsCollection.doc(projectId).update({
      'projectManagerId': null,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ============================================================
  // PROJECT MEMBERS
  // ============================================================

  Future<void> addMember({
    required String projectId,
    required String employeeUid,
  }) async {
    final uid = employeeUid.trim();

    if (uid.isEmpty) {
      throw Exception('Employee ID is required.');
    }

    await _projectsCollection.doc(projectId).update({
      'memberIds': FieldValue.arrayUnion([uid]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> addMembers({
    required String projectId,
    required List<String> employeeUids,
  }) async {
    final ids = employeeUids
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (ids.isEmpty) {
      return;
    }

    await _projectsCollection.doc(projectId).update({
      'memberIds': FieldValue.arrayUnion(ids),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> removeMember({
    required String projectId,
    required String employeeUid,
  }) async {
    final uid = employeeUid.trim();

    if (uid.isEmpty) {
      return;
    }

    final project = await getProjectOrThrow(projectId);

    // Do not remove the project creator from the project.
    if (project.createdBy == uid) {
      throw Exception(
        'The project creator cannot be removed from the project.',
      );
    }

    // If this employee is the project manager,
    // remove the manager assignment as well.
    final data = <String, dynamic>{
      'memberIds': FieldValue.arrayRemove([uid]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };

    if (project.projectManagerId == uid) {
      data['projectManagerId'] = null;
    }

    await _projectsCollection.doc(projectId).update(data);
  }

  Future<void> replaceMembers({
    required String projectId,
    required List<String> employeeUids,
  }) async {
    final project = await getProjectOrThrow(projectId);

    final members = employeeUids
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    // Creator should always remain part of the project.
    if (!members.contains(project.createdBy)) {
      members.add(project.createdBy);
    }

    if (project.projectManagerId != null &&
        project.projectManagerId!.isNotEmpty &&
        !members.contains(project.projectManagerId)) {
      members.add(project.projectManagerId!);
    }

    await _projectsCollection.doc(projectId).update({
      'memberIds': members,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ============================================================
  // SEARCH PROJECTS
  // ============================================================

  Future<List<Project>> searchProjects(String query) async {
    final search = query.trim().toLowerCase();

    if (search.isEmpty) {
      return getAllProjects();
    }

    final projects = await getAllProjects();

    return projects.where((project) {
      final name = project.name.toLowerCase();
      final description =
          project.description.toLowerCase();
      final clientName =
          (project.clientName ?? '').toLowerCase();

      return name.contains(search) ||
          description.contains(search) ||
          clientName.contains(search);
    }).toList();
  }

  // ============================================================
  // PROJECT COUNTS
  // ============================================================

  Future<int> getTotalProjectCount() async {
    final snapshot = await _projectsCollection.count().get();
    return snapshot.count ?? 0;
  }

  Future<int> getProjectCountByStatus(
    ProjectStatus status,
  ) async {
    final snapshot = await _projectsCollection
        .where('status', isEqualTo: status.name)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  Future<Map<ProjectStatus, int>> getProjectStatusCounts() async {
    final projects = await getAllProjects();

    final counts = <ProjectStatus, int>{
      for (final status in ProjectStatus.values) status: 0,
    };

    for (final project in projects) {
      counts[project.status] =
          (counts[project.status] ?? 0) + 1;
    }

    return counts;
  }

  // ============================================================
  // PROJECT TASK STATISTICS
  // ============================================================

  Future<ProjectTaskStats> getProjectTaskStats(
    String projectId,
  ) async {
    if (projectId.trim().isEmpty) {
      return const ProjectTaskStats.empty();
    }

    final snapshot = await _tasksCollection
        .where('projectId', isEqualTo: projectId)
        .get();

    int completed = 0;
    int inProgress = 0;
    int inReview = 0;
    int todo = 0;
    int backlog = 0;
    int blocked = 0;
    int cancelled = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final status = data['status']?.toString();

      switch (status) {
        case 'completed':
          completed++;
          break;

        case 'inProgress':
          inProgress++;
          break;

        case 'inReview':
          inReview++;
          break;

        case 'todo':
          todo++;
          break;

        case 'backlog':
          backlog++;
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

    final progress = total == 0
        ? 0.0
        : (completed / total) * 100;

    return ProjectTaskStats(
      total: total,
      completed: completed,
      inProgress: inProgress,
      inReview: inReview,
      todo: todo,
      backlog: backlog,
      blocked: blocked,
      cancelled: cancelled,
      progress: progress.clamp(0, 100),
    );
  }

  Future<double> calculateProjectProgress(
    String projectId,
  ) async {
    final stats = await getProjectTaskStats(projectId);

    return stats.progress;
  }

  Future<void> recalculateProjectProgress(
    String projectId,
  ) async {
    final progress = await calculateProjectProgress(projectId);

    await _projectsCollection.doc(projectId).update({
      'progress': progress,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> recalculateAllProjectProgress() async {
    final projects = await getAllProjects();

    final batch = _firestore.batch();

    for (final project in projects) {
      final stats = await getProjectTaskStats(project.projectId);

      batch.update(
        _projectsCollection.doc(project.projectId),
        {
          'progress': stats.progress,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        },
      );
    }

    await batch.commit();
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteProject(String projectId) async {
    if (projectId.trim().isEmpty) {
      throw Exception('Project ID is required.');
    }

    await _projectsCollection.doc(projectId).delete();
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

  int _sortByCreatedAtDescending(
    Project a,
    Project b,
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

    return bDate.compareTo(aDate);
  }
}

// ================================================================
// PROJECT TASK STATS
// ================================================================

class ProjectTaskStats {
  final int total;
  final int completed;
  final int inProgress;
  final int inReview;
  final int todo;
  final int backlog;
  final int blocked;
  final int cancelled;
  final double progress;

  const ProjectTaskStats({
    required this.total,
    required this.completed,
    required this.inProgress,
    required this.inReview,
    required this.todo,
    required this.backlog,
    required this.blocked,
    required this.cancelled,
    required this.progress,
  });

  const ProjectTaskStats.empty()
      : total = 0,
        completed = 0,
        inProgress = 0,
        inReview = 0,
        todo = 0,
        backlog = 0,
        blocked = 0,
        cancelled = 0,
        progress = 0;

  int get active =>
      inProgress + inReview + todo + backlog;

  int get unfinished =>
      total - completed - cancelled;

  bool get hasTasks => total > 0;

  bool get isCompleted => total > 0 && completed == total;
}