import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';
import '../utils/logger.dart';
import '../widgets/loading_state.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';
import 'overview_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    // Schedule initialization after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    Logger.log('Splash screen initializing app', tag: 'SplashScreen');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final storageService = StorageService();

    await authProvider.initialize();
    if (!mounted) return;

    // Small delay for smooth transition
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Check authentication status
    if (authProvider.isAuthenticated) {
      Logger.log(
        'User authenticated, navigating to overview',
        tag: 'SplashScreen',
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OverviewScreen()),
        (route) => false,
      );
      return;
    }

    // Check if user has completed onboarding
    final hasCompletedOnboarding = await storageService
        .hasCompletedOnboarding();

    if (!mounted) return;

    if (hasCompletedOnboarding) {
      Logger.log(
        'User has completed onboarding, navigating to login',
        tag: 'SplashScreen',
      );
      // User has seen onboarding, go directly to login
      Navigator.of(
        context,
      ).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
    } else {
      Logger.log('First time user, showing onboarding', tag: 'SplashScreen');
      // First time user, show onboarding
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: const LoadingState(
          useNavbarLogo: false,
          size: 120,
          message: 'Loading...',
        ),
      ),
    );
  }
}
