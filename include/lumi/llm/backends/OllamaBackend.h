// OllamaBackend.h - Ollama local LLM backend (FREE!)
// Ollama runs models locally - no API costs, full privacy
#pragma once

#include <lumi/base/ILLMBackend.h>
#include <lumi/base/LLMRequest.h>
#include <lumi/base/LLMResponse.h>
#include <string>

namespace lumi {

// Ollama backend - connects to local Ollama server
class OllamaBackend : public ILLMBackend {
public:
    // Constructor
    OllamaBackend(
        const std::string& model = "llama3.2",
        const std::string& host = "http://localhost",
        int port = 11434
    );

    ~OllamaBackend() override = default;

    // Synchronous inference
    LLMResponse generate(const LLMRequest& request) override;

    // Async inference
    void generateAsync(
        const LLMRequest& request,
        std::function<void(const LLMResponse&)> callback
    ) override;

    // Stream generation
    void generateStream(
        const LLMRequest& request,
        std::function<void(const std::string& token)> onToken,
        std::function<void(const LLMResponse&)> onComplete
    ) override;

    // Backend information
    std::string getBackendName() const override { return "Ollama"; }
    std::string getModelName() const override { return model_; }
    bool isAvailable() const override;

    // Configuration
    void setTemperature(float temp) override { temperature_ = temp; }
    void setMaxTokens(int maxTokens) override { maxTokens_ = maxTokens; }
    void setSystemPrompt(const std::string& prompt) override { systemPrompt_ = prompt; }

    // Health check
    bool healthCheck() override;

    // Ollama-specific
    void setModel(const std::string& model) { model_ = model; }
    std::string getEndpoint() const { return endpoint_; }

    // Helper: Pull model if not available
    bool pullModel();

    // Helper: List available models
    std::vector<std::string> listModels();

private:
    std::string buildRequestJson(const LLMRequest& request);
    LLMResponse parseResponseJson(const std::string& json);
    std::string httpPost(const std::string& url, const std::string& data);

    std::string model_;
    std::string host_;
    int port_;
    std::string endpoint_;
    float temperature_;
    int maxTokens_;
    std::string systemPrompt_;
};

// Factory function
inline std::unique_ptr<OllamaBackend> createOllama(
    const std::string& model = "llama3.2",
    const std::string& host = "http://localhost",
    int port = 11434
) {
    return std::make_unique<OllamaBackend>(model, host, port);
}

} // namespace lumi
