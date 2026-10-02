import 'package:cloud_firestore/cloud_firestore.dart';

/// How the visit was created.
enum VisitType {
  selfAdded,
  scheduled,
}

/// Current state of the visit.
enum VisitStatus {
  planned,
  inProgress,
  completed,
  cancelled,
  missed,
}

/// Result of the actual meeting/visit.
enum VisitOutcome {
  interested,
  notInterested,
  followUpRequired,
  demoRequested,
  proposalRequested,
  noResponse,
  notAvailable,
  converted,
  other,
}

class Visit {
  final String visitId;

  // ------------------------------------------------------------
  // LEAD / CUSTOMER IDENTITY
  // ------------------------------------------------------------

  /// Permanent identity of the business/person.
  final String customerUid;

  /// Related lead.
  ///
  /// This can be null initially when a salesperson is recording
  /// a completely new visit before creating the lead.
  final String? leadId;

  // ------------------------------------------------------------
  // VISIT TYPE / STATUS
  // ------------------------------------------------------------

  final VisitType visitType;
  final VisitStatus status;

  // ------------------------------------------------------------
  // OWNERSHIP
  // ------------------------------------------------------------

  /// Firebase UID of the person who created this visit.
  final String createdBy;

  /// Firebase UID of the salesperson responsible for the visit.
  final String assignedTo;

  // ------------------------------------------------------------
  // SCHEDULE / VISIT TIMES
  // ------------------------------------------------------------

  /// Used for scheduled visits.
  final DateTime? scheduledAt;

  /// Actual time the salesperson started the visit.
  final DateTime? startedAt;

  /// Actual time the salesperson completed the visit.
  final DateTime? completedAt;

  /// Actual time the visit was cancelled.
  final DateTime? cancelledAt;

  /// Actual time the visit was marked as missed.
  final DateTime? missedAt;

  // ------------------------------------------------------------
  // LOCATION
  // ------------------------------------------------------------

  /// GPS latitude captured from the device.
  final double? latitude;

  /// GPS longitude captured from the device.
  final double? longitude;

  /// Human-readable address.
  final String? address;

  /// City.
  final String? city;

  /// Area/locality.
  final String? area;

  /// Google/Maps place ID when available.
  final String? placeId;

  /// Google Maps URL.
  final String? mapsUrl;

  // ------------------------------------------------------------
  // PHOTOS
  // ------------------------------------------------------------

  /// Firebase Storage URLs of visit/business photos.
  final List<String> photos;

  // ------------------------------------------------------------
  // VISIT INFORMATION
  // ------------------------------------------------------------

  /// Why the salesperson visited.
  final String? purpose;

  /// Result of the visit.
  final VisitOutcome? outcome;

  /// Salesperson's notes.
  final String? notes;

  // ------------------------------------------------------------
  // FOLLOW-UP
  // ------------------------------------------------------------

  /// Optional next follow-up date/time.
  final DateTime? nextFollowUpAt;

  // ------------------------------------------------------------
  // LEAD CONVERSION
  // ------------------------------------------------------------

  /// Whether this visit should create/attach to a lead.
  final bool createLead;

  /// Whether this visit has already been linked to a lead.
  final bool leadCreated;

  // ------------------------------------------------------------
  // TIMESTAMPS
  // ------------------------------------------------------------

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Visit({
    required this.visitId,
    required this.customerUid,
    this.leadId,
    required this.visitType,
    required this.status,
    required this.createdBy,
    required this.assignedTo,
    this.scheduledAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.missedAt,
    this.latitude,
    this.longitude,
    this.address,
    this.city,
    this.area,
    this.placeId,
    this.mapsUrl,
    this.photos = const [],
    this.purpose,
    this.outcome,
    this.notes,
    this.nextFollowUpAt,
    this.createLead = true,
    this.leadCreated = false,
    this.createdAt,
    this.updatedAt,
  });

  // ============================================================
  // FIRESTORE → MODEL
  // ============================================================

