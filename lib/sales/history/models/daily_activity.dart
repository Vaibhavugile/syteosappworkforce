import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../models/visit.dart';

enum DailyActivityType {
  visitCreated,
  visitScheduled,
  visitStarted,
  visitCompleted,
  visitCancelled,
  visitMissed,
}

@immutable
class DailyActivity {
  final String id;
  final DailyActivityType type;
  final DateTime timestamp;
  final Visit visit;

  const DailyActivity({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.visit,
  });

  String get title {
    switch (type) {
      case DailyActivityType.visitCreated:
        return 'Visit Created';

      case DailyActivityType.visitScheduled:
        return 'Visit Scheduled';

      case DailyActivityType.visitStarted:
        return 'Visit Started';

      case DailyActivityType.visitCompleted:
        return 'Visit Completed';

      case DailyActivityType.visitCancelled:
        return 'Visit Cancelled';

      case DailyActivityType.visitMissed:
        return 'Visit Missed';
    }
  }

  String get subtitle {
    switch (type) {
      case DailyActivityType.visitCreated:
        return 'A new visit was added to your activity.';

      case DailyActivityType.visitScheduled:
        return 'A customer visit was scheduled.';

      case DailyActivityType.visitStarted:
        return 'The visit was started.';

      case DailyActivityType.visitCompleted:
        return 'The customer visit was completed.';

      case DailyActivityType.visitCancelled:
        return 'The visit was cancelled.';

      case DailyActivityType.visitMissed:
        return 'The visit was marked as missed.';
    }
  }

  IconData get icon {
    switch (type) {
      case DailyActivityType.visitCreated:
        return Icons.add_location_alt_outlined;

      case DailyActivityType.visitScheduled:
        return Icons.event_available_outlined;

      case DailyActivityType.visitStarted:
        return Icons.play_circle_outline_rounded;

      case DailyActivityType.visitCompleted:
        return Icons.check_circle_outline_rounded;

      case DailyActivityType.visitCancelled:
        return Icons.cancel_outlined;

      case DailyActivityType.visitMissed:
        return Icons.event_busy_outlined;
    }
  }

  bool get hasLocation {
    return visit.latitude != null &&
        visit.longitude != null;
  }

  String get outcomeLabel {
    switch (visit.outcome) {
      case VisitOutcome.interested:
        return 'Interested';

      case VisitOutcome.notInterested:
        return 'Not Interested';

      case VisitOutcome.followUpRequired:
        return 'Follow-up Required';

      case VisitOutcome.demoRequested:
        return 'Demo Requested';

      case VisitOutcome.proposalRequested:
        return 'Proposal Requested';

      case VisitOutcome.noResponse:
        return 'No Response';

      case VisitOutcome.notAvailable:
        return 'Not Available';

      case VisitOutcome.converted:
        return 'Converted';

      case VisitOutcome.other:
        return 'Other';

      case null:
        return '';
    }
  }
}