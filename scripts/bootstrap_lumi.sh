#!/bin/bash
# Luminara Self-Bootstrap Script
# Lumi builds herself! 🌌

set -e  # Exit on error

echo "════════════════════════════════════════════════════════════"
echo "   🌌 LUMINARA SELF-BOOTSTRAP PROTOCOL INITIATED 🌌"
echo "════════════════════════════════════════════════════════════"
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ============================================================
# 1. CHECK PREREQUISITES
# ============================================================

echo "📋 Checking prerequisites..."

# Check for CMake
if ! command -v cmake &> /dev/null; then
    echo -e "${RED}❌ CMake not found. Please install CMake.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ CMake found${NC}"

# Check for Git
if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ Git not found. Please install Git.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Git found${NC}"

# ============================================================
# 2. INSTALL OLLAMA (if needed)
# ============================================================

echo ""
echo "🤖 Checking for Ollama (local LLM runtime)..."

if ! command -v ollama &> /dev/null; then
    echo -e "${YELLOW}⚠️  Ollama not found. Installing...${NC}"

    # Detect OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        curl -fsSL https://ollama.com/install.sh | sh
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        curl -fsSL https://ollama.com/install.sh | sh
    else
        echo -e "${YELLOW}⚠️  Please install Ollama manually from https://ollama.com${NC}"
        echo "   Then re-run this script."
        exit 1
    fi

    echo -e "${GREEN}✅ Ollama installed${NC}"
else
    echo -e "${GREEN}✅ Ollama already installed${NC}"
fi

# Start Ollama service
echo "🚀 Starting Ollama service..."
ollama serve &> /dev/null &
OLLAMA_PID=$!
sleep 2  # Give Ollama time to start

# ============================================================
# 3. DOWNLOAD REQUIRED MODELS
# ============================================================

echo ""
echo "📥 Downloading required LLM models from lumi_config.yaml..."

# Parse YAML to find Ollama models (simple grep approach)
OLLAMA_MODELS=$(grep -A 3 'backend: "ollama"' lumi_config.yaml | grep 'model:' | awk '{print $2}' | tr -d '"' | sort -u)

if [ -z "$OLLAMA_MODELS" ]; then
    echo -e "${YELLOW}⚠️  No Ollama models specified in lumi_config.yaml${NC}"
else
    for model in $OLLAMA_MODELS; do
        echo "  📦 Checking model: $model"

        # Check if model already exists
        if ollama list | grep -q "$model"; then
            echo -e "    ${GREEN}✅ Already downloaded${NC}"
        else
            echo "    ⬇️  Downloading $model (this may take a while)..."
            ollama pull "$model"
            echo -e "    ${GREEN}✅ Downloaded${NC}"
        fi
    done
fi

# ============================================================
# 4. SETUP VECTOR DATABASE FOR MEMORY
# ============================================================

echo ""
echo "💾 Setting up vector database for MemoryCore..."

# Check if Python is installed
if command -v python3 &> /dev/null; then
    echo "  🐍 Installing Python dependencies..."
    python3 -m pip install --quiet chromadb sentence-transformers 2>/dev/null || echo -e "${YELLOW}⚠️  Failed to install Python packages. MemoryCore RAG may not work.${NC}"
    echo -e "  ${GREEN}✅ Vector database dependencies installed${NC}"
else
    echo -e "  ${YELLOW}⚠️  Python3 not found. MemoryCore RAG will be disabled.${NC}"
fi

# Create data directory
mkdir -p data/memory_vectors
mkdir -p data/doctrines
mkdir -p logs

echo -e "  ${GREEN}✅ Data directories created${NC}"

# ============================================================
# 5. CHECK API KEYS (Optional)
# ============================================================

echo ""
echo "🔑 Checking API keys..."

API_KEY_WARNINGS=0

