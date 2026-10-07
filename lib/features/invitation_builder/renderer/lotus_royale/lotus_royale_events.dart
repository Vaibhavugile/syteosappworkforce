import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/invitation_event.dart';
import '../../models/invitation_model.dart';
import '../../models/invitation_theme.dart';

/// Lotus Royale — premium wedding events section.
///
/// The new events artwork is intentionally a COMPLETE decorative background:
/// - palace / lake scenery
/// - flowers and lanterns
/// - five empty ivory-gold panels
/// - gold ornaments
///
/// Flutter adds ONLY the live event information inside those five panels.
/// This keeps the artwork clean and prevents the previous text/image overlap.
class LotusRoyaleEvents extends StatefulWidget {
  final InvitationModel invitation;
  final InvitationTheme theme;
  final bool isPreview;

  const LotusRoyaleEvents({
    super.key,
    required this.invitation,
    required this.theme,
    this.isPreview = false,
  });

  @override
  State<LotusRoyaleEvents> createState() => _LotusRoyaleEventsState();
}

class _LotusRoyaleEventsState extends State<LotusRoyaleEvents>
    with TickerProviderStateMixin {
  static const String _backgroundAsset =
      'assets/invitations/lotus_royale/backgrounds/events.webp';

  // The generated artwork is exactly 1024 × 1536.
  static const double _artWidth = 1024;
  static const double _artHeight = 1536;

  static const Color _wine = Color(0xFF713B4C);
  static const Color _deepWine = Color(0xFF5B2D3C);
  static const Color _gold = Color(0xFFC99C50);
  static const Color _body = Color(0xFF654E46);
  static const Color _muted = Color(0xFF866F67);

  late final AnimationController _entranceController;
  late final AnimationController _motionController;

  bool _reduceMotion = false;

  InvitationModel get invitation => widget.invitation;
  InvitationTheme get theme => widget.theme;

  List<InvitationEvent> get events =>
      invitation.enabledEvents.take(5).toList();

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;

      if (_reduceMotion) {
        _entranceController.value = 1;
        _motionController.stop();
      } else {
        _entranceController.forward();
      }

      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _motionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF3E8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = width * _artHeight / _artWidth;

          return SizedBox(
            width: width,
            height: height,
            child: AnimatedBuilder(
              animation: _motionController,
              builder: (context, _) {
                final p = _motionController.value;

                // Extremely subtle artwork drift. The text stays fixed.
                final bgShift = _reduceMotion
                    ? 0.0
                    : math.sin(p * math.pi * 2) * 0.28;

                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned.fill(
                      child: Transform.translate(
                        offset: Offset(0, bgShift),
                        child: Image.asset(
                          _backgroundAsset,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (_, __, ___) =>
                              _fallbackBackground(),
                        ),
                      ),
                    ),

                    // Header sits in the clean space below the top arch.
                    Positioned(
                      top: height * 0.067,
                      left: width * 0.16,
                      right: width * 0.16,
                      height: height * 0.075,
                      child: _buildHeader(),
                    ),

                    // Five live event panels.
                    ...List.generate(
                      events.length,
                      (index) => _buildEvent(
                        event: events[index],
                        index: index,
                        width: width,
                        height: height,
                      ),
                    ),

                    if (!_reduceMotion)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _PetalPainter(
                              progress: p,
                              opacity: 0.07,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'OUR WEDDING',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _wine,
            fontFamily: theme.bodyFont,
            fontSize: 7.0,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Wedding Events',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _wine,
            fontFamily: theme.headingFont,
            fontSize: 23,
            height: 0.95,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'A JOURNEY OF LOVE, BLESSINGS AND CELEBRATIONS',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _body,
            fontFamily: theme.bodyFont,
            fontSize: 5.2,
            letterSpacing: 0.9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEvent({
    required InvitationEvent event,
    required int index,
    required double width,
    required double height,
  }) {
    // Exact panel positions from the new 1024 × 1536 artwork.
    const panelTops = <double>[
      0.118,
      0.252,
      0.389,
      0.526,
      0.662,
    ];

    final safeIndex = index.clamp(0, panelTops.length - 1);

    return Positioned(
      left: width * 0.205,
      right: width * 0.205,
      top: height * panelTops[safeIndex],
      height: height * 0.112,
      child: _EventEntrance(
        controller: _entranceController,
        index: index,
        child: _buildPanel(event, width),
      ),
    );
  }

  Widget _buildPanel(InvitationEvent event, double width) {
    final date = _parseEventDate(event.date);

    final title = event.name.trim().isEmpty
        ? 'Wedding Celebration'
        : event.name.trim();

    final time = event.time.trim();
    final venue = event.venue.trim();
    final description = event.description.trim();

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: width * 0.012),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Live event title.
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _wine,
                fontFamily: theme.headingFont,
                fontSize: title.length > 20 ? 12.2 : 14.5,
                fontWeight: FontWeight.w600,
                height: 1.0,
                shadows: const [
                  Shadow(
                    color: Color(0x22FFFFFF),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 3),

            // Tiny live gold divider.
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 0.8,
                  color: _gold.withValues(alpha: 0.72),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.auto_awesome,
                  size: 5.5,
                  color: _gold.withValues(alpha: 0.95),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 24,
                  height: 0.8,
                  color: _gold.withValues(alpha: 0.72),
                ),
              ],
            ),

            const SizedBox(height: 3),

            // Date + time.
            if (date != null || time.isNotEmpty)
              _buildMetaRow(
                date: date,
                time: time,
              ),

            if (venue.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 7,
                    color: _gold,
                  ),
                  const SizedBox(width: 2.5),
                  Flexible(
                    child: Text(
                      venue,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _body,
                        fontFamily: theme.bodyFont,
                        fontSize: 6.6,
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ],

          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow({
    required DateTime? date,
    required String time,
  }) {
    final dateText = date == null
        ? ''
        : '${date.day.toString().padLeft(2, '0')} ${_month(date.month)} ${date.year}';

    final weekday = date == null ? '' : _weekday(date.weekday);

    final pieces = <String>[
      if (dateText.isNotEmpty) dateText,
      if (weekday.isNotEmpty) weekday,
      if (time.isNotEmpty) time,
    ];

    return Text(
      pieces.join('  •  '),
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: _body,
        fontFamily: theme.bodyFont,
        fontSize: 6.4,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
    );
  }

  DateTime? _parseEventDate(String value) {
    var input = value.trim();

    if (input.isEmpty) return null;

    final iso = DateTime.tryParse(input);
    if (iso != null) return iso;

    // Friday, 14 November 2026 -> 14 November 2026
    input = input.replaceFirst(
      RegExp(
        r'^(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday),?\s+',
        caseSensitive: false,
      ),
      '',
    );

    // 14 November 2026
    final longMatch = RegExp(
      r'^(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})$',
      caseSensitive: false,
    ).firstMatch(input);

    if (longMatch != null) {
      final day = int.tryParse(longMatch.group(1)!);
      final month = _monthNumber(longMatch.group(2)!);
      final year = int.tryParse(longMatch.group(3)!);

      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    // 14/11/2026
    final slashMatch = RegExp(
      r'^(\d{1,2})/(\d{1,2})/(\d{4})$',
    ).firstMatch(input);

    if (slashMatch != null) {
      final day = int.tryParse(slashMatch.group(1)!);
      final month = int.tryParse(slashMatch.group(2)!);
      final year = int.tryParse(slashMatch.group(3)!);

      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    // 14-11-2026
    final dashMatch = RegExp(
      r'^(\d{1,2})-(\d{1,2})-(\d{4})$',
    ).firstMatch(input);

    if (dashMatch != null) {
      final day = int.tryParse(dashMatch.group(1)!);
      final month = int.tryParse(dashMatch.group(2)!);
      final year = int.tryParse(dashMatch.group(3)!);

      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    return null;
  }

  String _month(int month) {
    const values = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];

    if (month < 1 || month > 12) return '';
    return values[month - 1];
  }

  int? _monthNumber(String value) {
    const values = <String, int>{
      'january': 1,
      'jan': 1,
      'february': 2,
      'feb': 2,
      'march': 3,
      'mar': 3,
      'april': 4,
      'apr': 4,
      'may': 5,
      'june': 6,
      'jun': 6,
      'july': 7,
      'jul': 7,
      'august': 8,
      'aug': 8,
      'september': 9,
      'sep': 9,
      'sept': 9,
      'october': 10,
      'oct': 10,
      'november': 11,
      'nov': 11,
      'december': 12,
      'dec': 12,
    };

    return values[value.trim().toLowerCase()];
  }

  String _weekday(int weekday) {
    const values = [
      'MON',
      'TUE',
      'WED',
      'THU',
      'FRI',
      'SAT',
      'SUN',
    ];

    if (weekday < 1 || weekday > 7) return '';
    return values[weekday - 1];
  }

  Widget _fallbackBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFE9D9),
            Color(0xFFFFD9D0),
            Color(0xFFFFF4E8),
          ],
        ),
      ),
    );
  }
}

class _EventEntrance extends StatelessWidget {
  final AnimationController controller;
  final int index;
  final Widget child;

  const _EventEntrance({
    required this.controller,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final start = (index * 0.08).clamp(0.0, 0.55);
    final end = (start + 0.35).clamp(0.0, 1.0);

    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(
        start,
        end,
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final value = animation.value;

        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: Transform.scale(
              scale: 0.985 + (value * 0.015),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _PetalPainter extends CustomPainter {
  final double progress;
  final double opacity;

  const _PetalPainter({
    required this.progress,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE96B8A).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 7; i++) {
      final phase = (progress + i / 7) % 1;

      final x = size.width * ((i * 0.173 + 0.08) % 1);
      final y = size.height * phase;

      canvas.save();

      canvas.translate(
        x + math.sin(phase * math.pi * 4 + i) * 5,
        y,
      );

      canvas.rotate(
        math.sin(phase * math.pi * 2 + i) * 0.5,
      );

      final path = Path()
        ..moveTo(0, -3)
        ..quadraticBezierTo(4, 0, 0, 4)
        ..quadraticBezierTo(-4, 0, 0, -3)
        ..close();

      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PetalPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
