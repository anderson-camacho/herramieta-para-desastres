import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SosPayload {
  const SosPayload({
    required this.message,
    this.position,
    this.mapsUrl,
  });

  final String message;
  final Position? position;
  final String? mapsUrl;
}

class SosService {
  SosService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('signalscope/methods');

  final MethodChannel _channel;

  Future<void> startSosTone() => _channel.invokeMethod<void>('startSosTone');

  Future<void> startRescueWhistle() => _channel.invokeMethod<void>('startRescueWhistle');

  Future<void> stopAudibleSignal() => _channel.invokeMethod<void>('stopAudibleSignal');

  Future<bool> isTorchAvailable() async {
    return await _channel.invokeMethod<bool>('isTorchAvailable') ?? false;
  }

  Future<bool> setTorchEnabled(bool enabled) async {
    return await _channel.invokeMethod<bool>(
          'setTorchEnabled',
          <String, Object?>{'enabled': enabled},
        ) ??
        false;
  }

  Future<SosPayload> buildPayload({
    required String contactName,
    required String customNote,
  }) async {
    Position? position;
    String? mapsUrl;
    final locationEnabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Geolocator.checkPermission();
    final hasPermission = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    if (locationEnabled && hasPermission) {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      mapsUrl =
          'https://maps.google.com/?q=${position.latitude},${position.longitude}';
    }

    final buffer = StringBuffer()
      ..writeln('SOS: necesito ayuda.')
      ..writeln('Contacto de referencia: ${contactName.trim().isEmpty ? 'No configurado' : contactName.trim()}');

    if (customNote.trim().isNotEmpty) {
      buffer.writeln('Nota: ${customNote.trim()}');
    }

    if (position != null) {
      buffer
        ..writeln('Latitud: ${position.latitude}')
        ..writeln('Longitud: ${position.longitude}');
      if (mapsUrl != null) {
        buffer.writeln('Mapa: $mapsUrl');
      }
    } else {
      buffer.writeln('Ubicacion actual no disponible en este momento.');
    }

    return SosPayload(
      message: buffer.toString().trim(),
      position: position,
      mapsUrl: mapsUrl,
    );
  }

  Future<LocationPermission> requestLocationPermission() async {
    return Geolocator.requestPermission();
  }

  Future<void> sharePayload(SosPayload payload) {
    return SharePlus.instance.share(
      ShareParams(text: payload.message, subject: 'SOS SignalScope'),
    );
  }

  Future<void> launchSms(String phoneNumber, SosPayload payload) async {
    final uri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: <String, String>{
        'body': payload.message,
      },
    );
    await _launch(uri);
  }

  Future<void> launchDialer(String phoneNumber) async {
    await _launch(Uri(scheme: 'tel', path: phoneNumber));
  }

  Future<void> launchEmail({
    required String email,
    required SosPayload payload,
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: <String, String>{
        'subject': 'SOS SignalScope',
        'body': payload.message,
      },
    );
    await _launch(uri);
  }

  Future<void> launchMaps(SosPayload payload) async {
    if (payload.mapsUrl == null) {
      throw StateError('No current location available');
    }
    await _launch(Uri.parse(payload.mapsUrl!));
  }

  Future<void> _launch(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw StateError('Could not launch $uri');
    }
  }
}

bool isAndroidLikePlatform() =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
