import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/invitation_model.dart';
import '../../models/invitation_theme.dart';

class LotusRoyaleCountdown extends StatefulWidget {
  final InvitationModel invitation;
  final InvitationTheme theme;
  final bool isPreview;

  const LotusRoyaleCountdown({
    super.key,
    required this.invitation,
    required this.theme,
    this.isPreview = false,
  });

  @override
  State<LotusRoyaleCountdown> createState() =>
      _LotusRoyaleCountdownState();
}

class _LotusRoyaleCountdownState extends State<LotusRoyaleCountdown> {
  static const String _backgroundAsset =
      'assets/invitations/lotus_royale/backgrounds/countdown.webp';

  static const String _artworkAsset =
      'assets/invitations/lotus_royale/frames/countdown_artwork.webp';

  Timer? _timer;
  DateTime? _targetDate;
  Duration? _remaining;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(covariant LotusRoyaleCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.invitation.weddingDate !=
            widget.invitation.weddingDate ||
        oldWidget.invitation.weddingTime !=
            widget.invitation.weddingTime) {
      _timer?.cancel();
      _initialize();
    }
  }

  void _initialize() {
    _targetDate = _parseWeddingDateTime();
    _update();

    if (_targetDate != null) {
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _update(),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _update() {
    if (!mounted) return;

    final target = _targetDate;

    if (target == null) {
      setState(() => _remaining = null);
      return;
    }

    final difference = target.difference(DateTime.now());

    setState(() {
      _remaining =
          difference.isNegative ? Duration.zero : difference;
    });
  }

  DateTime? _parseWeddingDateTime() {
    final dateText = widget.invitation.weddingDate.trim();
    if (dateText.isEmpty) return null;

    DateTime? date = DateTime.tryParse(dateText);

    if (date == null) {
      const formats = [
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

    final time = _parseTime(widget.invitation.weddingTime);

    return DateTime(
      date.year,
      date.month,
      date.day,
      time?.$1 ?? 0,
      time?.$2 ?? 0,
    );
  }

  (int, int)? _parseTime(String value) {
    final text = value.trim().toUpperCase();
    if (text.isEmpty) return null;

    final amPm = RegExp(
      r'^(\d{1,2})(?::(\d{2}))?\s*(AM|PM)$',
    ).firstMatch(text);

    if (amPm != null) {
      int hour = int.tryParse(amPm.group(1) ?? '') ?? -1;
      final minute = int.tryParse(amPm.group(2) ?? '0') ?? -1;
      final period = amPm.group(3) ?? 'AM';

      if (hour < 1 || hour > 12) return null;
      if (minute < 0 || minute > 59) return null;

      if (period == 'AM' && hour == 12) hour = 0;
      if (period == 'PM' && hour != 12) hour += 12;

      return (hour, minute);
    }

    final twentyFour = RegExp(
      r'^(\d{1,2}):(\d{2})$',
    ).firstMatch(text);

    if (twentyFour != null) {
      final hour =
          int.tryParse(twentyFour.group(1) ?? '') ?? -1;
      final minute =
          int.tryParse(twentyFour.group(2) ?? '') ?? -1;

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = width < 420;

        // The background is a full invitation section.
        final sectionHeight = compact ? 980.0 : 1020.0;

        // The supplied transparent artwork is 1245 × 1263.
        // It is intentionally kept proportional.
        final artworkWidth = (width * 1.03).clamp(340.0, 560.0);
        final artworkHeight = artworkWidth * (1263 / 1245);

        // Position the artwork over the clean center of the background.
        final artworkTop = compact ? 185.0 : 205.0;

        return SizedBox(
          width: double.infinity,
          height: sectionHeight,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: Image.asset(
                  _backgroundAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      color: widget.theme.backgroundColor,
                    );
                  },
                ),
              ),

              // A very subtle veil keeps the background from competing
              // with the transparent artwork.
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: widget.theme.backgroundColor.withValues(
                      alpha: 0.035,
                    ),
                  ),
                ),
              ),

              Positioned(
                left: (width - artworkWidth) / 2,
                top: artworkTop,
                width: artworkWidth,
                height: artworkHeight,
                child: Image.asset(
                  _artworkAsset,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) {
                    return const SizedBox.shrink();
                  },
                ),
              ),

              if (_remaining != null &&
                  _remaining != Duration.zero)
                Positioned(
                  left: 0,
                  right: 0,
                  top: artworkTop,
                  height: artworkHeight,
                  child: _buildLiveNumbers(
                    artworkWidth,
                  ),
                ),

              if (_remaining == Duration.zero &&
                  _targetDate != null)
                Positioned(
                  left: 22,
                  right: 22,
                  bottom: 30,
                  child: _buildWeddingDay(),
                ),

              if (_remaining == null)
                Positioned(
                  left: 22,
                  right: 22,
                  bottom: 30,
                  child: _buildUnavailable(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveNumbers(double artworkWidth) {
    final remaining = _remaining!;

    final values = [
      remaining.inDays.toString(),
      _twoDigits(remaining.inHours.remainder(24)),
      _twoDigits(remaining.inMinutes.remainder(60)),
      _twoDigits(remaining.inSeconds.remainder(60)),
    ];

    // Coordinates are based on the original 1245px artwork.
    // These are the centers of the four number panels.
    const centers = [204.0, 445.0, 687.0, 930.0];
    const numberY = 590.0;

    final scale = artworkWidth / 1245.0;
    final artworkLeft =
        (MediaQuery.sizeOf(context).width - artworkWidth) / 2;

    return Stack(
      children: List.generate(4, (index) {
        final numberSize = (88 * scale).clamp(25.0, 42.0);

        return Positioned(
          left: artworkLeft + centers[index] * scale - 48 * scale,
          top: numberY * scale,
          width: 96 * scale,
          child: Text(
            values[index],
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: TextStyle(
              color: widget.theme.primaryColor,
              fontSize: numberSize,
              height: 0.92,
              fontWeight: FontWeight.w500,
              fontFamily: widget.theme.headingFont,
              shadows: [
                Shadow(
                  color: Colors.white.withValues(alpha: 0.55),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildWeddingDay() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: widget.theme.backgroundColor.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: widget.theme.accentColor.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: widget.theme.primaryColor.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        'Today is the day! Let the celebration begin.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: widget.theme.primaryColor,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          fontFamily: widget.theme.headingFont,
        ),
      ),
    );
  }

  Widget _buildUnavailable() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: widget.theme.backgroundColor.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: widget.theme.accentColor.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        'Add your wedding date and time to start the countdown.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: widget.theme.mutedTextColor,
          fontSize: 11.5,
          fontFamily: widget.theme.bodyFont,
        ),
      ),
    );
  }

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }
}
