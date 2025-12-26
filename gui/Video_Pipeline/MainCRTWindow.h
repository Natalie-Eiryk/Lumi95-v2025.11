// MainCRTWindow.h - Qt6 CRT-style window for Luminara
#pragma once

#include <QMainWindow>
#include <QTextEdit>
#include <QVBoxLayout>
#include <QLabel>
#include <QGroupBox>
#include <QTabWidget>
#include <QTimer>
#include <vector>
#include <string>

// Forward declarations
class CodonPhysicsEngine;
class EmotionCoreCPU;
class GalaxyMapWidget;

class MainCRTWindow : public QMainWindow {
    Q_OBJECT

public:
    explicit MainCRTWindow(CodonPhysicsEngine* engine, QWidget* parent = nullptr);
    virtual ~MainCRTWindow();

    void setEmotionCore(EmotionCoreCPU* core);
    void addLoadedModule(const std::string& moduleName, const std::string& status);
    void setSystemStatus(const std::string& status);

private slots:
    void onDomainSelected(const QString& domainName);

private:
    void setupUI();
    void applyCRTStyle();
    void updateDisplay();

    // UI Components
    QWidget* centralWidget;
    QVBoxLayout* mainLayout;
    QLabel* titleLabel;
    QLabel* systemStatusLabel;
    QTabWidget* tabWidget;

    // Module List Tab
    QTextEdit* moduleDisplay;
    QGroupBox* moduleGroup;

    // Console Tab
    QTextEdit* consoleOutput;
    QGroupBox* consoleGroup;

    // Galaxy Map Tab
    GalaxyMapWidget* galaxyMap;

    // Core references
    CodonPhysicsEngine* physicsEngine;
    EmotionCoreCPU* emotionCore;

    // Module tracking
    std::vector<std::pair<std::string, std::string>> loadedModules;

    // Update timer
    QTimer* updateTimer;
};
