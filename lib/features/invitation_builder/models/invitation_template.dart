import 'package:flutter/foundation.dart';

enum InvitationCategory {
  floral,
  royal,
  traditional,
  romantic,
  luxury,
  modern,
}

enum InvitationAnimation {
  fadeIn,
  fadeUp,
  scaleIn,
  imageReveal,
  flowerBloom,
  petalFall,
  parallax,
  cardTilt,
  curtainOpen,
  envelopeOpen,
}

enum GalleryStyle {
  grid,
  masonry,
  slider,
  cinematic,
}

@immutable
class InvitationTemplate {
  final String id;
  final String name;
  final String description;

  /// Template category.
  final InvitationCategory category;

  /// Small preview image shown in the template selector.
  final String previewAsset;

  /// Main hero/background asset.
  final String heroBackgroundAsset;

  /// ID of the theme used by this template.
  final String themeId;

  /// Ordered list of sections used by this template.
  final List<String> sections;

  /// Gallery layout.
  final GalleryStyle galleryStyle;

  /// Animation configuration.
  final InvitationAnimation heroAnimation;
  final InvitationAnimation textAnimation;
  final InvitationAnimation photoAnimation;
  final InvitationAnimation backgroundAnimation;

  /// Optional premium effects.
  final bool enablePetals;
  final bool enableParallax;
  final bool enable3DTilt;

  const InvitationTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.previewAsset,
    required this.heroBackgroundAsset,
    required this.themeId,
    required this.sections,
    required this.galleryStyle,
    required this.heroAnimation,
    required this.textAnimation,
    required this.photoAnimation,
    required this.backgroundAnimation,
    this.enablePetals = false,
    this.enableParallax = false,
    this.enable3DTilt = false,
  });

  InvitationTemplate copyWith({
    String? id,
    String? name,
    String? description,
    InvitationCategory? category,
    String? previewAsset,
    String? heroBackgroundAsset,
    String? themeId,
    List<String>? sections,
    GalleryStyle? galleryStyle,
    InvitationAnimation? heroAnimation,
    InvitationAnimation? textAnimation,
    InvitationAnimation? photoAnimation,
    InvitationAnimation? backgroundAnimation,
    bool? enablePetals,
    bool? enableParallax,
    bool? enable3DTilt,
  }) {
    return InvitationTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      previewAsset:
          previewAsset ?? this.previewAsset,
      heroBackgroundAsset:
          heroBackgroundAsset ??
          this.heroBackgroundAsset,
      themeId: themeId ?? this.themeId,
      sections:
          sections ?? List<String>.from(this.sections),
      galleryStyle:
          galleryStyle ?? this.galleryStyle,
      heroAnimation:
          heroAnimation ?? this.heroAnimation,
      textAnimation:
          textAnimation ?? this.textAnimation,
      photoAnimation:
          photoAnimation ?? this.photoAnimation,
      backgroundAnimation:
          backgroundAnimation ??
          this.backgroundAnimation,
      enablePetals:
          enablePetals ?? this.enablePetals,
      enableParallax:
          enableParallax ?? this.enableParallax,
      enable3DTilt:
          enable3DTilt ?? this.enable3DTilt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.name,
      'previewAsset': previewAsset,
      'heroBackgroundAsset': heroBackgroundAsset,
      'themeId': themeId,
      'sections': sections,
      'galleryStyle': galleryStyle.name,
      'heroAnimation': heroAnimation.name,
      'textAnimation': textAnimation.name,
      'photoAnimation': photoAnimation.name,
      'backgroundAnimation':
          backgroundAnimation.name,
      'enablePetals': enablePetals,
      'enableParallax': enableParallax,
      'enable3DTilt': enable3DTilt,
    };
  }

  factory InvitationTemplate.fromMap(
    Map<String, dynamic> map,
  ) {
    final categoryName =
        map['category']?.toString() ?? 'floral';

    final galleryStyleName =
        map['galleryStyle']?.toString() ?? 'grid';

    final heroAnimationName =
        map['heroAnimation']?.toString() ?? 'fadeIn';

    final textAnimationName =
        map['textAnimation']?.toString() ?? 'fadeUp';

    final photoAnimationName =
        map['photoAnimation']?.toString() ??
        'imageReveal';

    final backgroundAnimationName =
        map['backgroundAnimation']?.toString() ??
        'parallax';

    return InvitationTemplate(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description:
          map['description']?.toString() ?? '',
      category:
          _categoryFromString(categoryName),
      previewAsset:
          map['previewAsset']?.toString() ?? '',
      heroBackgroundAsset:
          map['heroBackgroundAsset']?.toString() ??
          '',
      themeId:
          map['themeId']?.toString() ?? '',
      sections:
          _sectionsFromMap(map['sections']),
      galleryStyle:
          _galleryStyleFromString(
        galleryStyleName,
      ),
      heroAnimation:
          _animationFromString(
        heroAnimationName,
        InvitationAnimation.fadeIn,
      ),
      textAnimation:
          _animationFromString(
        textAnimationName,
        InvitationAnimation.fadeUp,
      ),
      photoAnimation:
          _animationFromString(
        photoAnimationName,
        InvitationAnimation.imageReveal,
      ),
      backgroundAnimation:
          _animationFromString(
        backgroundAnimationName,
        InvitationAnimation.parallax,
      ),
      enablePetals:
          map['enablePetals'] is bool
              ? map['enablePetals'] as bool
              : false,
      enableParallax:
          map['enableParallax'] is bool
              ? map['enableParallax'] as bool
              : false,
      enable3DTilt:
          map['enable3DTilt'] is bool
              ? map['enable3DTilt'] as bool
              : false,
    );
  }

  static InvitationCategory _categoryFromString(
    String value,
  ) {
    return InvitationCategory.values.firstWhere(
      (item) => item.name == value,
      orElse: () => InvitationCategory.floral,
    );
  }

  static GalleryStyle _galleryStyleFromString(
    String value,
  ) {
    return GalleryStyle.values.firstWhere(
      (item) => item.name == value,
      orElse: () => GalleryStyle.grid,
    );
  }

  static InvitationAnimation _animationFromString(
    String value,
    InvitationAnimation fallback,
  ) {
    return InvitationAnimation.values.firstWhere(
      (item) => item.name == value,
      orElse: () => fallback,
    );
  }

  static List<String> _sectionsFromMap(
    dynamic value,
  ) {
    if (value is! List) {
      return const [];
    }

    return value
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  bool hasSection(String sectionId) {
    return sections.contains(sectionId);
  }

  bool get hasGallery {
    return hasSection('gallery');
  }

  bool get hasEvents {
    return hasSection('events');
  }

  bool get hasStory {
    return hasSection('story');
  }

  bool get hasVenue {
    return hasSection('venue');
  }

  bool get hasRsvp {
    return hasSection('rsvp');
  }

  bool get hasCountdown {
    return hasSection('countdown');
  }

  @override
  String toString() {
    return 'InvitationTemplate('
        'id: $id, '
        'name: $name, '
        'category: ${category.name}, '
        'themeId: $themeId'
        ')';
  }
}