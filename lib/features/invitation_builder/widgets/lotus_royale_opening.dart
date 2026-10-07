import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/invitation_model.dart';

class LotusRoyaleOpening extends StatefulWidget {
  const LotusRoyaleOpening({
    super.key,
    required this.invitation,
    required this.onOpened,
  });

  final InvitationModel invitation;
  final VoidCallback onOpened;

  @override
  State<LotusRoyaleOpening> createState() => _LotusRoyaleOpeningState();
}

class _LotusRoyaleOpeningState extends State<LotusRoyaleOpening>
    with SingleTickerProviderStateMixin {
  static const String _coverAsset =
      'assets/invitations/lotus_royale/icons/lotus_opening_cover.webp';

  static const String _videoAsset =
      'assets/invitations/lotus_royale/icons/lotus_opening_reveal.mp4';

  VideoPlayerController? _videoController;

  late final AnimationController _sealGlowController;

  bool _videoInitialized = false;
  bool _isOpening = false;
  bool _hasFinished = false;
  bool _showFinalFade = false;

  @override
  void initState() {
    super.initState();

    _sealGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _prepareVideo();
  }

  Future<void> _prepareVideo() async {
    final controller = VideoPlayerController.asset(_videoAsset);

    _videoController = controller;

    try {
      await controller.initialize();

      await controller.setLooping(false);
      await controller.setVolume(0.0);

      controller.addListener(_videoListener);

      if (!mounted) {
        controller.removeListener(_videoListener);
        await controller.dispose();
        return;
      }

      setState(() {
        _videoInitialized = true;
      });
    } catch (e) {
      debugPrint('Lotus Royale opening video error: $e');

      if (mounted) {
        setState(() {
          _videoInitialized = false;
        });
      }
    }
  }

  void _videoListener() {
    final controller = _videoController;

    if (controller == null ||
        !controller.value.isInitialized ||
        _hasFinished) {
      return;
    }

    final position = controller.value.position;
    final duration = controller.value.duration;

    if (duration == Duration.zero) {
      return;
    }

    final remaining = duration - position;

    if (remaining <= const Duration(milliseconds: 100) &&
        !controller.value.isPlaying) {
      _finishOpening();
    }
  }

  Future<void> _startOpening() async {
    if (_isOpening || _hasFinished) {
      return;
    }

    final controller = _videoController;

    if (controller == null) {
      return;
    }

    setState(() {
      _isOpening = true;
    });

    _sealGlowController.stop();

    try {
      if (!_videoInitialized) {
        await controller.initialize();

        await controller.setLooping(false);
        await controller.setVolume(0.0);

        controller.addListener(_videoListener);

        if (mounted) {
          setState(() {
            _videoInitialized = true;
          });
        }
      }

      await controller.seekTo(Duration.zero);

      await controller.play();
    } catch (e) {
      debugPrint('Unable to play Lotus Royale opening: $e');

      if (mounted) {
        setState(() {
          _isOpening = false;
        });
      }
    }
  }

  void _finishOpening() {
    if (_hasFinished) {
      return;
    }

    _hasFinished = true;

    if (!mounted) {
      return;
    }

    setState(() {
      _showFinalFade = true;
    });

    Future.delayed(
      const Duration(milliseconds: 350),
      () {
        if (!mounted) return;

        widget.onOpened();
      },
    );
  }

  @override
  void dispose() {
    _sealGlowController.dispose();

    final controller = _videoController;

    if (controller != null) {
      controller.removeListener(_videoListener);
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F0E7),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // -------------------------------------------------------------
              // OPENING IMAGE
              // -------------------------------------------------------------

              if (!_isOpening)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _startOpening,
                  child: _buildOpeningCover(constraints),
                ),

              // -------------------------------------------------------------
              // VIDEO
              // -------------------------------------------------------------

              if (_isOpening && _videoInitialized)
                _buildRevealVideo(),

              // -------------------------------------------------------------
              // LOADING VIDEO
              // -------------------------------------------------------------

              if (_isOpening && !_videoInitialized)
                _buildVideoLoading(),

              // -------------------------------------------------------------
              // TAP INDICATOR
              // -------------------------------------------------------------

              if (!_isOpening)
                _buildTapIndicator(constraints),

              // -------------------------------------------------------------
              // FINAL WHITE TRANSITION
              // -------------------------------------------------------------

              IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _showFinalFade ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  child: Container(
                    color: const Color(0xFFFFFCF8),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // =========================================================================
  // COVER IMAGE
  // =========================================================================

  Widget _buildOpeningCover(BoxConstraints constraints) {
    return SizedBox.expand(
      child: Image.asset(
        _coverAsset,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (context, error, stackTrace) {
          return _buildAssetError(
            'Opening image could not be loaded.',
          );
        },
      ),
    );
  }

  // =========================================================================
  // VIDEO
  // =========================================================================

  Widget _buildRevealVideo() {
    final controller = _videoController;

    if (controller == null || !controller.value.isInitialized) {
      return _buildVideoLoading();
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        alignment: Alignment.center,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }

  // =========================================================================
  // VIDEO LOADING
  // =========================================================================

  Widget _buildVideoLoading() {
    return Container(
      color: const Color(0xFFF9F1E8),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: Color(0xFFC79A52),
        ),
      ),
    );
  }

  // =========================================================================
  // TAP INDICATOR
  // =========================================================================

  Widget _buildTapIndicator(BoxConstraints constraints) {
    final width = constraints.maxWidth;

    final compact = width < 600;

    return Positioned(
      left: 0,
      right: 0,
      bottom: compact ? 42 : 60,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _sealGlowController,
          builder: (context, child) {
            final pulse = _sealGlowController.value;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Gold glow
                Container(
                  width: 80 + (pulse * 12),
                  height: 80 + (pulse * 12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFD9AD61).withValues(
                          alpha: 0.10 + (pulse * 0.10),
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 2),

                // Text
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: const Color(0xFFC69A58).withValues(
                        alpha: 0.45,
                      ),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Text(
                    'TAP TO OPEN',
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 3.0,
                      color: Color(0xFF805E43),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // =========================================================================
  // ERROR
  // =========================================================================

  Widget _buildAssetError(String message) {
    return Container(
      color: const Color(0xFFF9F1E8),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.image_not_supported_outlined,
            size: 36,
            color: Color(0xFFB89060),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF765E50),
            ),
          ),
        ],
      ),
    );
  }
}