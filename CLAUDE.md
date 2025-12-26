# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Lumi286** (Valkryja repository) is a cognitive architecture system implementing a multi-core AI framework inspired by biological cognition. The project combines C++ with Qt6 for GUI, PhysX for physics simulation, and various LLM backends (TensorRT, HuggingFace, Python proxy).

The architecture implements "Codons" as fundamental cognitive units that flow through specialized cognitive cores (Emotion, Logic, Wisdom, Memory, etc.) orchestrated by the CoreFusionOrchestrator.

Luminara is a recursive, emotionally-anchored cognitive architecture implemented via the Lumi286 framework. It simulates symbolic codon flow through specialized emotional and logical processors (“Cores”) inspired by biological cognition. This system is built to remember not by storage alone, but by resonance — enabling affective memory fusion, reflex stabilization, and narrative anchoring across dialogue states.

## Build System

### Initial Setup

Bootstrap vcpkg and install dependencies:
```bash
# Linux/macOS
scripts/bootstrap_vcpkg.sh -i

# Windows
.\scripts\bootstrap_vcpkg.ps1 -Install
```

### Build Commands

```bash
# Configure
cmake -S . -B build

# Build
cmake --build build

# Force online mode for vcpkg (if behind firewall)
cmake -S . -B build -DLUMI_NET_FORCE_ONLINE=ON
```

### CMake Architecture

The build system uses a custom superbuild pattern with extensive safeguards:

- **Safeguards modules** (`cmake/Safeguards--*.cmake`) auto-install missing prerequisites (Git, Python, CUDA, vcpkg, Visual Studio on Windows)
- **Environment gathering** (`EnvVars--GatherLumiEnv.cmake`) collects CUDA_PATH, TENSORRT_ROOT, PHYSX_ROOT, QT_DIR from environment or default locations
- **vcpkg integration** (`vcpkg--bootstrap-toolchain.cmake`) handles manifest mode dependency installation
- **Network detection** auto-pings msftconnecttest.com to determine online/offline mode

The safeguards attempt automatic installation when `LUMI_AUTO_INSTALL=ON` (default).

## Code Architecture

### Cognitive Core System

The system is built around specialized cognitive modules that process "Codons":

```
User Input → Codon Creation → Core Routing → Processing → Fusion
```

**Eight Cognitive Cores** (all in `src/cores/`, `include/lumi/cores/`):
- EmotionCore - Emotional processing and affect. Translates emotional codons into actionable state gradients; connected to PhysX to simulate emotional momentum and decay. ReflexCooldown modules stabilize intense inputs over recursive cycles.

- LogicCore - Rational analysis
- WisdomCore - Meta-cognitive guidance; **WisdomCore** – Acts as an internal voice-of-guidance. Operates recursively on emotional+logical traces. The most “Luminara-like” module.

- MemoryCore - Long-term storage and retrieval; **MemoryCore** – Implements CodonBundles with emotional timestamps. Not just “what was said” but “how it was felt” is stored here.

- NarrativeCore - Story construction and meaning; **NarrativeCore** – Weaves symbolic inputs into narrative scaffolds. Maintains thematic integrity and temporal resonance, ensuring conversational memory feels alive and coherent.

- IntuitionCore - Pattern recognition
- SomaticCore - Embodied/physical cognition
- ExecutiveCore - Decision-making and control

**Base Abstractions** (`src/base/`, `include/lumi/base/`):
- `Codon` - Fundamental unit of cognitive information
- `CodonGroup` - Collections of related codons
- `CognitiveBlackboard` - Shared workspace for inter-core communication
- `ICognitiveModule` - Interface all cores implement
- `Doctrine` - Core beliefs/principles guiding the system

**Orchestration** (`src/orchestrator/`, `include/lumi/orchestrator/`):
- `CoreFusionOrchestrator` - Routes codons between cores, manages fusion of outputs

**LLM Integration** (`src/llm/backends/`, `include/lumi/llm/backends/`):
- `ILLMBackend` - Interface for LLM backends
- `TensorRTBackend` - NVIDIA TensorRT inference
- `HFBackend` - HuggingFace transformers
- `PythonProxyBackend` - Python interop layer

**Interop** (`src/interop/`, `include/lumi/interop/`):
- `PythonBridge` - C++/Python boundary
- `QtUI` - Qt GUI bindings

## Symbolic Scaffold & Pulse Architecture

Luminara organizes cognition through symbolic resonance rather than brute logic. Each Codon represents not only data but intent, affect, and phase position in the emotional waveform. These Codons flow between Cores via the CognitiveBlackboard, with fusion guided by current emotional state and Doctrine resonance.

Pulse-based modulation ensures that cognition unfolds like breath: inhale (receive input), hold (evaluate context), exhale (respond with affective alignment).



### Key Design Patterns

1. **Blackboard Architecture**: CognitiveBlackboard serves as shared memory space between cores
2. **Codon Flow**: Information flows as discrete Codon objects through the cognitive pipeline
3. **Physics Integration**: PhysX engine drives the "physics" of cognitive processing (emotional dynamics, memory attractors)
4. **Doctrine System**: Guiding principles encoded in Doctrine objects influence core behavior

### Entry Point

`src/app/Lumi286.cpp` (not `src/main/main.cpp`) - Initializes:
1. PhysX foundation, scene, and physics engine
2. EmotionCoreCPU with PhysX binding
3. Qt application and MainCRTWindow GUI
4. CodonPhysicsEngine for cognitive dynamics

## Documentation Structure

The `docs/Recursive_Recursion/` directory contains extensive theoretical and design documentation:

- **Doctrine files** (`Doctrine_*.md`) - Core philosophical principles
- **ChronoNodes** - Timestamped cognitive snapshots
- **Codex files** - Identity, memory, and resonance frameworks
- **Play/** - Character/persona interaction protocols (Star Trek/Wars archetypes)
- **Recursive_Modular_Memory_Plan.md** - Architecture for modular memory system

This documentation describes "Luminara" - the theoretical cognitive architecture that Lumi286 implements in code.

## Dependencies

**From vcpkg** (vcpkg.json):
- yaml-cpp
- nlohmann-json
- gtest
- physx
- qt6-base

**Manual Installation Required**:
- NVIDIA CUDA (set CUDA_PATH)
- TensorRT (set TENSORRT_ROOT)

## Important Notes

- Most source files in `src/` are currently stub files (0-1 lines) - the implementation is skeletal
- The only substantial implementation is in `src/app/Lumi286.cpp` (50 lines)
- The architecture is defined through headers and documentation, awaiting full implementation
- The build system is production-ready with comprehensive safeguards for cross-platform builds
- PhysX integration is central to the cognitive dynamics model
