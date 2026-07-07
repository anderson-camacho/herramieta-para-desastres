# Matriz de pruebas manuales

| Android | Fabricante | Modelo | SIM | Wi-Fi | BLE | USB Host | Resultado esperado |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 8/9 | Samsung/Xiaomi/Motorola | Gama media antigua | 1 | Si | Si | No | Dashboard abre, permisos, celular y Wi-Fi con degradacion razonable |
| 12 | Motorola/Samsung | Telefono intermedio | 2 | Si | Si | Si | Sin mezclar suscripciones, BLE limitado y USB Host detectado |
| 14/15 | Pixel/Samsung | Telefono reciente | 1 o eSIM | Si | Si | Si | Permisos modernos, `targetSdk` 35, BLE y Wi-Fi segun restricciones actuales |
| 12+ | Tableta sin telefonia | Sin SIM | Si | Si | Variable | Variable | Celular como no compatible y resto funcional |

## Casos prioritarios

- Permiso concedido y denegado para telefono, ubicacion y Bluetooth.
- Wi-Fi apagado.
- Bluetooth apagado.
- Sin SIM.
- Dual SIM.
- Segundo plano y reanudacion.
- Sesion BLE inicia y se detiene sola.
- Dispositivo sin USB Host.
- Dispositivo con USB OTG.

