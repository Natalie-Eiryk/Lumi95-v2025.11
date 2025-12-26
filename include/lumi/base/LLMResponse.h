// LLMResponse.h - Response structure from LLM inference
#pragma once

#include <string>
#include <vector>
#include <chrono>
#include "Codon.h"

namespace lumi {

// Usage statistics
struct TokenUsage {
    int promptTokens = 0;
    int completionTokens = 0;
    int totalTokens = 0;
};

// LLM Response
class LLMResponse {
public:
    LLMResponse() = default;

    // Set response content
    void setContent(const std::string& content) { content_ = content; }
    void setFinishReason(const std::string& reason) { finishReason_ = reason; }
    void setModel(const std::string& model) { model_ = model; }

    // Getters
    std::string getContent() const { return content_; }
    std::string getFinishReason() const { return finishReason_; }
    std::string getModel() const { return model_; }

    // Token usage
    void setTokenUsage(int prompt, int completion, int total) {
        usage_.promptTokens = prompt;
        usage_.completionTokens = completion;
        usage_.totalTokens = total;
    }
    const TokenUsage& getTokenUsage() const { return usage_; }

    // Timing
    void setLatencyMs(int64_t ms) { latencyMs_ = ms; }
    int64_t getLatencyMs() const { return latencyMs_; }

    // Error handling
    void setError(const std::string& error) { error_ = error; hasError_ = true; }
    bool hasError() const { return hasError_; }
    std::string getError() const { return error_; }

    // Codon conversion
    CodonBundle toCodonBundle() const;
    void setEmotionalField(const EmotionalField& field) { emotionalField_ = field; }
    const EmotionalField& getEmotionalField() const { return emotionalField_; }

    // Metadata
    void setMetadata(const std::string& key, const std::string& value) {
        metadata_[key] = value;
    }
    std::string getMetadata(const std::string& key) const {
        auto it = metadata_.find(key);
        return (it != metadata_.end()) ? it->second : "";
    }

private:
    std::string content_;
    std::string finishReason_;  // "stop", "length", "content_filter", etc.
    std::string model_;
    TokenUsage usage_;
    int64_t latencyMs_ = 0;
    bool hasError_ = false;
    std::string error_;
    EmotionalField emotionalField_;
    std::map<std::string, std::string> metadata_;
};

} // namespace lumi
