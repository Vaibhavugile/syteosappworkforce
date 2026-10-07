import 'package:flutter/foundation.dart';

@immutable
class InvitationEvent {
  final String id;
  final String name;
  final String date;
  final String time;
  final String venue;
  final String description;
  final String icon;
  final bool enabled;

  const InvitationEvent({
    required this.id,
    required this.name,
    required this.date,
    required this.time,
    required this.venue,
    this.description = '',
    this.icon = 'event',
    this.enabled = true,
  });

  InvitationEvent copyWith({
    String? id,
    String? name,
    String? date,
    String? time,
    String? venue,
    String? description,
    String? icon,
    bool? enabled,
  }) {
    return InvitationEvent(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      time: time ?? this.time,
      venue: venue ?? this.venue,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': date,
      'time': time,
      'venue': venue,
      'description': description,
      'icon': icon,
      'enabled': enabled,
    };
  }

  factory InvitationEvent.fromMap(
    Map<String, dynamic> map,
  ) {
    return InvitationEvent(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      time: map['time']?.toString() ?? '',
      venue: map['venue']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      icon: map['icon']?.toString() ?? 'event',
      enabled: map['enabled'] is bool
          ? map['enabled'] as bool
          : true,
    );
  }

  @override
  String toString() {
    return 'InvitationEvent('
        'id: $id, '
        'name: $name, '
        'date: $date, '
        'time: $time, '
        'venue: $venue, '
        'enabled: $enabled'
        ')';
  }
}