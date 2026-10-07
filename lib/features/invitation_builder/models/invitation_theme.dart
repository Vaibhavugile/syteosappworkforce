import 'package:flutter/material.dart';

@immutable
class InvitationTheme {
  final String id;
  final String name;

  // Main colors
  final Color backgroundColor;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;

  // Text colors
  final Color textColor;
  final Color mutedTextColor;

  // Typography
  final String headingFont;
  final String bodyFont;
  final String scriptFont;

  // UI styling
  final double borderRadius;
  final bool useGoldDetails;

  const InvitationTheme({
    required this.id,
    required this.name,
    required this.backgroundColor,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.textColor,
    required this.mutedTextColor,
    required this.headingFont,
    required this.bodyFont,
    required this.scriptFont,
    this.borderRadius = 20,
    this.useGoldDetails = true,
  });

  InvitationTheme copyWith({
    String? id,
    String? name,
    Color? backgroundColor,
    Color? primaryColor,
    Color? secondaryColor,
    Color? accentColor,
    Color? textColor,
    Color? mutedTextColor,
    String? headingFont,
    String? bodyFont,
    String? scriptFont,
    double? borderRadius,
    bool? useGoldDetails,
  }) {
    return InvitationTheme(
      id: id ?? this.id,
      name: name ?? this.name,
      backgroundColor:
          backgroundColor ?? this.backgroundColor,
      primaryColor:
          primaryColor ?? this.primaryColor,
      secondaryColor:
          secondaryColor ?? this.secondaryColor,
      accentColor:
          accentColor ?? this.accentColor,
      textColor:
          textColor ?? this.textColor,
      mutedTextColor:
          mutedTextColor ?? this.mutedTextColor,
      headingFont:
          headingFont ?? this.headingFont,
      bodyFont:
          bodyFont ?? this.bodyFont,
      scriptFont:
          scriptFont ?? this.scriptFont,
      borderRadius:
          borderRadius ?? this.borderRadius,
      useGoldDetails:
          useGoldDetails ?? this.useGoldDetails,
    );
  }

  /// Convert theme colors to values that can be stored later.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'backgroundColor': backgroundColor.toARGB32(),
      'primaryColor': primaryColor.toARGB32(),
      'secondaryColor': secondaryColor.toARGB32(),
      'accentColor': accentColor.toARGB32(),
      'textColor': textColor.toARGB32(),
      'mutedTextColor': mutedTextColor.toARGB32(),
      'headingFont': headingFont,
      'bodyFont': bodyFont,
      'scriptFont': scriptFont,
      'borderRadius': borderRadius,
      'useGoldDetails': useGoldDetails,
    };
  }

  factory InvitationTheme.fromMap(
    Map<String, dynamic> map,
  ) {
    return InvitationTheme(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      backgroundColor: _colorFromMap(
        map['backgroundColor'],
        Colors.white,
      ),
      primaryColor: _colorFromMap(
        map['primaryColor'],
        Colors.black,
      ),
      secondaryColor: _colorFromMap(
        map['secondaryColor'],
        Colors.grey,
      ),
      accentColor: _colorFromMap(
        map['accentColor'],
        Colors.amber,
      ),
      textColor: _colorFromMap(
        map['textColor'],
        Colors.black,
      ),
      mutedTextColor: _colorFromMap(
        map['mutedTextColor'],
        Colors.grey,
      ),
      headingFont:
          map['headingFont']?.toString() ??
              'Cormorant Garamond',
      bodyFont:
          map['bodyFont']?.toString() ??
              'Poppins',
      scriptFont:
          map['scriptFont']?.toString() ??
              'Great Vibes',
      borderRadius:
          (map['borderRadius'] as num?)?.toDouble() ?? 20,
      useGoldDetails:
          map['useGoldDetails'] is bool
              ? map['useGoldDetails'] as bool
              : true,
    );
  }

  static Color _colorFromMap(
    dynamic value,
    Color fallback,
  ) {
    if (value is int) {
      return Color(value);
    }

    if (value is num) {
      return Color(value.toInt());
    }

    if (value is String) {
      final String hex = value
          .replaceFirst('#', '')
          .trim();

      try {
        if (hex.length == 6) {
          return Color(
            int.parse('FF$hex', radix: 16),
          );
        }

        if (hex.length == 8) {
          return Color(
            int.parse(hex, radix: 16),
          );
        }
      } catch (_) {
        return fallback;
      }
    }

    return fallback;
  }

  @override
  String toString() {
    return 'InvitationTheme('
        'id: $id, '
        'name: $name, '
        'headingFont: $headingFont, '
        'bodyFont: $bodyFont, '
        'scriptFont: $scriptFont'
        ')';
  }
}