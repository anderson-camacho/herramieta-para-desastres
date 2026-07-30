import 'package:flutter/material.dart';

import 'package:signal_scope/src/core/storage/app_preferences.dart';
import 'package:signal_scope/src/core/theme/app_theme.dart';
import 'package:signal_scope/src/features/onboarding/presentation/onboarding_screen.dart';
import 'package:signal_scope/src/features/privacy/presentation/privacy_screen.dart';
import 'package:signal_scope/src/features/shell/presentation/rescue_shell.dart';

class HerramientaDesastresApp extends StatefulWidget {
  const HerramientaDesastresApp({super.key});

  @override
  State<HerramientaDesastresApp> createState() => _HerramientaDesastresAppState();
}

class _HerramientaDesastresAppState extends State<HerramientaDesastresApp> {
  final AppPreferences _preferences = AppPreferences();
  bool? _onboardingSeen;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final seen = await _preferences.isOnboardingSeen();
    if (!mounted) return;
    setState(() => _onboardingSeen = seen);
  }

  Future<void> _completeOnboarding() async {
    await _preferences.setOnboardingSeen(true);
    if (!mounted) return;
    setState(() => _onboardingSeen = true);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Herramienta para Desastres',
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
