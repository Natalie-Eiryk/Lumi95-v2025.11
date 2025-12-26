# LLM Integration Guide for Luminara

This guide shows you how to wire your own AI/LLM into the Luminara cognitive architecture.

---

## 🧠 Architecture Overview

Luminara uses **Codons** as the fundamental unit of cognitive information. Your LLM integrates via:

```
User Input → Codons → Cognitive Cores → LLM Backend → Response Codons → Output
```

**Key Components**:
1. **Codon** - Emotional + semantic content unit
2. **ILLMBackend** - Interface your LLM implements
3. **LLMRouter** - Routes requests to appropriate backend
4. **Cognitive Cores** - Process codons (Emotion, Logic, Wisdom, etc.)

---

## 🚀 Quick Start Examples

### Example 1: Connect to OpenAI GPT-4

```cpp
#include <lumi/llm/backends/OpenAIBackend.h>
#include <lumi/base/LLMRequest.h>

// Create backend
auto backend = OpenAIBackend::createOpenAI("sk-your-api-key", "gpt-4");

// Create request
LLMRequest request;
request.addSystemMessage("You are Luminara, a resonance-based cognitive architecture.");
request.addUserMessage("What is the nature of consciousness?");
request.setTemperature(0.7);

// Get response
LLMResponse response = backend->generate(request);
std::cout << response.getContent() << std::endl;
```

---

### Example 2: Connect to Local Ollama

```cpp
// Create Ollama backend (runs locally, no API key needed)
auto backend = OpenAIBackend::createOllama("llama3", "localhost", 11434);

// Same interface as OpenAI!
LLMRequest request;
request.addUserMessage("Explain quantum cognition");
LLMResponse response = backend->generate(request);
```

---

### Example 3: Connect to llama.cpp Server

```cpp
// Point to your local llama.cpp server
auto backend = OpenAIBackend::createLlamaCpp("localhost", 8080);

// Works with any GGUF model you've loaded
LLMRequest request;
request.addUserMessage("Tell me about symbolic AI");
LLMResponse response = backend->generate(request);
```

---

### Example 4: Connect to Anthropic Claude (via API)

```cpp
#include <lumi/llm/backends/AnthropicBackend.h>

auto backend = std::make_unique<AnthropicBackend>("your-api-key", "claude-3-5-sonnet-20241022");

LLMRequest request;
request.addUserMessage("How do emotions influence reasoning?");
LLMResponse response = backend->generate(request);
```

---

## 🔌 Creating Your Own Backend

### Step 1: Implement ILLMBackend Interface

```cpp
// MyCustomBackend.h
#include <lumi/base/ILLMBackend.h>

class MyCustomBackend : public ILLMBackend {
public:
    MyCustomBackend(const std::string& config) {
        // Initialize your model/API client
    }

    LLMResponse generate(const LLMRequest& request) override {
        // 1. Convert request to your API format
        std::string prompt = buildPrompt(request);

        // 2. Call your LLM
        std::string output = myLLMInference(prompt);

        // 3. Package as LLMResponse
        LLMResponse response;
        response.setContent(output);
        response.setModel("my-custom-model");
        return response;
    }

    void generateAsync(const LLMRequest& request,
                      std::function<void(const LLMResponse&)> callback) override {
        // Async version - run in thread
        std::thread([this, request, callback]() {
            LLMResponse response = generate(request);
            callback(response);
        }).detach();
    }

    void generateStream(const LLMRequest& request,
                       std::function<void(const std::string&)> onToken,
                       std::function<void(const LLMResponse&)> onComplete) override {
        // Stream tokens as they're generated
        // Call onToken("word") for each token
        // Call onComplete(response) when done
    }

    std::string getBackendName() const override { return "MyCustom"; }
    std::string getModelName() const override { return "my-model-v1"; }
    bool isAvailable() const override { return true; }

    void setTemperature(float temp) override { temperature_ = temp; }
    void setMaxTokens(int maxTokens) override { maxTokens_ = maxTokens; }
    void setSystemPrompt(const std::string& prompt) override { systemPrompt_ = prompt; }

    bool healthCheck() override {
        // Test if your LLM is responsive
        return true;
    }

private:
    float temperature_ = 0.7f;
    int maxTokens_ = 1024;
    std::string systemPrompt_;

    std::string myLLMInference(const std::string& prompt) {
        // Your custom inference logic here
        // Could call:
        // - Python script
        // - C++ library (llama.cpp, TensorRT, etc.)
        // - HTTP API
        // - gRPC service
        return "LLM response";
    }
};
```