  factory Visit.fromMap(
    String visitId,
    Map<String, dynamic> data,
  ) {
    return Visit(
      visitId: visitId,

      customerUid:
          data['customerUid'] as String? ?? '',

      leadId:
          data['leadId'] as String?,

      visitType:
          visitTypeFromString(
            data['visitType'] as String?,
          ),

      status:
          visitStatusFromString(
            data['status'] as String?,
          ),

      createdBy:
          data['createdBy'] as String? ?? '',

      assignedTo:
          data['assignedTo'] as String? ?? '',

      scheduledAt:
          _toDateTime(data['scheduledAt']),

      startedAt:
          _toDateTime(data['startedAt']),

      completedAt:
          _toDateTime(data['completedAt']),

      cancelledAt:
          _toDateTime(data['cancelledAt']),

      missedAt:
          _toDateTime(data['missedAt']),

      latitude:
          _toDouble(data['latitude']),

      longitude:
          _toDouble(data['longitude']),

      address:
          data['address'] as String?,

      city:
          data['city'] as String?,

      area:
          data['area'] as String?,

      placeId:
          data['placeId'] as String?,

      mapsUrl:
          data['mapsUrl'] as String?,

      photos:
          _toStringList(data['photos']),

      purpose:
          data['purpose'] as String?,

      outcome:
          visitOutcomeFromString(
            data['outcome'] as String?,
          ),

      notes:
          data['notes'] as String?,

      nextFollowUpAt:
          _toDateTime(data['nextFollowUpAt']),

      createLead:
          data['createLead'] as bool? ?? true,

      leadCreated:
          data['leadCreated'] as bool? ?? false,

      createdAt:
          _toDateTime(data['createdAt']),

      updatedAt:
          _toDateTime(data['updatedAt']),
    );
  }

  // ============================================================
  // MODEL → FIRESTORE
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'customerUid': customerUid,

      'leadId': leadId,

      'visitType':
          visitTypeToString(visitType),

      'status':
          visitStatusToString(status),

      'createdBy': createdBy,

      'assignedTo': assignedTo,

      'scheduledAt':
          _toTimestamp(scheduledAt),

      'startedAt':
          _toTimestamp(startedAt),

      'completedAt':
          _toTimestamp(completedAt),

      'cancelledAt':
          _toTimestamp(cancelledAt),

      'missedAt':
          _toTimestamp(missedAt),

      'latitude': latitude,

      'longitude': longitude,

      'address': address,

      'city': city,

      'area': area,

      'placeId': placeId,

      'mapsUrl': mapsUrl,

      'photos': photos,

      'purpose': purpose,

      'outcome':
          outcome == null
              ? null
              : visitOutcomeToString(
                  outcome!,
                ),

      'notes': notes,

      'nextFollowUpAt':
          _toTimestamp(nextFollowUpAt),

      'createLead': createLead,

      'leadCreated': leadCreated,

      'createdAt':
          _toTimestamp(createdAt),

