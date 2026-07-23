import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ─── Re-export flutter_animate so screens only need one import ───
export 'package:flutter_animate/flutter_animate.dart';

// ════════════════════════════════════════════════════════════════
//  0. Reduced motion
// ════════════════════════════════════════════════════════════════

/// Honours the platform "remove animations" accessibility setting.
extension MotionQuery on BuildContext {
  /// True when the user has asked the OS to minimise animation.
  bool get reduceMotion => MediaQuery.maybeDisableAnimationsOf(this) ?? false;

  /// Collapses [duration] to zero when reduced motion is requested.
  Duration motion(Duration duration) => reduceMotion ? Duration.zero : duration;
}

// ════════════════════════════════════════════════════════════════
//  1. SlideFadeIn — slides up + fades in on mount
// ════════════════════════════════════════════════════════════════

/// Slides up and fades in its child when inserted.
class SlideFadeIn extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double offset;
  final Curve curve;

  const SlideFadeIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 450),
    this.delay = Duration.zero,
    this.offset = 28,
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return child;
    return child
        .animate(delay: delay)
        .fadeIn(duration: duration, curve: curve)
        .slideY(begin: offset / 100, end: 0, duration: duration, curve: curve);
  }
}

// ════════════════════════════════════════════════════════════════
//  2. StaggerFadeIn — staggered slide-fade for list items
// ════════════════════════════════════════════════════════════════

/// Wraps children with staggered slide-fade animations.
class StaggerFadeIn extends StatelessWidget {
  final List<Widget> children;
  final Duration itemDuration;
  final Duration staggerDelay;
  final double offset;

  const StaggerFadeIn({
    super.key,
    required this.children,
    this.itemDuration = const Duration(milliseconds: 380),
    this.staggerDelay = const Duration(milliseconds: 80),
    this.offset = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < children.length; i++)
          children[i]
              .animate(delay: staggerDelay * i)
              .fadeIn(duration: itemDuration, curve: Curves.easeOutCubic)
              .slideY(
                begin: offset / 100,
                end: 0,
                duration: itemDuration,
                curve: Curves.easeOutCubic,
              ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  3. BounceIn — spring-scale entrance for cards / FABs
// ════════════════════════════════════════════════════════════════

/// Spring-scale entrance. Great for cards, dialogs, FABs.
class BounceIn extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double beginScale;

  const BounceIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
    this.beginScale = 0.72,
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: delay)
        .fadeIn(duration: duration, curve: Curves.easeOut)
        .scale(
          begin: Offset(beginScale, beginScale),
          end: const Offset(1, 1),
          duration: duration,
          curve: Curves.elasticOut,
        );
  }
}

// ════════════════════════════════════════════════════════════════
//  4. ShimmerBox — real diagonal shimmer sweep (not opacity fade)
// ════════════════════════════════════════════════════════════════

class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.grey.shade200;
    final highlightColor = Colors.grey.shade100;

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_anim.value - 1, -0.3),
              end: Alignment(_anim.value, 0.3),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  5. PulseDot — breathing status indicator
// ════════════════════════════════════════════════════════════════

/// A breathing dot — perfect for "in_progress", "pending", live states.
class PulseDot extends StatelessWidget {
  final Color color;
  final double size;

  const PulseDot({super.key, required this.color, this.size = 8});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 2.2,
      height: size * 2.2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulsing ring
          Container(
                width: size * 2.2,
                height: size * 2.2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.25),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(
                begin: 0.5,
                end: 1.0,
                duration: 900.ms,
                curve: Curves.easeInOut,
              )
              .fadeIn(begin: 0.1, duration: 900.ms),

          // Inner solid dot
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  6. WaveLoadingIndicator — 3-dot wave (for chats / loading)
// ════════════════════════════════════════════════════════════════

class WaveLoadingIndicator extends StatelessWidget {
  final Color color;
  final double dotSize;

  const WaveLoadingIndicator({
    super.key,
    this.color = const Color(0xFF2563EB),
    this.dotSize = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child:
              Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  )
                  .animate(
                    onPlay: (c) => c.repeat(),
                    delay: Duration(milliseconds: i * 160),
                  )
                  .moveY(
                    begin: 0,
                    end: -dotSize * 0.85,
                    duration: 420.ms,
                    curve: Curves.easeInOut,
                  )
                  .then()
                  .moveY(
                    begin: -dotSize * 0.85,
                    end: 0,
                    duration: 420.ms,
                    curve: Curves.easeInOut,
                  ),
        );
      }),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  7. SuccessCheckmark — animated SVG-like checkmark
