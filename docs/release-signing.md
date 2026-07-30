# Firma de lanzamiento para Android

La aplicacion no debe distribuir APK `release` firmados con la llave de depuracion. Cada instalacion publica o compartida debe usar una llave privada de lanzamiento controlada por el propietario del proyecto.

## Requisitos

- JDK 17 con `keytool` disponible en el `PATH`.
- Flutter y Android SDK configurados.
- Acceso seguro para guardar las contrasenas y una copia de respaldo del keystore.

## 1. Crear el keystore

Desde PowerShell, en la raiz del proyecto:

```powershell
./scripts/create-release-keystore.ps1
```

El script crea por defecto:

```text
android/keystore/herramienta-desastres-release.jks
```

Durante la ejecucion, `keytool` solicita contrasenas y datos del certificado. Guarda las contrasenas en un administrador de secretos y conserva una copia de respaldo del archivo `.jks` fuera del repositorio.

## 2. Crear `key.properties`

Copia el archivo de ejemplo:

```powershell
Copy-Item android/key.properties.example android/key.properties
```

Completa los valores reales:

```properties
storePassword=CONTRASENA_DEL_KEYSTORE
keyPassword=CONTRASENA_DE_LA_LLAVE
keyAlias=herramienta-desastres
storeFile=../keystore/herramienta-desastres-release.jks
```

`android/key.properties`, `*.jks` y `*.keystore` estan ignorados por Git y nunca deben subirse al repositorio.

## 3. Generar el APK firmado

```powershell
flutter clean
flutter pub get
flutter build apk --release --flavor production -t lib/main.dart
```

El APK se genera en:

```text
build/app/outputs/flutter-apk/app-production-release.apk
```

## 4. Verificar la firma

Con Android Build Tools instalado:

```powershell
apksigner verify --verbose --print-certs build/app/outputs/flutter-apk/app-production-release.apk
```

La salida debe indicar que la verificacion fue exitosa y mostrar el certificado de la llave creada.

## Consideraciones importantes

- No pierdas ni reemplaces el keystore después de distribuir la aplicacion. Las futuras actualizaciones deben firmarse con la misma llave.
- No compartas el archivo `.jks`, `key.properties` ni las contrasenas por GitHub, correo o chat.
- Una firma valida identifica al publicador, pero no garantiza por si sola que Google Play Protect no muestre advertencias para una aplicacion instalada fuera de Google Play.
- Para distribucion publica estable, se recomienda publicar mediante Google Play y usar Play App Signing.
