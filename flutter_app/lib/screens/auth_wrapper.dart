// screens/auth_wrapper.dart
//
// Entry point after app launch. Checks if a token is stored
// and routes accordingly:
//   No token           → LandingScreen
//   Token + onboarded  → MainShell
//   Token + not onboarded → OnboardingScreen

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'landing_screen.dart';
import 'main_shell.dart';
import 'onboarding_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await context.read<AuthProvider>().tryAutoLogin();
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F8FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restaurant_rounded,
                  size: 56, color: Color(0xFF43A047)),
              SizedBox(height: 20),
              CircularProgressIndicator(color: Color(0xFF43A047)),
            ],
          ),
        ),
      );
    }

    final auth = context.watch<AuthProvider>();

    if (!auth.isLoggedIn) {
      return const LandingScreen();
    }

    if (!auth.currentUser!.onboardingCompleted) {
      return const OnboardingScreen();
    }

    return const MainShell();
  }
}
