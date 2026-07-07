import 'package:flutter/material.dart';

import 'package:signal_scope/src/features/sos/application/emergency_settings_store.dart';
import 'package:signal_scope/src/features/sos/domain/emergency_models.dart';

class EmergencyConfigurationScreen extends StatefulWidget {
  const EmergencyConfigurationScreen({super.key});

  @override
  State<EmergencyConfigurationScreen> createState() =>
      _EmergencyConfigurationScreenState();
}

class _EmergencyConfigurationScreenState
    extends State<EmergencyConfigurationScreen> {
  final EmergencySettingsStore _store = EmergencySettingsStore();

  bool _loading = true;
  late EmergencySettings _settings;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _settings = await _store.load();
    if (!mounted) {
      return;
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    await _store.save(_settings);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuracion guardada.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Configuracion de emergencia')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                Text('Contactos de emergencia', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                ..._settings.contacts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final contact = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: <Widget>[
                            TextFormField(
                              initialValue: contact.name,
                              decoration: const InputDecoration(labelText: 'Nombre'),
                              onChanged: (value) => _updateContact(index, contact.copyWith(name: value)),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              initialValue: contact.phone,
                              decoration: const InputDecoration(labelText: 'Telefono'),
                              onChanged: (value) => _updateContact(index, contact.copyWith(phone: value)),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              initialValue: contact.email,
                              decoration: const InputDecoration(labelText: 'Correo'),
                              onChanged: (value) => _updateContact(index, contact.copyWith(email: value)),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _settings = _settings.copyWith(
                                      contacts: List<EmergencyContact>.from(_settings.contacts)
                                        ..removeAt(index),
                                    );
                                  });
                                },
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Eliminar'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _settings = _settings.copyWith(
                        contacts: List<EmergencyContact>.from(_settings.contacts)
                          ..add(const EmergencyContact(name: '', phone: '', email: '')),
                      );
                    });
                  },
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Agregar contacto'),
                ),
                const SizedBox(height: 20),
                Text('Mensajes rapidos', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                ..._settings.quickMessages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final quick = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: <Widget>[
                            TextFormField(
                              initialValue: quick.title,
                              decoration: const InputDecoration(labelText: 'Titulo corto'),
                              onChanged: (value) => _updateQuickMessage(index, quick.copyWith(title: value)),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              initialValue: quick.text,
                              maxLines: 3,
                              decoration: const InputDecoration(labelText: 'Mensaje'),
                              onChanged: (value) => _updateQuickMessage(index, quick.copyWith(text: value)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _settings.additionalNote,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Nota adicional por defecto',
                  ),
                  onChanged: (value) =>
                      _settings = _settings.copyWith(additionalNote: value),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Guardar configuracion'),
                ),
              ],
            ),
    );
  }

  void _updateContact(int index, EmergencyContact contact) {
    setState(() {
      final next = List<EmergencyContact>.from(_settings.contacts);
      next[index] = contact;
      _settings = _settings.copyWith(contacts: next);
    });
  }

  void _updateQuickMessage(int index, QuickEmergencyMessage message) {
    setState(() {
      final next = List<QuickEmergencyMessage>.from(_settings.quickMessages);
      next[index] = message;
      _settings = _settings.copyWith(quickMessages: next);
    });
  }
}
