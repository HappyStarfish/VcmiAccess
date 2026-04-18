# VCMI Portable Export Script
# Verwendung: .\export-portable.ps1
# Kopiert alle benoetigten Dateien in den VcmiAccess Ordner
# und erstellt eine Release-ZIP
#
# Quellen fuer DLLs:
#   - VCMI-eigene:   Build-Output (vcmi-1.7.3\build\bin\RelWithDebInfo)
#   - Conan-Deps:    _runtime_libs.txt (SDL2, Boost, FFmpeg, etc.)
#   - Qt5:           Conan Qt-Paket (Qt5Core, qwindows.dll, etc.)
#   - Screenreader:  deps\ Ordner (Tolk.dll, nvdaControllerClient64.dll)

# === Versionsnummer hier anpassen ===
$Version = "V0.3.6"

$ProjectRoot = "C:\Users\Sonja\Documents\Modprojekte\VCMI"
$BuildOutput = "$ProjectRoot\vcmi-1.7.3\build\bin\RelWithDebInfo"
$SourceRoot = "$ProjectRoot\vcmi-1.7.3"
$ConanMsvc = "$SourceRoot\conan-msvc"
$PortableDir = "$ProjectRoot\VcmiAccess-$Version"
$ZipFile = "$ProjectRoot\VcmiAccess.zip"
$DepsDir = "$ProjectRoot\deps"

Write-Host "VCMI Accessibility Export" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan

# Pruefen ob Build-Output existiert
if (-not (Test-Path $BuildOutput)) {
    Write-Host "Fehler: Build-Output nicht gefunden unter $BuildOutput" -ForegroundColor Red
    Write-Host "Bitte zuerst bauen mit: .\build.ps1" -ForegroundColor Yellow
    exit 1
}

# Portable-Ordner leeren oder erstellen
if (Test-Path $PortableDir) {
    Write-Host "Loesche alten VcmiAccess-Ordner..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $PortableDir
}
New-Item -ItemType Directory -Path $PortableDir | Out-Null
Write-Host "VcmiAccess-Ordner erstellt: $PortableDir" -ForegroundColor Green

# === 1. VCMI eigene DLLs und EXEs kopieren ===
Write-Host "Kopiere VCMI DLLs und EXEs..." -ForegroundColor Yellow
Get-ChildItem -Path $BuildOutput -Filter "*.dll" | Copy-Item -Destination $PortableDir
Get-ChildItem -Path $BuildOutput -Filter "*.exe" | Copy-Item -Destination $PortableDir

# Debug- und Build-Artefakte entfernen
Remove-Item -Path "$PortableDir\*.pdb" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$PortableDir\*.lib" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$PortableDir\*.exp" -Force -ErrorAction SilentlyContinue

# === 2. Conan Runtime-DLLs kopieren (SDL2, Boost, FFmpeg, etc.) ===
Write-Host "Kopiere Conan Runtime-DLLs..." -ForegroundColor Yellow
$RuntimeLibsFile = "$ConanMsvc\_runtime_libs.txt"
if (Test-Path $RuntimeLibsFile) {
    $runtimeLibs = Get-Content $RuntimeLibsFile
    $copiedCount = 0
    $missingCount = 0
    foreach ($lib in $runtimeLibs) {
        $lib = $lib.Trim()
        if ($lib -and (Test-Path $lib)) {
            Copy-Item -Path $lib -Destination $PortableDir
            $copiedCount++
        } elseif ($lib) {
            Write-Host "  WARNUNG: Nicht gefunden: $lib" -ForegroundColor Red
            $missingCount++
        }
    }
    Write-Host "  $copiedCount Conan-DLLs kopiert" -ForegroundColor Green
    if ($missingCount -gt 0) {
        Write-Host "  $missingCount DLLs fehlen! Evtl. Conan-Cache bereinigt?" -ForegroundColor Red
    }
} else {
    Write-Host "  FEHLER: _runtime_libs.txt nicht gefunden: $RuntimeLibsFile" -ForegroundColor Red
    Write-Host "  Conan-Abhaengigkeiten koennen nicht kopiert werden!" -ForegroundColor Red
    exit 1
}

