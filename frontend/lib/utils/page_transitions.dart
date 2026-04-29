import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Premium 3D page transitions for cinematic navigation.
///
/// All transitions use spring-physics curves for natural, Apple-level motion.

// ─── Depth Zoom Transition ───────────────────────────────────────────────────
// Old page scales down + fades out; new page scales up from 0.85 with fade-in.
// Used for: Login → Dashboard
class DepthZoomTransition extends PageRouteBuilder {
  final Widget page;

  DepthZoomTransition({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 600),
          reverseTransitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            // Incoming page
            final scaleIn = Tween<double>(begin: 0.85, end: 1.0)
                .animate(curvedAnimation);
            final fadeIn = Tween<double>(begin: 0.0, end: 1.0)
                .animate(curvedAnimation);
            final slideIn = Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(curvedAnimation);

            return SlideTransition(
              position: slideIn,
              child: ScaleTransition(
                scale: scaleIn,
                child: FadeTransition(
                  opacity: fadeIn,
                  child: child,
                ),
              ),
            );
          },
        );
}

// ─── 3D Flip Transition ──────────────────────────────────────────────────────
// Page rotates on Y-axis like turning a page in a book.
// Used for: Dashboard tab switches (optional)
class FlipPageTransition extends PageRouteBuilder {
  final Widget page;

  FlipPageTransition({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            );

            return AnimatedBuilder(
              animation: curved,
              builder: (context, _) {
                final angle = (1 - curved.value) * math.pi / 6; // 30 degrees max
                return Transform(
                  alignment: Alignment.centerRight,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // perspective
                    ..rotateY(angle),
                  child: Opacity(
                    opacity: curved.value.clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
            );
          },
        );
}

// ─── Slide & Perspective Transition ──────────────────────────────────────────
// New page slides in from the right with subtle perspective skew.
// Used for: Splash → Login
class SlidePerspectiveTransition extends PageRouteBuilder {
  final Widget page;

  SlidePerspectiveTransition({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 550),
          reverseTransitionDuration: const Duration(milliseconds: 450),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );

            return AnimatedBuilder(
              animation: curved,
              builder: (context, _) {
                final slide = (1 - curved.value);
                final perspective = slide * 0.015;
                return Transform(
                  alignment: Alignment.centerLeft,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, perspective) // perspective depth
                    ..translate(slide * 300, 0.0, 0.0), // slide from right
                  child: Opacity(
                    opacity: curved.value.clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
            );
          },
        );
}

// ─── Fade Scale Transition ───────────────────────────────────────────────────
// Simple elegant fade + gentle scale. Used for: Splash → Login
class FadeScaleTransition extends PageRouteBuilder {
  final Widget page;

  FadeScaleTransition({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 450),
          reverseTransitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            );

            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
                child: child,
              ),
            );
          },
        );
}
