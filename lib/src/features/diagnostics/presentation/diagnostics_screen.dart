import 'package:flutter/material.dart';

import 'package:signal_scope/src/core/logging/app_logger.dart';
import 'package:signal_scope/src/core/models/capability_snapshot.dart';

class DiagnosticsScreen extends StatelessWidget {
  const DiagnosticsScreen({
    super.key,
    this.capabilities,
  });

  final CapabilitySnapshot? capabilities;

  @override
  Widget build(BuildContext context) {
    final logs = AppLogger.instance.entries.reversed.toList();
    return ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Text(
            'Diagnostico del sistema',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Capacidades'),
                  const SizedBox(height: 12),
                  Text('Plataforma: ${capabilities?.platform ?? 'desconocida'} ${capabilities?.platformVersion ?? ''}'),
                  Text('Fabricante: ${capabilities?.manufacturer ?? 'desconocido'}'),
                  Text('Modelo: ${capabilities?.model ?? 'desconocido'}'),
                  Text('Telefonia: ${capabilities?.supportsTelephony == true ? 'si' : 'no'}'),
                  Text('Wi-Fi: ${capabilities?.supportsWifi == true ? 'si' : 'no'}'),
                  Text('Bluetooth: ${capabilities?.supportsBluetooth == true ? 'si' : 'no'}'),
                  Text('BLE: ${capabilities?.supportsBle == true ? 'si' : 'no'}'),
                  Text('USB Host: ${capabilities?.supportsUsbHost == true ? 'si' : 'no'}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Restricciones conocidas'),
                  const SizedBox(height: 12),
                  ...(capabilities?.restrictions ?? const <String>['Sin datos'])
                      .map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(item),
                          )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Registros locales recientes'),
                  const SizedBox(height: 12),
                  if (logs.isEmpty) const Text('Sin eventos registrados'),
                  ...logs.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('[${entry.level}] ${entry.timestamp.toIso8601String()} ${entry.message}'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
    );
  }
}
