import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'splashscreen.dart';
import 'onboardingscreen.dart';
import 'loginscreen.dart';
import 'registrationscreen.dart';
import 'forgotpasswordscreen.dart';
import 'homescreen.dart';
import 'cropadvisoryscreen.dart';
import 'weatherforecastscreen.dart';
import 'pestanddisesasemanagementscreen.dart';
import 'marketpricescreen.dart';
import 'farmingtipsandnewsscreen.dart';
import 'profileandsettingsscreen.dart';

import 'translation_provider.dart';
import 'api_config.dart';
import 'connectivity_service.dart';
import 'dart:io';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();

  // Initialize connectivity monitoring
  await ConnectivityService.instance.initialize();

  // Try to resolve the best available backend URL
  await ApiConfig.resolveBaseUrl();

  runApp(const AgrosmartApp());
}

class AgrosmartApp extends StatelessWidget {
  const AgrosmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppState.darkModeNotifier,
      builder: (context, isDark, child) {
        return ValueListenableBuilder<int>(
          valueListenable: AppState.languageIndexNotifier,
          builder: (context, langIdx, child) {
            return MaterialApp(
              title: 'Agrosmart',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.theme,
              darkTheme: ThemeData(
                useMaterial3: true,
                fontFamily: 'Poppins',
                colorScheme: ColorScheme.fromSeed(
                  seedColor: AppTheme.primary,
                  brightness: Brightness.dark,
                ),
                scaffoldBackgroundColor: const Color(0xFF121212),
                cardTheme: CardThemeData(
                  color: const Color(0xFF1E1E1E),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              initialRoute: '/',
              routes: {
                '/': (context) => const SplashScreen(),
                '/onboarding': (context) => const OnboardingScreen(),
                '/login': (context) => const LoginScreen(),
                '/register': (context) => const RegistrationScreen(),
                '/forgot_password': (context) => const ForgotPasswordScreen(),
                '/home': (context) => const HomeScreen(),
                '/crop_advisory': (context) => const CropAdvisoryScreen(),
                '/weather': (context) => const WeatherScreen(),
                '/pest': (context) => const PestDiseaseScreen(),
                '/market': (context) => const MarketScreen(),
                '/tips': (context) => const FarmingTipsNewsScreen(),
                '/profile': (context) => const ProfileSettingsScreen(),
              },
            );
          },
        );
      },
    );
  }
}
