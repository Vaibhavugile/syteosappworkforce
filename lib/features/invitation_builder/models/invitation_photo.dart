import 'package:flutter/foundation.dart';

enum InvitationPhotoType {
  bride,
  groom,
  couple,
  story,
  gallery,
  venue,
}

@immutable
class InvitationPhoto {
  final String id;

  /// Firebase Storage download URL.
  final String url;

  /// Type of photo used in the invitation.
  final InvitationPhotoType type;

  /// Temporary local optimized image path.
  ///
  /// This is used while the image is being uploaded.
  /// It should normally not be persisted permanently.
  final String? localPath;

  /// Display order for story/gallery photos.
  final int order;

  const InvitationPhoto({
    required this.id,
    required this.url,
    required this.type,
    this.localPath,
    this.order = 0,
  });

  InvitationPhoto copyWith({
    String? id,
    String? url,
    InvitationPhotoType? type,
    String? localPath,
    int? order,
  }) {
    return InvitationPhoto(
      id: id ?? this.id,
      url: url ?? this.url,
      type: type ?? this.type,
      localPath: localPath ?? this.localPath,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'type': type.name,
      'localPath': localPath,
      'order': order,
    };
  }

  factory InvitationPhoto.fromMap(
    Map<String, dynamic> map,
  ) {
    final String typeName =
        map['type']?.toString() ?? 'gallery';

    final InvitationPhotoType type =
        InvitationPhotoType.values.firstWhere(
      (value) => value.name == typeName,
      orElse: () => InvitationPhotoType.gallery,
    );

    return InvitationPhoto(
      id: map['id']?.toString() ?? '',
      url: map['url']?.toString() ?? '',
      type: type,
      localPath: map['localPath']?.toString(),
      order: (map['order'] as num?)?.toInt() ?? 0,
    );
  }

  bool get hasUploadedUrl {
    return url.trim().isNotEmpty;
  }

  bool get hasLocalFile {
    return localPath != null &&
        localPath!.trim().isNotEmpty;
  }

  bool get isBridePhoto {
    return type == InvitationPhotoType.bride;
  }

  bool get isGroomPhoto {
    return type == InvitationPhotoType.groom;
  }

  bool get isCouplePhoto {
    return type == InvitationPhotoType.couple;
  }

  bool get isStoryPhoto {
    return type == InvitationPhotoType.story;
  }

  bool get isGalleryPhoto {
    return type == InvitationPhotoType.gallery;
  }

  bool get isVenuePhoto {
    return type == InvitationPhotoType.venue;
  }

  @override
  String toString() {
    return 'InvitationPhoto('
        'id: $id, '
        'type: ${type.name}, '
        'order: $order, '
        'hasUploadedUrl: $hasUploadedUrl'
        ')';
  }
}