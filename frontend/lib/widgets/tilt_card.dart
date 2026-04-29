import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

/// A premium 3D tilt card that tracks the mouse cursor and applies
/// perspective transforms for an interactive, gyroscope-like effect.
///
/// Features:
/// - Mouse-tracking 3D tilt using Matrix4 perspective
/// - Dynamic shadow that moves opposite to tilt direction
/// - Smooth hover elevation change
/// - Configurable tilt intensity and shadow depth
class TiltCard extends StatefulWidget {
  final Widget child;
  final double tiltIntensity;
  final double maxElevation;
  final double baseElevation;
  final BorderRadius borderRadius;
  final Color? shadowColor;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final Border? border;
  final VoidCallback? onTap;

  const TiltCard({
    super.key,
    required this.child,
    this.tiltIntensity = 0.008,
    this.maxElevation = 20.0,
    this.baseElevation = 4.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.shadowColor,
    this.backgroundColor,
    this.padding,
    this.border,
    this.onTap,
  });

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> with SingleTickerProviderStateMixin {
  double _rotateX = 0;
  double _rotateY = 0;
  double _elevation = 4.0;
  bool _isHovered = false;

  late AnimationController _resetController;
  late Animation<double> _resetX;
  late Animation<double> _resetY;
  late Animation<double> _resetElevation;

  @override
  void initState() {
    super.initState();
    _elevation = widget.baseElevation;
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onHover(PointerHoverEvent event) {
    if (!mounted) return;
    final RenderBox box = context.findRenderObject() as RenderBox;
    final size = box.size;
    final local = box.globalToLocal(event.position);

    // Calculate normalized offset from center (-0.5 to 0.5)
    final dx = (local.dx / size.width) - 0.5;
    final dy = (local.dy / size.height) - 0.5;

    setState(() {
      _rotateX = -dy * widget.tiltIntensity * 100; // tilt on X based on vertical position
      _rotateY = dx * widget.tiltIntensity * 100;  // tilt on Y based on horizontal position
      _elevation = widget.maxElevation;
      _isHovered = true;
    });
  }

  void _onExit(PointerExitEvent event) {
    // Smoothly animate back to flat position
    _resetX = Tween<double>(begin: _rotateX, end: 0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutCubic),
    );
    _resetY = Tween<double>(begin: _rotateY, end: 0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutCubic),
    );
    _resetElevation = Tween<double>(begin: _elevation, end: widget.baseElevation).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutCubic),
    );

    _resetController.reset();
    _resetController.forward();

    _resetController.addListener(() {
      if (mounted) {
        setState(() {
          _rotateX = _resetX.value;
          _rotateY = _resetY.value;
          _elevation = _resetElevation.value;
        });
      }
    });

    setState(() => _isHovered = false);
  }

  @override
  Widget build(BuildContext context) {
    final shadowCol = widget.shadowColor ?? Colors.black.withValues(alpha: 0.12);

    return MouseRegion(
      onHover: _onHover,
      onExit: _onExit,
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: _isHovered ? const Duration(milliseconds: 50) : const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          transformAlignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..rotateX(_rotateX * 0.0174533) // degrees to radians
            ..rotateY(_rotateY * 0.0174533),
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? Colors.white,
            borderRadius: widget.borderRadius,
            border: widget.border,
            boxShadow: [
              BoxShadow(
                color: shadowCol,
                blurRadius: _elevation * 2,
                offset: Offset(-_rotateY * 0.6, _rotateX * 0.6 + _elevation * 0.5),
                spreadRadius: _isHovered ? 2 : 0,
              ),
              if (_isHovered)
                BoxShadow(
                  color: shadowCol.withValues(alpha: 0.06),
                  blurRadius: _elevation * 3,
                  offset: Offset(-_rotateY * 1.2, _rotateX * 1.2 + _elevation),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: widget.borderRadius,
            child: Padding(
              padding: widget.padding ?? EdgeInsets.zero,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
