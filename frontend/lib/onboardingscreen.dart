// onboarding_screen.dart
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'translation_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  final List<_OnboardingData> _pages = const [
    _OnboardingData(
      icon: Icons.wb_sunny_rounded,
      iconColor: Color(0xFFF4A261),
      bgColor: Color(0xFFFFF3E8),
      title: 'Smart Crop Advisory',
      subtitle:
      'Get AI-powered recommendations tailored to your soil, crops, and local conditions.',
      illustration: '🌾',
    ),
    _OnboardingData(
      icon: Icons.cloud_rounded,
      iconColor: Color(0xFF4CC9F0),
      bgColor: Color(0xFFE8F7FF),
      title: 'Real-Time Weather',
      subtitle:
      'Hyper-local forecasts and rain alerts to help you plan every farming activity.',
      illustration: '⛅',
    ),
    _OnboardingData(
      icon: Icons.bug_report_rounded,
      iconColor: Color(0xFFE63946),
      bgColor: Color(0xFFFFE8EA),
      title: 'Pest & Disease Watch',
      subtitle:
      'Detect threats early with AI image recognition and get instant treatment guides.',
      illustration: '🔬',
    ),
    _OnboardingData(
      icon: Icons.trending_up_rounded,
      iconColor: Color(0xFF2D6A4F),
      bgColor: Color(0xFFE8F5EE),
      title: 'Live Market Prices',
      subtitle:
      'Track commodity prices at nearby mandis and never undersell your harvest again.',
      illustration: '📈',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _animCtrl.reset();
    _animCtrl.forward();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/register');
    }
  }

  void _skip() {
    Navigator.pushReplacementNamed(context, '/register');
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _pages.length,
            itemBuilder: (_, i) => _OnboardingPage(
              data: _pages[i],
              anim: _fadeAnim,
              isCurrent: i == _currentPage,
            ),
          ),

          // Skip button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 20,
            child: TextButton(
              onPressed: _skip,
              child: Text(
                'Skip'.tr,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  28, 24, 28, MediaQuery.of(context).padding.bottom + 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                          (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? AppTheme.primary
                              : AppTheme.accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Next / Get Started button
                  AppButton(
                    label: _currentPage == _pages.length - 1
                        ? 'Get Started'.tr
                        : 'Continue'.tr,
                    onTap: _next,
                    icon: _currentPage == _pages.length - 1
                        ? Icons.check_rounded
                        : Icons.arrow_forward_rounded,
                  ),

                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already a farmer?  '.tr,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushReplacementNamed(context, '/login'),
                        child: Text(
                          'Sign In'.tr,
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  final Animation<double> anim;
  final bool isCurrent;

  const _OnboardingPage({
    required this.data,
    required this.anim,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Column(
      children: [
        // Illustration area
        Container(
          height: size.height * 0.52,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                data.bgColor,
                data.bgColor.withValues(alpha: 0.6),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Big circle BG
              Positioned(
                top: size.height * 0.05,
                child: Container(
                  width: size.width * 0.72,
                  height: size.width * 0.72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: data.iconColor.withValues(alpha: 0.1),
                  ),
                ),
              ),
              // Inner circle
              Container(
                width: size.width * 0.5,
                height: size.width * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: data.iconColor.withValues(alpha: 0.15),
                ),
              ),
              // Emoji + icon
              FadeTransition(
                opacity: anim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data.illustration,
                      style: TextStyle(fontSize: 80),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: data.iconColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(data.icon, color: data.iconColor, size: 30),
                    ),
                  ],
                ),
              ),

              // Floating dots decoration
              Positioned(
                top: 40,
                left: 30,
                child: _dot(data.iconColor, 10),
              ),
              Positioned(
                top: 100,
                right: 40,
                child: _dot(data.iconColor, 7),
              ),
              Positioned(
                bottom: 80,
                right: 60,
                child: _dot(data.iconColor, 12),
              ),
            ],
          ),
        ),

        // Text
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
            child: FadeTransition(
              opacity: anim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    data.title.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      height: 1.2,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    data.subtitle.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.textSecondary,
                      height: 1.6,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dot(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.4),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String subtitle;
  final String illustration;

  const _OnboardingData({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.illustration,
  });
}