param(
    [string]$Alias = "herramienta-desastres",
    [string]$KeystorePath = "android/keystore/herramienta-desastres-release.jks",
    [int]$ValidityDays = 10000
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command keytool -ErrorAction SilentlyContinue)) {
    throw "No se encontro keytool. Verifica que JDK 17 este instalado y agregado al PATH."
}

$resolvedPath = Join-Path (Get-Location) $KeystorePath
$directory = Split-Path -Parent $resolvedPath
New-Item -ItemType Directory -Force -Path $directory | Out-Null

if (Test-Path $resolvedPath) {
    throw "Ya existe un keystore en: $resolvedPath"
}

Write-Host "Se creara una llave privada de lanzamiento en: $resolvedPath"
Write-Host "Guarda las contrasenas en un administrador seguro. Si pierdes la llave no podras actualizar la misma app publicada."

& keytool `
    -genkeypair `
    -v `
    -keystore $resolvedPath `
    -alias $Alias `
    -keyalg RSA `
    -keysize 2048 `
    -validity $ValidityDays

if ($LASTEXITCODE -ne 0) {
    throw "keytool termino con codigo $LASTEXITCODE"
}

Write-Host "Keystore creado correctamente."
Write-Host "Ahora copia android/key.properties.example como android/key.properties y completa las contrasenas."
