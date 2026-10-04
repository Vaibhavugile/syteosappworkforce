import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/lead.dart';
import '../models/daily_activity.dart';

class TimelineEventCard extends StatelessWidget {
  final DailyActivity activity;
  final Lead? lead;
  final VoidCallback? onTap;

  const TimelineEventCard({
    super.key,
    required this.activity,
    this.lead,
    this.onTap,
  });

  Color get _accent {
    switch (activity.type) {
      case DailyActivityType.visitCreated:
        return const Color(0xFF6366F1);

      case DailyActivityType.visitScheduled:
        return const Color(0xFF2563EB);

      case DailyActivityType.visitStarted:
        return const Color(0xFFF59E0B);

      case DailyActivityType.visitCompleted:
        return const Color(0xFF059669);

      case DailyActivityType.visitCancelled:
        return const Color(0xFFDC2626);

      case DailyActivityType.visitMissed:
        return const Color(0xFF7C3AED);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visit = activity.visit;

    final businessName =
        lead?.businessName.trim().isNotEmpty == true
            ? lead!.businessName
            : 'Customer Visit';

    final contact =
        lead?.contactPerson.trim().isNotEmpty == true
            ? lead!.contactPerson
            : '';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 58,
            child: Text(
              DateFormat('hh:mm a')
                  .format(activity.timestamp),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _accent.withOpacity(.10),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _accent.withOpacity(.18),
                  ),
                ),
                child: Icon(
                  activity.icon,
                  color: _accent,
                  size: 16,
                ),
              ),
              Container(
                width: 1,
                height: 82,
                color: const Color(0xFFE5E7EB),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin:
                  const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          activity.title,
                          style: TextStyle(
                            color: _accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (activity.hasLocation)
                        const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFF9CA3AF),
                          size: 15,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    businessName,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (contact.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      contact,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 7),
                  Text(
                    activity.subtitle,
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 9.5,
                      height: 1.35,
                    ),
                  ),
                  if (activity.outcomeLabel
                      .isNotEmpty) ...[
                    const SizedBox(height: 9),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFFECFDF5),
                        borderRadius:
                            BorderRadius.circular(9),
                      ),
                      child: Text(
                        'Outcome • ${activity.outcomeLabel}',
                        style: const TextStyle(
                          color: Color(0xFF047857),
                          fontSize: 9,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                  if ((visit.notes ?? '')
                      .trim()
                      .isNotEmpty) ...[
                    const SizedBox(height: 9),
                    Text(
                      visit.notes!.trim(),
                      maxLines: 3,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 9.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}