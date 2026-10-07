import 'package:flutter/foundation.dart';

import 'invitation_event.dart';
import 'invitation_photo.dart';

@immutable
class InvitationModel {
  final String id;
  final String userId;

  /// Selected template and theme.
  final String templateId;
  final String themeId;

  // ---------------------------------------------------------------------------
  // COUPLE
  // ---------------------------------------------------------------------------

  final String brideName;
  final String groomName;

  final String brideDescription;
  final String groomDescription;

  // ---------------------------------------------------------------------------
  // WEDDING
  // ---------------------------------------------------------------------------

  final String weddingDate;
  final String weddingTime;

  // ---------------------------------------------------------------------------
  // STORY
  // ---------------------------------------------------------------------------

  final String storyTitle;
  final String storyText;

  // ---------------------------------------------------------------------------
  // VENUE
  // ---------------------------------------------------------------------------

  final String venueName;
  final String venueAddress;

  final double? venueLatitude;
  final double? venueLongitude;

  // ---------------------------------------------------------------------------
  // EVENTS
  // ---------------------------------------------------------------------------

  final List<InvitationEvent> events;

  // ---------------------------------------------------------------------------
  // PHOTOS
  // ---------------------------------------------------------------------------

  final List<InvitationPhoto> photos;

  // ---------------------------------------------------------------------------
  // FEATURES
  // ---------------------------------------------------------------------------

  final bool countdownEnabled;
  final bool rsvpEnabled;
  final bool musicEnabled;

  final String? musicId;

  // ---------------------------------------------------------------------------
  // PUBLISHING
  // ---------------------------------------------------------------------------

  final bool published;

  /// Public URL slug.
  ///
  /// Example:
  /// ananya-and-rohan
  final String slug;

  // ---------------------------------------------------------------------------
  // TIMESTAMPS
  // ---------------------------------------------------------------------------

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const InvitationModel({
    required this.id,
    required this.userId,
    required this.templateId,
    required this.themeId,
    this.brideName = '',
    this.groomName = '',
    this.brideDescription = '',
    this.groomDescription = '',
    this.weddingDate = '',
    this.weddingTime = '',
    this.storyTitle = '',
    this.storyText = '',
    this.venueName = '',
    this.venueAddress = '',
    this.venueLatitude,
    this.venueLongitude,
    this.events = const [],
    this.photos = const [],
    this.countdownEnabled = true,
    this.rsvpEnabled = true,
    this.musicEnabled = false,
    this.musicId,
    this.published = false,
    this.slug = '',
    this.createdAt,
    this.updatedAt,
  });

  // ===========================================================================
  // PHOTO HELPERS
  // ===========================================================================

  InvitationPhoto? get bridePhoto {
    for (final photo in photos) {
      if (photo.type == InvitationPhotoType.bride) {
        return photo;
      }
    }

    return null;
  }

  InvitationPhoto? get groomPhoto {
    for (final photo in photos) {
      if (photo.type == InvitationPhotoType.groom) {
        return photo;
      }
    }

    return null;
  }

  InvitationPhoto? get couplePhoto {
    for (final photo in photos) {
      if (photo.type == InvitationPhotoType.couple) {
        return photo;
      }
    }

    return null;
  }

  InvitationPhoto? get venuePhoto {
    for (final photo in photos) {
      if (photo.type == InvitationPhotoType.venue) {
        return photo;
      }
    }

    return null;
  }

  List<InvitationPhoto> get storyPhotos {
    final result = photos
        .where(
          (photo) =>
              photo.type == InvitationPhotoType.story,
        )
        .toList();

    result.sort(
      (a, b) => a.order.compareTo(b.order),
    );

    return result;
  }

  List<InvitationPhoto> get galleryPhotos {
    final result = photos
        .where(
          (photo) =>
              photo.type == InvitationPhotoType.gallery,
        )
        .toList();

    result.sort(
      (a, b) => a.order.compareTo(b.order),
    );

    return result;
  }

  // ===========================================================================
  // EVENT HELPERS
  // ===========================================================================

  List<InvitationEvent> get enabledEvents {
    return events
        .where((event) => event.enabled)
        .toList();
  }

  // ===========================================================================
  // COPY WITH
  // ===========================================================================

  InvitationModel copyWith({
    String? id,
    String? userId,
    String? templateId,
    String? themeId,
    String? brideName,
    String? groomName,
    String? brideDescription,
    String? groomDescription,
    String? weddingDate,
    String? weddingTime,
    String? storyTitle,
    String? storyText,
    String? venueName,
    String? venueAddress,
    double? venueLatitude,
    double? venueLongitude,
    List<InvitationEvent>? events,
    List<InvitationPhoto>? photos,
    bool? countdownEnabled,
    bool? rsvpEnabled,
    bool? musicEnabled,
    String? musicId,
    bool? published,
    String? slug,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InvitationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      templateId: templateId ?? this.templateId,
      themeId: themeId ?? this.themeId,
      brideName: brideName ?? this.brideName,
      groomName: groomName ?? this.groomName,
      brideDescription:
          brideDescription ?? this.brideDescription,
      groomDescription:
          groomDescription ?? this.groomDescription,
      weddingDate:
          weddingDate ?? this.weddingDate,
      weddingTime:
          weddingTime ?? this.weddingTime,
      storyTitle:
          storyTitle ?? this.storyTitle,
      storyText:
          storyText ?? this.storyText,
      venueName:
          venueName ?? this.venueName,
      venueAddress:
          venueAddress ?? this.venueAddress,
      venueLatitude:
          venueLatitude ?? this.venueLatitude,
      venueLongitude:
          venueLongitude ?? this.venueLongitude,
      events:
          events ?? List<InvitationEvent>.from(this.events),
      photos:
          photos ?? List<InvitationPhoto>.from(this.photos),
      countdownEnabled:
          countdownEnabled ?? this.countdownEnabled,
      rsvpEnabled:
          rsvpEnabled ?? this.rsvpEnabled,
      musicEnabled:
          musicEnabled ?? this.musicEnabled,
      musicId:
          musicId ?? this.musicId,
      published:
          published ?? this.published,
      slug:
          slug ?? this.slug,
      createdAt:
          createdAt ?? this.createdAt,
      updatedAt:
          updatedAt ?? this.updatedAt,
    );
  }