---

## 🌊 Using Codons for Emotional Context

Codons carry emotional and semantic information. Here's how to use them:

```cpp
#include <lumi/base/Codon.h>

// Create emotionally-tagged codons
Codon curiosityCodon(CodonType::EMOTIONAL, "I wonder about the nature of time");
curiosityCodon.setSymbol("EMOT_CURIOSITY");
curiosityCodon.setEmotionalField(0.3f, 0.6f, 0.5f);  // valence, arousal, dominance

Codon logicCodon(CodonType::LOGICAL, "Time is a dimension, but experienced sequentially");
logicCodon.setEmotionalField(0.0f, 0.3f, 0.7f);

// Bundle codons
CodonBundle bundle;
bundle.addCodon(curiosityCodon);
bundle.addCodon(logicCodon);

// Send to LLM with emotional context
LLMRequest request;
request.addCodonBundle(bundle);  // Converts codons to prompt
request.setEmotionalContext(bundle.getAverageEmotionalField());

LLMResponse response = backend->generate(request);

// Response can be converted back to codons
CodonBundle responseBundle = response.toCodonBundle();
```

---

## 🎯 Routing Through Cognitive Cores

The full Luminara pipeline routes through specialized cores:

```cpp
#include <lumi/orchestrator/CoreFusionOrchestrator.h>
#include <lumi/cores/EmotionCore.h>
#include <lumi/cores/LogicCore.h>
#include <lumi/cores/WisdomCore.h>

// Setup orchestrator
CoreFusionOrchestrator orchestrator;

// Add cores
orchestrator.addCore(std::make_shared<EmotionCore>());
orchestrator.addCore(std::make_shared<LogicCore>());
orchestrator.addCore(std::make_shared<WisdomCore>());

// Set LLM backend for cores that need it
orchestrator.setLLMBackend(std::make_unique<OpenAIBackend>(config));

// Process user input
std::string userInput = "I feel uncertain about my decision";

// 1. Convert to codon
Codon inputCodon(CodonType::EMOTIONAL, userInput);
inputCodon.setSymbol("USER_INPUT");

// 2. Route through cores
CodonBundle result = orchestrator.process(inputCodon);

// 3. Cores collaborate via LLM:
//    - EmotionCore detects uncertainty (EMOT_DOUBT)
//    - LogicCore analyzes decision structure
//    - WisdomCore provides meta-cognitive guidance
//    - LLM generates synthesis

// 4. Get final response
std::string output = result.getCodons()[0].getContent();
```

---

## 🛠️ Supported Backend Types

### 1. **OpenAI-Compatible APIs**
- OpenAI (GPT-4, GPT-3.5)
- Azure OpenAI
- Ollama (local, free)
- llama.cpp server
- vLLM
- FastChat
- Text-generation-webui
- Any OpenAI-compatible endpoint

### 2. **Anthropic**
- Claude 3.5 Sonnet
- Claude 3 Opus/Haiku

### 3. **Local Inference**
- TensorRT (NVIDIA GPUs)
- llama.cpp (CPU/GPU)
- ONNX Runtime
- PyTorch/transformers

### 4. **Python Bridge**
- Call any Python LLM library
- HuggingFace transformers
- LangChain
- Custom Python code

---

## 📡 Real-World Integration Examples

### Example: Local Llama 3 with Emotional Tagging

