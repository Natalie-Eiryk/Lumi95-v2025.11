// MainCRTWindow.h - Stub header for Qt CRT-style window
#pragma once

// Forward declarations to avoid Qt dependency in stub
class QWidget;
class QApplication;
class CodonPhysicsEngine;
class EmotionCoreCPU;

// Stub base class (would be QMainWindow in real implementation)
class MainCRTWindow {
public:
    explicit MainCRTWindow(CodonPhysicsEngine* engine, QWidget* parent = nullptr)
        : physicsEngine(engine), emotionCore(nullptr) {
        // Stub implementation
    }

    virtual ~MainCRTWindow() = default;

    void setEmotionCore(EmotionCoreCPU* core) {
        emotionCore = core;
    }

    void resize(int width, int height) {
        // Stub implementation
    }

    void show() {
        // Stub implementation
    }

private:
    CodonPhysicsEngine* physicsEngine;
    EmotionCoreCPU* emotionCore;
};
