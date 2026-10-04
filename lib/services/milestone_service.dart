import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/milestone.dart';

class MilestoneService {
  MilestoneService._();

  static final MilestoneService instance = MilestoneService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _milestonesCollection =>
      _firestore.collection('milestones');

  CollectionReference<Map<String, dynamic>> get _tasksCollection =>
      _firestore.collection('tasks');

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
  // CREATE MILESTONE
  // ============================================================

  Future<String> createMilestone({
    required String projectId,
    required String name,
    String? description,
    MilestoneStatus status = MilestoneStatus.upcoming,
    DateTime? startDate,
    DateTime? dueDate,
  }) async {
    final uid = currentUserUid;

    if (projectId.trim().isEmpty) {
      throw Exception('Project ID is required.');
    }

    if (name.trim().isEmpty) {
      throw Exception('Milestone name is required.');
    }

    final projectSnapshot =
        await _projectsCollection.doc(projectId).get();

    if (!projectSnapshot.exists) {
      throw Exception('Project not found.');
    }

    final ref = _milestonesCollection.doc();

    final now = DateTime.now();

    final milestone = Milestone(
      milestoneId: ref.id,
      projectId: projectId,
      name: name.trim(),
      description: _nullableString(description) ?? '',
      status: status,
      startDate: startDate,
      dueDate: dueDate,
      completedAt: null,
      progress: 0,
      taskCount: 0,
      completedTaskCount: 0,
      createdBy: uid,
      createdAt: now,
      updatedAt: now,
    );

    await ref.set(milestone.toMap());

    return ref.id;
  }

  // ============================================================
  // GET
  // ============================================================

  Future<Milestone?> getMilestone(
    String milestoneId,
  ) async {
    if (milestoneId.trim().isEmpty) {
      return null;
    }

    final snapshot =
        await _milestonesCollection.doc(milestoneId).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return Milestone.fromMap(snapshot.id, snapshot.data()!);
  }

  Future<Milestone> getMilestoneOrThrow(
    String milestoneId,
  ) async {
    final milestone = await getMilestone(milestoneId);

    if (milestone == null) {
      throw Exception('Milestone not found.');
    }

    return milestone;
  }

  // ============================================================
  // WATCH
  // ============================================================

