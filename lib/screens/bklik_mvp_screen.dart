import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

enum BklikStage {
  toolSelect,
  video,
  fishChoice,
  wrongTool,
  success,
}

class BklikMvpScreen extends StatefulWidget {
  const BklikMvpScreen({super.key});

  @override
  State<BklikMvpScreen> createState() => _BklikMvpScreenState();
}

class _BklikMvpScreenState extends State<BklikMvpScreen> {
  BklikStage _stage = BklikStage.toolSelect;

  VideoPlayerController? _videoController;
  VoidCallback? _videoListener;

  bool _videoReady = false;
  bool _videoFinished = false;
  bool _isTransitioning = false;

  int _bklikIndex = 0;
  late List<String> _fishOrder;

  Timer? _wrongToolTimer;

  static const List<String> _fishAssets = [
    'assets/images/fish1.png',
    'assets/images/fish2.png',
    'assets/images/bklik.png',
  ];

  @override
  void initState() {
    super.initState();
    _shuffleFish();
  }

  void _shuffleFish() {
    _fishOrder = List<String>.from(_fishAssets)..shuffle();
    _bklikIndex = _fishOrder.indexOf('assets/images/bklik.png');
  }

  Future<void> _disposeVideo() async {
    final controller = _videoController;

    if (controller != null && _videoListener != null) {
      controller.removeListener(_videoListener!);
    }

    _videoListener = null;
    _videoController = null;

    if (controller != null) {
      await controller.pause();
      await controller.dispose();
    }
  }

  Future<void> _playVideo({
    required String assetPath,
    required FutureOr<void> Function() onFinished,
  }) async {
    if (_isTransitioning) return;

    _isTransitioning = true;
    await _disposeVideo();

    if (!mounted) return;

    setState(() {
      _stage = BklikStage.video;
      _videoReady = false;
      _videoFinished = false;
    });

    final controller = VideoPlayerController.asset(assetPath);
    _videoController = controller;

    try {
      await controller.initialize();

      if (!mounted || controller != _videoController) {
        await controller.dispose();
        return;
      }

      _videoListener = () async {
        final value = controller.value;

        if (_videoFinished ||
            !value.isInitialized ||
            value.duration == Duration.zero) {
          return;
        }

        final remaining = value.duration - value.position;

        if (remaining <= const Duration(milliseconds: 120)) {
          _videoFinished = true;

          if (_videoListener != null) {
            controller.removeListener(_videoListener!);
          }

          await onFinished();
        }
      };

      controller.addListener(_videoListener!);

      setState(() {
        _videoReady = true;
      });

      await controller.play();
    } catch (error) {
      debugPrint('Video error for $assetPath: $error');

      if (mounted) {
        setState(() {
          _stage = BklikStage.toolSelect;
          _videoReady = false;
        });
      }
    } finally {
      _isTransitioning = false;
    }
  }

  Future<void> _startCorrectFlow() async {
    await _playVideo(
      assetPath: 'assets/videos/intro.mp4',
      onFinished: () async {
        await _playVideo(
          assetPath: 'assets/videos/hook_drop.mp4',
          onFinished: () async {
            await _disposeVideo();

            if (!mounted) return;

            setState(() {
              _stage = BklikStage.fishChoice;
              _videoReady = false;
            });
          },
        );
      },
    );
  }

