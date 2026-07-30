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
    final validContacts = _settings.contacts
        .where(
          (contact) => contact.name.trim().isNotEmpty &&
              (contact.phone.trim().isNotEmpty || contact.email.trim().isNotEmpty),
        )
        .toList();

    _settings = _settings.copyWith(contacts: validContacts);
    await _store.save(_settings);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contactos guardados.')),
    );
    Navigator.of(context).pop(true);
  }

  Future<void> _addContact() async {
    final contact = await showModalBottomSheet<EmergencyContact>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ContactEditor(),
    );
    if (contact == null || !mounted) {
      return;
    }
    setState(() {
      _settings = _settings.copyWith(
        contacts: <EmergencyContact>[..._settings.contacts, contact],
      );
    });
  }

  Future<void> _editContact(int index) async {
    final contact = await showModalBottomSheet<EmergencyContact>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ContactEditor(contact: _settings.contacts[index]),
    );
    if (contact == null || !mounted) {
      return;
    }
    setState(() {
      final contacts = List<EmergencyContact>.from(_settings.contacts);
      contacts[index] = contact;
      _settings = _settings.copyWith(contacts: contacts);
    });
  }

  void _removeContact(int index) {
    setState(() {
      final contacts = List<EmergencyContact>.from(_settings.contacts)
        ..removeAt(index);
      _settings = _settings.copyWith(contacts: contacts);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis contactos'),
        actions: <Widget>[
          TextButton(
            onPressed: _loading ? null : _save,
            child: const Text('Guardar'),
          ),
        ],
      ),
      floatingActionButton: _loading
          ? null
          : FloatingActionButton.extended(
              onPressed: _addContact,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Agregar contacto'),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
              children: <Widget>[
                Text(
                  '¿A quién debemos avisar?',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Agrega familiares, vecinos o amigos. Puedes guardar teléfono, correo o ambos.',
                ),
                const SizedBox(height: 20),
                if (_settings.contacts.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: <Widget>[
                          Icon(
                            Icons.person_add_alt_1,
                            size: 64,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Todavía no tienes contactos',
                            style: theme.textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Pulsa “Agregar contacto” para guardar la primera persona.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _addContact,
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar mi primer contacto'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ..._settings.contacts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final contact = entry.value;
                  final detail = <String>[
                    if (contact.phone.trim().isNotEmpty) contact.phone.trim(),
                    if (contact.email.trim().isNotEmpty) contact.email.trim(),
                  ].join(' · ');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        leading: CircleAvatar(
                          child: Text(
                            contact.name.trim().isEmpty
                                ? '?'
                                : contact.name.trim()[0].toUpperCase(),
                          ),
                        ),
                        title: Text(
                          contact.name.trim().isEmpty
                              ? 'Contacto sin nombre'
                              : contact.name.trim(),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(detail.isEmpty ? 'Sin teléfono ni correo' : detail),
                        onTap: () => _editContact(index),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _editContact(index);
                            } else if (value == 'delete') {
                              _removeContact(index);
                            }
                          },
                          itemBuilder: (_) => const <PopupMenuEntry<String>>[
                            PopupMenuItem(value: 'edit', child: Text('Editar')),
                            PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),
                Text(
                  'Mensaje adicional',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _settings.additionalNote,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Ejemplo: tengo movilidad reducida o necesito medicamentos.',
                  ),
                  onChanged: (value) {
                    _settings = _settings.copyWith(additionalNote: value);
                  },
                ),
              ],
            ),
    );
  }
}

class _ContactEditor extends StatefulWidget {
  const _ContactEditor({this.contact});

  final EmergencyContact? contact;

  @override
  State<_ContactEditor> createState() => _ContactEditorState();
}

class _ContactEditorState extends State<_ContactEditor> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact?.name ?? '');
    _phoneController = TextEditingController(text: widget.contact?.phone ?? '');
    _emailController = TextEditingController(text: widget.contact?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _finish() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    if (name.isEmpty || (phone.isEmpty && email.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe un nombre y al menos un teléfono o correo.'),
        ),
      );
      return;
    }
    Navigator.of(context).pop(
      EmergencyContact(name: name, phone: phone, email: email),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              widget.contact == null ? 'Agregar contacto' : 'Editar contacto',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo (opcional)',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _finish,
              child: const Text('Guardar contacto'),
            ),
          ],
        ),
      ),
    );
  }
}
