import '../models/invitation_template.dart';
import 'invitation_themes.dart';

class InvitationTemplates {
  InvitationTemplates._();

  // ===========================================================================
  // 1. LOTUS ROYALE
  // ===========================================================================

  static const InvitationTemplate lotusRoyale =
      InvitationTemplate(
    id: 'lotus_royale',
    name: 'Lotus Royale',
    description:
        'A romantic floral invitation with soft blush, ivory, rose and gold details.',
    category: InvitationCategory.floral,

    previewAsset:
        'assets/invitations/lotus_royale/preview/preview.webp',

    heroBackgroundAsset:
        'assets/invitations/lotus_royale/backgrounds/hero.webp',

    themeId: 'lotus_royale',

    sections: [
      'hero',
      'story',
      'couple',
      'events',
      'gallery',
      'venue',
      'countdown',
      'rsvp',
      'footer',
    ],

    galleryStyle: GalleryStyle.masonry,

    heroAnimation:
        InvitationAnimation.flowerBloom,

    textAnimation:
        InvitationAnimation.fadeUp,

    photoAnimation:
        InvitationAnimation.imageReveal,

    backgroundAnimation:
        InvitationAnimation.parallax,

    enablePetals: true,
    enableParallax: true,
    enable3DTilt: true,
  );

  // ===========================================================================
  // 2. ROYAL PALACE
  // ===========================================================================

  static const InvitationTemplate royalPalace =
      InvitationTemplate(
    id: 'royal_palace',
    name: 'Royal Palace',
    description:
        'A grand royal wedding design inspired by palace architecture and traditional Indian luxury.',
    category: InvitationCategory.royal,

    previewAsset:
        'assets/invitations/lotus_royale/preview/royal_palace.webp',

    heroBackgroundAsset:
        'assets/invitations/lotus_royale/backgrounds/royal_palace.webp',

    themeId: 'maroon_gold',

    sections: [
      'hero',
      'story',
      'couple',
      'events',
      'gallery',
      'venue',
      'countdown',
      'rsvp',
      'footer',
    ],

    galleryStyle: GalleryStyle.cinematic,

    heroAnimation:
        InvitationAnimation.curtainOpen,

    textAnimation:
        InvitationAnimation.fadeUp,

    photoAnimation:
        InvitationAnimation.imageReveal,

    backgroundAnimation:
        InvitationAnimation.parallax,

    enablePetals: false,
    enableParallax: true,
    enable3DTilt: false,
  );

  // ===========================================================================
  // 3. MODERN LUXURY
  // ===========================================================================

  static const InvitationTemplate modernLuxury =
      InvitationTemplate(
    id: 'modern_luxury',
    name: 'Modern Luxury',
    description:
        'A sophisticated dark luxury invitation with cinematic photography and elegant gold accents.',
    category: InvitationCategory.luxury,

    previewAsset:
        'assets/invitations/lotus_royale/preview/modern_luxury.webp',

    heroBackgroundAsset:
        'assets/invitations/lotus_royale/backgrounds/modern_luxury.webp',

    themeId: 'black_gold',

    sections: [
      'hero',
      'couple',
      'story',
      'events',
      'gallery',
      'venue',
      'countdown',
      'rsvp',
      'footer',
    ],

    galleryStyle: GalleryStyle.cinematic,

    heroAnimation:
        InvitationAnimation.fadeIn,

    textAnimation:
        InvitationAnimation.fadeUp,

    photoAnimation:
        InvitationAnimation.imageReveal,

    backgroundAnimation:
        InvitationAnimation.parallax,

    enablePetals: false,
    enableParallax: true,
    enable3DTilt: true,
  );

  // ===========================================================================
  // 4. GARDEN ROMANCE
  // ===========================================================================

  static const InvitationTemplate gardenRomance =
      InvitationTemplate(
    id: 'garden_romance',
    name: 'Garden Romance',
    description:
        'A soft romantic invitation inspired by blooming gardens, delicate flowers and timeless love.',
    category: InvitationCategory.romantic,

    previewAsset:
        'assets/invitations/lotus_royale/preview/garden_romance.webp',

    heroBackgroundAsset:
        'assets/invitations/lotus_royale/backgrounds/garden_romance.webp',

    themeId: 'lotus_royale',

    sections: [
      'hero',
      'story',
      'couple',
      'events',
      'gallery',
      'venue',
      'countdown',
      'rsvp',
      'footer',
    ],

    galleryStyle: GalleryStyle.masonry,

    heroAnimation:
        InvitationAnimation.flowerBloom,

    textAnimation:
        InvitationAnimation.fadeUp,

    photoAnimation:
        InvitationAnimation.imageReveal,

    backgroundAnimation:
        InvitationAnimation.parallax,

    enablePetals: true,
    enableParallax: true,
    enable3DTilt: true,
  );

  // ===========================================================================
  // 5. TRADITIONAL MANDALA
  // ===========================================================================

  static const InvitationTemplate traditionalMandala =
      InvitationTemplate(
    id: 'traditional_mandala',
    name: 'Traditional Mandala',
    description:
        'A traditional Indian invitation featuring mandala-inspired details and warm royal tones.',
    category: InvitationCategory.traditional,

    previewAsset:
        'assets/invitations/lotus_royale/preview/traditional_mandala.webp',

    heroBackgroundAsset:
        'assets/invitations/lotus_royale/backgrounds/traditional_mandala.webp',

    themeId: 'maroon_gold',

    sections: [
      'hero',
      'story',
      'couple',
      'events',
      'gallery',
      'venue',
      'countdown',
      'rsvp',
      'footer',
    ],

    galleryStyle: GalleryStyle.grid,

    heroAnimation:
        InvitationAnimation.envelopeOpen,

    textAnimation:
        InvitationAnimation.fadeUp,

    photoAnimation:
        InvitationAnimation.imageReveal,

    backgroundAnimation:
        InvitationAnimation.parallax,

    enablePetals: false,
    enableParallax: true,
    enable3DTilt: false,
  );

  // ===========================================================================
  // ALL TEMPLATES
  // ===========================================================================

  static const List<InvitationTemplate> all = [
    lotusRoyale,
    royalPalace,
    modernLuxury,
    gardenRomance,
    traditionalMandala,
  ];

  // ===========================================================================
  // FIND TEMPLATE
  // ===========================================================================

  static InvitationTemplate? findById(String id) {
    for (final template in all) {
      if (template.id == id) {
        return template;
      }
    }

    return null;
  }

  // ===========================================================================
  // GET TEMPLATE
  // ===========================================================================

  static InvitationTemplate getById(String id) {
    return findById(id) ?? lotusRoyale;
  }

  // ===========================================================================
  // CATEGORY FILTER
  // ===========================================================================

  static List<InvitationTemplate> byCategory(
    InvitationCategory category,
  ) {
    return all
        .where(
          (template) =>
              template.category == category,
        )
        .toList();
  }

  // ===========================================================================
  // THEME FOR TEMPLATE
  // ===========================================================================

  static String themeIdForTemplate(
    InvitationTemplate template,
  ) {
    return template.themeId;
  }

  // ===========================================================================
  // THEME OBJECT FOR TEMPLATE
  // ===========================================================================

  static dynamic themeForTemplate(
    InvitationTemplate template,
  ) {
    return InvitationThemes.getById(
      template.themeId,
    );
  }
}