import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/visit.dart';
import '../models/daily_activity.dart';

class DailyHistoryData {
  final DateTime date;
  final List<Visit> visits;
  final List<DailyActivity> activities;

  const DailyHistoryData({
    required this.date,
    required this.visits,
    required this.activities,
  });

  int get totalVisits => visits.length;

  int get totalCreated {
    return activities
        .where(
          (a) => a.type == DailyActivityType.visitCreated,
        )
        .length;
  }

  int get totalScheduled {
    return activities
        .where(
          (a) => a.type == DailyActivityType.visitScheduled,
        )
        .length;
  }

  int get totalStarted {
    return activities
        .where(
          (a) => a.type == DailyActivityType.visitStarted,
        )
        .length;
  }

  int get totalCompleted {
    return activities
        .where(
          (a) => a.type == DailyActivityType.visitCompleted,
        )
        .length;
  }

  int get totalCancelled {
    return activities
        .where(
          (a) => a.type == DailyActivityType.visitCancelled,
        )
        .length;
  }

  int get totalMissed {
    return activities
        .where(
          (a) => a.type == DailyActivityType.visitMissed,
        )
        .length;
  }

  int get interested {
    return visits
        .where(
          (v) => v.outcome == VisitOutcome.interested,
        )
        .length;
  }

  int get notInterested {
    return visits
        .where(
          (v) => v.outcome == VisitOutcome.notInterested,
        )
        .length;
  }

  int get followUpRequired {
    return visits
        .where(
          (v) => v.outcome == VisitOutcome.followUpRequired,
        )
        .length;
  }

  int get demoRequested {
    return visits
        .where(
          (v) => v.outcome == VisitOutcome.demoRequested,
        )
        .length;
  }

  int get proposalRequested {
    return visits
        .where(
          (v) => v.outcome == VisitOutcome.proposalRequested,
        )
        .length;
  }

  int get converted {
    return visits
        .where(
          (v) => v.outcome == VisitOutcome.converted,
        )
        .length;
  }

  int get noResponse {
    return visits
        .where(
          (v) => v.outcome == VisitOutcome.noResponse,
        )
        .length;
  }

  int get notAvailable {
    return visits
        .where(
          (v) => v.outcome == VisitOutcome.notAvailable,
        )
        .length;
  }

  int get other {
    return visits
        .where(
          (v) => v.outcome == VisitOutcome.other,
        )
        .length;
  }

  int get locationCount {
    return visits
        .where(
          (v) =>
              v.latitude != null &&
              v.longitude != null,
        )
        .length;
  }

  DateTime? get firstActivityTime {
    if (activities.isEmpty) {
      return null;
    }

    return activities
        .map((e) => e.timestamp)
        .reduce(
          (a, b) => a.isBefore(b) ? a : b,
        );
  }

  DateTime? get lastActivityTime {
    if (activities.isEmpty) {
      return null;
    }

    return activities
        .map((e) => e.timestamp)
        .reduce(
          (a, b) => a.isAfter(b) ? a : b,
        );
  }
}

class DailyHistoryService {
  DailyHistoryService._();

  static final DailyHistoryService instance =
      DailyHistoryService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>>
      get _visitsCollection =>
          _firestore.collection('visits');

  String get currentUserUid {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in to view daily history.',
      );
    }

    return user.uid;
  }

  Future<DailyHistoryData> getHistoryForDate(
    DateTime date,
  ) async {
    final uid = currentUserUid;

    final start = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final end = start.add(
      const Duration(days: 1),
    );

    /*
     * We intentionally retrieve the user's visits and
     * evaluate every lifecycle timestamp locally.
     *
     * This means a visit created on one day but completed
     * on another day will correctly appear in both days.
     */
    final snapshot = await _visitsCollection
        .where(
          'assignedTo',
          isEqualTo: uid,
        )
        .get();

    final visits = <Visit>[];

    for (final document in snapshot.docs) {
      final visit = Visit.fromMap(
        document.id,
        document.data(),
      );

      final hasActivity = _isTimestampInRange(
            visit.createdAt,
            start,
            end,
          ) ||
          _isTimestampInRange(
            visit.scheduledAt,
            start,
            end,
          ) ||
          _isTimestampInRange(
            visit.startedAt,
            start,
            end,
          ) ||
          _isTimestampInRange(
            visit.completedAt,
            start,
            end,
          ) ||
          _isTimestampInRange(
            visit.cancelledAt,
            start,
            end,
          ) ||
          _isTimestampInRange(
            visit.missedAt,
            start,
            end,
          );

      if (hasActivity) {
        visits.add(visit);
      }
    }

    final activities = <DailyActivity>[];

    for (final visit in visits) {
      _addActivity(
        activities,
        visit: visit,
        type: DailyActivityType.visitCreated,
        timestamp: visit.createdAt,
        start: start,
        end: end,
      );

      _addActivity(
        activities,
        visit: visit,
        type: DailyActivityType.visitScheduled,
        timestamp: visit.scheduledAt,
        start: start,
        end: end,
      );

      _addActivity(
        activities,
        visit: visit,
        type: DailyActivityType.visitStarted,
        timestamp: visit.startedAt,
        start: start,
        end: end,
      );

      _addActivity(
        activities,
        visit: visit,
        type: DailyActivityType.visitCompleted,
        timestamp: visit.completedAt,
        start: start,
        end: end,
      );

      _addActivity(
        activities,
        visit: visit,
        type: DailyActivityType.visitCancelled,
        timestamp: visit.cancelledAt,
        start: start,
        end: end,
      );

      _addActivity(
        activities,
        visit: visit,
        type: DailyActivityType.visitMissed,
        timestamp: visit.missedAt,
        start: start,
        end: end,
      );
    }

    activities.sort(
      (a, b) => a.timestamp.compareTo(b.timestamp),
    );

    visits.sort(
      (a, b) {
        final aTime =
            a.scheduledAt ??
            a.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);

        final bTime =
            b.scheduledAt ??
            b.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);

        return aTime.compareTo(bTime);
      },
    );

    return DailyHistoryData(
      date: start,
      visits: visits,
      activities: activities,
    );
  }

  void _addActivity(
    List<DailyActivity> activities, {
    required Visit visit,
    required DailyActivityType type,
    required DateTime? timestamp,
    required DateTime start,
    required DateTime end,
  }) {
    if (timestamp == null) {
      return;
    }

    if (!_isTimestampInRange(
      timestamp,
      start,
      end,
    )) {
      return;
    }

    activities.add(
      DailyActivity(
        id: '${visit.visitId}_${type.name}',
        type: type,
        timestamp: timestamp,
        visit: visit,
      ),
    );
  }

  bool _isTimestampInRange(
    DateTime? timestamp,
    DateTime start,
    DateTime end,
  ) {
    if (timestamp == null) {
      return false;
    }

    return !timestamp.isBefore(start) &&
        timestamp.isBefore(end);
  }
}