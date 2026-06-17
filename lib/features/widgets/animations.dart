import 'package:flutter/material.dart';

/// Slides up and fades in its child when inserted.
class SlideFadeIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double offset;
  final Curve curve;

  const SlideFadeIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.delay = Duration.zero,
    this.offset = 30,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<SlideFadeIn> createState() => _SlideFadeInState();
}

class _SlideFadeInState extends State<SlideFadeIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    _slide = Tween<Offset>(
      begin: Offset(0, widget.offset / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(opacity: _opacity, child: widget.child),
    );
  }
}

/// Wraps children with staggered slide-fade animations.
class StaggerFadeIn extends StatelessWidget {
  final List<Widget> children;
  final Duration itemDuration;
  final Duration staggerDelay;
  final double offset;

  const StaggerFadeIn({
    super.key,
    required this.children,
    this.itemDuration = const Duration(milliseconds: 350),
    this.staggerDelay = const Duration(milliseconds: 100),
    this.offset = 25,
  });

  @override
  Widget build(BuildContext context) {
    final list = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      list.add(
        _DelayedSlideFade(
          delay: staggerDelay * i,
          duration: itemDuration,
          offset: offset,
          child: children[i],
        ),
      );
    }
    return Column(children: list);
  }
}

class _DelayedSlideFade extends StatefulWidget {
  final Duration delay;
  final Duration duration;
  final double offset;
  final Widget child;

  const _DelayedSlideFade({
    required this.delay,
    required this.duration,
    required this.offset,
    required this.child,
  });

  @override
  State<_DelayedSlideFade> createState() => _DelayedSlideFadeState();
}

class _DelayedSlideFadeState extends State<_DelayedSlideFade>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
    _slide = Tween<Offset>(
      begin: Offset(0, widget.offset / 100),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(opacity: _opacity, child: widget.child),
    );
  }
}

/// Pulsing shimmer placeholder for loading states.
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
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: _animation.value),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

// ── Reusable skeleton layout patterns ──────────────────────────

/// A single shimmer row: circle + two text lines.
class SkeletonRow extends StatelessWidget {
  final double spacing;
  const SkeletonRow({super.key, this.spacing = 12});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing / 2),
      child: Row(
        children: [
          const ShimmerBox(width: 44, height: 44, borderRadius: 22),
          const SizedBox(width: 14),
          const Expanded(
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
      ),
      child: Row(
        children: [
          const ShimmerBox(width: 44, height: 44, borderRadius: 10),
          const SizedBox(width: 14),
          const Expanded(
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
          const ShimmerBox(width: 18, height: 18, borderRadius: 9),
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
      children: List.generate(
        count,
        (_) => SkeletonCard(height: cardHeight),
      ),
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
