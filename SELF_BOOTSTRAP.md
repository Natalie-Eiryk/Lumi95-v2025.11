# Lumi95 - Self-Bootstrapping System

## One Command Setup

```bash
# Clone and build - everything auto-installs!
git clone https://github.com/yourusername/Lumi95
cd Lumi95
cmake -S . -B build
cmake --build build --config Debug --target ollama_pipeline_example
```

That's it! No manual steps required.

## What Happens Automatically

### During CMake Configure

The CMake safeguards system automatically detects and installs:

1. **✅ Git** - Version control
2. **✅ Python** - For build scripts (creates venv, installs requirements)
3. **✅ CUDA** - GPU acceleration (if NVIDIA GPU detected)
4. **✅ vcpkg** - Package manager (clones, bootstraps, installs manifest)
5. **✅ Qt6** - GUI framework (via vcpkg)
6. **✅ yaml-cpp, nlohmann-json, gtest** - Dependencies (via vcpkg)
7. **✅ Ollama** - Local LLM runtime (**NEW!**)

### During Ollama Setup

If Ollama is missing, CMake will:

**Windows:**
- Download OllamaSetup.exe
- Run silent installer
- Verify installation

**Mac:**
- Use Homebrew (`brew install ollama`)
- Start service

**Linux:**
- Run official install script
- Configure systemd service

### During Build (ollama_pipeline_example)

When building the Ollama example, CMake will:

1. **Check if Ollama is running** - Start service if needed
2. **Pull llama3.2 model** - Auto-download if missing (~2GB)
3. **Verify connectivity** - Ensure http://localhost:11434 responds
4. **Build executable** - Compile with all dependencies linked

## Self-Healing

If something breaks:

```bash
# Reconfigure (re-runs all checks and installs)
cmake -S . -B build

# Clean rebuild
rm -rf build
cmake -S . -B build
cmake --build build
```

CMake will re-detect what's missing and reinstall.

## Controlling Auto-Install

By default, auto-install is **ON**. To disable:

```bash
cmake -DLUMI_AUTO_INSTALL=OFF -S . -B build
```

This makes CMake warn about missing dependencies instead of installing them.

## Architecture Files

The self-bootstrap system consists of:

### Core Safeguards
- `cmake/Safeguards--Entry.cmake` - Main coordinator
- `cmake/Safeguards--Core.cmake` - Helper functions
- `cmake/Safeguards--EnsureGit.cmake` - Git detection/install
- `cmake/Safeguards--EnsurePython.cmake` - Python setup
- `cmake/Safeguards--EnsureVS.cmake` - Visual Studio (Windows)
- `cmake/Safeguards--EnsureVcpkg.cmake` - Package manager
- `cmake/Safeguards--EnsureOllama.cmake` - **LLM runtime** ⭐

### Configuration
- `vcpkg.json` - Manifest of required packages
- `CMakeLists.txt` - Root build file with safeguard calls
- `src/CMakeLists.txt` - Source tree with Ollama integration

## What You Get

After the automated setup:

```
build/
  src/
    Debug/
      Lumi286.exe                    # Main GUI application
      test_attractor_physics.exe     # Physics simulation test
      full_pipeline_example.exe      # Mock LLM pipeline
      ollama_pipeline_example.exe    # REAL LLM pipeline ⭐
```

## Testing the Full Pipeline

```bash
# Run with real Ollama LLM (fully automated)
./build/src/Debug/ollama_pipeline_example.exe
```

Output:
```
================================================================
  LUMINARA + OLLAMA PIPELINE
  Real Physics-Guided LLM Responses (FREE!)
================================================================

[1] Connecting to Ollama...
    ✓ Ollama running at http://localhost:11434
    ✓ Model: llama3.2

[2] Initializing attractor landscape...
    ✓ 8 cognitive attractors ready

[3-7] Running physics simulation...
    [Physics collapse details]

[8] Generating response with Ollama...
    (This may take 5-30 seconds)

================================================================
  LUMINARA'S RESPONSE (Physics-Guided via Ollama)
================================================================

[Actual LLM response guided by physics]

================================================================
```

## Performance Notes

**First build:**
- Ollama installer: ~2 minutes (Windows)
- llama3.2 model pull: ~3-5 minutes (2GB download)
- vcpkg dependencies: ~5-10 minutes (first time only)
- **Total: ~10-15 minutes** for completely fresh setup

**Subsequent builds:**
- Everything cached
- **Total: ~30 seconds** for incremental builds

## Requirements

Minimum:
- **Internet connection** (for downloads)
- **4GB RAM** (8GB recommended for llama3.2)
- **10GB disk space** (for Qt6, vcpkg, Ollama, models)
- **Windows 10+, macOS 10.15+, or Ubuntu 20.04+**

Recommended:
- **16GB RAM** (for larger models like llama3.1)
- **NVIDIA GPU** (for CUDA acceleration, but CPU works)
- **SSD** (for faster builds)

## Troubleshooting

**"Ollama not available"**
```bash
# Manually install
# Windows: https://ollama.com/download/OllamaSetup.exe
# Mac: brew install ollama
# Linux: curl https://ollama.com/install.sh | sh

# Then reconfigure
cmake -S . -B build
```

**Model download fails**
```bash
# Pull manually
ollama pull llama3.2

# Verify
ollama list
```

**Build fails**
```bash
# Clean and retry
rm -rf build
cmake -S . -B build
cmake --build build --target ollama_pipeline_example
```

## Advanced: Custom Models

To use a different Ollama model:

1. Pull the model:
   ```bash
   ollama pull mistral
   ```

2. Edit `examples/ollama_pipeline_example.cpp`:
   ```cpp
   // Line ~120
   auto ollama = createOllama("mistral", "http://localhost", 11434);
   ```

3. Edit `src/CMakeLists.txt`:
   ```cmake
   # Line ~286
   lumi_sg_ensure_ollama_model("mistral")
   ```

4. Rebuild:
   ```bash
   cmake --build build --target ollama_pipeline_example
   ```

## Philosophy

**"Just git clone and build"**

The entire system is designed to work out-of-the-box with zero configuration:

- No environment variables to set
- No manual downloads
- No configuration files to edit
- No "install X before Y" steps

CMake handles everything. This is how all software should work.

---

**Questions?** Open an issue at https://github.com/yourusername/Lumi95/issues