# === 3. Qt5-DLLs kopieren ===
Write-Host "Kopiere Qt5-DLLs..." -ForegroundColor Yellow
$QtDataFile = "$ConanMsvc\Qt5-relwithdebinfo-x86_64-data.cmake"
$QtPackageFolder = $null
if (Test-Path $QtDataFile) {
    $match = Select-String -Path $QtDataFile -Pattern 'set\(qt_PACKAGE_FOLDER_RELWITHDEBINFO "(.+?)"\)' | Select-Object -First 1
    if ($match) {
        $QtPackageFolder = $match.Matches[0].Groups[1].Value
    }
}

if ($QtPackageFolder -and (Test-Path $QtPackageFolder)) {
    # Qt-DLLs die VCMI benoetigt (Launcher, Map-Editor)
    $QtDlls = @(
        "Qt5Core.dll",
        "Qt5Gui.dll",
        "Qt5Network.dll",
        "Qt5Svg.dll",
        "Qt5Widgets.dll",
        "Qt5Xml.dll",
        "libEGL.dll",
        "libGLESv2.dll"
    )
    foreach ($dll in $QtDlls) {
        $src = Join-Path "$QtPackageFolder\bin" $dll
        if (Test-Path $src) {
            Copy-Item -Path $src -Destination $PortableDir
        } else {
            Write-Host "  WARNUNG: Qt-DLL nicht gefunden: $dll" -ForegroundColor Red
        }
    }
    Write-Host "  Qt5-DLLs kopiert" -ForegroundColor Green

    # Qt Platforms-Plugin (qwindows.dll) - zwingend fuer GUI
    $PlatformsDir = "$PortableDir\platforms"
    New-Item -ItemType Directory -Path $PlatformsDir | Out-Null
    $QWindowsSrc = "$QtPackageFolder\plugins\platforms\qwindows.dll"
    if (Test-Path $QWindowsSrc) {
        Copy-Item -Path $QWindowsSrc -Destination $PlatformsDir
        Write-Host "  qwindows.dll kopiert" -ForegroundColor Green
    } else {
        Write-Host "  FEHLER: qwindows.dll nicht gefunden!" -ForegroundColor Red
    }
} else {
    Write-Host "  FEHLER: Qt-Paketordner nicht ermittelt aus $QtDataFile" -ForegroundColor Red
    Write-Host "  Qt5-DLLs koennen nicht kopiert werden!" -ForegroundColor Red
    exit 1
}

# === 4. Tolk/NVDA-DLLs kopieren (Screenreader-Unterstuetzung) ===
Write-Host "Kopiere Tolk/NVDA-DLLs..." -ForegroundColor Yellow
$TolkDlls = @("Tolk.dll", "nvdaControllerClient64.dll")
foreach ($dll in $TolkDlls) {
    $src = Join-Path $DepsDir $dll
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination $PortableDir
        Write-Host "  $dll kopiert" -ForegroundColor Green
    } else {
        Write-Host "  WARNUNG: $dll nicht gefunden in $DepsDir" -ForegroundColor Yellow
        Write-Host "  Bitte $dll in den deps-Ordner kopieren!" -ForegroundColor Yellow
    }
}

# === 5. AI-Ordner kopieren (nur DLLs) ===
Write-Host "Kopiere AI-DLLs..." -ForegroundColor Yellow
$AIDir = "$PortableDir\AI"
New-Item -ItemType Directory -Path $AIDir | Out-Null
Get-ChildItem -Path "$BuildOutput\AI" -Filter "*.dll" | Copy-Item -Destination $AIDir

# === 6. Config-Ordner kopieren ===
Write-Host "Kopiere Config..." -ForegroundColor Yellow
Copy-Item -Recurse -Path "$SourceRoot\config" -Destination $PortableDir

# === 7. Mods-Ordner kopieren ===
Write-Host "Kopiere Mods..." -ForegroundColor Yellow
Copy-Item -Recurse -Path "$SourceRoot\Mods" -Destination $PortableDir

# === 8. BAT-Dateien erstellen ===
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

# === Zusammenfassung der kopierten DLLs ===
$dllCount = (Get-ChildItem -Path $PortableDir -Filter "*.dll").Count
$dllCount += (Get-ChildItem -Path "$PortableDir\AI" -Filter "*.dll" -ErrorAction SilentlyContinue).Count
$dllCount += (Get-ChildItem -Path "$PortableDir\platforms" -Filter "*.dll" -ErrorAction SilentlyContinue).Count
Write-Host "Insgesamt $dllCount DLLs im Export" -ForegroundColor Cyan

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
Write-Host "Hinweis: VC++ Redistributable 2015-2022 muss installiert sein!" -ForegroundColor Yellow
