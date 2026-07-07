import 'package:flutter/material.dart';

import 'package:signal_scope/src/features/dashboard/presentation/dashboard_screen.dart';
import 'package:signal_scope/src/features/diagnostics/presentation/diagnostics_screen.dart';
import 'package:signal_scope/src/features/preparation/presentation/preparation_screen.dart';
import 'package:signal_scope/src/features/sos/presentation/sos_screen.dart';

class RescueShell extends StatefulWidget {
  const RescueShell({super.key});

  @override
  State<RescueShell> createState() => _RescueShellState();
}

class _RescueShellState extends State<RescueShell> {
  int _currentIndex = 0;

  late final List<Widget> _screens = <Widget>[
    const SosScreen(),
    const DashboardScreen(embedded: true),
    const PreparationScreen(),
    const DiagnosticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF1E1C1A),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: <Widget>[
                  Icon(Icons.signal_cellular_alt, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'RESCUE SIGNAL',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _titleForIndex(_currentIndex),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: theme.colorScheme.outlineVariant, width: 2),
                ),
                child: IndexedStack(
                  index: _currentIndex,
                  children: _screens,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (value) => setState(() => _currentIndex = value),
                destinations: const <NavigationDestination>[
                  NavigationDestination(
                    icon: Icon(Icons.emergency_outlined),
                    selectedIcon: Icon(Icons.emergency),
                    label: 'Emergency',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.wifi_tethering_outlined),
                    selectedIcon: Icon(Icons.wifi_tethering),
                    label: 'Signals',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.assignment_turned_in_outlined),
                    selectedIcon: Icon(Icons.assignment_turned_in),
                    label: 'Preparation',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.more_horiz),
                    selectedIcon: Icon(Icons.more_horiz),
                    label: 'More',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _titleForIndex(int index) => switch (index) {
        0 => 'Inicio de emergencia',
        1 => 'Escaneos y señales',
        2 => 'Preparacion',
        _ => 'Mas opciones',
      };
}

