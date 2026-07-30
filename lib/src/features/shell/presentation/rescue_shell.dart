import 'package:flutter/material.dart';

import 'package:signal_scope/src/features/dashboard/presentation/dashboard_screen.dart';
import 'package:signal_scope/src/features/diagnostics/presentation/diagnostics_screen.dart';
import 'package:signal_scope/src/features/preparation/presentation/preparation_screen.dart';
import 'package:signal_scope/src/features/sos/presentation/emergency_home_screen.dart';

class RescueShell extends StatefulWidget {
  const RescueShell({super.key});

  @override
  State<RescueShell> createState() => _RescueShellState();
}

class _RescueShellState extends State<RescueShell> {
  int _currentIndex = 0;

  late final List<Widget> _screens = <Widget>[
    const EmergencyHomeScreen(),
    const DashboardScreen(embedded: true),
    const PreparationScreen(),
    const DiagnosticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _currentIndex, children: _screens),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (value) => setState(() => _currentIndex = value),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.sensors_outlined),
            selectedIcon: Icon(Icons.sensors),
            label: 'Teléfono',
          ),
          NavigationDestination(
            icon: Icon(Icons.health_and_safety_outlined),
            selectedIcon: Icon(Icons.health_and_safety),
            label: 'Preparar',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'Revisar',
          ),
        ],
      ),
    );
  }
}