  // ===========================================================================
  // FIRESTORE SERIALIZATION
  // ===========================================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'templateId': templateId,
      'themeId': themeId,

      'brideName': brideName,
      'groomName': groomName,

      'brideDescription': brideDescription,
      'groomDescription': groomDescription,

      'weddingDate': weddingDate,
      'weddingTime': weddingTime,

      'storyTitle': storyTitle,
      'storyText': storyText,

      'venueName': venueName,
      'venueAddress': venueAddress,
      'venueLatitude': venueLatitude,
      'venueLongitude': venueLongitude,

      'events': events
          .map((event) => event.toMap())
          .toList(),

      'photos': photos
          .map((photo) => photo.toMap())
          .toList(),

      'countdownEnabled': countdownEnabled,
      'rsvpEnabled': rsvpEnabled,
      'musicEnabled': musicEnabled,
      'musicId': musicId,

      'published': published,
      'slug': slug,

      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // ===========================================================================
  // FROM MAP
  // ===========================================================================

  factory InvitationModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return InvitationModel(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',

      templateId:
          map['templateId']?.toString() ?? '',

      themeId:
          map['themeId']?.toString() ?? '',

      brideName:
          map['brideName']?.toString() ?? '',

      groomName:
          map['groomName']?.toString() ?? '',

      brideDescription:
          map['brideDescription']?.toString() ?? '',

      groomDescription:
          map['groomDescription']?.toString() ?? '',

      weddingDate:
          map['weddingDate']?.toString() ?? '',

      weddingTime:
          map['weddingTime']?.toString() ?? '',

      storyTitle:
          map['storyTitle']?.toString() ?? '',

      storyText:
          map['storyText']?.toString() ?? '',

      venueName:
          map['venueName']?.toString() ?? '',

      venueAddress:
          map['venueAddress']?.toString() ?? '',

      venueLatitude:
          (map['venueLatitude'] as num?)?.toDouble(),

      venueLongitude:
          (map['venueLongitude'] as num?)?.toDouble(),

      events:
          _eventsFromMap(map['events']),

      photos:
          _photosFromMap(map['photos']),

      countdownEnabled:
          map['countdownEnabled'] is bool
              ? map['countdownEnabled'] as bool
              : true,

      rsvpEnabled:
          map['rsvpEnabled'] is bool
              ? map['rsvpEnabled'] as bool
              : true,

      musicEnabled:
          map['musicEnabled'] is bool
              ? map['musicEnabled'] as bool
              : false,

      musicId:
          map['musicId']?.toString(),

      published:
          map['published'] is bool
              ? map['published'] as bool
              : false,

      slug:
          map['slug']?.toString() ?? '',

      createdAt:
          _dateTimeFromMap(map['createdAt']),

      updatedAt:
          _dateTimeFromMap(map['updatedAt']),
    );
  }

  // ===========================================================================
  // MAP HELPERS
  // ===========================================================================

  static List<InvitationEvent> _eventsFromMap(
    dynamic value,
  ) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map(
          (item) => InvitationEvent.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  static List<InvitationPhoto> _photosFromMap(
    dynamic value,
  ) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map(
          (item) => InvitationPhoto.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  static DateTime? _dateTimeFromMap(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    // Supports Firestore Timestamp without
    // directly importing cloud_firestore here.
    try {
      final dynamic timestamp = value;

      final dynamic dateTime =
          timestamp.toDate();

      if (dateTime is DateTime) {
        return dateTime;
      }
    } catch (_) {
      // Invalid timestamp.
    }

    return null;
  }

  // ===========================================================================
  // VALIDATION HELPERS
  // ===========================================================================

  bool get hasCoupleNames {
    return brideName.trim().isNotEmpty &&
        groomName.trim().isNotEmpty;
  }

  bool get hasWeddingDate {
    return weddingDate.trim().isNotEmpty;
  }

  bool get hasVenue {
    return venueName.trim().isNotEmpty;
  }

  bool get hasEvents {
    return enabledEvents.isNotEmpty;
  }

  bool get hasPhotos {
    return photos.isNotEmpty;
  }

  bool get canPublish {
    return id.trim().isNotEmpty &&
        userId.trim().isNotEmpty &&
        templateId.trim().isNotEmpty &&
        hasCoupleNames &&
        hasWeddingDate &&
        hasVenue;
  }

  @override
  String toString() {
    return 'InvitationModel('
        'id: $id, '
        'userId: $userId, '
        'templateId: $templateId, '
        'brideName: $brideName, '
        'groomName: $groomName, '
        'published: $published'
        ')';
  }
}