  Stream<Milestone?> watchMilestone(
    String milestoneId,
  ) {
    if (milestoneId.trim().isEmpty) {
      return Stream.value(null);
    }

    return _milestonesCollection
        .doc(milestoneId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }

      return Milestone.fromMap(snapshot.id, snapshot.data()!);
    });
  }

  // ============================================================
  // PROJECT MILESTONES
  // ============================================================

  Future<List<Milestone>> getProjectMilestones(
    String projectId,
  ) async {
    final snapshot = await _milestonesCollection
        .where('projectId', isEqualTo: projectId)
        .get();

    final milestones = snapshot.docs
        .map((doc) => Milestone.fromMap(doc.id, doc.data()))
        .toList();

    milestones.sort(_sortByDueDateAscending);

    return milestones;
  }

  Stream<List<Milestone>> watchProjectMilestones(
    String projectId,
  ) {
    return _milestonesCollection
        .where('projectId', isEqualTo: projectId)
        .snapshots()
        .map((snapshot) {
      final milestones = snapshot.docs
          .map((doc) => Milestone.fromMap(doc.id, doc.data()))
          .toList();

      milestones.sort(_sortByDueDateAscending);

      return milestones;
    });
  }

  // ============================================================
  // ALL MILESTONES
  // ============================================================

  Future<List<Milestone>> getAllMilestones() async {
    final snapshot = await _milestonesCollection.get();

    final milestones = snapshot.docs
        .map((doc) => Milestone.fromMap(doc.id, doc.data()))
        .toList();

    milestones.sort(_sortByDueDateAscending);

    return milestones;
  }

  Stream<List<Milestone>> watchAllMilestones() {
    return _milestonesCollection.snapshots().map((snapshot) {
      final milestones = snapshot.docs
          .map((doc) => Milestone.fromMap(doc.id, doc.data()))
          .toList();

      milestones.sort(_sortByDueDateAscending);

      return milestones;
    });
  }

  // ============================================================
  // STATUS FILTER
  // ============================================================

  Future<List<Milestone>> getMilestonesByStatus(
    MilestoneStatus status,
  ) async {
    final snapshot = await _milestonesCollection
        .where('status', isEqualTo: status.name)
        .get();

    final milestones = snapshot.docs
        .map((doc) => Milestone.fromMap(doc.id, doc.data()))
        .toList();

    milestones.sort(_sortByDueDateAscending);

    return milestones;
  }

  Stream<List<Milestone>> watchMilestonesByStatus(
    MilestoneStatus status,
  ) {
    return _milestonesCollection
        .where('status', isEqualTo: status.name)
        .snapshots()
        .map((snapshot) {
      final milestones = snapshot.docs
          .map((doc) => Milestone.fromMap(doc.id, doc.data()))
          .toList();

      milestones.sort(_sortByDueDateAscending);

      return milestones;
    });
  }

  // ============================================================
  // UPDATE MILESTONE
  // ============================================================

  Future<void> updateMilestone({
    required String milestoneId,
    String? name,
    String? description,
    MilestoneStatus? status,
    DateTime? startDate,
    DateTime? dueDate,
    DateTime? completedAt,
    double? progress,
  }) async {
    if (milestoneId.trim().isEmpty) {
      throw Exception('Milestone ID is required.');
    }

    final data = <String, dynamic>{
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };

    if (name != null) {
      final value = name.trim();

      if (value.isEmpty) {
        throw Exception('Milestone name cannot be empty.');
      }

      data['name'] = value;
    }

    if (description != null) {
      data['description'] =
          description.trim().isEmpty ? null : description.trim();
    }

    if (status != null) {
      data['status'] = status.name;
    }

    if (startDate != null) {
      data['startDate'] = Timestamp.fromDate(startDate);
    }

    if (dueDate != null) {
      data['dueDate'] = Timestamp.fromDate(dueDate);
    }

    if (completedAt != null) {
      data['completedAt'] = Timestamp.fromDate(completedAt);
    }

    if (progress != null) {
      data['progress'] = progress.clamp(0, 100);
    }

    await _milestonesCollection
        .doc(milestoneId)
        .update(data);
  }

  // ============================================================
  // STATUS ACTIONS
  // ============================================================

  Future<void> startMilestone(
    String milestoneId,
  ) async {
    await updateMilestone(
      milestoneId: milestoneId,
      status: MilestoneStatus.inProgress,
    );
  }

  Future<void> completeMilestone(
    String milestoneId,
  ) async {
    final now = DateTime.now();

    await updateMilestone(
      milestoneId: milestoneId,
      status: MilestoneStatus.completed,
      progress: 100,
      completedAt: now,
    );
  }

  Future<void> delayMilestone(
    String milestoneId,
  ) async {
    await updateMilestone(
      milestoneId: milestoneId,
      status: MilestoneStatus.delayed,
    );
  }

  Future<void> cancelMilestone(
    String milestoneId,
  ) async {
    await updateMilestone(
      milestoneId: milestoneId,
      status: MilestoneStatus.cancelled,
    );
  }

  Future<void> reopenMilestone(
    String milestoneId,
  ) async {
    await updateMilestone(
      milestoneId: milestoneId,
      status: MilestoneStatus.inProgress,
      progress: null,
    );
  }

  // ============================================================
  // RECALCULATE FROM TASKS
  // ============================================================

  Future<MilestoneTaskStats> getMilestoneTaskStats(
    String milestoneId,
  ) async {
    if (milestoneId.trim().isEmpty) {
      return const MilestoneTaskStats.empty();
    }

    final snapshot = await _tasksCollection
        .where('milestoneId', isEqualTo: milestoneId)
        .get();

    int completed = 0;
    int active = 0;
    int blocked = 0;
    int cancelled = 0;

    double totalPercentage = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final status = data['status']?.toString();

      switch (status) {
        case 'completed':
          completed++;
          break;

        case 'blocked':
          blocked++;
          break;

        case 'cancelled':
          cancelled++;
          break;

        default:
          active++;
          break;
      }

      final rawPercentage =
          data['completionPercentage'];

      double percentage = 0;

      if (rawPercentage is num) {
        percentage = rawPercentage.toDouble();
      } else if (rawPercentage is String) {
        percentage =
            double.tryParse(rawPercentage) ?? 0;
      }

      totalPercentage +=
          percentage.clamp(0, 100);
    }

    final total = snapshot.docs.length;

    final progress = total == 0
        ? 0.0
        : (totalPercentage / total).clamp(0, 100).toDouble();

    return MilestoneTaskStats(
      total: total,
      completed: completed,
      active: active,
      blocked: blocked,
      cancelled: cancelled,
      progress: progress,
    );
  }

  Future<void> recalculateMilestoneProgress(
    String milestoneId,
  ) async {
    final stats =
        await getMilestoneTaskStats(milestoneId);

    await _milestonesCollection
        .doc(milestoneId)
        .update({
      'taskCount': stats.total,
      'completedTaskCount': stats.completed,
      'progress': stats.progress,
      'updatedAt':
          Timestamp.fromDate(DateTime.now()),
    });

    if (stats.total > 0 &&
        stats.completed == stats.total) {
      await _milestonesCollection
          .doc(milestoneId)
          .update({
        'status':
            MilestoneStatus.completed.name,
        'completedAt':
            Timestamp.fromDate(DateTime.now()),
      });
    }
  }

  Future<void> recalculateProjectMilestones(
    String projectId,
  ) async {
    final milestones =
        await getProjectMilestones(projectId);

    for (final milestone in milestones) {
      await recalculateMilestoneProgress(
        milestone.milestoneId,
      );
    }
  }

  // ============================================================
  // OVERDUE
  // ============================================================

  Future<List<Milestone>> getOverdueMilestones() async {
    final milestones = await getAllMilestones();

    final now = DateTime.now();

    return milestones.where((milestone) {
      final dueDate = milestone.dueDate;

      if (dueDate == null) {
        return false;
      }

      if (milestone.status ==
              MilestoneStatus.completed ||
          milestone.status ==
              MilestoneStatus.cancelled) {
        return false;
      }

      return dueDate.isBefore(now);
    }).toList();
  }

  Future<List<Milestone>> getProjectOverdueMilestones(
    String projectId,
  ) async {
    final milestones =
        await getProjectMilestones(projectId);

    final now = DateTime.now();

    return milestones.where((milestone) {
      final dueDate = milestone.dueDate;

      if (dueDate == null) {
        return false;
      }

      if (milestone.status ==
              MilestoneStatus.completed ||
          milestone.status ==
              MilestoneStatus.cancelled) {
        return false;
      }

      return dueDate.isBefore(now);
    }).toList();
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteMilestone(
    String milestoneId,
  ) async {
    if (milestoneId.trim().isEmpty) {
      throw Exception('Milestone ID is required.');
    }

    // We intentionally do not delete the tasks.
    //
    // Existing tasks keep their history and can later
    // be reassigned to another milestone.
    await _milestonesCollection
        .doc(milestoneId)
        .delete();
  }

  // ============================================================
  // COUNTS
  // ============================================================

  Future<int> getProjectMilestoneCount(
    String projectId,
  ) async {
    final snapshot = await _milestonesCollection
        .where(
          'projectId',
          isEqualTo: projectId,
        )
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  Future<Map<MilestoneStatus, int>>
      getProjectMilestoneStatusCounts(
    String projectId,
  ) async {
    final milestones =
        await getProjectMilestones(projectId);

    final counts = <MilestoneStatus, int>{
      for (final status in MilestoneStatus.values)
        status: 0,
    };

    for (final milestone in milestones) {
      counts[milestone.status] =
          (counts[milestone.status] ?? 0) + 1;
    }

    return counts;
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

  int _sortByDueDateAscending(
    Milestone a,
    Milestone b,
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
}

// ================================================================
// MILESTONE TASK STATS
// ================================================================

class MilestoneTaskStats {
  final int total;
  final int completed;
  final int active;
  final int blocked;
  final int cancelled;
  final double progress;

  const MilestoneTaskStats({
    required this.total,
    required this.completed,
    required this.active,
    required this.blocked,
    required this.cancelled,
    required this.progress,
  });

  const MilestoneTaskStats.empty()
      : total = 0,
        completed = 0,
        active = 0,
        blocked = 0,
        cancelled = 0,
        progress = 0;

  bool get hasTasks => total > 0;

  bool get isCompleted =>
      total > 0 && completed == total;

  int get unfinished =>
      total - completed - cancelled;
}