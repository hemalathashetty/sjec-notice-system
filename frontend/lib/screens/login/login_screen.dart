import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/tilt_card.dart';
import '../../widgets/animated_list_item.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Animations
  late AnimationController _entranceController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;
  late Animation<double> _logoScale;

  // Parallax tracking
  double _mouseX = 0;
  double _mouseY = 0;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Logo scales in with elastic bounce
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    // Header text fades + slides in
    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );
    _headerSlide = Tween<Offset>(begin: const Offset(0, 20), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // Card slides up from below with spring feel
    _cardFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.4, 0.85, curve: Curves.easeOut),
      ),
    );
    _cardSlide = Tween<Offset>(begin: const Offset(0, 60), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.4, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final result = await AuthService.login(
      _emailController.text.trim().toLowerCase(),
      _passwordController.text,
    );
    setState(() => _isLoading = false);
    if (result['success']) {
      final route = AuthService.getRouteForRole(result['role']);
      if (mounted) Navigator.pushReplacementNamed(context, route);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message'] ?? 'Login failed'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: MouseRegion(
        onHover: (event) {
          final size = MediaQuery.of(context).size;
          setState(() {
            _mouseX = (event.position.dx / size.width - 0.5) * 2;
            _mouseY = (event.position.dy / size.height - 0.5) * 2;
          });
        },
        child: Column(
          children: [
            // ── Top Dark Section with Parallax ──
            AnimatedBuilder(
              animation: _entranceController,
              builder: (context, _) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 60, bottom: 40),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0A0E3F),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Subtle floating glow orb (parallax layer 1 — deep)
                      Positioned(
                        top: 20 + _mouseY * 8,
                        right: 60 + _mouseX * 12,
                        child: Container(
                          width: 120, height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [
                              AppColors.primary.withValues(alpha: 0.3),
                              Colors.transparent,
                            ]),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -20 + _mouseY * -5,
                        left: 40 + _mouseX * -8,
                        child: Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [
                              AppColors.primaryLight.withValues(alpha: 0.2),
                              Colors.transparent,
                            ]),
                          ),
                        ),
                      ),
                      // Main content (parallax layer 2 — foreground)
                      Transform.translate(
                        offset: Offset(_mouseX * 4, _mouseY * 3),
                        child: Column(
                          children: [
                            // Logo with scale entrance
                            Transform.scale(
                              scale: _logoScale.value,
                              child: Container(
                                width: 80, height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Image.asset(
                                      'assets/images/sjec_logo.jpg',
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.account_balance_rounded,
                                        color: Color(0xFF0A0E3F),
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Title with fade + slide
                            Transform.translate(
                              offset: _headerSlide.value,
                              child: Opacity(
                                opacity: _headerFade.value,
                                child: Column(
                                  children: [
                                    Text(
                                      'SJEC Notice Board',
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'St Joseph Engineering College',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // ── Glassmorphism divider strip ──
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.primaryLight.withValues(alpha: 0.4),
                    AppColors.primary.withValues(alpha: 0.6),
                    AppColors.primaryLight.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // ── Bottom White Section with Card ──
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: SingleChildScrollView(
                  child: AnimatedBuilder(
                    animation: _entranceController,
                    builder: (context, _) {
                      return Transform.translate(
                        offset: _cardSlide.value,
                        child: Opacity(
                          opacity: _cardFade.value,
                          child: _buildLoginForm(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Center(
      child: TiltCard(
        tiltIntensity: 0.005,
        maxElevation: 16.0,
        baseElevation: 3.0,
        borderRadius: BorderRadius.circular(16),
        shadowColor: AppColors.primary.withValues(alpha: 0.12),
        backgroundColor: Colors.white,
        border: Border.all(color: Colors.grey.shade100),
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedListItem(
                  index: 0,
                  child: Text(
                    'Welcome Back',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                AnimatedListItem(
                  index: 1,
                  child: Text(
                    'Sign in with your college email',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Email Field
                AnimatedListItem(
                  index: 2,
                  child: _buildInputField(
                    controller: _emailController,
                    label: 'College Email',
                    hint: 'admin@sjec.ac.in',
                    icon: Icons.email_outlined,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (!v.endsWith('@sjec.ac.in')) return 'Use college email';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Password Field
                AnimatedListItem(
                  index: 3,
                  child: _buildInputField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.black38,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 40),

                // Sign In Button with press-depth
                AnimatedListItem(
                  index: 4,
                  child: PressDepthButton(
                    onPressed: _isLoading ? null : _login,
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A237E), Color(0xFF283593)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'Sign In',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                AnimatedListItem(
                  index: 5,
                  child: Center(
                    child: Text(
                      'Only SJEC college emails are allowed',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.black38,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black45,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.black38),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
        ),
      ],
    );
  }
}