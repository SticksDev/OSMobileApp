import 'package:flutter/material.dart';
import 'package:openshock_mobile/widgets/feature_card.dart';

import '../services/storage_service.dart';
import '../utils/logger.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const _bgColor = Color(0xFF0A0A0A);
  static const _pagePadding = EdgeInsets.all(24);
  static const _logoSize = 120.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Padding(
          padding: _pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Image.asset(
                  'assets/os/Icon512.png',
                  width: _logoSize,
                  height: _logoSize,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome to OpenShock',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your mobile control center',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const SizedBox(height: 48),
              const FeatureCard(
                icon: Icons.devices,
                title: 'Control Your Devices',
                description:
                    'Manage and control all your shockers from anywhere with real-time updates',
              ),
              const SizedBox(height: 16),
              const FeatureCard(
                icon: Icons.security,
                title: 'Secure & Private',
                description:
                    'Your data is encrypted and stored securely on your device',
              ),
              const SizedBox(height: 16),
              const FeatureCard(
                icon: Icons.speed,
                title: 'Fast & Responsive',
                description:
                    'Instant control with a modern, intuitive interface',
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _handleGetStarted(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleGetStarted(BuildContext context) async {
    Logger.log(
      'User completed onboarding, navigating to login',
      tag: 'OnboardingScreen',
    );

    await StorageService().setOnboardingComplete(true);
    if (!context.mounted) return;

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }
}
