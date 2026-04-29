import 'package:flutter/material.dart';

/// A widget that animates its child into view with a staggered
/// slide-up + fade-in effect based on its index in a list.
///
/// Provides a premium "items appearing one by one" animation
/// commonly seen in high-end product websites.
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;
  final Offset slideOffset;
  final Curve curve;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 80),
    this.duration = const Duration(milliseconds: 500),
    this.slideOffset = const Offset(0, 30),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
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

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    _slide = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    // Stagger the animation start based on index
    Future.delayed(widget.delay * widget.index, () {
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _slide.value,
          child: Opacity(
            opacity: _opacity.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// A hover-lift effect wrapper that elevates content on mouse hover
/// with smooth shadow and scale animation.
class HoverLift extends StatefulWidget {
  final Widget child;
  final double liftAmount;
  final Duration duration;

  const HoverLift({
    super.key,
    required this.child,
    this.liftAmount = 4.0,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..translate(0.0, _isHovered ? -widget.liftAmount : 0.0, 0.0),
        child: widget.child,
      ),
    );
  }
}

/// A press-depth button wrapper that gives a tactile "push into surface" feel.
class PressDepthButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double pressScale;
  final Duration duration;

  const PressDepthButton({
    super.key,
    required this.child,
    this.onPressed,
    this.pressScale = 0.96,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<PressDepthButton> createState() => _PressDepthButtonState();
}

class _PressDepthButtonState extends State<PressDepthButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? widget.pressScale : 1.0,
        duration: widget.duration,
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}
