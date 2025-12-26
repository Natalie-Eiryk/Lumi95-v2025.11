// OllamaBackend.cpp - Ollama implementation with simple HTTP client
#include <lumi/llm/backends/OllamaBackend.h>
#include <sstream>
#include <iostream>

// Simple HTTP client using Windows WinHTTP or cross-platform fallback
#ifdef _WIN32
#include <windows.h>
#include <winhttp.h>
#pragma comment(lib, "winhttp.lib")
#else
// For Linux/Mac, would use libcurl
#include <curl/curl.h>
#endif

namespace lumi {

OllamaBackend::OllamaBackend(const std::string& model, const std::string& host, int port)
    : model_(model)
    , host_(host)
    , port_(port)
    , temperature_(0.7f)
    , maxTokens_(2048)
    , systemPrompt_("You are a helpful AI assistant.")
{
    endpoint_ = host_ + ":" + std::to_string(port_);
}

LLMResponse OllamaBackend::generate(const LLMRequest& request) {
    LLMResponse response;

    try {
        // Build request JSON
        std::string requestJson = buildRequestJson(request);

        // Make HTTP POST to Ollama API
        std::string url = endpoint_ + "/api/generate";
        std::string responseJson = httpPost(url, requestJson);

        // Parse response
        response = parseResponseJson(responseJson);
        response.setModel(model_);

    } catch (const std::exception& e) {
        response.setError(std::string("Ollama error: ") + e.what());
    }

    return response;
}

void OllamaBackend::generateAsync(
    const LLMRequest& request,
    std::function<void(const LLMResponse&)> callback
) {
    // Simplified: just call synchronous version
    // In production, would use async HTTP client
    LLMResponse response = generate(request);
    if (callback) {
        callback(response);
    }
}

void OllamaBackend::generateStream(
    const LLMRequest& request,
    std::function<void(const std::string& token)> onToken,
    std::function<void(const LLMResponse&)> onComplete
) {
    // Simplified: generate and stream word by word
    LLMResponse response = generate(request);

    if (onToken && !response.hasError()) {
        std::istringstream iss(response.getContent());
        std::string word;
        while (iss >> word) {
            onToken(word + " ");
        }
    }

    if (onComplete) {
        onComplete(response);
    }
}

bool OllamaBackend::isAvailable() const {
    // Check if Ollama is running
    // Note: Can't use httpPost here since it's not const
    // In production, would have separate const-safe health check
    return true;  // Assume available for now
}

bool OllamaBackend::healthCheck() {
    return isAvailable();
}

bool OllamaBackend::pullModel() {
    try {
        // Request to pull model
        std::string url = endpoint_ + "/api/pull";
        std::string data = "{\"name\":\"" + model_ + "\"}";
        std::string response = httpPost(url, data);
        return !response.empty();
    } catch (...) {
        return false;
    }
}

std::vector<std::string> OllamaBackend::listModels() {
    std::vector<std::string> models;
    try {
        std::string url = endpoint_ + "/api/tags";
        std::string response = httpPost(url, "");
        // Parse JSON response (simplified - in production use JSON library)
        // For now, just return empty
    } catch (...) {
    }
    return models;
}

std::string OllamaBackend::buildRequestJson(const LLMRequest& request) {
    std::ostringstream json;
    json << "{";
    json << "\"model\":\"" << model_ << "\",";
    json << "\"prompt\":\"";

    // Combine all messages into prompt
    for (const auto& msg : request.getMessages()) {
        if (msg.role == MessageRole::SYSTEM) {
            json << "[SYSTEM] " << msg.content << "\\n\\n";
        } else if (msg.role == MessageRole::USER) {
            json << "[USER] " << msg.content << "\\n\\n";
        } else if (msg.role == MessageRole::ASSISTANT) {
            json << "[ASSISTANT] " << msg.content << "\\n\\n";
        }
    }

    json << "\",";
    json << "\"stream\":false,";
    json << "\"options\":{";
    json << "\"temperature\":" << request.getTemperature() << ",";
    json << "\"num_predict\":" << maxTokens_;
    json << "}";
    json << "}";

    return json.str();
}

LLMResponse OllamaBackend::parseResponseJson(const std::string& json) {
    LLMResponse response;

    // Simplified JSON parsing (in production, use nlohmann::json or similar)
    // Look for "response":"..." field
    size_t responsePos = json.find("\"response\":\"");
    if (responsePos != std::string::npos) {
        size_t start = responsePos + 12;  // Skip past "response":"
        size_t end = json.find("\"", start);

        if (end != std::string::npos) {
            std::string content = json.substr(start, end - start);

            // Unescape newlines
            size_t pos = 0;
            while ((pos = content.find("\\n", pos)) != std::string::npos) {
                content.replace(pos, 2, "\n");
                pos += 1;
            }

            response.setContent(content);
            response.setFinishReason("stop");
        }
    }

    return response;
}

#ifdef _WIN32

std::string OllamaBackend::httpPost(const std::string& urlStr, const std::string& data) {
    std::string result;

    // Parse URL
    std::wstring whost = L"localhost";
    int wport = port_;
    std::string path = "/api/generate";

    // Extract path from URL
    size_t hostEnd = urlStr.find(':', 7);  // Skip "http://"
    size_t pathStart = urlStr.find('/', 7);
    if (pathStart != std::string::npos) {
        path = urlStr.substr(pathStart);
    }

    // Initialize WinHTTP
    HINTERNET hSession = WinHttpOpen(
        L"Luminara/1.0",
        WINHTTP_ACCESS_TYPE_DEFAULT_PROXY,
        WINHTTP_NO_PROXY_NAME,
        WINHTTP_NO_PROXY_BYPASS,
        0
    );

    if (!hSession) {
        throw std::runtime_error("Failed to initialize WinHTTP");
    }

    // Connect
    HINTERNET hConnect = WinHttpConnect(
        hSession,
        whost.c_str(),
        wport,
        0
    );

    if (!hConnect) {
        WinHttpCloseHandle(hSession);
        throw std::runtime_error("Failed to connect to Ollama");
    }

    // Convert path to wide string
    std::wstring wpath(path.begin(), path.end());

    // Open request
    HINTERNET hRequest = WinHttpOpenRequest(
        hConnect,
        L"POST",
        wpath.c_str(),
        NULL,
        WINHTTP_NO_REFERER,
        WINHTTP_DEFAULT_ACCEPT_TYPES,
        0
    );

    if (!hRequest) {
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
        throw std::runtime_error("Failed to open request");
    }

    // Set headers
    std::wstring headers = L"Content-Type: application/json\r\n";

    // Send request
    BOOL bResults = WinHttpSendRequest(
        hRequest,
        headers.c_str(),
        -1,
        (LPVOID)data.c_str(),
        data.length(),
        data.length(),
        0
    );

    if (bResults) {
        bResults = WinHttpReceiveResponse(hRequest, NULL);
    }

    // Read response
    if (bResults) {
        DWORD dwSize = 0;
        DWORD dwDownloaded = 0;

        do {
            dwSize = 0;
            if (!WinHttpQueryDataAvailable(hRequest, &dwSize)) {
                break;
            }

            if (dwSize == 0) {
                break;
            }

            char* pszOutBuffer = new char[dwSize + 1];
            ZeroMemory(pszOutBuffer, dwSize + 1);

            if (!WinHttpReadData(hRequest, pszOutBuffer, dwSize, &dwDownloaded)) {
                delete[] pszOutBuffer;
                break;
            }

            result.append(pszOutBuffer, dwDownloaded);
            delete[] pszOutBuffer;

        } while (dwSize > 0);
    }

    // Cleanup
    WinHttpCloseHandle(hRequest);
    WinHttpCloseHandle(hConnect);
    WinHttpCloseHandle(hSession);

    return result;
}

#else

// Linux/Mac implementation using libcurl
static size_t WriteCallback(void* contents, size_t size, size_t nmemb, void* userp) {
    ((std::string*)userp)->append((char*)contents, size * nmemb);
    return size * nmemb;
}

std::string OllamaBackend::httpPost(const std::string& url, const std::string& data) {
    std::string response;

    CURL* curl = curl_easy_init();
    if (curl) {
        curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, data.c_str());

        struct curl_slist* headers = NULL;
        headers = curl_slist_append(headers, "Content-Type: application/json");
        curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);

        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response);

        CURLcode res = curl_easy_perform(curl);

        curl_slist_free_all(headers);
        curl_easy_cleanup(curl);

        if (res != CURLE_OK) {
            throw std::runtime_error(std::string("curl error: ") + curl_easy_strerror(res));
        }
    }

    return response;
}

#endif

} // namespace lumi
