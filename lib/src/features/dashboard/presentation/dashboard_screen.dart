import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:signal_scope/src/core/logging/app_logger.dart';
import 'package:signal_scope/src/core/models/capability_snapshot.dart';
import 'package:signal_scope/src/features/history/application/history_store.dart';
import 'package:signal_scope/src/features/signals/data/demo_signal_repository.dart';
import 'package:signal_scope/src/features/signals/data/native_signal_repository.dart';
import 'package:signal_scope/src/features/signals/domain/signal_models.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.useDemoOverride,
    this.embedded = false,
  });

  final bool? useDemoOverride;
  final bool embedded;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final bool _useDemo =
      widget.useDemoOverride ?? (kIsWeb || defaultTargetPlatform != TargetPlatform.android);
  late final dynamic _repository = _useDemo ? DemoSignalRepository() : NativeSignalRepository();
  final HistoryStore _historyStore = HistoryStore();
  final Map<SignalModuleType, List<HistoricalPoint>> _history = <SignalModuleType, List<HistoricalPoint>>{};
  StreamSubscription<List<SignalReading>>? _subscription;

  CapabilitySnapshot? _capabilities;
  List<SignalReading> _signals = const <SignalReading>[];
  bool _historyEnabled = true;
  bool _bleRunning = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _historyEnabled = await _historyStore.isEnabled();
    _capabilities = await _repository.loadCapabilities() as CapabilitySnapshot;
    _subscription = (_repository.watchSignals() as Stream<List<SignalReading>>).listen((items) {
      if (!mounted) {
        return;
      }
      setState(() {
        _signals = items;
        if (_historyEnabled) {
          for (final reading in items) {
            _history[reading.module] = _historyStore.retainLatest(
              _history[reading.module] ?? const <HistoricalPoint>[],
              reading,
            );
          }
        }
      });
    }, onError: (Object error, StackTrace stackTrace) {
      AppLogger.instance.log('error', 'Signal stream failed: $error');
    });
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _toggleHistory(bool value) async {
    await _historyStore.setEnabled(value);
    if (!mounted) {
      return;
    }
    setState(() {
      _historyEnabled = value;
      if (!value) {
        _history.clear();
      }
    });
  }

  Future<void> _toggleBle() async {
    if (_useDemo) {
      setState(() => _bleRunning = !_bleRunning);
      return;
    }
    if (_bleRunning) {
      await (_repository as NativeSignalRepository).stopBleSession();
      if (!mounted) {
        return;
      }
      setState(() => _bleRunning = false);
      return;
    }
    await (_repository as NativeSignalRepository).startBleSession();
    if (!mounted) {
      return;
    }
    setState(() => _bleRunning = true);
  }

  Future<void> _requestRelevantPermissions() async {
    if (_useDemo) {
      return;
    }
    final requests = <Permission>[
      Permission.phone,
      Permission.locationWhenInUse,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.nearbyWifiDevices,
    ];
    await requests.request();
    _capabilities = await _repository.loadCapabilities() as CapabilitySnapshot;
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('SignalScope'),
              actions: <Widget>[
                Row(
                  children: <Widget>[
                    const Text('Demo'),
                    Switch(
                      value: _useDemo,
                      onChanged: null,
                    ),
                  ],
                ),
              ],
            ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Text('Escaneos y senales', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'Aqui estan los modulos tecnicos de deteccion. Si lo urgente es pedir ayuda, vuelve a la pestaña Emergency.',
          ),
          const SizedBox(height: 20),
          if (_useDemo)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Funcion limitada fuera de Android'),
                    SizedBox(height: 8),
                    Text(
                      'Esta plataforma usa adaptadores de demostracion. Las mediciones reales de telefonia, Wi-Fi y Bluetooth dependen de APIs Android publicas.',
                    ),
                  ],
                ),
              ),
            ),
          if (_useDemo) const SizedBox(height: 20),
          _OverviewCard(
            capabilities: _capabilities,
            historyEnabled: _historyEnabled,
            onToggleHistory: _toggleHistory,
            onRequestPermissions: _requestRelevantPermissions,
            useDemo: _useDemo,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: _signals
                .map(
                  (signal) => SizedBox(
                    width: 360,
                    child: _SignalCard(
                      signal: signal,
                      history: _history[signal.module] ?? const <HistoricalPoint>[],
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Sesion BLE', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(_bleRunning ? 'Escaneo activo por tiempo limitado' : 'Escaneo detenido'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _toggleBle,
                    child: Text(_bleRunning ? 'Detener BLE' : 'Iniciar BLE'),
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

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.capabilities,
    required this.historyEnabled,
    required this.onToggleHistory,
    required this.onRequestPermissions,
    required this.useDemo,
  });

  final CapabilitySnapshot? capabilities;
  final bool historyEnabled;
  final ValueChanged<bool> onToggleHistory;
  final Future<void> Function() onRequestPermissions;
  final bool useDemo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Diagnostico inicial', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Text('${capabilities?.manufacturer ?? 'Cargando'} ${capabilities?.model ?? ''}'),
            Text('Plataforma: ${capabilities?.platform ?? 'unknown'} ${capabilities?.platformVersion ?? ''}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (capabilities?.permissionStates.entries ?? <MapEntry<String, String>>[])
                  .map((entry) => Chip(label: Text('${entry.key}: ${entry.value}')))
                  .toList(),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Guardar historial local'),
              subtitle: const Text('Mantiene solo una ventana corta de puntos RSSI en el dispositivo'),
              value: historyEnabled,
              onChanged: onToggleHistory,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: useDemo ? null : onRequestPermissions,
              child: const Text('Solicitar permisos necesarios'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignalCard extends StatelessWidget {
  const _SignalCard({
    required this.signal,
    required this.history,
  });

  final SignalReading signal;
  final List<HistoricalPoint> history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(signal.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(signal.summary),
            const SizedBox(height: 6),
            Text('Estado: ${signal.availability.name}'),
            Text('RSSI: ${signal.rssi?.toString() ?? 'No disponible'} dBm'),
            if (signal.networkType != null) Text('Tipo: ${signal.networkType}'),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: history.isEmpty
                  ? const Center(child: Text('Sin historial'))
                  : LineChart(
                      LineChartData(
                        minY: -130,
                        maxY: 0,
                        titlesData: const FlTitlesData(show: false),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: <LineChartBarData>[
                          LineChartBarData(
                            isCurved: true,
                            color: theme.colorScheme.primary,
                            dotData: const FlDotData(show: false),
                            spots: history
                                .asMap()
                                .entries
                                .map((entry) => FlSpot(entry.key.toDouble(), entry.value.value))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
