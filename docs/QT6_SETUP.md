# Qt6 GUI Setup Guide

## Current Status

✅ **Console Mode Working** - Lumi286 displays loaded modules in beautiful console format
⚠️ **Qt6 GUI Available But Not Enabled** - GUI code is written and ready, but Qt6 isn't being found by CMake

---

## Why Qt6 Isn't Working Yet

vcpkg installed qtbase (Qt6.9.3) but CMake can't find the Qt6Config.cmake files. This is likely a vcpkg manifest mode issue where packages are registered but not fully extracted to the installed directory.

---

## How to Enable Qt6 GUI

### Option 1: Manual vcpkg Installation (Recommended)

```bash
# Navigate to vcpkg directory
cd deps/vcpkg

# Install qtbase explicitly
.\vcpkg.exe install qtbase:x64-windows --recurse

# Verify installation
.\vcpkg.exe list | findstr qt

# Should show qtbase with all features installed
```

Then regenerate CMake:
```bash
cmake -S . -B build
```

CMake should now find Qt6 and enable the GUI.

### Option 2: Set CMAKE_PREFIX_PATH

If Qt6 is installed but not found, explicitly tell CMake where to look:

```bash
cmake -S . -B build -DCMAKE_PREFIX_PATH="F:/Lumi95/deps/vcpkg/installed/x64-windows"
```

### Option 3: Use System Qt6

Download and install Qt6 from https://www.qt.io/download and set Qt6_DIR:

```bash
cmake -S . -B build -DQt6_DIR="C:/Qt/6.9.3/msvc2022_64/lib/cmake/Qt6"
```

---

## Verifying Qt6 is Enabled

When CMake finds Qt6, you'll see:

```
-- [Lumi] Qt6 GUI enabled for Lumi286
```

When building, you'll see:
```
lumi_gui.vcxproj -> F:\Lumi95\build\src\Debug\lumi_gui.lib
```

When running, you'll see a beautiful CRT-style green-on-black GUI window displaying all loaded modules!

---

## What the GUI Will Show

When Qt6 is enabled, Lumi286 will launch with:

**Title**: 🌌 LUMINARA COGNITIVE ARCHITECTURE 🌌

**Module Display** (in retro CRT style):
```
╔════════════════════════════════════════════════════════════╗
║  MODULE NAME                │  STATUS                      ║
╠════════════════════════════════════════════════════════════╣
║  PhysX Foundation           │  INITIALIZED                 ║
║  PhysX Physics Engine       │  ACTIVE                      ║
║  CodonPhysicsEngine         │  READY                       ║
║  EmotionCore (CPU)          │  ALLOCATED                   ║
║  EmotionCore Binding        │  BOUND TO PHYSX              ║
║  LogicCore                  │  STUB                        ║
║  WisdomCore                 │  STUB                        ║
║  MemoryCore                 │  STUB                        ║
║  NarrativeCore              │  STUB                        ║
║  IntuitionCore              │  STUB                        ║
║  SomaticCore                │  STUB                        ║
║  ExecutiveCore              │  STUB                        ║
║  CoreFusionOrchestrator     │  STUB                        ║
╚════════════════════════════════════════════════════════════╝
```

**System Console** (real-time status updates):
```
[07:27:05] System boot initiated
[07:27:06] Module loaded: PhysX Foundation [INITIALIZED]
[07:27:06] Module loaded: CodonPhysicsEngine [READY]
[07:27:06] EmotionCore bound successfully
[07:27:07] Status: ✅ ONLINE - All systems nominal
```

**Visual Style**:
- Green phosphor text on black background (classic CRT aesthetic)
- Monospace Courier New font
- Real-time updates every second
- Animated console log

---

## Troubleshooting

### "Qt6_DIR-NOTFOUND" in CMakeCache.txt

This means CMake can't find Qt6. Solutions:
1. Run `deps/vcpkg/vcpkg.exe install qtbase:x64-windows` manually
2. Check that `deps/vcpkg/installed/x64-windows/share/qt6` exists
3. Set CMAKE_PREFIX_PATH to vcpkg installed directory

### "AUTOMOC disabled" warning

This means Qt6 was found but MOC (Meta-Object Compiler) isn't configured. The CMakeLists.txt is already set up to handle this - just ensure Qt6_FOUND is TRUE.

### Build errors about QApplication

If you see `Cannot open include file: 'QApplication'`, Qt6 headers aren't found. Check that:
1. Qt6 is installed by vcpkg (`vcpkg list | findstr qt`)
2. CMAKE found Qt6 (look for "Qt6 GUI enabled" message)
3. LUMI_HAS_QT6 is defined (check preprocessor definitions)

---

## For Now: Console Mode Works Great!

The console display shows all modules beautifully. You can continue developing Luminara's core functionality (Codons, Cores, Memory, etc.) and the GUI will automatically enable once Qt6 is properly configured.

---

## Next Steps After Qt6 is Enabled

1. Add interactive input box to GUI
2. Display emotional state visualization
3. Show PhysX attractor field in real-time
4. Add memory resonance graph
5. Implement CRT scanline effects and phosphor glow

The GUI foundation is ready - just waiting for Qt6 discovery!
