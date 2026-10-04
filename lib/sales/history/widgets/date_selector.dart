import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateSelector extends StatelessWidget {
  final DateTime date;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final ValueChanged<DateTime> onDateSelected;

  const DateSelector({
    super.key,
    required this.date,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.onDateSelected,
  });

  bool get isToday {
    final now = DateTime.now();

    return now.year == date.year &&
        now.month == date.month &&
        now.day == date.day;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          _roundButton(
            icon: Icons.chevron_left_rounded,
            onTap: onPrevious,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(13),
              onTap: () async {
                final selected =
                    await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now()
                      .add(const Duration(days: 365)),
                );

                if (selected != null) {
                  onDateSelected(selected);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FD),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat(
                        'EEEE',
                      ).format(date),
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat(
                        'dd MMM yyyy',
                      ).format(date),
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _roundButton(
            icon: Icons.chevron_right_rounded,
            onTap: onNext,
          ),
          const SizedBox(width: 8),
          if (!isToday)
            TextButton(
              onPressed: onToday,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'Today',
                style: TextStyle(
                  color: Color(0xFF4F46E5),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _roundButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            icon,
            color: const Color(0xFF374151),
            size: 21,
          ),
        ),
      ),
    );
  }
}