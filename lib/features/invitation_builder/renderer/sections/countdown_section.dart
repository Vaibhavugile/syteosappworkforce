import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/invitation_model.dart';
import '../../models/invitation_theme.dart';

class InvitationCountdownSection extends StatefulWidget {
  final InvitationModel invitation;
  final InvitationTheme theme;
  final bool isPreview;

  const InvitationCountdownSection({
    super.key,
    required this.invitation,
    required this.theme,
    this.isPreview = false,
  });

  @override
  State<InvitationCountdownSection> createState() =>
      _InvitationCountdownSectionState();
}

class _InvitationCountdownSectionState
    extends State<InvitationCountdownSection> {
  Timer? _timer;

  Duration? _remaining;
  DateTime? _weddingDateTime;

  @override
  void initState() {
    super.initState();

    _weddingDateTime = _parseWeddingDateTime();

    _updateCountdown();

    if (_weddingDateTime != null) {
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _updateCountdown(),
      );
    }
  }

  @override
  void didUpdateWidget(
    covariant InvitationCountdownSection oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.invitation.weddingDate !=
            widget.invitation.weddingDate ||
        oldWidget.invitation.weddingTime !=
            widget.invitation.weddingTime) {
      _weddingDateTime = _parseWeddingDateTime();

      _timer?.cancel();

      _updateCountdown();

      if (_weddingDateTime != null) {
        _timer = Timer.periodic(
          const Duration(seconds: 1),
          (_) => _updateCountdown(),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateCountdown() {
    if (!mounted) return;

    final target = _weddingDateTime;

    if (target == null) {
      setState(() {
        _remaining = null;
      });
      return;
    }

    final now = DateTime.now();
    final difference = target.difference(now);

    setState(() {
      _remaining = difference.isNegative
          ? Duration.zero
          : difference;
    });
  }

  DateTime? _parseWeddingDateTime() {
    final String dateText =
        widget.invitation.weddingDate.trim();

    final String timeText =
        widget.invitation.weddingTime.trim();

    if (dateText.isEmpty) return null;

    DateTime? date;

    // ISO:
    // 2026-12-18
    date = DateTime.tryParse(dateText);

    if (date == null) {
      final formats = [
        'dd MMMM yyyy',
        'd MMMM yyyy',
        'dd MMM yyyy',
        'd MMM yyyy',
        'dd/MM/yyyy',
        'd/M/yyyy',
        'dd-MM-yyyy',
        'd-M-yyyy',
      ];

      for (final format in formats) {
        try {
          date = DateFormat(format).parseStrict(dateText);
          break;
        } catch (_) {}
      }
    }

    if (date == null) return null;

    int hour = 0;
    int minute = 0;

    if (timeText.isNotEmpty) {
      final parsedTime = _parseTime(timeText);

      if (parsedTime != null) {
        hour = parsedTime.$1;
        minute = parsedTime.$2;
      }
    }

    return DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }

  (int, int)? _parseTime(String value) {
    final String normalized =
        value.trim().toUpperCase();

    final RegExp amPmPattern = RegExp(
      r'^(\d{1,2})(?::(\d{2}))?\s*(AM|PM)$',
    );

    final amPmMatch =
        amPmPattern.firstMatch(normalized);

    if (amPmMatch != null) {
      int hour =
          int.tryParse(amPmMatch.group(1) ?? '') ?? 0;

      final int minute =
          int.tryParse(amPmMatch.group(2) ?? '0') ?? 0;

      final String period =
          amPmMatch.group(3) ?? 'AM';

      if (hour < 1 || hour > 12) return null;
      if (minute < 0 || minute > 59) return null;

      if (period == 'AM') {
        if (hour == 12) hour = 0;
      } else {
        if (hour != 12) hour += 12;
      }

      return (hour, minute);
    }

    final RegExp twentyFourHourPattern =
        RegExp(r'^(\d{1,2}):(\d{2})$');

    final twentyFourMatch =
        twentyFourHourPattern.firstMatch(normalized);

    if (twentyFourMatch != null) {
      final int hour =
          int.tryParse(twentyFourMatch.group(1) ?? '') ?? -1;

      final int minute =
          int.tryParse(twentyFourMatch.group(2) ?? '') ?? -1;

      if (hour < 0 || hour > 23) return null;
      if (minute < 0 || minute > 59) return null;

      return (hour, minute);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.invitation.countdownEnabled) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 70,
      ),
      decoration: BoxDecoration(
        color: widget.theme.backgroundColor,
      ),
      child: Column(
        children: [
          _buildTopDecoration(),
          const SizedBox(height: 20),

          Text(
            'THE COUNTDOWN',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.theme.accentColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
              fontFamily: widget.theme.bodyFont,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Until We Say “I Do”',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.theme.primaryColor,
              fontSize: 31,
              height: 1.1,
              fontWeight: FontWeight.w500,
              fontFamily: widget.theme.headingFont,
            ),
          ),

          const SizedBox(height: 34),

          if (_remaining == null)
            _buildUnavailableState()
          else if (_remaining == Duration.zero)
            _buildWeddingDayState()
          else
            _buildCountdown(),

          const SizedBox(height: 30),

          if (_weddingDateTime != null)
            _buildWeddingDateLabel(),

          const SizedBox(height: 30),

          _buildBottomDecoration(),
        ],
      ),
    );
  }

  Widget _buildCountdown() {
    final Duration remaining = _remaining!;

    final int days = remaining.inDays;

    final int hours =
        remaining.inHours.remainder(24);

    final int minutes =
        remaining.inMinutes.remainder(60);

    final int seconds =
        remaining.inSeconds.remainder(60);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact =
            constraints.maxWidth < 360;

        return Wrap(
          alignment: WrapAlignment.center,
          spacing: compact ? 7 : 10,
          runSpacing: 12,
          children: [
            _buildTimeCard(
              value: days.toString(),
              label: days == 1 ? 'DAY' : 'DAYS',
              width: compact ? 72 : 78,
            ),
            _buildSeparator(),
            _buildTimeCard(
              value: _twoDigits(hours),
              label: 'HOURS',
              width: compact ? 72 : 78,
            ),
            _buildSeparator(),
            _buildTimeCard(
              value: _twoDigits(minutes),
              label: 'MINUTES',
              width: compact ? 72 : 78,
            ),
            _buildSeparator(),
            _buildTimeCard(
              value: _twoDigits(seconds),
              label: 'SECONDS',
              width: compact ? 72 : 78,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimeCard({
    required String value,
    required String label,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: widget.theme.secondaryColor.withValues(
          alpha: 0.28,
        ),
        borderRadius: BorderRadius.circular(
          widget.theme.borderRadius,
        ),
        border: Border.all(
          color: widget.theme.accentColor.withValues(
            alpha: 0.45,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: widget.theme.accentColor.withValues(
              alpha: 0.08,
            ),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.theme.primaryColor,
              fontSize: 25,
              fontWeight: FontWeight.w600,
              fontFamily: widget.theme.headingFont,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.theme.mutedTextColor,
              fontSize: 7.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              fontFamily: widget.theme.bodyFont,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeparator() {
    return SizedBox(
      height: 70,
      child: Center(
        child: Text(
          '•',
          style: TextStyle(
            color: widget.theme.accentColor,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildWeddingDateLabel() {
    final date = _weddingDateTime!;

    final String formattedDate =
        DateFormat('EEEE, d MMMM yyyy').format(date);

    final String formattedTime =
        DateFormat('h:mm a').format(date);

    return Column(
      children: [
        Text(
          formattedDate,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: widget.theme.textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: widget.theme.bodyFont,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          formattedTime,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: widget.theme.mutedTextColor,
            fontSize: 12,
            fontFamily: widget.theme.bodyFont,
          ),
        ),
      ],
    );
  }

  Widget _buildWeddingDayState() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 26,
        vertical: 22,
      ),
      decoration: BoxDecoration(
        color: widget.theme.secondaryColor.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(
          widget.theme.borderRadius + 4,
        ),
        border: Border.all(
          color: widget.theme.accentColor.withValues(
            alpha: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          Text(
            '♥',
            style: TextStyle(
              color: widget.theme.accentColor,
              fontSize: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Today is the day!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.theme.primaryColor,
              fontSize: 27,
              fontWeight: FontWeight.w600,
              fontFamily: widget.theme.headingFont,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Let the celebration begin.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.theme.mutedTextColor,
              fontSize: 13,
              fontFamily: widget.theme.bodyFont,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnavailableState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 25,
      ),
      decoration: BoxDecoration(
        color: widget.theme.secondaryColor.withValues(
          alpha: 0.2,
        ),
        borderRadius: BorderRadius.circular(
          widget.theme.borderRadius,
        ),
      ),
      child: Text(
        'Your countdown will appear here once '
        'the wedding date is added.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: widget.theme.mutedTextColor,
          fontSize: 13,
          height: 1.6,
          fontFamily: widget.theme.bodyFont,
        ),
      ),
    );
  }

  Widget _buildTopDecoration() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 45,
          height: 1,
          color: widget.theme.accentColor.withValues(
            alpha: 0.45,
          ),
        ),
        const SizedBox(width: 12),
        Icon(
          Icons.favorite,
          size: 14,
          color: widget.theme.accentColor,
        ),
        const SizedBox(width: 12),
        Container(
          width: 45,
          height: 1,
          color: widget.theme.accentColor.withValues(
            alpha: 0.45,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomDecoration() {
    return Text(
      '✦  ✧  ✦',
      style: TextStyle(
        color: widget.theme.accentColor.withValues(
          alpha: 0.7,
        ),
        fontSize: 14,
        letterSpacing: 5,
      ),
    );
  }

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }
}