# VcmiAccess - VCMI Accessibility Edition

VCMI is an open-source reimplementation of the Heroes of Might and Magic 3 engine.
This version includes accessibility extensions that strive to make the game fully usable with screen readers.
We are blind ourselves and passionate about gaming. Claude Code did all the coding as we don't have any coding experience. However, we've been designing and testing everything thoroughly and will continue to do so until everything is fully functional. Our goal is to show the world that making mainstream games fully playable for the blind is possible by showcasing an example. There are many similar projects out there, some of them in a far more professionally polished state than what we could hope to achieve. But we're still happy to be part of this movement.

For further accessible gaming projects, help, support, and bug reports, please refer to the [Audiogames.net forum](https://forum.audiogames.net).

## Setup

1. Install the original Heroes of Might and Magic 3 (or the free demo)
2. Download and extract the latest release
3. Run **VCMI_launcher.exe** - it will ask you where your game files are installed
4. Start the game with **VCMI_client.exe**

## Features

(Note: This is still a beta version. Most things work but please don't set your expectations too high just yet. We'll keep working on it, so please let us know about any bugs you stumble upon, either here or in the Audiogames forum.)
- Full screen reader support via Tolk (NVDA/JAWS)
- Keyboard navigation for all menus and dialogs
- Exploration mode (F2) for accessible map navigation
- Context-sensitive help (F1) everywhere
- Battle accessibility with unit and action announcements
- Localized announcements in multiple languages

## Quick Start Guide

All the game action happens on a rectangular map with two levels and lots of obstacles.
Pressing the arrow keys will automatically move your selected hero, spending their valuable movement points.
That is why we have created an exploration mode:

- Press **F2** to activate exploration mode and explore the map freely
- **Arrow keys** move the cursor without spending movement
- **Ctrl+Arrow** jumps to the next interesting object in that direction
- **Enter** sends your hero walking to the cursor position
- **X** moves the cursor to the nearest unexplored area
- **Shift+X** autowalks your hero towards unexplored land

Press **F1** at any time for context-sensitive help.
Press **Ctrl+Shift+F12** to temporarily disable or re-enable the accessibility features.

## Keyboard Shortcuts

Some of these are accessibility-specific, many are already built into VCMI.

### Resource Handling

- **F7** on the map: Read all resources
- **1-9** in Kingdom Overview (K): Read individual resources

### Main Menu

- **N** - New game
- **L** - Load game
- **Q / Escape** - Quit
- **B / Escape** - Back

Singleplayer submenu: **S** Singleplayer, **M** Multiplayer, **C** Campaign, **T** Tutorial

Multiplayer submenu: **H** Hotseat, **C** Host game, **J** Join game, **Ctrl+Tab** Online lobby

### Lobby / Map Selection

- **Tab** - Switch between map list and buttons
- **B** - Begin game
- **L** - Load game
- **S** - Save game
- **R** - Random map
- **A** - Additional options
- **E** - Extra options
- **T** - Turn options

### Adventure Map

Basic Navigation:

- **H** - Next hero
- **Ctrl+H** - First hero
- **T** - Next town
- **Ctrl+T** - First town
- **N** - Next object (hero or town)
- **K** - Kingdom overview

Accessibility:

- **F2** - Toggle exploration mode
- **F7** - Announce resources
- **Alt+H** - Hero list navigation

Hero Actions:

- **M** - Move hero along path
- **C** - Cast spell (open spellbook)
- **Z** - Set hero asleep
- **W** - Wake hero
- **D** - Dig for grail
- **Enter** - Open selected hero/town

Game Controls:

- **E** - End turn
- **O** - Game options
- **L** - Load game
- **S** - Save game
- **F8** - Quick save
- **F9** - Quick load
- **Ctrl+F** - Search
- **Alt+F** - Continue search

Movement (Numpad or Arrow keys):

- **Numpad 7 / Home** - Move northwest
- **Numpad 8 / Up** - Move north
- **Numpad 9 / PageUp** - Move northeast
- **Numpad 4 / Left** - Move west
- **Numpad 6 / Right** - Move east
- **Numpad 1 / End** - Move southwest
- **Numpad 2 / Down** - Move south
- **Numpad 3 / PageDown** - Move southeast

### Exploration Mode

- **Arrow keys** - Move cursor without spending movement
- **Ctrl+Arrow** - Jump to next reachable object in direction
- **Ctrl+Shift+Left/Right** - Cycle through all objects
- **Shift+Arrow** - Jump to unexplored tile in direction
- **X** - Move cursor to nearest unexplored
- **Shift+X** - Move hero to nearest unexplored
- **Ctrl+X** - Auto-explore
- **Enter** - Set path to cursor position

### Battle

Navigation:

- **Arrow keys** - Move hex cursor
- **Tab** - Select next enemy and move cursor
- **Shift+Tab** - Select previous enemy
- **Ctrl+Right** - Jump to next unit (any)
- **Ctrl+Left** - Jump to previous unit (any)
- **Enter** - Interact with hex under cursor

Actions:

- **W** - Wait
- **D / Space** - Defend
- **C** - Cast spell
- **F / G** - Use creature spell
- **A** - Autocombat
- **Q** - End battle with autocombat
- **S** - Surrender
- **R** - Retreat

Information:

- **F8** - Announce current stack info
- **I** - Info about active unit
- **V** - Info about hovered unit
- **Z** - Toggle battle queue
- **Ctrl+Shift+M** - Toggle mute battle announcements

Quickspell slots: **1-0** for slots 1-10, **N** for slot 11, **M** for slot 12

### Hero Window

- **Up/Down** - Navigate through menu items
- **Enter** - Activate selected item
- **Escape** - Close window
- **C** - Commander
- **D** - Dismiss hero
- **S** - Split army

Equipment Navigation (when activated):

- **Up/Down** - Navigate through equipment slots
- **Enter** - Show artifact popup
- **I** - Show artifact description
- **U** - Unequip artifact to backpack
- **Escape** - Exit equipment navigation

### Town / Castle

- **Up/Down** - Switch between towns
- **I** - Accessible building overview and management
- **B** - Town hall
- **F** - Fort
- **G** - Mage guild
- **M** - Marketplace
- **T** - Tavern
- **R** - Open recruitment
- **H** - Open hero
- **E** - Hero exchange (requires two heroes)
- **Space** - Swap armies between heroes

### Kingdom Overview

- **H** - Hero list tab
- **T** - Town list tab
- **I** - Announce details of selected entry
- **A** - Announce army of selected entry
- **R** - Announce resources
- **M** - Announce mines

### Spellbook

- **Tab** - Toggle between school and spell navigation
- **Up/Down** - Switch between magic schools (when in school navigation)
- **Arrow keys** - Navigate through spells (when in spell navigation)
- **Enter** - Cast selected spell
- **D** - Announce spell description

### Marketplace / Trade

- **Up/Down** - Select resource
- **Tab** - Switch between give and receive panels
- **Left/Right** - Adjust trade amount
- **Enter** - Complete trade
- **M** - Maximum amount

### Hero Exchange

- **F10 / Q** - Swap all armies
- **F11 / Q** - Swap all artifacts
- **Ctrl+F11** - Swap equipped artifacts
- **Shift+F11** - Swap backpack artifacts

### Quick Recruitment (Fort/Citadel/Castle)

- **1-7** - Recruit from individual creature slots
- **U** - Upgrade all creatures
- **M** - Set maximum for all

### Online Lobby

- **Tab** - Cycle forward through areas
- **Shift+Tab** - Cycle backward through areas

### Save/Load Dialogs

Press Tab to jump to the file list. Files are organized in folders - press Right to open a folder, navigate with arrows, and select with Enter. Then Tab again to the Start button.
