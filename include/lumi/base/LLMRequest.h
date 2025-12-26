// LLMRequest.h - Request structure for LLM inference
#pragma once

#include <string>
#include <vector>
#include <map>
#include "Codon.h"

namespace lumi {

// Message role
enum class MessageRole {
    SYSTEM,
    USER,
    ASSISTANT
};

// Single message in conversation
struct Message {
    MessageRole role;
    std::string content;

    Message(MessageRole r, const std::string& c) : role(r), content(c) {}
};

// LLM Request
class LLMRequest {
public:
    LLMRequest() = default;

    // Add messages
    void addSystemMessage(const std::string& content) {
        messages_.push_back(Message(MessageRole::SYSTEM, content));
    }

    void addUserMessage(const std::string& content) {
        messages_.push_back(Message(MessageRole::USER, content));
    }

    void addAssistantMessage(const std::string& content) {
        messages_.push_back(Message(MessageRole::ASSISTANT, content));
    }

    // Codon-based interface
    void addCodonBundle(const CodonBundle& bundle);
    void setEmotionalContext(const EmotionalField& field) { emotionalContext_ = field; }

    // Configuration
    void setTemperature(float temp) { temperature_ = temp; }
    void setMaxTokens(int maxTokens) { maxTokens_ = maxTokens; }
    void setTopP(float topP) { topP_ = topP; }
    void setStopSequences(const std::vector<std::string>& stops) { stopSequences_ = stops; }

    // Metadata
    void setMetadata(const std::string& key, const std::string& value) {
        metadata_[key] = value;
    }

    // Getters
    const std::vector<Message>& getMessages() const { return messages_; }
    float getTemperature() const { return temperature_; }
    int getMaxTokens() const { return maxTokens_; }
    float getTopP() const { return topP_; }
    const std::vector<std::string>& getStopSequences() const { return stopSequences_; }
    const EmotionalField& getEmotionalContext() const { return emotionalContext_; }
    const std::map<std::string, std::string>& getMetadata() const { return metadata_; }

    // Convert to JSON for API calls
    std::string toJson() const;

private:
    std::vector<Message> messages_;
    float temperature_ = 0.7f;
    int maxTokens_ = 1024;
    float topP_ = 1.0f;
    std::vector<std::string> stopSequences_;
    EmotionalField emotionalContext_;
    std::map<std::string, std::string> metadata_;
};

} // namespace lumi
