# Aufgabenbeschreibung: VcmiAccess Screen-Reader-Unterstützung für macOS (und Linux)

**Ziel:** Die Sprachausgabe über Screen Reader, die aktuell nur auf Windows funktioniert, auf macOS zum Laufen bringen. Linux wäre ein Bonus, hat aber niedrigere Priorität.

**Priorität:** Mac zuerst. Linux, wenn Zeit übrig bleibt.

**Auftraggeberin:** Sonja (prinzessinderfreiheit@posteo.de) — blind, nutzt NVDA unter Windows.

---

## 1. Hintergrund

VcmiAccess ist ein Fork von [VCMI](https://github.com/vcmi/vcmi) (einer Open-Source-Neuimplementierung der Heroes-of-Might-and-Magic-III-Engine), der blinden Spielerinnen und Spielern Zugänglichkeit per Screen Reader ermöglicht. VCMI selbst ist schon crossplatform (SDL2, C++, CMake) — Windows, macOS (Intel + Apple Silicon), Linux, Android, iOS. Die offiziellen VCMI-Builds werden für alle diese Plattformen veröffentlicht.

**Das Problem**: Unsere Accessibility-Ebene nutzt unter Windows [Tolk](https://github.com/ndarilek/tolk) — eine Bibliothek, die NVDA, JAWS, Narrator etc. ansteuert. Tolk ist Windows-only. Auf macOS und Linux kompiliert unser Code zwar, aber die Screen-Reader-Ausgabe wird stumm verworfen.

**Was schon crossplatform ist (99% des Codes)**: Der gesamte Ordner `vcmi-1.7.3/client/accessibility/` außer `ScreenReader.cpp` — FocusManager, AccessibilityStrings, ExplorationMode, Logging, alle Patches in den Spielmenüs, Tastaturnavigation, Ansagetexte, Lokalisierung (27 Sprachen). Das alles läuft auf Mac sofort, sobald ein funktionierender Screen-Reader-Output vorhanden ist.

**Was neu geschrieben werden muss**: Nur das plattformspezifische Backend in `ScreenReader.cpp`.

---

## 2. Umfang der Aufgabe

### Priorität 1: macOS-Screen-Reader-Backend

Die Zielgruppe nutzt **VoiceOver** (in macOS eingebaut). Es gibt zwei technische Wege:

- **Weg A (bevorzugt): `NSAccessibilityPostNotification` mit `NSAccessibilityAnnouncementRequestedNotification`**
  - Der Text wird an VoiceOver übergeben, VoiceOver spricht ihn mit der vom Nutzer eingestellten Stimme und Geschwindigkeit.
  - Vorteil: konsistent mit dem, was Nutzer gewohnt sind.
  - Nachteil: VoiceOver-Queue/Interrupt ist weniger direkt steuerbar als bei Tolk.

- **Weg B (Fallback oder Ergänzung): `AVSpeechSynthesizer`**
  - Direkte Sprachausgabe über das System-TTS, unabhängig davon ob VoiceOver läuft.
  - Vorteil: volle Kontrolle über Queue, Interrupt, Geschwindigkeit.
  - Nachteil: spricht mit eigener Stimme, nicht mit VoiceOvers Stimme — kann verwirrend sein.

**Empfehlung**: Implementiere **Weg A als Standard**. Weg B als Option in den Einstellungen, falls Weg A zu unzuverlässig ist. Entscheidung nach Rücksprache.

### Priorität 2: macOS-Build zum Laufen bringen

Offizielle VCMI-Build-Anleitungen:
- <https://vcmi.eu/developers/Building_macOS/>
- <https://wiki.vcmi.eu/How_to_build_VCMI_(macOS)>

Unser Fork sollte nach dem gleichen Prozess baubar sein. Erwartete Stolperstellen:
- Dependencies via Homebrew oder vorgefertigtes `dependencies-mac`-Archiv
- Xcode-Projekt via CMake generieren
- Code-Signing (für Testen auf der eigenen Maschine irrelevant, für Distribution relevant — erstmal ignorieren)

### Priorität 3 (optional): Linux-Backend

- API: [speech-dispatcher / libspeechd](https://github.com/brailcom/speechd) — wird von Orca genutzt, ist Standard auf Linux
- Package: `libspeechd-dev` (Debian/Ubuntu)
- API-Funktionen: `spd_open`, `spd_say` (mit Priorität `SPD_MESSAGE` oder `SPD_IMPORTANT`), `spd_stop`, `spd_close`
- Deutlich einfacher als macOS, aber niedrigere Priorität weil die Nutzerin aktuell Windows + macOS nutzt.

---

## 3. Aktuelle Code-Struktur

### Relevante Dateien (alle Pfade relativ zum Repo-Root)

- `vcmi-1.7.3/client/accessibility/ScreenReader.h` — öffentliche API der ScreenReader-Singleton-Klasse
- `vcmi-1.7.3/client/accessibility/ScreenReader.cpp` — Tolk-Backend, Windows-only
- `vcmi-1.7.3/client/accessibility/Tolk.h` — Original-Tolk-Header
- `vcmi-1.7.3/client/CMakeLists.txt` — Client-Build, Zeilen 4-9 und 225-232 listen die Accessibility-Dateien

### Aktuelle `ScreenReader`-API (muss erhalten bleiben)

```cpp
void speak(const std::string & text);                 // Alias für speakQueued
void speakQueued(const std::string & text);           // In Queue einreihen
void speakInterruptible(const std::string & text);    // Aktuelle Sprache abbrechen, sofort sprechen
void speakWithDetails(const std::string & mainText, const std::vector<std::string> & details);
void speakBattle(const std::string & text);           // Respektiert battleMuted-Flag
void stop();                                          // Aktuelle Sprache abbrechen
void update();                                        // Pro Frame aus dem Game-Loop aufgerufen
bool isAvailable() const;
void setEnabled(bool); bool isEnabled() const;
void setBattleMuted(bool); void toggleBattleMute(); bool isBattleMuted() const;
std::string getScreenReaderName() const;
```

Diese API wird an **367 Stellen im Client-Code** aufgerufen (`ScreenReader::getInstance().speakXxx(...)`). Sie darf **nicht verändert** werden. Jede neue Implementierung muss sich dahinter verstecken.

### Aktueller Windows-Code

`ScreenReader.cpp` lädt `Tolk.dll` dynamisch via `LoadLibraryW`, holt sich Funktionszeiger via `GetProcAddress`, ruft `Tolk_Load`, `Tolk_DetectScreenReader`, `Tolk_Output(text, interrupt)` und `Tolk_Silence` auf. Alles in `#ifdef VCMI_WINDOWS`-Blöcken gekapselt. Auf Nicht-Windows-Plattformen liefert `initialize()` `false` — damit werden Sprechaufrufe still verworfen.

---

## 4. Empfohlene Umsetzung

### 4.1 Backend-Abstraktion einführen

Statt neue `#ifdef`-Blöcke in `ScreenReader.cpp` zu stopfen, saubere Trennung:

```
vcmi-1.7.3/client/accessibility/
├── ScreenReader.h              (unverändert — öffentliche API)
├── ScreenReader.cpp            (delegiert an Backend)
├── backend/
│   ├── IScreenReaderBackend.h  (neue Schnittstelle)
│   ├── TolkBackend.cpp         (Windows, der bisherige Code)
│   ├── VoiceOverBackend.mm     (macOS, Objective-C++)
│   └── SpeechdBackend.cpp      (Linux, optional)
```

**Schnittstelle** (Vorschlag):

```cpp
class IScreenReaderBackend {
public:
    virtual ~IScreenReaderBackend() = default;
    virtual bool initialize() = 0;
    virtual bool isAvailable() const = 0;
    virtual std::string getName() const = 0;
    virtual void speak(const std::string & utf8, bool interrupt) = 0;
    virtual void stop() = 0;
};
```

`ScreenReader::initialize()` wählt per `#ifdef` das passende Backend aus. Queue-Management, Battle-Muting, Enabled-Flag etc. bleiben in `ScreenReader.cpp` und sind backend-unabhängig.

### 4.2 macOS-Backend (Details)

Datei `VoiceOverBackend.mm` — `.mm` bedeutet Objective-C++, d.h. C++ darf Objective-C-Calls machen.

**Minimalimplementierung (Weg A):**

```objc
#import <AppKit/AppKit.h>

bool VoiceOverBackend::initialize() {
    // VoiceOver läuft, wenn AXIsProcessTrusted() + VoiceOver-Check.
    // Einfachere Variante: einfach immer als "verfügbar" markieren,
    // denn NSAccessibilityPostNotification schlägt nicht fehl, wenn
    // kein Screen Reader läuft — der Text wird nur ignoriert.
    return true;
}

void VoiceOverBackend::speak(const std::string & utf8, bool interrupt) {
    NSString * str = [NSString stringWithUTF8String:utf8.c_str()];
    NSAccessibilityPriorityLevel prio = interrupt
        ? NSAccessibilityPriorityHigh
        : NSAccessibilityPriorityMedium;

    NSDictionary * info = @{
        NSAccessibilityAnnouncementKey: str,
        NSAccessibilityPriorityKey: @(prio)
    };

    NSWindow * window = [[NSApplication sharedApplication] mainWindow];
    NSAccessibilityPostNotificationWithUserInfo(
        window,
        NSAccessibilityAnnouncementRequestedNotification,
        info
    );
}
```

**CMake-Integration für macOS**:

```cmake
if(APPLE)
    list(APPEND vcmiclientcommon_SRCS
        accessibility/backend/VoiceOverBackend.mm)
    # Cocoa-Framework linken
    find_library(COCOA_LIBRARY Cocoa)
    target_link_libraries(vcmiclientcommon PRIVATE ${COCOA_LIBRARY})
endif()
```

Wichtig: `.mm`-Dateien brauchen `-fobjc-arc` (Automatic Reference Counting) oder manuelles Memory-Management. Apple Clang akzeptiert `.mm` automatisch als Objective-C++.

### 4.3 Was du nicht anfassen musst

- `FocusManager.cpp`, `FocusAdapters.cpp`, `AccessibilityStrings.cpp` — plattformneutral, kompilieren unverändert.
- Die 367 `ScreenReader::getInstance().speakXxx(...)`-Aufrufe im Rest des Clients — bleiben unverändert.
- Die Lokalisierungs-JSON-Dateien — unverändert.
- Das eigentliche VCMI-Spiellogik.

---

## 5. Build- und Testanweisungen

### 5.1 Repo klonen

```
git clone https://github.com/HappyStarfish/VcmiAccess.git
cd VcmiAccess
```

Branch: `master` (dort passiert alles).

### 5.2 macOS-Build

Dependencies (Homebrew):
```
brew install cmake boost sdl2 sdl2_image sdl2_ttf sdl2_mixer qt@5 ffmpeg minizip tbb
```

Build:
```
cd vcmi-1.7.3
mkdir build && cd build
cmake -G Xcode ..
cmake --build . --config RelWithDebInfo
```

Alternativ: Xcode-Projekt in `build/VCMI.xcodeproj` öffnen, Scheme `vcmiclient` wählen, Build.

### 5.3 Testen

Zum Testen brauchst du das Spiel Heroes of Might and Magic III — kommerziell (Steam, GOG) oder aus der HoMM3-Demo, die VCMI unterstützt. VCMI-Launcher fragt beim ersten Start nach dem HoMM3-Ordner.

VoiceOver aktivieren: `Cmd + F5` oder Systemeinstellungen → Bedienungshilfen → VoiceOver.

**Testmatrix (minimal)**:
- Hauptmenü öffnet sich → erste Ansage hörbar?
- Pfeiltasten im Menü → Menüpunkte werden angesagt?
- Spiel starten (Szenario laden) → Ortsnamen, Held-Auswahl angesagt?
- Stadtansicht (auf Stadt klicken) → Gebäude/Kreaturen angesagt?
- Kampf starten → Stack-Infos angesagt?

Sonja kann die detaillierten Tests machen, sobald die erste Version überhaupt spricht. Ziel deiner Arbeit ist: **irgendeine hörbare Ausgabe auf macOS**, von da an kann iteriert werden.

### 5.4 Linux-Build (falls du dich dran wagst)

```
sudo apt install cmake g++ libboost-all-dev libsdl2-dev libsdl2-image-dev libsdl2-ttf-dev \
                 libsdl2-mixer-dev qtbase5-dev libavformat-dev libswscale-dev libtbb-dev \
                 libspeechd-dev
cd vcmi-1.7.3
mkdir build && cd build
cmake ..
make -j$(nproc)
```

Orca aktivieren: `Super+Alt+S` unter GNOME.

---

## 6. Definition of Done

**Minimal (Priorität 1 erfüllt):**
- [ ] macOS-Build kompiliert sauber mit `cmake --build . --config RelWithDebInfo`
- [ ] Bei aktivem VoiceOver hört man Ansagen beim Öffnen des Hauptmenüs
- [ ] `speakInterruptible` unterbricht hörbar laufende Ansagen
- [ ] `speakQueued` reiht Ansagen hintereinander ein, ohne die vorherige abzubrechen
- [ ] Pull Request gegen `master` des Forks mit Zusammenfassung der Änderungen

**Ideal (Priorität 2 + 3 erfüllt):**
- [ ] Linux-Backend mit speech-dispatcher funktioniert analog
- [ ] CI-Workflow (GitHub Actions) für macOS- und Linux-Builds ergänzt
- [ ] README im Root erwähnt macOS/Linux-Support-Status

---

## 7. Kontakt und Rückfragen

- **Issues / Fragen**: Im Repo <https://github.com/HappyStarfish/VcmiAccess> als Issue anlegen oder direkt an Sonja mailen
- **Upstream-Referenz** (nicht unser Fork, aber baubar zum Vergleichen): <https://github.com/vcmi/vcmi>
- **Bei CMake-Problemen**: Die VCMI-Community hat ein Forum <https://forum.vcmi.eu> und Discord

### Nützliche Ressourcen

- NSAccessibility-Doku: <https://developer.apple.com/documentation/appkit/nsaccessibility>
- AVSpeechSynthesizer: <https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer>
- speech-dispatcher API: <https://htmlpreview.github.io/?https://github.com/brailcom/speechd/blob/master/doc/speech-dispatcher.html>
- VCMI Build-Doku macOS: <https://wiki.vcmi.eu/How_to_build_VCMI_(macOS)>
- Tolk-Header (Referenz für API-Semantik, die wir nachbauen): `vcmi-1.7.3/client/accessibility/Tolk.h`

---

## 8. Zeitschätzung

- Setup + Build auf macOS zum ersten Mal: 0,5–1 Tag
- VoiceOver-Backend schreiben + durchgehend testen: 2–3 Tage
- Backend-Abstraktion sauber refaktorieren: 1 Tag
- Pull Request + Feedback-Runde: 0,5 Tag
- **Summe macOS-Minimalziel: ca. 1 Arbeitswoche**
- Linux-Backend zusätzlich: 1–2 Tage

Plane realistisch mit 1,5–2 Wochen, wenn du die APIs nicht schon kennst.
