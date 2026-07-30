# Herramienta para Desastres

Herramienta para Desastres es una aplicacion Flutter con Android como plataforma principal para observar senales que el dispositivo puede medir legalmente mediante APIs publicas: celular, Wi-Fi, Bluetooth/BLE y compatibilidad USB Host para un futuro SDR externo.

## Que hace

- Diagnostica capacidades del dispositivo y estado de permisos.
- Muestra estado celular, Wi-Fi, Bluetooth y BLE mediante una interfaz comun en Flutter.
- Mantiene historial local opcional para visualizar variacion de RSSI en el tiempo.
- Detecta compatibilidad USB Host y expone una base de arquitectura para SDR externo.
- Incluye onboarding, modo demo, privacidad visible y diagnostico del dispositivo.

## Que no hace

- No usa APIs ocultas ni privilegios del sistema.
- No promete acceso total a todas las radios del telefono.
- No captura trafico Wi-Fi ajeno ni datos privados.
- No afirma identificar fuentes RF arbitrarias sin SDR externo.

## Estado del MVP en este repositorio

Se entrega un recorrido vertical funcional a nivel de codigo:

- Flutter multiplataforma con degradacion explicita fuera de Android.
- Integracion Android nativa en Kotlin por `MethodChannel` y `EventChannel`.
- Diagnostico, permisos, dashboard, historial, onboarding y modo demo.
- Estructura SDR desacoplada con adaptador simulado y detector USB Host.

## Requisitos

- Flutter estable reciente compatible con Dart 3.4+.
- Android SDK con `compileSdk` 36.
- JDK 17.

## Instalacion de Flutter

La documentacion oficial de Flutter para instalar el SDK esta en [docs.flutter.dev/install](https://docs.flutter.dev/install).

## Comandos principales

```bash
flutter doctor -v
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --debug --flavor development -t lib/main.dart
flutter build apk --release --flavor production -t lib/main.dart
flutter build apk --release --flavor production -t lib/main.dart --split-per-abi
flutter build appbundle --release --flavor production -t lib/main.dart
flutter build web
```

## Artefactos verificados en esta maquina

- APK debug de desarrollo: `build/app/outputs/flutter-apk/app-development-debug.apk`
- APK release universal: `build/app/outputs/flutter-apk/app-production-release.apk`
- APKs por ABI: `build/app/outputs/flutter-apk/app-*-production-release.apk`
- Android App Bundle: `build/app/outputs/bundle/productionRelease/app-production-release.aab`
- Build web: `build/web`

## Instalacion en Android

```bash
adb devices
adb install -r build/app/outputs/flutter-apk/app-development-debug.apk
```

Para release manual:

```bash
adb install -r build/app/outputs/flutter-apk/app-production-release.apk
```

## Sabores

- `development`
- `staging`
- `production`

## Permisos Android

- `READ_PHONE_STATE`
- `ACCESS_NETWORK_STATE`
- `ACCESS_WIFI_STATE`
- `ACCESS_FINE_LOCATION` con `maxSdkVersion=32` para compatibilidad
- `NEARBY_WIFI_DEVICES`
- `BLUETOOTH`, `BLUETOOTH_ADMIN` con `maxSdkVersion=30`
- `BLUETOOTH_SCAN`
- `BLUETOOTH_CONNECT`

## Arquitectura

La documentacion detallada esta en `docs/architecture.md`.

## Privacidad

La politica de privacidad esta en `docs/privacy-policy.md`.

## Licencia

Este proyecto se publica bajo Apache-2.0.

## Limitaciones verificadas en este entorno

- `flutter analyze` paso sin issues.
- `flutter test` paso.
- `flutter build web` paso.
- Se generaron APK debug, APK release, APKs por ABI y AAB.
- No fue posible validar hardware real: Dual SIM, BLE real, Wi-Fi real, OTG real, SDR real.
- El build de Windows requiere habilitar `Developer Mode` por soporte de symlinks.
