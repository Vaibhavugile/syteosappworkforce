import 'package:cloud_firestore/cloud_firestore.dart';

enum LeadStatus {
  newLead,
  contacted,
  interested,
  followUp,
  visitScheduled,
  visitCompleted,
  demo,
  proposal,
  negotiation,
  won,
  lost,
  notInterested,
  invalid,
}

enum LeadSource {
  selfVisit,
  scheduledVisit,
  call,
  website,
  referral,
  manual,
  other,
}

enum LeadPriority {
  low,
  medium,
  high,
}

class Lead {
  final String leadId;

  // ------------------------------------------------------------
  // PERMANENT BUSINESS / CUSTOMER ID
  // ------------------------------------------------------------
  final String customerUid;

  // ------------------------------------------------------------
  // BUSINESS INFORMATION
  // ------------------------------------------------------------
  final String businessName;
  final String category;

  final String contactPerson;
  final String phone;
  final String? alternatePhone;
  final String? email;

  // ------------------------------------------------------------
  // LOCATION
  // ------------------------------------------------------------
  final String? address;
  final String? city;
  final String? area;

  final double? latitude;
  final double? longitude;

  final String? placeId;
  final String? mapsUrl;

  // ------------------------------------------------------------
  // MEDIA
  // ------------------------------------------------------------
  final List<String> photos;

  // ------------------------------------------------------------
  // SALES INFORMATION
  // ------------------------------------------------------------
  final LeadStatus status;
  final LeadSource source;
  final LeadPriority priority;

  // ------------------------------------------------------------
  // OWNERSHIP
  // ------------------------------------------------------------
  final String createdBy;
  final String assignedTo;

  // ------------------------------------------------------------
  // NOTES / FOLLOW-UP
  // ------------------------------------------------------------
  final String? notes;
  final DateTime? nextFollowUpAt;

  // ------------------------------------------------------------
  // TIMESTAMPS
  // ------------------------------------------------------------
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ------------------------------------------------------------
  // ACTIVE FLAG
  // ------------------------------------------------------------
  final bool isActive;

