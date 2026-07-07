import 'package:flutter/material.dart';

import 'package:signal_scope/src/core/storage/app_preferences.dart';
import 'package:signal_scope/src/core/theme/app_theme.dart';
import 'package:signal_scope/src/features/onboarding/presentation/onboarding_screen.dart';
import 'package:signal_scope/src/features/privacy/presentation/privacy_screen.dart';
import 'package:signal_scope/src/features/shell/presentation/rescue_shell.dart';

class SignalScopeApp extends StatefulWidget {
  const SignalScopeApp({super.key});

  @override
  State<SignalScopeApp> createState() => _SignalScopeAppState();
}

class _SignalScopeAppState extends State<SignalScopeApp> {
  final AppPreferences _preferences = AppPreferences();
  bool? _onboardingSeen;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final seen = await _preferences.isOnboardingSeen();
    if (!mounted) {
      return;
    }
    setState(() {
      _onboardingSeen = seen;
    });
  }

  Future<void> _completeOnboarding() async {
    await _preferences.setOnboardingSeen(true);
    if (!mounted) {
      return;
    }
    setState(() {
      _onboardingSeen = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SignalScope',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routes: <String, WidgetBuilder>{
        '/privacy': (_) => const PrivacyScreen(),
      },
          home: _onboardingSeen == null
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _onboardingSeen == true
              ? const RescueShell()
              : OnboardingScreen(
                  onContinue: _completeOnboarding,
                  onUseLimitedMode: _completeOnboarding,
                  onOpenPrivacy: () => Navigator.of(context).pushNamed('/privacy'),
                  onOpenPermissions: _completeOnboarding,
                ),
    );
  }
}