  void _showWrongTool() {
    _wrongToolTimer?.cancel();

    setState(() {
      _stage = BklikStage.wrongTool;
    });

    _wrongToolTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      setState(() {
        _stage = BklikStage.toolSelect;
      });
    });
  }

  Future<void> _selectFish(int index) async {
    if (_isTransitioning) return;

    if (index == _bklikIndex) {
      await _playVideo(
        assetPath: 'assets/videos/bklik_catch.mp4',
        onFinished: () async {
          await _playVideo(
            assetPath: 'assets/videos/success.mp4',
            onFinished: () async {
              await _disposeVideo();

              if (!mounted) return;

              setState(() {
                _stage = BklikStage.success;
                _videoReady = false;
              });
            },
          );
        },
      );
    } else {
      await _playVideo(
        assetPath: 'assets/videos/wrong_fish.mp4',
        onFinished: () async {
          await _disposeVideo();

          if (!mounted) return;

          setState(() {
            _stage = BklikStage.fishChoice;
            _videoReady = false;
          });
        },
      );
    }
  }

  Future<void> _restartGame() async {
    _wrongToolTimer?.cancel();
    await _disposeVideo();

    _shuffleFish();

    if (!mounted) return;

    setState(() {
      _stage = BklikStage.toolSelect;
      _videoReady = false;
      _videoFinished = false;
      _isTransitioning = false;
    });
  }

  @override
  void dispose() {
    _wrongToolTimer?.cancel();

    final controller = _videoController;

    if (controller != null && _videoListener != null) {
      controller.removeListener(_videoListener!);
    }

    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case BklikStage.toolSelect:
        return _buildToolSelectScreen();

      case BklikStage.fishChoice:
        return _buildFishChoiceScreen();

      case BklikStage.wrongTool:
        return _buildWrongToolScreen();

      case BklikStage.success:
        return _buildSuccessScreen();

      case BklikStage.video:
        return _buildVideoScreen();
    }
  }

  Widget _buildToolSelectScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF8DDAEB),
      body: SafeArea(
        child: Center(
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;

                return Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/tools_screen.png',
                        fit: BoxFit.fill,
                      ),
                    ),

                    // Boat: սխալ ընտրություն
                    _tapZone(
                      left: width * 0.20,
                      top: height * 0.10,
                      width: width * 0.60,
                      height: height * 0.25,
                      onTap: _showWrongTool,
                    ),

                    // Hook: ճիշտ ընտրություն
                    _tapZone(
                      left: width * 0.20,
                      top: height * 0.37,
                      width: width * 0.60,
                      height: height * 0.27,
                      onTap: _startCorrectFlow,
                    ),

                    // Net: սխալ ընտրություն
                    _tapZone(
                      left: width * 0.17,
                      top: height * 0.66,
                      width: width * 0.66,
                      height: height * 0.27,
                      onTap: _showWrongTool,
                    ),

                    // Պարզ animated hand hint դեպի կարթը
                    Positioned(
                      left: width * 0.60,
                      top: height * 0.47,
                      child: const HandHint(
                        icon: '👆',
                        size: 48,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFishChoiceScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF8DDAEB),
      body: SafeArea(
        child: Center(
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;

                final fishWidth = width * 0.55;
                final fishHeight = height * 0.19;
                final fishLeft = (width - fishWidth) / 2;

                return Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/fish_choice_background.png',
                        fit: BoxFit.fill,
                      ),
                    ),

                    _fishButton(
                      index: 0,
                      left: fishLeft,
                      top: height * 0.15,
                      width: fishWidth,
                      height: fishHeight,
                    ),

                    _fishButton(
                      index: 1,
                      left: fishLeft,
                      top: height * 0.40,
                      width: fishWidth,
                      height: fishHeight,
                    ),

                    _fishButton(
                      index: 2,
                      left: fishLeft,
                      top: height * 0.65,
                      width: fishWidth,
                      height: fishHeight,
                    ),

                    Positioned(
                      left: width * 0.67,
                      top: height * 0.22,
                      child: const HandHint(
                        icon: '👆',
                        size: 46,
                      ),
                    ),

                    Positioned(
                      right: width * 0.04,
                      bottom: height * 0.025,
                      child: _roundIconButton(
                        icon: Icons.refresh_rounded,
                        onPressed: _restartGame,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWrongToolScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF8DDAEB),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _wrongToolTimer?.cancel();

          setState(() {
            _stage = BklikStage.toolSelect;
          });
        },
        child: Center(
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: Image.asset(
              'assets/images/wrong_answer.png',
              fit: BoxFit.fill,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF8DDAEB),
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF90E5F4),
                    Color(0xFF31B9DC),
                  ],
                ),
              ),
            ),
          ),
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '🎉',
                  style: TextStyle(fontSize: 100),
                ),
                SizedBox(height: 16),
                Text(
                  '🐠',
                  style: TextStyle(fontSize: 90),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 50,
            child: Center(
              child: _roundIconButton(
                icon: Icons.replay_rounded,
                onPressed: _restartGame,
                size: 70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoScreen() {
    final controller = _videoController;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: _videoReady && controller != null
                ? FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: controller.value.size.width,
                      height: controller.value.size.height,
                      child: VideoPlayer(controller),
                    ),
                  )
                : const Center(
                    child: CircularProgressIndicator(),
                  ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            right: 12,
            child: IconButton.filledTonal(
              onPressed: _restartGame,
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fishButton({
    required int index,
    required double left,
    required double top,
    required double width,
    required double height,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _selectFish(index),
        child: AnimatedScale(
          scale: 1,
          duration: const Duration(milliseconds: 200),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Image.asset(
              _fishOrder[index],
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }

  Widget _tapZone({
    required double left,
    required double top,
    required double width,
    required double height,
    required VoidCallback onTap,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: const ColoredBox(
          color: Colors.transparent,
        ),
      ),
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 58,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: Colors.white.withValues(alpha: 0.92),
        elevation: 6,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Icon(
            icon,
            size: size * 0.52,
            color: const Color(0xFF137A9A),
          ),
        ),
      ),
    );
  }
}

class HandHint extends StatefulWidget {
  final String icon;
  final double size;

  const HandHint({
    super.key,
    this.icon = '👆',
    this.size = 48,
  });

  @override
  State<HandHint> createState() => _HandHintState();
}

class _HandHintState extends State<HandHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _verticalMovement;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _verticalMovement = Tween<double>(
      begin: 0,
      end: 15,
    ).animate(curve);

    _scale = Tween<double>(
      begin: 0.95,
      end: 1.15,
    ).animate(curve);

    _opacity = Tween<double>(
      begin: 0.65,
      end: 1,
    ).animate(curve);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _opacity.value,
            child: Transform.translate(
              offset: Offset(0, _verticalMovement.value),
              child: Transform.scale(
                scale: _scale.value,
                child: child,
              ),
            ),
          );
        },
        child: Text(
          widget.icon,
          style: TextStyle(
            fontSize: widget.size,
            shadows: const [
              Shadow(
                blurRadius: 8,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}