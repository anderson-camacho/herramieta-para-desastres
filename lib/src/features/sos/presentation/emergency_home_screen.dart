import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:signal_scope/src/features/sos/application/emergency_settings_store.dart';
import 'package:signal_scope/src/features/sos/application/sos_service.dart';
import 'package:signal_scope/src/features/sos/domain/emergency_models.dart';
import 'package:signal_scope/src/features/sos/presentation/emergency_configuration_screen.dart';

class EmergencyHomeScreen extends StatefulWidget {
  const EmergencyHomeScreen({super.key});

  @override
  State<EmergencyHomeScreen> createState() => _EmergencyHomeScreenState();
}

class _EmergencyHomeScreenState extends State<EmergencyHomeScreen> {
  final EmergencySettingsStore _store = EmergencySettingsStore();
  final SosService _service = SosService();

  EmergencySettings? _settings;
  bool _loading = true;
  bool _sirenActive = false;
  bool _torchActive = false;
  bool _torchAvailable = false;
  String _selectedMessage = 'Necesito ayuda urgente. Por favor comunícate conmigo.';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _store.load();
    final torchAvailable = await _service.isTorchAvailable();
    if (!mounted) {
      return;
    }
    setState(() {
      _settings = settings;
      _selectedMessage = settings.quickMessages.isEmpty
          ? _selectedMessage
          : settings.quickMessages.first.text;
      _torchAvailable = torchAvailable;
      _loading = false;
    });
  }

  @override
  void dispose() {
    unawaited(_service.stopAudibleSignal());
    unawaited(_service.setTorchEnabled(false));
    super.dispose();
  }

  Future<void> _openContacts() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const EmergencyConfigurationScreen(),
      ),
    );
    await _load();
  }

  Future<SosPayload> _payload() async {
    await Permission.locationWhenInUse.request();
    final settings = _settings!;
    return _service.buildPayload(
      contactName: settings.contacts.isEmpty
          ? 'Sin contacto configurado'
          : settings.contacts.first.name,
      customNote: '$_selectedMessage\n${settings.additionalNote}'.trim(),
    );
  }

  Future<void> _sendSms() async {
    final contacts = _settings!.contacts
        .where((contact) => contact.phone.trim().isNotEmpty)
        .toList();
    if (contacts.isEmpty) {
      await _showNoContacts();
      return;
    }
    final payload = await _payload();
    await _service.launchSms(
      contacts.map((contact) => contact.phone.trim()).join(','),
      payload,
    );
  }

  Future<void> _share() async {
    final payload = await _payload();
    await _service.sharePayload(payload);
  }

  Future<void> _callContact() async {
    final contact = _settings!.contacts
        .where((item) => item.phone.trim().isNotEmpty)
        .firstOrNull;
    if (contact == null) {
      await _showNoContacts();
      return;
    }
    await _service.launchDialer(contact.phone.trim());
  }

  Future<void> _callEmergency() async {
    final number = EmergencyDirectory.numbersFor(_settings!.countryCode)
        .where((entry) => entry.number.contains(RegExp(r'\d')))
        .firstOrNull;
    if (number != null) {
      await _service.launchDialer(number.number);
    }
  }

  Future<void> _showNoContacts() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.person_add_alt_1, size: 48),
        title: const Text('Agrega un contacto'),
        content: const Text(
          'Para enviar mensajes o llamar a alguien, primero guarda una persona de confianza.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Después'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openContacts();
            },
            child: const Text('Agregar ahora'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSiren() async {
    if (_sirenActive) {
      await _service.stopAudibleSignal();
    } else {
      await _service.startSosTone();
    }
    if (mounted) {
      setState(() => _sirenActive = !_sirenActive);
    }
  }

  Future<void> _toggleTorch() async {
    final next = !_torchActive;
    final success = await _service.setTorchEnabled(next);
    if (!mounted) {
      return;
    }
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fue posible controlar la linterna.')),
      );
      return;
    }
    setState(() => _torchActive = next);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _settings == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final theme = Theme.of(context);
    final contacts = _settings!.contacts;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: <Widget>[
        Row(
          children: <Widget>[
            Image.asset('assets/branding/emergencias_logo.png', width: 54, height: 54),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Emergencias',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text('Ayuda rápida, sin complicaciones'),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Mis contactos',
              onPressed: _openContacts,
              icon: const Icon(Icons.people_alt_outlined),
            ),
          ],
        ),
        const SizedBox(height: 22),
        if (contacts.isEmpty)
          Card(
            color: theme.colorScheme.primaryContainer,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _openContacts,
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.person_add_alt_1, size: 42),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Agrega una persona de confianza',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                          ),
                          SizedBox(height: 4),
                          Text('Así podrás enviarle tu mensaje y ubicación.'),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          )
        else
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.people_alt)),
              title: Text('${contacts.length} contacto${contacts.length == 1 ? '' : 's'} listo${contacts.length == 1 ? '' : 's'}'),
              subtitle: Text(contacts.take(2).map((item) => item.name).join(', ')),
              trailing: const Icon(Icons.edit_outlined),
              onTap: _openContacts,
            ),
          ),
        const SizedBox(height: 18),
        Text(
          '¿Qué necesitas hacer?',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        _BigActionButton(
          color: theme.colorScheme.error,
          icon: Icons.sms_outlined,
          title: 'Enviar SOS',
          subtitle: 'Mensaje y ubicación a tus contactos',
          onPressed: _sendSms,
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _SquareAction(
                icon: Icons.call,
                label: 'Llamar contacto',
                onPressed: _callContact,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SquareAction(
                icon: Icons.emergency,
                label: 'Llamar emergencia',
                onPressed: _callEmergency,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _SquareAction(
                icon: _sirenActive ? Icons.stop_circle : Icons.campaign,
                label: _sirenActive ? 'Detener sonido' : 'Sirena fuerte',
                active: _sirenActive,
                onPressed: _toggleSiren,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SquareAction(
                icon: _torchActive ? Icons.flashlight_off : Icons.flashlight_on,
                label: _torchActive ? 'Apagar luz' : 'Encender luz',
                onPressed: _torchAvailable ? _toggleTorch : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _BigActionButton(
          color: theme.colorScheme.primary,
          icon: Icons.share_outlined,
          title: 'Compartir ayuda',
          subtitle: 'WhatsApp, correo u otra aplicación',
          onPressed: _share,
        ),
        const SizedBox(height: 22),
        Text(
          'Mensaje rápido',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _settings!.quickMessages.map((message) {
            return ChoiceChip(
              label: Text(message.title),
              selected: _selectedMessage == message.text,
              onSelected: (_) => setState(() => _selectedMessage = message.text),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.chat_bubble_outline),
                const SizedBox(width: 12),
                Expanded(child: Text(_selectedMessage)),
                IconButton(
                  tooltip: 'Copiar',
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: _selectedMessage));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Mensaje copiado.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BigActionButton extends StatelessWidget {
  const _BigActionButton({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size.fromHeight(86),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      onPressed: onPressed,
      child: Row(
        children: <Widget>[
          Icon(icon, size: 38),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
                Text(subtitle),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _SquareAction extends StatelessWidget {
  const _SquareAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: active ? Theme.of(context).colorScheme.errorContainer : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onPressed,
        child: SizedBox(
          height: 126,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, size: 42),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
