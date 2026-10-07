import 'package:flutter/material.dart';

import '../models/invitation_model.dart';
import '../renderer/invitation_renderer.dart';
import '../services/invitation_publish_service.dart';
import '../widgets/lotus_royale_opening.dart';

/// Public wedding invitation screen.
///
/// Flow:
///
/// URL
///   ↓
/// Load published invitation
///   ↓
/// Lotus Royale opening envelope
///   ↓
/// User taps wax seal
///   ↓
/// Envelope opens
///   ↓
/// Actual invitation website
///   ↓
/// Premium 3D scrolling
class PublicInvitationScreen extends StatefulWidget {
  const PublicInvitationScreen({
    super.key,
    required this.slug,
  });

  final String slug;

  @override
  State<PublicInvitationScreen> createState() =>
      _PublicInvitationScreenState();
}

class _PublicInvitationScreenState
    extends State<PublicInvitationScreen> {
  final InvitationPublishService _publishService =
      InvitationPublishService();

  late Future<InvitationModel?> _invitationFuture;

  bool _invitationOpened = false;

  @override
  void initState() {
    super.initState();

    _invitationFuture = _loadInvitation();
  }

  Future<InvitationModel?> _loadInvitation() {
    return _publishService.getPublishedInvitation(
      widget.slug,
    );
  }

  Future<void> _retry() async {
    setState(() {
      _invitationOpened = false;
      _invitationFuture = _loadInvitation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7EDE6),
      body: FutureBuilder<InvitationModel?>(
        future: _invitationFuture,
        builder: (
          context,
          snapshot,
        ) {
          // ============================================================
          // LOADING DATA
          // ============================================================

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const _InvitationInitialLoadingView();
          }

          // ============================================================
          // ERROR
          // ============================================================

          if (snapshot.hasError) {
            return _InvitationErrorView(
              onRetry: _retry,
            );
          }

          // ============================================================
          // NOT FOUND
          // ============================================================

          final InvitationModel? invitation =
              snapshot.data;

          if (invitation == null) {
            return const _InvitationNotFoundView();
          }

          // ============================================================
          // ENVELOPE OPENING
          // ============================================================

          if (!_invitationOpened) {
            return LotusRoyaleOpening(
              invitation: invitation,
              onOpened: () {
                if (!mounted) return;

                setState(() {
                  _invitationOpened = true;
                });
              },
            );
          }

          // ============================================================
          // ACTUAL PUBLIC INVITATION
          // ============================================================

          return _PublicInvitationContent(
            invitation: invitation,
          );
        },
      ),
    );
  }
}

// ============================================================================
// PUBLIC INVITATION CONTENT
// ============================================================================

class _PublicInvitationContent extends StatelessWidget {
  const _PublicInvitationContent({
    required this.invitation,
  });

  final InvitationModel invitation;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: InvitationRenderer(
        invitation: invitation,
        isPreview: false,
      ),
    );
  }
}

// ============================================================================
// INITIAL FIRESTORE LOADING
// ============================================================================

class _InvitationInitialLoadingView
    extends StatefulWidget {
  const _InvitationInitialLoadingView();

  @override
  State<_InvitationInitialLoadingView> createState() =>
      _InvitationInitialLoadingViewState();
}

class _InvitationInitialLoadingViewState
    extends State<_InvitationInitialLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF7EDE6),
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final scale =
                0.96 +
                (0.04 *
                    ((1 +
                            ((_controller.value * 2) *
                                3.14159265359)
                                .clamp(
                                  -1.0,
                                  1.0,
                                )) /
                        2));

            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: 0.07,
                      ),
                      blurRadius: 25,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mail_outline_rounded,
                  size: 25,
                  color: Color(0xFFA83D58),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Preparing your invitation',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4B302C),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// NOT FOUND
// ============================================================================

class _InvitationNotFoundView
    extends StatelessWidget {
  const _InvitationNotFoundView();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF5F1EC),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: Color(0xFFF2D2C8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  size: 34,
                  color: Color(0xFFA83D58),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Invitation not found',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3D2926),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This invitation may have been unpublished or the link may be incorrect.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  height: 1.5,
                  fontSize: 14,
                  color: Color(0xFF806F68),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ERROR
// ============================================================================

class _InvitationErrorView
    extends StatelessWidget {
  const _InvitationErrorView({
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF5F1EC),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: Color(0xFFA83D58),
              ),
              const SizedBox(height: 18),
              const Text(
                'Unable to open invitation',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3D2926),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please check your connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF806F68),
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFA83D58),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 13,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}