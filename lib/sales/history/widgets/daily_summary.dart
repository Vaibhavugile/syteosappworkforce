import 'package:flutter/material.dart';

import '../services/daily_history_service.dart';

class DailySummary extends StatelessWidget {
  final DailyHistoryData data;

  const DailySummary({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final cards = <_SummaryItem>[
      _SummaryItem(
        label: 'Visits',
        value: data.totalVisits,
        icon: Icons.location_on_outlined,
      ),
      _SummaryItem(
        label: 'Created',
        value: data.totalCreated,
        icon: Icons.add_location_alt_outlined,
      ),
      _SummaryItem(
        label: 'Started',
        value: data.totalStarted,
        icon: Icons.play_circle_outline_rounded,
      ),
      _SummaryItem(
        label: 'Completed',
        value: data.totalCompleted,
        icon: Icons.check_circle_outline_rounded,
      ),
      _SummaryItem(
        label: 'Interested',
        value: data.interested,
        icon: Icons.thumb_up_alt_outlined,
      ),
      _SummaryItem(
        label: 'Follow-up',
        value: data.followUpRequired,
        icon: Icons.schedule_outlined,
      ),
      _SummaryItem(
        label: 'Demo',
        value: data.demoRequested,
        icon: Icons.slideshow_outlined,
      ),
      _SummaryItem(
        label: 'Proposal',
        value: data.proposalRequested,
        icon: Icons.description_outlined,
      ),
      _SummaryItem(
        label: 'Converted',
        value: data.converted,
        icon: Icons.verified_outlined,
      ),
      _SummaryItem(
        label: 'Cancelled',
        value: data.totalCancelled,
        icon: Icons.cancel_outlined,
      ),
      _SummaryItem(
        label: 'Missed',
        value: data.totalMissed,
        icon: Icons.event_busy_outlined,
      ),
      _SummaryItem(
        label: 'Not Interested',
        value: data.notInterested,
        icon: Icons.thumb_down_alt_outlined,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daily Summary',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.75,
          ),
          itemBuilder: (_, index) {
            final item = cards[index];

            return Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius:
                          BorderRadius.circular(11),
                    ),
                    child: Icon(
                      item.icon,
                      color: const Color(0xFF4F46E5),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.value}',
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SummaryItem {
  final String label;
  final int value;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });
}