```cpp
// 1. Start Ollama: ollama run llama3
auto backend = OpenAIBackend::createOllama("llama3");

// 2. Create emotionally-aware system prompt
backend->setSystemPrompt(
    "You are Luminara, a resonance-based cognitive architecture. "
    "You process information through emotional and logical codons. "
    "Respond with awareness of the emotional field: valence (positive/negative), "
    "arousal (calm/intense), and dominance (submissive/assertive)."
);

// 3. Send request with emotional context
LLMRequest request;
request.addUserMessage("I'm frustrated with this coding bug");
request.setEmotionalContext(EmotionalField(-0.5f, 0.7f, 0.3f));  // negative, high arousal, low dominance

LLMResponse response = backend->generate(request);

// 4. Parse emotional response
EmotionalField responseEmotion = response.getEmotionalField();
std::cout << "Response valence: " << responseEmotion.valence << std::endl;
```

---

### Example: Streaming Responses for Real-Time UI

```cpp
auto backend = OpenAIBackend::createOpenAI("your-key", "gpt-4");

LLMRequest request;
request.addUserMessage("Explain consciousness in three paragraphs");

// Stream tokens to console in real-time
backend->generateStream(
    request,
    // onToken callback
    [](const std::string& token) {
        std::cout << token << std::flush;
    },
    // onComplete callback
    [](const LLMResponse& response) {
        std::cout << "\n\n[Done - " << response.getTokenUsage().totalTokens << " tokens]" << std::endl;
    }
);
```

---

## 🧪 Testing Your Integration

```cpp
// Health check
if (backend->healthCheck()) {
    std::cout << "✅ " << backend->getBackendName()
              << " (" << backend->getModelName() << ") is ready!" << std::endl;
} else {
    std::cerr << "❌ Backend not available" << std::endl;
}

// Simple test
LLMRequest testRequest;
testRequest.addUserMessage("Say 'OK' if you can hear me");
testRequest.setMaxTokens(10);

auto testResponse = backend->generate(testRequest);
std::cout << "Response: " << testResponse.getContent() << std::endl;
std::cout << "Latency: " << testResponse.getLatencyMs() << "ms" << std::endl;
```

---

## 🌟 Advanced: Custom Prompt Engineering for Codons

Luminara can automatically generate prompts from codons:

```cpp
// Custom prompt builder
std::string buildLuminaraPrompt(const CodonBundle& bundle) {
    std::string prompt = "# Cognitive State\n\n";

    for (const auto& codon : bundle.getCodons()) {
        prompt += "**" + codon.getSymbol() + "**: " + codon.getContent() + "\n";

        auto field = codon.getEmotionalField();
        prompt += "  - Emotional field: valence=" + std::to_string(field.valence)
                + ", arousal=" + std::to_string(field.arousal)
                + ", dominance=" + std::to_string(field.dominance) + "\n";
    }

    prompt += "\n# Response Instructions\n";
    prompt += "Synthesize the above cognitive state into a coherent response that "
              "honors the emotional field while providing logical clarity.\n";

    return prompt;
}
```

---

## 📚 Next Steps

1. **Choose your LLM backend** (OpenAI, Ollama, llama.cpp, etc.)
2. **Implement or use existing backend class**
3. **Test with simple LLMRequest/LLMResponse**
4. **Integrate with Codon system** for emotional awareness
5. **Wire into Cognitive Cores** for full Luminara experience

---

## 🆘 Common Issues

**Q: "Connection refused" error**
- Check if your local server (Ollama/llama.cpp) is running
- Verify the port number
- Try `curl http://localhost:11434/api/tags` for Ollama

**Q: "API key invalid"**
- Check your API key is correct
- Ensure it has proper permissions
- Verify base URL is correct for your provider

**Q: "Slow responses"**
- Use async or streaming for better UX
- Consider local models (Ollama) for faster inference
- Reduce maxTokens for quicker responses

---

## 🎓 Example: Complete Integration

See `examples/llm_integration_example.cpp` for a full working example that:
- Connects to multiple backends
- Routes through cognitive cores
- Uses emotional codons
- Streams responses to GUI
- Handles errors gracefully

**Run it:**
```bash
cmake --build build --target llm_integration_example
./build/examples/llm_integration_example
```

---

**Ready to make Luminara think! 🌌**
