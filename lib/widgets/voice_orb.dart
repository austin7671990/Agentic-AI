import 'package:flutter/material.dart';
import '../services/voice_service.dart';

class VoiceOrb extends StatelessWidget {
  final VoiceState state;
  final double audioLevel;
  final double size;

  const VoiceOrb({
    super.key,
    required this.state,
    this.audioLevel = 0.0,
    required this.size,
  });

  Color get _idleColor => const Color(0xFF667eea);
  Color get _listenColor => const Color(0xFF10b981);
  Color get _thinkColor => const Color(0xFFf59e0b);
  Color get _speakColor => const Color(0xFF3b82f6);

  Color get _primaryColor {
    switch (state) {
      case VoiceState.listening: return _listenColor;
      case VoiceState.thinking: return _thinkColor;
      case VoiceState.speaking: return _speakColor;
      default: return _idleColor;
    }
  }

  Color get _secondaryColor {
    switch (state) {
      case VoiceState.listening: return const Color(0xFF059669);
      case VoiceState.thinking: return const Color(0xFFd97706);
      case VoiceState.speaking: return const Color(0xFF2563eb);
      default: return const Color(0xFF764ba2);
    }
  }

  double get _pulseScale {
    switch (state) {
      case VoiceState.idle: return 1.0;
      case VoiceState.listening: return 1.0 + (audioLevel * 0.3);
      case VoiceState.thinking: return 1.0;
      case VoiceState.speaking: return 1.0;
      default: return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: _pulseScale),
      duration: const Duration(milliseconds: 150),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [_primaryColor, _secondaryColor],
                center: Alignment.center,
                radius: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.4),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
                BoxShadow(
                  color: _secondaryColor.withOpacity(0.2),
                  blurRadius: 80,
                  spreadRadius: 30,
                ),
              ],
            ),
            child: _buildInnerEffect(),
          ),
        );
      },
    );
  }

  Widget _buildInnerEffect() {
    switch (state) {
      case VoiceState.listening:
        return _AudioWaves(color: Colors.white.withOpacity(0.3));
      case VoiceState.thinking:
        return _SpinningRing(color: Colors.white.withOpacity(0.2));
      case VoiceState.speaking:
        return _RippleEffect(color: Colors.white.withOpacity(0.3));
      default:
        return _BreathingPulse(color: Colors.white.withOpacity(0.15));
    }
  }
}

class _BreathingPulse extends StatefulWidget {
  final Color color;
  const _BreathingPulse({required this.color});

  @override
  State<_BreathingPulse> createState() => _BreathingPulseState();
}

class _BreathingPulseState extends State<_BreathingPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(0.1 + (_controller.value * 0.2)),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _AudioWaves extends StatelessWidget {
  final Color color;
  const _AudioWaves({required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (i) {
          return _AudioBar(
            color: color,
            delay: i * 0.1,
            index: i,
          );
        }),
      ),
    );
  }
}

class _AudioBar extends StatefulWidget {
  final Color color;
  final double delay;
  final int index;
  const _AudioBar({required this.color, required this.delay, required this.index});

  @override
  State<_AudioBar> createState() => _AudioBarState();
}

class _AudioBarState extends State<_AudioBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final height = 8.0 + (_controller.value * 24.0 * (1.0 - (widget.index - 2).abs() * 0.2));
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 4,
          height: height,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _SpinningRing extends StatefulWidget {
  final Color color;
  const _SpinningRing({required this.color});

  @override
  State<_SpinningRing> createState() => _SpinningRingState();
}

class _SpinningRingState extends State<_SpinningRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * 3.14159,
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: widget.color, width: 2),
            ),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: widget.color.withOpacity(0.5), width: 1),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _RippleEffect extends StatefulWidget {
  final Color color;
  const _RippleEffect({required this.color});

  @override
  State<_RippleEffect> createState() => _RippleEffectState();
}

class _RippleEffectState extends State<_RippleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            _buildRipple(0.3 + (_controller.value * 0.4)),
            _buildRipple(0.1 + (_controller.value * 0.3)),
          ],
        );
      },
    );
  }

  Widget _buildRipple(double opacity) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: widget.color.withOpacity(opacity.clamp(0.0, 1.0)),
          width: 1,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}