      'updatedAt':
          _toTimestamp(updatedAt),
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  Visit copyWith({
    String? visitId,
    String? customerUid,
    String? leadId,
    VisitType? visitType,
    VisitStatus? status,
    String? createdBy,
    String? assignedTo,
    DateTime? scheduledAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    DateTime? missedAt,
    double? latitude,
    double? longitude,
    String? address,
    String? city,
    String? area,
    String? placeId,
    String? mapsUrl,
    List<String>? photos,
    String? purpose,
    VisitOutcome? outcome,
    String? notes,
    DateTime? nextFollowUpAt,
    bool? createLead,
    bool? leadCreated,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Visit(
      visitId: visitId ?? this.visitId,

      customerUid:
          customerUid ?? this.customerUid,

      leadId:
          leadId ?? this.leadId,

      visitType:
          visitType ?? this.visitType,

      status:
          status ?? this.status,

      createdBy:
          createdBy ?? this.createdBy,

      assignedTo:
          assignedTo ?? this.assignedTo,

      scheduledAt:
          scheduledAt ?? this.scheduledAt,

      startedAt:
          startedAt ?? this.startedAt,

      completedAt:
          completedAt ?? this.completedAt,

      cancelledAt:
          cancelledAt ?? this.cancelledAt,

      missedAt:
          missedAt ?? this.missedAt,

      latitude:
          latitude ?? this.latitude,

      longitude:
          longitude ?? this.longitude,

      address:
          address ?? this.address,

      city:
          city ?? this.city,

      area:
          area ?? this.area,

      placeId:
          placeId ?? this.placeId,

      mapsUrl:
          mapsUrl ?? this.mapsUrl,

      photos:
          photos ?? this.photos,

      purpose:
          purpose ?? this.purpose,

      outcome:
          outcome ?? this.outcome,

      notes:
          notes ?? this.notes,

      nextFollowUpAt:
          nextFollowUpAt ?? this.nextFollowUpAt,

      createLead:
          createLead ?? this.createLead,

      leadCreated:
          leadCreated ?? this.leadCreated,

      createdAt:
          createdAt ?? this.createdAt,

      updatedAt:
          updatedAt ?? this.updatedAt,
    );
  }
}

// ================================================================
// VISIT TYPE
// ================================================================

String visitTypeToString(
  VisitType type,
) {
  switch (type) {
    case VisitType.selfAdded:
      return 'SELF_ADDED';

    case VisitType.scheduled:
      return 'SCHEDULED';
  }
}

VisitType visitTypeFromString(
  String? value,
) {
  switch (value) {
    case 'SCHEDULED':
      return VisitType.scheduled;

    case 'SELF_ADDED':
    default:
      return VisitType.selfAdded;
  }
}

// ================================================================
// VISIT STATUS
// ================================================================

String visitStatusToString(
  VisitStatus status,
) {
  switch (status) {
    case VisitStatus.planned:
      return 'PLANNED';

    case VisitStatus.inProgress:
      return 'IN_PROGRESS';

    case VisitStatus.completed:
      return 'COMPLETED';

    case VisitStatus.cancelled:
      return 'CANCELLED';

    case VisitStatus.missed:
      return 'MISSED';
  }
}

VisitStatus visitStatusFromString(
  String? value,
) {
  switch (value) {
    case 'IN_PROGRESS':
      return VisitStatus.inProgress;

    case 'COMPLETED':
      return VisitStatus.completed;

    case 'CANCELLED':
      return VisitStatus.cancelled;

    case 'MISSED':
      return VisitStatus.missed;

    case 'PLANNED':
    default:
      return VisitStatus.planned;
  }
}

// ================================================================
// VISIT OUTCOME
// ================================================================

String visitOutcomeToString(
  VisitOutcome outcome,
) {
  switch (outcome) {
    case VisitOutcome.interested:
      return 'INTERESTED';

    case VisitOutcome.notInterested:
      return 'NOT_INTERESTED';

    case VisitOutcome.followUpRequired:
      return 'FOLLOW_UP_REQUIRED';

    case VisitOutcome.demoRequested:
      return 'DEMO_REQUESTED';

    case VisitOutcome.proposalRequested:
      return 'PROPOSAL_REQUESTED';

    case VisitOutcome.noResponse:
      return 'NO_RESPONSE';

    case VisitOutcome.notAvailable:
      return 'NOT_AVAILABLE';

    case VisitOutcome.converted:
      return 'CONVERTED';

    case VisitOutcome.other:
      return 'OTHER';
  }
}

VisitOutcome? visitOutcomeFromString(
  String? value,
) {
  switch (value) {
    case 'INTERESTED':
      return VisitOutcome.interested;

    case 'NOT_INTERESTED':
      return VisitOutcome.notInterested;

    case 'FOLLOW_UP_REQUIRED':
      return VisitOutcome.followUpRequired;

    case 'DEMO_REQUESTED':
      return VisitOutcome.demoRequested;

    case 'PROPOSAL_REQUESTED':
      return VisitOutcome.proposalRequested;

    case 'NO_RESPONSE':
      return VisitOutcome.noResponse;

    case 'NOT_AVAILABLE':
      return VisitOutcome.notAvailable;

    case 'CONVERTED':
      return VisitOutcome.converted;

    case 'OTHER':
      return VisitOutcome.other;

    default:
      return null;
  }
}

// ================================================================
// FIRESTORE HELPERS
// ================================================================

double? _toDouble(
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

DateTime? _toDateTime(
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

  return null;
}

Timestamp? _toTimestamp(
  DateTime? value,
) {
  if (value == null) {
    return null;
  }

  return Timestamp.fromDate(value);
}

List<String> _toStringList(
  dynamic value,
) {
  if (value is! List) {
    return [];
  }

  return value
      .where(
        (item) => item != null,
      )
      .map(
        (item) => item.toString(),
      )
      .toList();
}