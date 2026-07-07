import 'package:flutter/material.dart';

import 'package:signal_scope/src/features/diagnostics/presentation/diagnostics_screen.dart';
import 'package:signal_scope/src/features/sos/application/emergency_settings_store.dart';
import 'package:signal_scope/src/features/sos/presentation/emergency_configuration_screen.dart';

class PreparationScreen extends StatefulWidget {
  const PreparationScreen({super.key});

  @override
  State<PreparationScreen> createState() => _PreparationScreenState();
}

class _PreparationScreenState extends State<PreparationScreen> {
  final EmergencySettingsStore _store = EmergencySettingsStore();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder(
      future: _store.load(),
      builder: (context, snapshot) {
        final settings = snapshot.data;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Text('Guias de supervivencia', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            const _GuideCard(
              title: 'Terremoto',
              subtitle: 'Alejate de vidrios, protege cabeza y cuello, y revisa rutas de salida.',
            ),
            const SizedBox(height: 12),
            const _GuideCard(
              title: 'Inundacion',
              subtitle: 'Busca altura, evita corrientes y no intentes cruzar agua rapida.',
            ),
            const SizedBox(height: 12),
            const _GuideCard(
              title: 'Persona atrapada',
              subtitle: 'Mantente calmado, protege nariz y boca y conserva bateria.',
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text('Configuracion de emergencia', style: theme.textTheme.titleLarge),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const EmergencyConfigurationScreen(),
                              ),
                            );
                            if (mounted) {
                              setState(() {});
                            }
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Editar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Contactos configurados: ${settings?.contacts.length ?? 0}',
                    ),
                    const SizedBox(height: 8),
                    ...(settings?.contacts ?? const []).take(3).map(
                          (contact) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text('${contact.name}: ${contact.phone} ${contact.email}'.trim()),
                          ),
                        ),
                    const SizedBox(height: 12),
                    Text(
                      'Mensajes rapidos configurados: ${settings?.quickMessages.length ?? 0}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Probar aplicacion', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const Text('Verifica permisos, senales y contactos antes de una emergencia real.'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                                builder: (_) => Scaffold(
                                  appBar: AppBar(title: const Text('Diagnostico del sistema')),
                                  body: const DiagnosticsScreen(),
                                ),
                          ),
                        );
                      },
                      child: const Text('Abrir diagnostico'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.chevron_right),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
