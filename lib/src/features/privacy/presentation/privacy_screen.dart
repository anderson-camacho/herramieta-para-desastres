import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacidad')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const <Widget>[
          Text('SignalScope procesa la informacion localmente y no requiere una cuenta.'),
          SizedBox(height: 12),
          Text('No recopila IMEI, IMSI, numero de telefono, contactos, mensajes ni claves Wi-Fi.'),
          SizedBox(height: 12),
          Text('El historial es opcional y se mantiene en el propio dispositivo.'),
          SizedBox(height: 12),
          Text('La app solo observa datos que Android expone por APIs publicas permitidas.'),
        ],
      ),
    );
  }
}
