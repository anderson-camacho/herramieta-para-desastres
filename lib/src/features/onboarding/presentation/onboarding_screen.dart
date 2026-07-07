import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({
    super.key,
    required this.onContinue,
    required this.onOpenPrivacy,
    required this.onOpenPermissions,
    required this.onUseLimitedMode,
  });

  final VoidCallback onContinue;
  final VoidCallback onOpenPrivacy;
  final VoidCallback onOpenPermissions;
  final VoidCallback onUseLimitedMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              theme.colorScheme.primaryContainer,
              theme.colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('SignalScope', style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 12),
                        Text(
                          'Observa senales que Android expone legalmente: celular, Wi-Fi, Bluetooth y compatibilidad USB Host.',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 20),
                        const _Bullet(text: 'No mide cualquier frecuencia arbitraria sin un SDR externo.'),
                        const _Bullet(text: 'Cada permiso se pide solo para funciones relacionadas.'),
                        const _Bullet(text: 'Los datos se procesan localmente y no requieren cuenta.'),
                        const _Bullet(text: 'RSSI y dBm son aproximaciones tecnicas, no distancia exacta ni velocidad de Internet.'),
                        const _Bullet(text: 'Los resultados dependen del fabricante, operador, entorno y version de Android.'),
                        const _Bullet(text: 'Los escaneos frecuentes pueden aumentar el consumo de bateria.'),
                        const _Bullet(text: 'La app puede ayudarte a pedir ayuda con sonido, luz, mensaje, llamada y mapa, pero no reemplaza un radio profesional de rescate.'),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: <Widget>[
                            FilledButton(
                              onPressed: onContinue,
                              child: const Text('Continuar'),
                            ),
                            OutlinedButton(
                              onPressed: onOpenPrivacy,
                              child: const Text('Ver privacidad'),
                            ),
                            OutlinedButton(
                              onPressed: onOpenPermissions,
                              child: const Text('Configurar permisos'),
                            ),
                            TextButton(
                              onPressed: onUseLimitedMode,
                              child: const Text('Usar con funciones limitadas'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 10),
            child: Icon(Icons.circle, size: 8),
          ),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