// ════════════════════════════════════════════════════════════════

class SuccessCheckmark extends StatefulWidget {
  final double size;
  final Color color;
  final Color checkColor;
  final Duration duration;
  final VoidCallback? onComplete;

  const SuccessCheckmark({
    super.key,
    this.size = 80,
    this.color = const Color(0xFF10B981),
    this.checkColor = Colors.white,
    this.duration = const Duration(milliseconds: 700),
    this.onComplete,
  });

  @override
  State<SuccessCheckmark> createState() => _SuccessCheckmarkState();
}

class _SuccessCheckmarkState extends State<SuccessCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _circleAnim;
  late Animation<double> _checkAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _circleAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    _checkAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
    );
    _ctrl.forward().then((_) => widget.onComplete?.call());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, child) => CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _CheckmarkPainter(
          circleProgress: _circleAnim.value,
          checkProgress: _checkAnim.value,
          circleColor: widget.color,
          checkColor: widget.checkColor,
        ),
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double circleProgress;
  final double checkProgress;
  final Color circleColor;
  final Color checkColor;

  _CheckmarkPainter({
    required this.circleProgress,
    required this.checkProgress,
    required this.circleColor,
    required this.checkColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Fill circle
    canvas.drawCircle(
      center,
      radius * circleProgress,
      Paint()..color = circleColor,
    );

    // Checkmark path
    if (checkProgress > 0) {
      final path = Path()
        ..moveTo(size.width * 0.25, size.height * 0.52)
        ..lineTo(size.width * 0.44, size.height * 0.70)
        ..lineTo(size.width * 0.75, size.height * 0.35);

      final metrics = path.computeMetrics().first;
      final drawPath = metrics.extractPath(0, metrics.length * checkProgress);

      canvas.drawPath(
        drawPath,
        Paint()
          ..color = checkColor
          ..strokeWidth = size.width * 0.08
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_CheckmarkPainter old) =>
      old.circleProgress != circleProgress ||
      old.checkProgress != checkProgress;
}

// ════════════════════════════════════════════════════════════════
//  8. AnimatedCountUp — smooth number counter
// ════════════════════════════════════════════════════════════════

class AnimatedCountUp extends StatefulWidget {
  final int end;
  final int begin;
  final Duration duration;
  final TextStyle? style;
  final String prefix;
  final String suffix;

  const AnimatedCountUp({
    super.key,
    required this.end,
    this.begin = 0,
    this.duration = const Duration(milliseconds: 1200),
    this.style,
    this.prefix = '',
    this.suffix = '',
  });

  @override
  State<AnimatedCountUp> createState() => _AnimatedCountUpState();
}

class _AnimatedCountUpState extends State<AnimatedCountUp>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = Tween<double>(
      begin: widget.begin.toDouble(),
      end: widget.end.toDouble(),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (ctx, child) => Text(
        '${widget.prefix}${_anim.value.round()}${widget.suffix}',
        style: widget.style,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  9. PageTransitions — custom route builder helpers
// ════════════════════════════════════════════════════════════════

class AppPageTransitions {
  AppPageTransitions._();

  /// Slide up + fade. Use for bottom sheets promoted to full pages.
  static Route<T> slideUpFade<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (ctx, a1, a2) => page,
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
        final slide =
            Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }

  /// Scale + fade. Use for detail screens or modals.
  static Route<T> scaleFade<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (ctx, a1, a2) => page,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (ctx, animation, a2, child) {
        final scale = Tween<double>(begin: 0.94, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
    );
  }

  /// Horizontal slide. Use for step-by-step flows.
  static Route<T> slideHorizontal<T>(Widget page, {bool fromRight = true}) {
    return PageRouteBuilder<T>(
      pageBuilder: (ctx, a1, a2) => page,
      transitionDuration: const Duration(milliseconds: 360),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
        final begin = Offset(fromRight ? 1.0 : -1.0, 0);
        final slide = Tween<Offset>(begin: begin, end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );
        final secondary =
            Tween<Offset>(
              begin: Offset.zero,
              end: Offset(fromRight ? -0.3 : 0.3, 0),
            ).animate(
              CurvedAnimation(
                parent: secondaryAnimation,
                curve: Curves.easeOutCubic,
              ),
            );
        return SlideTransition(
          position: secondary,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  10. Skeleton layouts (enhanced with real shimmer)
// ════════════════════════════════════════════════════════════════

/// A single shimmer row: circle + two text lines.
class SkeletonRow extends StatelessWidget {
  final double spacing;
  const SkeletonRow({super.key, this.spacing = 12});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing / 2),
      child: const Row(
        children: [
          ShimmerBox(width: 44, height: 44, borderRadius: 22),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(height: 14, borderRadius: 6),
                SizedBox(height: 8),
                ShimmerBox(width: 140, height: 11, borderRadius: 5),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A card skeleton with optional trailing icon space.
class SkeletonCard extends StatelessWidget {
  final double height;
  const SkeletonCard({super.key, this.height = 100});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        children: [
          ShimmerBox(width: 44, height: 44, borderRadius: 10),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(height: 14, borderRadius: 6),
                SizedBox(height: 8),
                ShimmerBox(width: 120, height: 11, borderRadius: 5),
              ],
            ),
          ),
          ShimmerBox(width: 18, height: 18, borderRadius: 9),
        ],
      ),
    );
  }
}

/// Repeated card skeletons for list loading.
class SkeletonList extends StatelessWidget {
  final int count;
  final double cardHeight;
  const SkeletonList({super.key, this.count = 5, this.cardHeight = 100});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (_) => SkeletonCard(height: cardHeight)),
    );
  }
}

