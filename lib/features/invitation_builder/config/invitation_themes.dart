import 'package:flutter/material.dart';

import '../models/invitation_theme.dart';

class InvitationThemes {
  InvitationThemes._();

  // ===========================================================================
  // LOTUS ROYALE
  // ===========================================================================

  static const InvitationTheme lotusRoyale =
      InvitationTheme(
    id: 'lotus_royale',
    name: 'Lotus Royale',

    backgroundColor: Color(0xFFFFF5EE),
    primaryColor: Color(0xFFA83D58),
    secondaryColor: Color(0xFFF2D2C8),
    accentColor: Color(0xFFC8A15A),

    textColor: Color(0xFF4B302C),
    mutedTextColor: Color(0xFF856B63),

    headingFont: 'Cormorant Garamond',
    bodyFont: 'Poppins',
    scriptFont: 'Great Vibes',

    borderRadius: 24,
    useGoldDetails: true,
  );

  // ===========================================================================
  // IVORY GOLD
  // ===========================================================================

  static const InvitationTheme ivoryGold =
      InvitationTheme(
    id: 'ivory_gold',
    name: 'Ivory Gold',

    backgroundColor: Color(0xFFFFF9F0),
    primaryColor: Color(0xFF9A7135),
    secondaryColor: Color(0xFFEBDCC4),
    accentColor: Color(0xFFD6B36A),

    textColor: Color(0xFF3C3028),
    mutedTextColor: Color(0xFF75675A),

    headingFont: 'Cormorant Garamond',
    bodyFont: 'Poppins',
    scriptFont: 'Allura',

    borderRadius: 22,
    useGoldDetails: true,
  );

  // ===========================================================================
  // MAROON GOLD
  // ===========================================================================

  static const InvitationTheme maroonGold =
      InvitationTheme(
    id: 'maroon_gold',
    name: 'Maroon Gold',

    backgroundColor: Color(0xFF3B1018),
    primaryColor: Color(0xFFD5AD5B),
    secondaryColor: Color(0xFF6D2634),
    accentColor: Color(0xFFF0D79A),

    textColor: Color(0xFFFFF7E7),
    mutedTextColor: Color(0xFFE2CFAE),

    headingFont: 'Cormorant Garamond',
    bodyFont: 'Poppins',
    scriptFont: 'Great Vibes',

    borderRadius: 20,
    useGoldDetails: true,
  );

  // ===========================================================================
  // EMERALD GOLD
  // ===========================================================================

  static const InvitationTheme emeraldGold =
      InvitationTheme(
    id: 'emerald_gold',
    name: 'Emerald Gold',

    backgroundColor: Color(0xFF0D2C25),
    primaryColor: Color(0xFFCBA75A),
    secondaryColor: Color(0xFF244D42),
    accentColor: Color(0xFFE7D09A),

    textColor: Color(0xFFFFF9ED),
    mutedTextColor: Color(0xFFD8CCAE),

    headingFont: 'Cormorant Garamond',
    bodyFont: 'Poppins',
    scriptFont: 'Allura',

    borderRadius: 20,
    useGoldDetails: true,
  );

  // ===========================================================================
  // CHAMPAGNE
  // ===========================================================================

  static const InvitationTheme champagne =
      InvitationTheme(
    id: 'champagne',
    name: 'Champagne',

    backgroundColor: Color(0xFFF5E9D5),
    primaryColor: Color(0xFFA98053),
    secondaryColor: Color(0xFFE5D2B2),
    accentColor: Color(0xFFD8BE91),

    textColor: Color(0xFF3D3128),
    mutedTextColor: Color(0xFF79695A),

    headingFont: 'Cormorant Garamond',
    bodyFont: 'Poppins',
    scriptFont: 'Allura',

    borderRadius: 24,
    useGoldDetails: true,
  );

  // ===========================================================================
  // BLACK GOLD
  // ===========================================================================

  static const InvitationTheme blackGold =
      InvitationTheme(
    id: 'black_gold',
    name: 'Black Gold',

    backgroundColor: Color(0xFF0D0D0D),
    primaryColor: Color(0xFFD4AF65),
    secondaryColor: Color(0xFF252525),
    accentColor: Color(0xFFF2D79D),

    textColor: Color(0xFFFFFFFF),
    mutedTextColor: Color(0xFFCFC5B2),

    headingFont: 'Cormorant Garamond',
    bodyFont: 'Poppins',
    scriptFont: 'Great Vibes',

    borderRadius: 18,
    useGoldDetails: true,
  );

  // ===========================================================================
  // ALL THEMES
  // ===========================================================================

  static const List<InvitationTheme> all = [
    lotusRoyale,
    ivoryGold,
    maroonGold,
    emeraldGold,
    champagne,
    blackGold,
  ];

  // ===========================================================================
  // FIND THEME
  // ===========================================================================

  static InvitationTheme? findById(String id) {
    for (final theme in all) {
      if (theme.id == id) {
        return theme;
      }
    }

    return null;
  }

  // ===========================================================================
  // GET THEME
  // ===========================================================================

  static InvitationTheme getById(String id) {
    return findById(id) ?? lotusRoyale;
  }
}