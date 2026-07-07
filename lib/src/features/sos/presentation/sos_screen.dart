import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:signal_scope/src/core/logging/app_logger.dart';
import 'package:signal_scope/src/features/sos/application/emergency_settings_store.dart';
import 'package:signal_scope/src/features/sos/application/sos_service.dart';
import 'package:signal_scope/src/features/sos/domain/emergency_models.dart';
import 'package:signal_scope/src/features/sos/presentation/emergency_configuration_screen.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  final SosService _sosService = SosService();
  final EmergencySettingsStore _settingsStore = EmergencySettingsStore();
  final TextEditingController _messageController = TextEditingController();

  EmergencySettings? _settings;
  SosPayload? _payload;
  bool _loading = true;
  bool _sending = false;
  bool _sirenActive = false;
  bool _whistleActive = false;
  bool _beaconActive = false;
  bool _torchAvailable = false;
  bool _torchActive = false;
  Timer? _beaconTimer;
  Color _beaconColor = Colors.white;
  String _selectedPreset = '';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final settings = await _settingsStore.load();
    final torchAvailable = await _sosService.isTorchAvailable();
    if (!mounted) {
      return;
    }
    setState(() {
      _settings = settings;
      _selectedPreset = settings.quickMessages.first.text;
      _messageController.text = settings.quickMessages.first.text;
      _torchAvailable = torchAvailable;
      _loading = false;
    });
    await _refreshPayload();
  }

  @override
  void dispose() {
    _beaconTimer?.cancel();
    unawaited(_sosService.stopAudibleSignal());
    unawaited(_sosService.setTorchEnabled(false));
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _refreshPayload() async {
    final settings = _settings;
    if (settings == null) {
      return;
    }
    setState(() => _sending = true);
    try {
      await Permission.locationWhenInUse.request();
      final payload = await _sosService.buildPayload(
        contactName: settings.contacts.isEmpty ? 'Sin contacto configurado' : settings.contacts.first.name,
        customNote: '${_messageController.text.trim()}\n${settings.additionalNote.trim()}'.trim(),
      );
      if (!mounted) {
        return;
      }
      setState(() => _payload = payload);
    } catch (error) {
      _showInfo('$error');
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _share() async {
    final payload = await _ensurePayload();
    await _sosService.sharePayload(payload);
  }

  Future<void> _copy() async {
    final payload = await _ensurePayload();
    await Clipboard.setData(ClipboardData(text: payload.message));
    _showInfo('Mensaje copiado. Ya puedes pegarlo donde lo necesites.');
  }

  Future<void> _call(String phone) async {
    if (phone.trim().isEmpty) {
      _showInfo('Configura un numero primero.');
      return;
    }
    await _sosService.launchDialer(phone.trim());
  }

  Future<void> _smsAll() async {
    final settings = _settings;
    if (settings == null) {
      return;
    }
    final phones = settings.contacts.map((item) => item.phone.trim()).where((item) => item.isNotEmpty).toList();
    if (phones.isEmpty) {
      _showInfo('No hay telefonos configurados para SMS.');
      return;
    }
    final payload = await _ensurePayload();
    await _sosService.launchSms(phones.join(','), payload);
  }

  Future<void> _emailAll() async {
    final settings = _settings;
    if (settings == null) {
      return;
    }
    final emails = settings.contacts.map((item) => item.email.trim()).where((item) => item.isNotEmpty).toList();
    if (emails.isEmpty) {
      _showInfo('No hay correos configurados.');
      return;
    }
    final payload = await _ensurePayload();
    await _sosService.launchEmail(email: emails.join(','), payload: payload);
  }

  Future<void> _maps() async {
    final payload = await _ensurePayload();
    await _sosService.launchMaps(payload);
  }

  Future<SosPayload> _ensurePayload() async {
    if (_payload != null) {
      return _payload!;
    }
    await _refreshPayload();
    if (_payload == null) {
      throw StateError('No se pudo preparar el mensaje SOS.');
    }
    return _payload!;
  }

  Future<void> _toggleSiren() async {
    if (_sirenActive) {
      await _sosService.stopAudibleSignal();
      if (!mounted) {
        return;
      }
      setState(() {
        _sirenActive = false;
        _whistleActive = false;
      });
      return;
    }
    await _sosService.startSosTone();
    if (!mounted) {
      return;
    }
    setState(() {
      _sirenActive = true;
      _whistleActive = false;
    });
  }

  Future<void> _toggleWhistle() async {
    if (_whistleActive) {
      await _sosService.stopAudibleSignal();
      if (!mounted) {
        return;
      }
      setState(() {
        _sirenActive = false;
        _whistleActive = false;
      });
      return;
    }
    await _sosService.startRescueWhistle();
    if (!mounted) {
      return;
    }
    setState(() {
      _sirenActive = false;
      _whistleActive = true;
    });
  }

  void _toggleBeacon() {
    if (_beaconActive) {
      _beaconTimer?.cancel();
      setState(() {
        _beaconActive = false;
        _beaconColor = Colors.white;
      });
      return;
    }
    _beaconTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _beaconColor = _beaconColor == Colors.white ? Colors.red.shade100 : Colors.white;
      });
    });
    setState(() => _beaconActive = true);
  }

  Future<void> _toggleTorch() async {
    final next = !_torchActive;
    final success = await _sosService.setTorchEnabled(next);
    if (!mounted) {
      return;
    }
    if (!success) {
      _showInfo('Este dispositivo no permitio encender la linterna real.');
      return;
    }
    setState(() => _torchActive = next);
  }

  String _locationStatus() {
    final position = _payload?.position;
    if (position == null) {
      return 'Ubicacion pendiente o no disponible';
    }
    if (position.accuracy <= 20) {
      return 'Ubicacion precisa por GPS';
    }
    if (position.accuracy <= 100) {
      return 'Ubicacion aproximada';
    }
    return 'Ubicacion de baja precision';
  }

  void _applyPreset(String text) {
    setState(() {
      _selectedPreset = text;
      _messageController.text = text;
    });
    _payload = null;
  }

  void _showInfo(String message) {
    AppLogger.instance.log('warning', message);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading || _settings == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final numbers = EmergencyDirectory.numbersFor(_settings!.countryCode);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      color: _beaconActive ? _beaconColor : Colors.transparent,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Card(
            color: theme.colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: <Widget>[
                  Text(
                    'ENVIAR SOS',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pulsa actualizar ubicacion, revisa el mensaje y usa enviar por SMS o compartir. Esta pantalla pone primero lo urgente.',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(88),
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: theme.colorScheme.onSecondary,
                    ),
                    onPressed: _sending ? null : _smsAll,
                    icon: const Icon(Icons.sms, size: 30),
                    label: Text(
                      _sending ? 'PREPARANDO...' : 'ENVIAR AHORA POR SMS',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: <Widget>[
                      OutlinedButton.icon(
                        onPressed: _refreshPayload,
                        icon: const Icon(Icons.my_location),
                        label: const Text('Actualizar ubicacion'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _share,
                        icon: const Icon(Icons.share),
                        label: const Text('Compartir'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _emailAll,
                        icon: const Icon(Icons.email),
                        label: const Text('Correo'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _copy,
                        icon: const Icon(Icons.copy),
                        label: const Text('Copiar'),
                      ),
                    ],
                  ),
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
                  Row(
                    children: <Widget>[
                      Text('Estado actual', style: theme.textTheme.titleLarge),
                      const Spacer(),
                      FilledButton.tonalIcon(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const EmergencyConfigurationScreen(),
                            ),
                          );
                          await _bootstrap();
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text('Configurar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _StatusRow(label: 'Pais sugerido', value: _settings!.countryCode),
                  _StatusRow(label: 'Ubicacion', value: _locationStatus()),
                  _StatusRow(
                    label: 'Contactos listos',
                    value: '${_settings!.contacts.where((item) => item.phone.trim().isNotEmpty || item.email.trim().isNotEmpty).length}',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Explicacion simple: la app usa los canales reales del telefono. No manda una radio de rescate profesional, pero si te ayuda a avisar con mensaje, llamada, sonido, luz y ubicacion.',
                  ),
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
                  Text('Mensaje de emergencia', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text(
                    'Elige una frase rapida o escribe la tuya. Luego pulsa el boton de SMS, compartir o correo.',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _settings!.quickMessages.map((item) {
                      final selected = _selectedPreset == item.text;
                      return ChoiceChip(
                        label: Text(item.title),
                        selected: selected,
                        onSelected: (_) => _applyPreset(item.text),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _messageController,
                    maxLines: 4,
                    onChanged: (_) => _payload = null,
                    decoration: const InputDecoration(
                      labelText: 'Mensaje que necesita la otra persona',
                      helperText: 'Ejemplo: no puedo respirar, no puedo ver nada, estoy atrapado, sigo con vida.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: <Widget>[
                      OutlinedButton.icon(
                        onPressed: _smsAll,
                        icon: const Icon(Icons.sms),
                        label: const Text('SMS a contactos'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _call(_settings!.contacts.firstOrNull?.phone ?? ''),
                        icon: const Icon(Icons.call),
                        label: const Text('Llamar contacto'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _maps,
                        icon: const Icon(Icons.map),
                        label: const Text('Abrir mapa'),
                      ),
                    ],
                  ),
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
                  Text('Sonido y luz', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text(
                    'Usa estas senales para que te escuchen o te vean mejor. El pitido no garantiza que un perro de rescate te detecte; es una ayuda sonora local, no un sistema canino especializado.',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: _toggleSiren,
                        icon: Icon(_sirenActive ? Icons.stop : Icons.campaign),
                        label: Text(_sirenActive ? 'Detener sirena' : 'Sonido SOS'),
                      ),
                      FilledButton.icon(
                        onPressed: _toggleWhistle,
                        icon: Icon(_whistleActive ? Icons.stop : Icons.surround_sound),
                        label: Text(_whistleActive ? 'Detener pitido' : 'Pitido de rescate'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _toggleBeacon,
                        icon: Icon(_beaconActive ? Icons.visibility_off : Icons.flash_on),
                        label: Text(_beaconActive ? 'Apagar faro' : 'Pantalla faro'),
                      ),
                      if (_torchAvailable)
                        OutlinedButton.icon(
                          onPressed: _toggleTorch,
                          icon: Icon(_torchActive ? Icons.flashlight_off : Icons.flashlight_on),
                          label: Text(_torchActive ? 'Apagar linterna' : 'Linterna real'),
                        ),
                    ],
                  ),
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
                  Text('Numeros de emergencia cercanos', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text(
                    'Estos numeros son una referencia segun el pais detectado del dispositivo. Verificalos localmente si estas de viaje.',
                  ),
                  const SizedBox(height: 12),
                  ...numbers.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        color: theme.colorScheme.surfaceContainerLow,
                        child: ListTile(
                          title: Text('${entry.label}: ${entry.number}'),
                          subtitle: Text(entry.description),
                          trailing: IconButton(
                            onPressed: entry.number.contains(RegExp(r'\d'))
                                ? () => _call(entry.number)
                                : null,
                            icon: const Icon(Icons.call),
                          ),
                        ),
                      ),
                    ),
                  ),
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
                  Text('Mensaje preparado', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Text(
                    _payload?.message ??
                        'Pulsa "Actualizar ubicacion" para preparar un mensaje con ubicacion y nota actualizadas.',
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

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
