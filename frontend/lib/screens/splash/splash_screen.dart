import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/colors.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();

    // Main entrance animations
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    // Continuous pulsing effect for the background
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
      ),
    );

    _mainController.forward();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 6));
    if (!mounted) return;

    final isLoggedIn = await AuthService.isLoggedIn();
    if (isLoggedIn) {
      final userInfo = await ApiService.getUserInfo();
      final role = userInfo['role'] ?? '';
      final route = AuthService.getRouteForRole(role);
      if (mounted) {
        Navigator.pushReplacementNamed(context, route);
      }
    } else {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D1642), // Primary dark
              Color(0xFF1A237E), // Primary
              Color(0xFF00BCD4), // Accent color mapped for vibrant look
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background pulsing decorative circles
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 300 + (_pulseController.value * 60),
                        height: 300 + (_pulseController.value * 60),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.02),
                        ),
                      ),
                      Container(
                        width: 200 + (_pulseController.value * 40),
                        height: 200 + (_pulseController.value * 40),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.04),
                        ),
                      ),
                    ],
                  );
                },
              ),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  
                  // Logo
                  AnimatedBuilder(
                    animation: _mainController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoScale.value,
                        child: Opacity(
                          opacity: _logoOpacity.value,
                          child: Container(
                            width: 140,
                            height: 140,
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withOpacity(0.3),
                                  blurRadius: 40,
                                  spreadRadius: 8,
                                  offset: const Offset(0, 15),
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/sjec_logo.jpg',
                              width: 80,
                              height: 80,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.account_balance,
                                  size: 72,
                                  color: AppColors.primary,
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 56),

                  // Texts
                  AnimatedBuilder(
                    animation: _mainController,
                    builder: (context, child) {
                      return SlideTransition(
                        position: _textSlide,
                        child: Opacity(
                          opacity: _textOpacity.value,
                          child: Column(
                            children: [
                              Text(
                                'SJEC',
                                style: GoogleFonts.poppins(
                                  fontSize: 60,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 10,
                                  height: 1.0,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'St Joseph Engineering College',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.9),
                                  letterSpacing: 2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.campaign_rounded,
                                      color: Colors.white.withOpacity(0.9),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Smart Notice Board',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const Spacer(),

                  // Custom smooth loading indicator
                  AnimatedBuilder(
                    animation: _mainController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _textOpacity.value,
                        child: Column(
                          children: [
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    color: Colors.white.withOpacity(0.15),
                                    strokeWidth: 4,
                                  ),
                                  const CircularProgressIndicator(
                                    color: AppColors.accent,
                                    strokeWidth: 4,
                                    strokeCap: StrokeCap.round,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}