// login_screen.dart
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'offline_api_service.dart';
import 'connectivity_service.dart';
import 'translation_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _passwordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = true;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final result = await OfflineApiService.login(
        _phoneCtrl.text.trim(),
        _passCtrl.text,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (result['success'] == true) {
          final isOffline = result['offline'] == true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isOffline
                  ? '🟠 Offline – showing your saved data'
                  : (result['message'] ?? 'Login successful!').toString()),
              backgroundColor: isOffline ? Colors.orange : AppTheme.success,
              duration: Duration(seconds: isOffline ? 4 : 2),
            ),
          );
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text((result['error'] ?? 'Login failed').toString()),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  bool get _isOffline => !ConnectivityService.instance.isOnlineNow;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top illustration with gradient
            SizedBox(
              height: size.height * 0.42,
              width: double.infinity,
              child: Stack(
                children: [
                  // Gradient background
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0A2118), Color(0xFF2D6A4F)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(36),
                      ),
                    ),
                  ),

                  // Pattern overlay
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(36)),
                      child: Stack(
                        children: [
                          Positioned(
                            top: -20,
                            right: -30,
                            child: Icon(Icons.eco,
                                size: 180,
                                color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          Positioned(
                            bottom: 20,
                            left: -20,
                            child: Icon(Icons.grass,
                                size: 140,
                                color: Colors.white.withValues(alpha: 0.04)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Logo + title
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                            height: MediaQuery.of(context).padding.top + 10),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.12),
                            border: Border.all(
                              color: AppTheme.primaryLight.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.eco_rounded,
                            color: AppTheme.primaryLight,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Agrosmart',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Welcome back, Farmer! 👋'.tr,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Form card
            FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sign In'.tr,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enter your credentials to continue'.tr,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Phone field
                        const _FieldLabel('Mobile / Email'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.emailAddress,
                          enableSuggestions: false,
                          autocorrect: false,
                          style: const TextStyle(
                              fontFamily: 'Poppins', fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Enter mobile or email'.tr,
                            prefixIcon: Icon(Icons.person_rounded,
                                color: AppTheme.primary, size: 20),
                          ),
                          validator: (v) =>
                          v!.isEmpty ? 'This field is required'.tr : null,
                        ),

                        const SizedBox(height: 16),

                        // Password field
                        const _FieldLabel('Password'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: !_passwordVisible,
                          enableSuggestions: false,
                          autocorrect: false,
                          style: const TextStyle(
                              fontFamily: 'Poppins', fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Enter your password'.tr,
                            prefixIcon: Icon(Icons.lock_rounded,
                                color: AppTheme.primary, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                                color: AppTheme.textLight,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                      () => _passwordVisible = !_passwordVisible),
                            ),
                          ),
                          validator: (v) =>
                          v!.isEmpty ? 'Password is required'.tr : null,
                        ),

                        const SizedBox(height: 12),

                        // Remember me + Forgot
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _rememberMe = !_rememberMe),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration:
                                    const Duration(milliseconds: 200),
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: _rememberMe
                                          ? AppTheme.primary
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: _rememberMe
                                            ? AppTheme.primary
                                            : AppTheme.textLight,
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: _rememberMe
                                        ? Icon(Icons.check_rounded,
                                        color: Colors.white, size: 13)
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Remember me'.tr,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/forgot_password');
                              },
                              child: Text(
                                'Forgot Password?'.tr,
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        AppButton(
                          label: 'Sign In'.tr,
                          isLoading: _isLoading,
                          onTap: _login,
                        ),

                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account?  ".tr,
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pushReplacementNamed(
                                  context, '/register'),
                              child: Text(
                                'Register'.tr,
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.tr,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
        fontFamily: 'Poppins',
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(icon, color: color, size: 20),
        label: Text(
          label,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
            fontSize: 13,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
