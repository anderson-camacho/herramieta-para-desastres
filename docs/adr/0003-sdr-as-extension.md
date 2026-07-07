# ADR 0003: SDR externo como extension

## Estado

Aprobado.

## Decision

La observacion RF fuera de las radios publicamente accesibles del telefono se modela como modulo opcional con receptor SDR por USB.

## Razon

Android no expone acceso arbitrario a frecuencias generales mediante APIs normales. Presentar el SDR como extension evita afirmar capacidades que el hardware base no posee.
