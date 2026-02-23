# VCMI Portable Export Script
# Verwendung: .\export-portable.ps1
# Kopiert alle benoetigten Dateien in den VcmiAccess Ordner
# und erstellt eine Release-ZIP

# === Versionsnummer hier anpassen ===
$Version = "V0.3.2"

$ProjectRoot = "C:\Users\Sonja\Documents\Modprojekte\VCMI"
$BuildOutput = "$ProjectRoot\vcmi-1.7.2\build\bin\RelWithDebInfo"
$SourceRoot = "$ProjectRoot\vcmi-1.7.2"
$PortableDir = "$ProjectRoot\VcmiAccess-$Version"
$ZipFile = "$ProjectRoot\VcmiAccess.zip"

Write-Host "VCMI Accessibility Export" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan

# Pruefen ob Build-Output existiert
if (-not (Test-Path $BuildOutput)) {
    Write-Host "Fehler: Build-Output nicht gefunden unter $BuildOutput" -ForegroundColor Red
    Write-Host "Bitte zuerst bauen mit: Build-und-Exportieren.bat" -ForegroundColor Yellow
    exit 1
}

# Portable-Ordner leeren oder erstellen
if (Test-Path $PortableDir) {
    Write-Host "Loesche alten VcmiAccess-Ordner..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $PortableDir
}
New-Item -ItemType Directory -Path $PortableDir | Out-Null
Write-Host "VcmiAccess-Ordner erstellt: $PortableDir" -ForegroundColor Green

# DLLs und EXEs kopieren (ohne Debug-Dateien)
Write-Host "Kopiere DLLs und EXEs..." -ForegroundColor Yellow
Get-ChildItem -Path $BuildOutput -Filter "*.dll" | Copy-Item -Destination $PortableDir
Get-ChildItem -Path $BuildOutput -Filter "*.exe" | Copy-Item -Destination $PortableDir

# Debug- und Build-Artefakte entfernen
Remove-Item -Path "$PortableDir\*.pdb" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$PortableDir\*.lib" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$PortableDir\*.exp" -Force -ErrorAction SilentlyContinue

# AI-Ordner kopieren (nur DLLs)
Write-Host "Kopiere AI-DLLs..." -ForegroundColor Yellow
$AIDir = "$PortableDir\AI"
New-Item -ItemType Directory -Path $AIDir | Out-Null
Get-ChildItem -Path "$BuildOutput\AI" -Filter "*.dll" | Copy-Item -Destination $AIDir

# Platforms-Ordner kopieren
Write-Host "Kopiere Platforms..." -ForegroundColor Yellow
$PlatformsDir = "$PortableDir\platforms"
New-Item -ItemType Directory -Path $PlatformsDir | Out-Null
Get-ChildItem -Path "$BuildOutput\platforms" -Filter "*.dll" | Copy-Item -Destination $PlatformsDir

# Config-Ordner kopieren
Write-Host "Kopiere Config..." -ForegroundColor Yellow
Copy-Item -Recurse -Path "$SourceRoot\config" -Destination $PortableDir

# Mods-Ordner kopieren
Write-Host "Kopiere Mods..." -ForegroundColor Yellow
Copy-Item -Recurse -Path "$SourceRoot\Mods" -Destination $PortableDir

# BAT-Dateien erstellen
Write-Host "Erstelle Startscripte..." -ForegroundColor Yellow

$BatContent = @{
    "VCMI_client.bat" = '@echo off`nstart "" "%~dp0VCMI_client.exe"'
    "VCMI_launcher.bat" = '@echo off`nstart "" "%~dp0VCMI_launcher.exe"'
    "VCMI_server.bat" = '@echo off`nstart "" "%~dp0VCMI_server.exe"'
    "VCMI_mapeditor.bat" = '@echo off`nstart "" "%~dp0VCMI_mapeditor.exe"'
}

foreach ($file in $BatContent.Keys) {
    $content = $BatContent[$file] -replace '`n', "`r`n"
    Set-Content -Path "$PortableDir\$file" -Value $content -NoNewline
}

# Log-Dateien entfernen (falls aus Build-Output mitkopiert)
Remove-Item -Path "$PortableDir\accessibility_log.txt" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$PortableDir\screenreader_log.txt" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$PortableDir\*.dmp" -Force -ErrorAction SilentlyContinue

# Groesse berechnen
$size = (Get-ChildItem -Recurse $PortableDir | Measure-Object -Property Length -Sum).Sum / 1MB
$sizeRounded = [math]::Round($size, 1)

Write-Host ""
Write-Host "Export abgeschlossen!" -ForegroundColor Green
Write-Host "VcmiAccess-Ordner: $sizeRounded MB" -ForegroundColor Cyan

# === Release-ZIP erstellen ===
Write-Host ""
Write-Host "Erstelle Release-ZIP..." -ForegroundColor Yellow

# Datumssuffix fuer den Ordner in der ZIP (MM-DD)
$DateSuffix = (Get-Date).ToString("MM-dd")
$ZipFolderName = "VcmiAccess-$DateSuffix"

# Alte ZIP loeschen
Remove-Item -Path $ZipFile -Force -ErrorAction SilentlyContinue

# Temp-Ordner fuer ZIP-Struktur
$TempZipDir = "$ProjectRoot\_zip_temp\$ZipFolderName"
if (Test-Path "$ProjectRoot\_zip_temp") {
    Remove-Item -Recurse -Force "$ProjectRoot\_zip_temp"
}
New-Item -ItemType Directory -Path $TempZipDir | Out-Null

# README.md und LICENSE.md auf oberste Ebene
Copy-Item -Path "$ProjectRoot\README.md" -Destination $TempZipDir
Copy-Item -Path "$ProjectRoot\LICENSE.md" -Destination $TempZipDir

# Mod-Dateien in Unterordner VcmiAccess
Copy-Item -Recurse -Path $PortableDir -Destination "$TempZipDir\$ZipFolderName"

# ZIP erstellen (schnelle .NET-Methode statt Compress-Archive)
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory(
    "$ProjectRoot\_zip_temp\$ZipFolderName",
    $ZipFile,
    [System.IO.Compression.CompressionLevel]::Optimal,
    $true
)

# Temp aufraumen
Remove-Item -Recurse -Force "$ProjectRoot\_zip_temp"

$zipSize = (Get-Item $ZipFile).Length / 1MB
$zipSizeRounded = [math]::Round($zipSize, 1)

Write-Host "ZIP erstellt: VcmiAccess.zip ($zipSizeRounded MB)" -ForegroundColor Green
Write-Host ""
Write-Host "ZIP-Struktur:" -ForegroundColor White
Write-Host "  $ZipFolderName/"
Write-Host "    README.md"
Write-Host "    LICENSE.md"
Write-Host "    $ZipFolderName/"
Write-Host "      VCMI_client.exe, DLLs, config/, Mods/ ..."
Write-Host ""
Write-Host "Hinweis: Auf dem Zielgeraet werden Heroes-3-Spieldaten benoetigt!" -ForegroundColor Yellow
