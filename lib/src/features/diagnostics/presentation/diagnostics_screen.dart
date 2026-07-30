import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:signal_scope/src/core/logging/app_logger.dart';
import 'package:signal_scope/src/core/models/capability_snapshot.dart';
import 'package:signal_scope/src/features/signals/data/native_signal_repository.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  final NativeSignalRepository _repository = NativeSignalRepository();
  CapabilitySnapshot? _capabilities;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final capabilities = await _repository.loadCapabilities();
      if (mounted) {
        setState(() {
          _capabilities = capabilities;
          _loading = false;
        });
      }
    } catch (error) {
      AppLogger.instance.log('error', 'No se pudieron leer capacidades: $error');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _requestPermissions() async {
    await <Permission>[
      Permission.phone,
      Permission.locationWhenInUse,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.nearbyWifiDevices,
      Permission.camera,
    ].request();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final capabilities = _capabilities;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Text(
          'Revisar mi teléfono',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        const Text(
          'Aquí puedes ver qué funciones detecta la aplicación y qué permisos faltan.',
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _loading ? null : _requestPermissions,
          icon: const Icon(Icons.verified_user_outlined),
          label: const Text('Revisar permisos y funciones'),
        ),
        const SizedBox(height: 16),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (capabilities == null)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No fue posible consultar el teléfono. Cierra y abre la aplicación e inténtalo otra vez.'),
            ),
          )
        else ...<Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${capabilities.manufacturer} ${capabilities.model}',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  Text('Android ${capabilities.platformVersion}'),
                  const SizedBox(height: 16),
                  _CapabilityTile(
                    icon: Icons.signal_cellular_alt,
                    label: 'Red celular',
                    available: capabilities.supportsTelephony,
                    permission: capabilities.permissionStates['phone'],
                  ),
                  _CapabilityTile(
                    icon: Icons.wifi,
                    label: 'Wi-Fi',
                    available: capabilities.supportsWifi,
                    permission: capabilities.permissionStates['nearbyWifi'] ??
                        capabilities.permissionStates['location'],
                  ),
                  _CapabilityTile(
                    icon: Icons.bluetooth,
                    label: 'Bluetooth',
                    available: capabilities.supportsBluetooth,
                    permission: capabilities.permissionStates['bluetoothScan'],
                  ),
                  _CapabilityTile(
                    icon: Icons.radar,
                    label: 'Bluetooth BLE',
                    available: capabilities.supportsBle,
                    permission: capabilities.permissionStates['bluetoothScan'],
                  ),
                  _CapabilityTile(
                    icon: Icons.usb,
                    label: 'USB para receptor externo',
                    available: capabilities.supportsUsbHost,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Permisos', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 10),
                  ...capabilities.permissionStates.entries.map(
                    (entry) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        entry.value == 'granted' ? Icons.check_circle : Icons.warning_amber,
                        color: entry.value == 'granted' ? Colors.green : theme.colorScheme.error,
                      ),
                      title: Text(_permissionLabel(entry.key)),
                      subtitle: Text(_permissionState(entry.value)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Limitaciones del teléfono', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 10),
                  ...capabilities.restrictions.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Icon(Icons.info_outline, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(item)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _permissionLabel(String key) => switch (key) {
        'phone' => 'Estado del teléfono',
        'location' => 'Ubicación',
        'nearbyWifi' => 'Redes Wi-Fi cercanas',
        'bluetoothScan' => 'Buscar Bluetooth',
        'bluetoothConnect' => 'Conectar Bluetooth',
        'camera' => 'Linterna',
        _ => key,
      };

  String _permissionState(String value) => switch (value) {
        'granted' => 'Permitido',
        'denied' => 'Falta permiso',
        'not_applicable' => 'No aplica en esta versión de Android',
        _ => value,
      };
}

class _CapabilityTile extends StatelessWidget {
  const _CapabilityTile({
    required this.icon,
    required this.label,
    required this.available,
    this.permission,
  });

  final IconData icon;
  final String label;
  final bool available;
  final String? permission;

  @override
  Widget build(BuildContext context) {
    final usable = available && (permission == null || permission == 'granted' || permission == 'not_applicable');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(
        !available
            ? 'El teléfono no reporta esta función'
            : usable
                ? 'Disponible para la aplicación'
                : 'Disponible, pero falta permiso',
      ),
      trailing: Icon(
        usable ? Icons.check_circle : Icons.warning_amber,
        color: usable ? Colors.green : Theme.of(context).colorScheme.error,
      ),
    );
  }
}