  const Lead({
    required this.leadId,
    required this.customerUid,
    required this.businessName,
    required this.category,
    required this.contactPerson,
    required this.phone,
    this.alternatePhone,
    this.email,
    this.address,
    this.city,
    this.area,
    this.latitude,
    this.longitude,
    this.placeId,
    this.mapsUrl,
    this.photos = const [],
    required this.status,
    required this.source,
    this.priority = LeadPriority.medium,
    required this.createdBy,
    required this.assignedTo,
    this.notes,
    this.nextFollowUpAt,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  // ============================================================
  // FIRESTORE → MODEL
  // ============================================================

  factory Lead.fromMap(
    String leadId,
    Map<String, dynamic> data,
  ) {
    return Lead(
      leadId: leadId,

      customerUid:
          data['customerUid'] as String? ?? '',

      businessName:
          data['businessName'] as String? ?? '',

      category:
          data['category'] as String? ?? '',

      contactPerson:
          data['contactPerson'] as String? ?? '',

      phone:
          data['phone'] as String? ?? '',

      alternatePhone:
          data['alternatePhone'] as String?,

      email:
          data['email'] as String?,

      address:
          data['address'] as String?,

      city:
          data['city'] as String?,

      area:
          data['area'] as String?,

      latitude:
          _toDouble(data['latitude']),

      longitude:
          _toDouble(data['longitude']),

      placeId:
          data['placeId'] as String?,

      mapsUrl:
          data['mapsUrl'] as String?,

      photos:
          _toStringList(data['photos']),

      status:
          leadStatusFromString(
            data['status'] as String?,
          ),

      source:
          leadSourceFromString(
            data['source'] as String?,
          ),

      priority:
          leadPriorityFromString(
            data['priority'] as String?,
          ),

      createdBy:
          data['createdBy'] as String? ?? '',

      assignedTo:
          data['assignedTo'] as String? ?? '',

      notes:
          data['notes'] as String?,

      nextFollowUpAt:
          _toDateTime(data['nextFollowUpAt']),

      createdAt:
          _toDateTime(data['createdAt']),

      updatedAt:
          _toDateTime(data['updatedAt']),

      isActive:
          data['isActive'] as bool? ?? true,
    );
  }

  // ============================================================
  // MODEL → FIRESTORE
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'customerUid': customerUid,

      'businessName': businessName,
      'category': category,

      'contactPerson': contactPerson,
      'phone': phone,
      'alternatePhone': alternatePhone,
      'email': email,

      'address': address,
      'city': city,
      'area': area,

      'latitude': latitude,
      'longitude': longitude,

      'placeId': placeId,
      'mapsUrl': mapsUrl,

      'photos': photos,

      'status': leadStatusToString(status),
      'source': leadSourceToString(source),
      'priority': leadPriorityToString(priority),

      'createdBy': createdBy,
      'assignedTo': assignedTo,

      'notes': notes,

      'nextFollowUpAt':
          nextFollowUpAt == null
              ? null
              : Timestamp.fromDate(
                  nextFollowUpAt!,
                ),

      'createdAt':
          createdAt == null
              ? null
              : Timestamp.fromDate(
                  createdAt!,
                ),

      'updatedAt':
          updatedAt == null
              ? null
              : Timestamp.fromDate(
                  updatedAt!,
                ),

      'isActive': isActive,
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  Lead copyWith({
    String? leadId,
    String? customerUid,
    String? businessName,
    String? category,
    String? contactPerson,
    String? phone,
    String? alternatePhone,
    String? email,
    String? address,
    String? city,
    String? area,
    double? latitude,
    double? longitude,
    String? placeId,
    String? mapsUrl,
    List<String>? photos,
    LeadStatus? status,
    LeadSource? source,
    LeadPriority? priority,
    String? createdBy,
    String? assignedTo,
    String? notes,
    DateTime? nextFollowUpAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Lead(
      leadId: leadId ?? this.leadId,
      customerUid:
          customerUid ?? this.customerUid,

      businessName:
          businessName ?? this.businessName,

      category:
          category ?? this.category,

      contactPerson:
          contactPerson ?? this.contactPerson,

      phone:
          phone ?? this.phone,

      alternatePhone:
          alternatePhone ?? this.alternatePhone,

      email:
          email ?? this.email,

      address:
          address ?? this.address,

      city:
          city ?? this.city,

      area:
          area ?? this.area,

      latitude:
          latitude ?? this.latitude,

      longitude:
          longitude ?? this.longitude,

      placeId:
          placeId ?? this.placeId,

      mapsUrl:
          mapsUrl ?? this.mapsUrl,

      photos:
          photos ?? this.photos,

      status:
          status ?? this.status,

      source:
          source ?? this.source,

      priority:
          priority ?? this.priority,

      createdBy:
          createdBy ?? this.createdBy,

      assignedTo:
          assignedTo ?? this.assignedTo,

      notes:
          notes ?? this.notes,

      nextFollowUpAt:
          nextFollowUpAt ?? this.nextFollowUpAt,

      createdAt:
          createdAt ?? this.createdAt,

      updatedAt:
          updatedAt ?? this.updatedAt,

      isActive:
          isActive ?? this.isActive,
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static double? _toDouble(
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

  static DateTime? _toDateTime(
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

  static List<String> _toStringList(
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
}

// ================================================================
// LEAD STATUS CONVERSION
// ================================================================

String leadStatusToString(
  LeadStatus status,
) {
  switch (status) {
    case LeadStatus.newLead:
      return 'NEW';

    case LeadStatus.contacted:
      return 'CONTACTED';

    case LeadStatus.interested:
      return 'INTERESTED';

    case LeadStatus.followUp:
      return 'FOLLOW_UP';

    case LeadStatus.visitScheduled:
      return 'VISIT_SCHEDULED';

    case LeadStatus.visitCompleted:
      return 'VISIT_COMPLETED';

    case LeadStatus.demo:
      return 'DEMO';

    case LeadStatus.proposal:
      return 'PROPOSAL';

    case LeadStatus.negotiation:
      return 'NEGOTIATION';

    case LeadStatus.won:
      return 'WON';

    case LeadStatus.lost:
      return 'LOST';

    case LeadStatus.notInterested:
      return 'NOT_INTERESTED';

    case LeadStatus.invalid:
      return 'INVALID';
  }
}

LeadStatus leadStatusFromString(
  String? value,
) {
  switch (value) {
    case 'CONTACTED':
      return LeadStatus.contacted;

    case 'INTERESTED':
      return LeadStatus.interested;

    case 'FOLLOW_UP':
      return LeadStatus.followUp;

    case 'VISIT_SCHEDULED':
      return LeadStatus.visitScheduled;

    case 'VISIT_COMPLETED':
      return LeadStatus.visitCompleted;

    case 'DEMO':
      return LeadStatus.demo;

    case 'PROPOSAL':
      return LeadStatus.proposal;

    case 'NEGOTIATION':
      return LeadStatus.negotiation;

    case 'WON':
      return LeadStatus.won;

    case 'LOST':
      return LeadStatus.lost;

    case 'NOT_INTERESTED':
      return LeadStatus.notInterested;

    case 'INVALID':
      return LeadStatus.invalid;

    case 'NEW':
    default:
      return LeadStatus.newLead;
  }
}

// ================================================================
// LEAD SOURCE CONVERSION
// ================================================================

String leadSourceToString(
  LeadSource source,
) {
  switch (source) {
    case LeadSource.selfVisit:
      return 'SELF_VISIT';

    case LeadSource.scheduledVisit:
      return 'SCHEDULED_VISIT';

    case LeadSource.call:
      return 'CALL';

    case LeadSource.website:
      return 'WEBSITE';

    case LeadSource.referral:
      return 'REFERRAL';

    case LeadSource.manual:
      return 'MANUAL';

    case LeadSource.other:
      return 'OTHER';
  }
}

LeadSource leadSourceFromString(
  String? value,
) {
  switch (value) {
    case 'SELF_VISIT':
      return LeadSource.selfVisit;

    case 'SCHEDULED_VISIT':
      return LeadSource.scheduledVisit;

    case 'CALL':
      return LeadSource.call;

    case 'WEBSITE':
      return LeadSource.website;

    case 'REFERRAL':
      return LeadSource.referral;

    case 'MANUAL':
      return LeadSource.manual;

    case 'OTHER':
    default:
      return LeadSource.other;
  }
}

// ================================================================
// LEAD PRIORITY CONVERSION
// ================================================================

String leadPriorityToString(
  LeadPriority priority,
) {
  switch (priority) {
    case LeadPriority.low:
      return 'LOW';

    case LeadPriority.medium:
      return 'MEDIUM';

    case LeadPriority.high:
      return 'HIGH';
  }
}

LeadPriority leadPriorityFromString(
  String? value,
) {
  switch (value) {
    case 'LOW':
      return LeadPriority.low;

    case 'HIGH':
      return LeadPriority.high;

    case 'MEDIUM':
    default:
      return LeadPriority.medium;
  }
}