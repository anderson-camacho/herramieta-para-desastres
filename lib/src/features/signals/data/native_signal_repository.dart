import 'dart:async';

import 'package:flutter/services.dart';

import 'package:signal_scope/src/core/models/capability_snapshot.dart';
import 'package:signal_scope/src/features/signals/domain/signal_models.dart';

class NativeSignalRepository {
  NativeSignalRepository({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _methodChannel = methodChannel ?? const MethodChannel('signalscope/methods'),
        _eventChannel = eventChannel ?? const EventChannel('signalscope/streams');

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  Stream<List<SignalReading>> watchSignals() {
    return _eventChannel.receiveBroadcastStream().map((event) {
      final rawList = (event as List<Object?>?) ?? <Object?>[];
      return rawList
          .map((item) => SignalReading.fromMap((item as Map<Object?, Object?>?) ?? <Object?, Object?>{}))
          .toList();
    });
  }

  Future<CapabilitySnapshot> loadCapabilities() async {
    final result = await _methodChannel.invokeMapMethod<Object?, Object?>('getCapabilities');
    return CapabilitySnapshot.fromMap(result ?? <Object?, Object?>{});
  }

  Future<List<String>> startBleSession() async {
    final result = await _methodChannel.invokeListMethod<Object?>('startBleScan');
    return (result ?? <Object?>[]).map((item) => '$item').toList();
  }

  Future<void> stopBleSession() => _methodChannel.invokeMethod<void>('stopBleScan');
}