/// A block skeleton: top area + body rows.
class SkeletonBlock extends StatelessWidget {
  final int rows;
  const SkeletonBlock({super.key, this.rows = 4});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(width: 160, height: 16, borderRadius: 6),
          const SizedBox(height: 18),
          ...List.generate(rows, (_) {
            return const Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  ShimmerBox(width: 18, height: 18, borderRadius: 4),
                  SizedBox(width: 12),
                  Expanded(child: ShimmerBox(height: 13, borderRadius: 5)),
                  SizedBox(width: 12),
                  ShimmerBox(width: 60, height: 13, borderRadius: 5),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Full-screen seat grid skeleton (matches seat layout: 4 cols + aisle).
class SkeletonSeatGrid extends StatelessWidget {
  final int rows;
  const SkeletonSeatGrid({super.key, this.rows = 7});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(
          children: [
            Expanded(child: ShimmerBox(height: 44, borderRadius: 10)),
            SizedBox(width: 8),
            Expanded(child: ShimmerBox(height: 44, borderRadius: 10)),
            SizedBox(width: 28),
            Expanded(child: ShimmerBox(height: 44, borderRadius: 10)),
            SizedBox(width: 8),
            Expanded(child: ShimmerBox(height: 44, borderRadius: 10)),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(rows, (_) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(child: ShimmerBox(height: 56, borderRadius: 10)),
                SizedBox(width: 8),
                Expanded(child: ShimmerBox(height: 56, borderRadius: 10)),
                SizedBox(width: 28),
                Expanded(child: ShimmerBox(height: 56, borderRadius: 10)),
                SizedBox(width: 8),
                Expanded(child: ShimmerBox(height: 56, borderRadius: 10)),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  11. TapScaleEffect — press-to-scale wrapper
// ════════════════════════════════════════════════════════════════

/// Wraps any widget with a subtle scale-down on press.
class TapScaleEffect extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  const TapScaleEffect({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.95,
  });

  @override
  State<TapScaleEffect> createState() => _TapScaleEffectState();
}

class _TapScaleEffectState extends State<TapScaleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: widget.scale,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  12. GlowContainer — glowing card effect
// ════════════════════════════════════════════════════════════════

/// A container with an animated glow effect. Great for featured cards.
class GlowContainer extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  const GlowContainer({
    super.key,
    required this.child,
    required this.glowColor,
    this.borderRadius = 16,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: glowColor.withValues(alpha: 0.15),
                blurRadius: 40,
                spreadRadius: 4,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .custom(
          duration: 2400.ms,
          curve: Curves.easeInOut,
          builder: (context, value, child) =>
              Transform.scale(scale: 1.0 + (value * 0.008), child: child),
        );
  }
}

// ════════════════════════════════════════════════════════════════
//  Helper to suppress unused import warning for math
// ════════════════════════════════════════════════════════════════
// ignore: unused_element
const _kPi = 3.141592653589793;
