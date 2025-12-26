// OpenAIBackend.h - OpenAI-compatible LLM backend
// Works with: OpenAI API, Azure OpenAI, Ollama, llama.cpp server, vLLM, etc.
#pragma once

#include <lumi/base/ILLMBackend.h>
#include <lumi/base/LLMRequest.h>
#include <lumi/base/LLMResponse.h>
#include <string>
#include <memory>

namespace lumi {

// Configuration for OpenAI-compatible backends
struct OpenAIConfig {
    std::string apiKey;           // API key (can be empty for local servers)
    std::string baseUrl;          // Base URL (e.g., "https://api.openai.com/v1")
    std::string model;            // Model name (e.g., "gpt-4", "llama3", etc.)
    std::string organization;     // Optional organization ID
    int timeoutSeconds = 60;      // Request timeout
    bool verifySSL = true;        // SSL verification

    OpenAIConfig() = default;
    OpenAIConfig(const std::string& key, const std::string& url, const std::string& mdl)
        : apiKey(key), baseUrl(url), model(mdl) {}
};

class OpenAIBackend : public ILLMBackend {
public:
    explicit OpenAIBackend(const OpenAIConfig& config);
    virtual ~OpenAIBackend() = default;

    // Factory methods for common configurations
    static std::unique_ptr<OpenAIBackend> createOpenAI(const std::string& apiKey, const std::string& model = "gpt-4");
    static std::unique_ptr<OpenAIBackend> createOllama(const std::string& model = "llama3", const std::string& host = "localhost", int port = 11434);
    static std::unique_ptr<OpenAIBackend> createLlamaCpp(const std::string& host = "localhost", int port = 8080);
    static std::unique_ptr<OpenAIBackend> createAzureOpenAI(const std::string& apiKey, const std::string& endpoint, const std::string& deployment);

    // ILLMBackend interface
    LLMResponse generate(const LLMRequest& request) override;
    void generateAsync(const LLMRequest& request, std::function<void(const LLMResponse&)> callback) override;
    void generateStream(const LLMRequest& request,
                       std::function<void(const std::string& token)> onToken,
                       std::function<void(const LLMResponse&)> onComplete) override;

    std::string getBackendName() const override { return "OpenAI-Compatible"; }
    std::string getModelName() const override { return config_.model; }
    bool isAvailable() const override;

    void setTemperature(float temp) override { temperature_ = temp; }
    void setMaxTokens(int maxTokens) override { maxTokens_ = maxTokens; }
    void setSystemPrompt(const std::string& prompt) override { systemPrompt_ = prompt; }

    bool healthCheck() override;

private:
    // HTTP request helper
    std::string makeHttpRequest(const std::string& endpoint, const std::string& jsonBody, bool streaming = false);
    LLMResponse parseResponse(const std::string& jsonResponse);

    OpenAIConfig config_;
    float temperature_ = 0.7f;
    int maxTokens_ = 1024;
    std::string systemPrompt_;
};

} // namespace lumi
