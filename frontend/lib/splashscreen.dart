// splash_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'app_theme.dart';
import 'local_storage.dart';
import 'user_session.dart';
import 'translation_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _rippleController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _rippleScale;
  late Animation<double> _rippleOpacity;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0, 0.5)),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));
    _rippleScale = Tween<double>(begin: 0.0, end: 3.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );
    _rippleOpacity = Tween<double>(begin: 0.4, end: 0.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();
    _rippleController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _textController.forward();

    // Check local session (works offline)
    final hasSession = await LocalStorage.hasSession();
    if (hasSession) {
      final sessionData = await LocalStorage.loadSession();
      if (sessionData != null) {
        UserSession.currentUser = User.fromJson(sessionData);
      }
    }

    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) {
      if (hasSession) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A2118), Color(0xFF1B4332), Color(0xFF2D6A4F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Background leaf patterns
            Positioned(
              top: -60,
              right: -60,
              child: _buildLeafDecor(200, 0.06),
            ),
            Positioned(
              bottom: 60,
              left: -80,
              child: _buildLeafDecor(260, 0.08),
            ),
            Positioned(
              top: size.height * 0.15,
              left: -40,
              child: _buildLeafDecor(120, 0.05),
            ),

            // Ripple effect
            Center(
              child: AnimatedBuilder(
                animation: _rippleController,
                builder: (_, __) => Opacity(
                  opacity: _rippleOpacity.value,
                  child: Container(
                    width: 160 * _rippleScale.value,
                    height: 160 * _rippleScale.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryLight.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (_, __) => Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: _buildLogo(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Text
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (_, __) => FadeTransition(
                      opacity: _textOpacity,
                      child: SlideTransition(
                        position: _textSlide,
                        child: Column(
                          children: [
                            Text(
                              'AgroSmart'.tr,
                              style: const TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1.2,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Smart Farming, Brighter Future'.tr,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.7),
                                letterSpacing: 0.5,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 80),

                  // Loading dots
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (_, __) => FadeTransition(
                      opacity: _textOpacity,
                      child: _LoadingDots(),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom tagline
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _textController,
                builder: (_, __) => FadeTransition(
                  opacity: _textOpacity,
                  child: Text(
                    'Powered by AI · Grown with Heart'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.4),
                      letterSpacing: 1.5,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.primaryLight.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryLight.withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: CustomPaint(
          painter: _LeafLogoPainter(),
        ),
      ),
    );
  }

  Widget _buildLeafDecor(double size, double opacity) {
    return Opacity(
      opacity: opacity,
      child: Icon(
        Icons.eco,
        size: size,
        color: AppTheme.primaryLight,
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
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
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.33;
            final t = (_ctrl.value - delay).clamp(0.0, 1.0);
            final scale = 0.5 + 0.5 * math.sin(t * math.pi);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 7 * scale + 3,
              height: 7 * scale + 3,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withValues(alpha: 0.5 + 0.5 * scale),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

class _LeafLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryLight
      ..style = PaintingStyle.fill;

    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Leaf shape
    path.moveTo(cx, cy - size.height * 0.48);
    path.cubicTo(
      cx + size.width * 0.48, cy - size.height * 0.1,
      cx + size.width * 0.48, cy + size.height * 0.3,
      cx, cy + size.height * 0.48,
    );
    path.cubicTo(
      cx - size.width * 0.48, cy + size.height * 0.3,
      cx - size.width * 0.48, cy - size.height * 0.1,
      cx, cy - size.height * 0.48,
    );
    canvas.drawPath(path, paint);

    // Stem line
    final stemPaint = Paint()
      ..color = AppTheme.primaryDark.withValues(alpha: 0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx, cy - size.height * 0.3),
      Offset(cx, cy + size.height * 0.48),
      stemPaint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}