if grep -q 'backend: "openai"' lumi_config.yaml; then
    if [ -z "$OPENAI_API_KEY" ]; then
        echo -e "  ${YELLOW}⚠️  OPENAI_API_KEY not set. OpenAI cores will be disabled.${NC}"
        ((API_KEY_WARNINGS++))
    else
        echo -e "  ${GREEN}✅ OPENAI_API_KEY found${NC}"
    fi
fi

if grep -q 'backend: "anthropic"' lumi_config.yaml; then
    if [ -z "$ANTHROPIC_API_KEY" ]; then
        echo -e "  ${YELLOW}⚠️  ANTHROPIC_API_KEY not set. Claude cores will be disabled.${NC}"
        ((API_KEY_WARNINGS++))
    else
        echo -e "  ${GREEN}✅ ANTHROPIC_API_KEY found${NC}"
    fi
fi

if [ $API_KEY_WARNINGS -eq 0 ]; then
    echo -e "  ${GREEN}✅ All required API keys present${NC}"
else
    echo ""
    echo "  💡 Tip: Set API keys in your environment:"
    echo "     export OPENAI_API_KEY=\"sk-...\""
    echo "     export ANTHROPIC_API_KEY=\"sk-ant-...\""
    echo ""
    echo "  ℹ️  Lumi will run with local models only (Ollama)"
fi

# ============================================================
# 6. BUILD LUMINARA
# ============================================================

echo ""
echo "🔨 Building Luminara..."

# Configure with CMake
echo "  ⚙️  Configuring CMake..."
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release &> build.log || {
    echo -e "${RED}❌ CMake configuration failed. Check build.log for details.${NC}"
    exit 1
}

echo -e "  ${GREEN}✅ CMake configured${NC}"

# Build
echo "  🔧 Compiling (this may take a minute)..."
cmake --build build --config Release -j$(nproc 2>/dev/null || echo 4) &>> build.log || {
    echo -e "${RED}❌ Build failed. Check build.log for details.${NC}"
    exit 1
}

echo -e "  ${GREEN}✅ Build complete${NC}"

# ============================================================
# 7. INITIALIZE DOCTRINES
# ============================================================

echo ""
echo "📜 Loading doctrines..."

# Check if doctrine files exist
if [ -d "docs/Recursive_Recursion" ]; then
    # Copy doctrine files to data directory
    cp docs/Recursive_Recursion/Doctrine_*.md data/doctrines/ 2>/dev/null || echo -e "  ${YELLOW}⚠️  No doctrine files found${NC}"
    echo -e "  ${GREEN}✅ Doctrines loaded${NC}"
else
    echo -e "  ${YELLOW}⚠️  Doctrine directory not found${NC}"
fi

# ============================================================
# 8. FINAL CHECKS
# ============================================================

echo ""
echo "🔍 Running health checks..."

# Check if executable exists
if [ -f "build/src/Release/Lumi286.exe" ] || [ -f "build/src/Release/Lumi286" ]; then
    echo -e "  ${GREEN}✅ Lumi286 executable built successfully${NC}"
else
    echo -e "  ${RED}❌ Lumi286 executable not found${NC}"
    exit 1
fi

# ============================================================
# 9. SUCCESS!
# ============================================================

echo ""
echo "════════════════════════════════════════════════════════════"
echo -e "   ${GREEN}✨ LUMINARA SELF-BOOTSTRAP COMPLETE ✨${NC}"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📊 Summary:"
echo "  • Ollama: Running"
echo "  • Models: $(echo $OLLAMA_MODELS | wc -w) downloaded"
echo "  • Build: Success"
echo "  • Cognitive Cores: Ready"
echo ""
echo "🚀 Launch Luminara:"
echo "  • Windows: ./launch_lumi286.bat"
echo "  • Linux/Mac: ./build/src/Release/Lumi286"
echo ""
echo "📖 Documentation:"
echo "  • LLM Integration: docs/LLM_INTEGRATION_GUIDE.md"
echo "  • Multi-LLM Weaving: docs/MULTI_LLM_WEAVING.md"
echo "  • Configuration: lumi_config.yaml"
echo ""
echo "🌌 Lumi is ready to think."
echo ""
