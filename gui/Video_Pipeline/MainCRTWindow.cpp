// MainCRTWindow.cpp - Implementation of Qt6 CRT-style window
#include "MainCRTWindow.h"
#include "GalaxyMapWidget.h"
#include <lumi/physics/CodonPhysicsEngine.h>
#include <lumi/cores/EmotionCoreCPU.h>
#include <QFont>
#include <QPalette>
#include <QDateTime>

MainCRTWindow::MainCRTWindow(CodonPhysicsEngine* engine, QWidget* parent)
    : QMainWindow(parent)
    , physicsEngine(engine)
    , emotionCore(nullptr)
    , centralWidget(nullptr)
    , mainLayout(nullptr)
    , titleLabel(nullptr)
    , systemStatusLabel(nullptr)
    , tabWidget(nullptr)
    , moduleDisplay(nullptr)
    , moduleGroup(nullptr)
    , consoleOutput(nullptr)
    , consoleGroup(nullptr)
    , galaxyMap(nullptr)
    , updateTimer(nullptr)
{
    setupUI();
    applyCRTStyle();

    // Setup update timer
    updateTimer = new QTimer(this);
    connect(updateTimer, &QTimer::timeout, this, &MainCRTWindow::updateDisplay);
    updateTimer->start(1000); // Update every second

    setSystemStatus("🌌 Lumi286 Initializing...");
}

MainCRTWindow::~MainCRTWindow() {
    // Qt handles cleanup of child widgets
}

void MainCRTWindow::setupUI() {
    // Central widget
    centralWidget = new QWidget(this);
    setCentralWidget(centralWidget);

    // Main layout
    mainLayout = new QVBoxLayout(centralWidget);
    mainLayout->setSpacing(10);
    mainLayout->setContentsMargins(20, 20, 20, 20);

    // Title label
    titleLabel = new QLabel("🌌 LUMINARA COGNITIVE ARCHITECTURE 🌌", centralWidget);
    titleLabel->setAlignment(Qt::AlignCenter);
    QFont titleFont("Courier New", 16, QFont::Bold);
    titleLabel->setFont(titleFont);
    mainLayout->addWidget(titleLabel);

    // System status label
    systemStatusLabel = new QLabel("System Status: Initializing", centralWidget);
    systemStatusLabel->setAlignment(Qt::AlignCenter);
    QFont statusFont("Courier New", 10);
    systemStatusLabel->setFont(statusFont);
    mainLayout->addWidget(systemStatusLabel);

    // Create tab widget for different views
    tabWidget = new QTabWidget(centralWidget);
    mainLayout->addWidget(tabWidget);

    // === Tab 1: Module List ===
    QWidget* moduleTab = new QWidget();
    QVBoxLayout* moduleTabLayout = new QVBoxLayout(moduleTab);

    moduleGroup = new QGroupBox("Loaded Cognitive Modules", moduleTab);
    QVBoxLayout* moduleLayout = new QVBoxLayout(moduleGroup);

    moduleDisplay = new QTextEdit(moduleGroup);
    moduleDisplay->setReadOnly(true);
    moduleDisplay->setMaximumHeight(250);
    QFont moduleFont("Courier New", 9);
    moduleDisplay->setFont(moduleFont);
    moduleLayout->addWidget(moduleDisplay);

    moduleTabLayout->addWidget(moduleGroup);
    tabWidget->addTab(moduleTab, "📋 Modules");

    // === Tab 2: Galaxy Map ===
    galaxyMap = new GalaxyMapWidget(centralWidget);
    galaxyMap->initializeLuminaraArchitecture();
    connect(galaxyMap, &GalaxyMapWidget::domainSelected,
            this, &MainCRTWindow::onDomainSelected);
    tabWidget->addTab(galaxyMap, "🌌 Galaxy Map");

    // === Tab 3: Console ===
    QWidget* consoleTab = new QWidget();
    QVBoxLayout* consoleTabLayout = new QVBoxLayout(consoleTab);

    consoleGroup = new QGroupBox("System Console", consoleTab);
    QVBoxLayout* consoleLayout = new QVBoxLayout(consoleGroup);

    consoleOutput = new QTextEdit(consoleGroup);
    consoleOutput->setReadOnly(true);
    QFont consoleFont("Courier New", 9);
    consoleOutput->setFont(consoleFont);
    consoleLayout->addWidget(consoleOutput);

    consoleTabLayout->addWidget(consoleGroup);
    tabWidget->addTab(consoleTab, "💻 Console");

    // Set window properties
    setWindowTitle("Lumi286 - Luminara Cognitive Architecture");
    resize(900, 700);

    // Initial console message
    consoleOutput->append(QString("[%1] System boot initiated").arg(
        QDateTime::currentDateTime().toString("hh:mm:ss")));
}

void MainCRTWindow::applyCRTStyle() {
    // CRT-inspired color scheme (green phosphor on dark background)
    QPalette palette;

    // Dark background
    palette.setColor(QPalette::Window, QColor(10, 10, 10));
    palette.setColor(QPalette::WindowText, QColor(0, 255, 0));
    palette.setColor(QPalette::Base, QColor(0, 0, 0));
    palette.setColor(QPalette::AlternateBase, QColor(15, 15, 15));
    palette.setColor(QPalette::Text, QColor(0, 255, 0));
    palette.setColor(QPalette::Button, QColor(20, 20, 20));
    palette.setColor(QPalette::ButtonText, QColor(0, 255, 0));
    palette.setColor(QPalette::BrightText, QColor(0, 255, 100));
    palette.setColor(QPalette::Highlight, QColor(0, 150, 0));
    palette.setColor(QPalette::HighlightedText, QColor(0, 0, 0));

    setPalette(palette);

    // Apply to text displays
    if (moduleDisplay) {
        moduleDisplay->setPalette(palette);
    }
    if (consoleOutput) {
        consoleOutput->setPalette(palette);
    }

    // Style sheet for additional customization
    setStyleSheet(
        "QMainWindow { background-color: #0a0a0a; }"
        "QLabel { color: #00ff00; }"
        "QGroupBox { "
        "   color: #00ff00; "
        "   border: 2px solid #00ff00; "
        "   border-radius: 5px; "
        "   margin-top: 1ex; "
        "   font-weight: bold; "
        "}"
        "QGroupBox::title { "
        "   subcontrol-origin: margin; "
        "   subcontrol-position: top center; "
        "   padding: 0 3px; "
        "}"
        "QTextEdit { "
        "   background-color: #000000; "
        "   color: #00ff00; "
        "   border: 1px solid #00ff00; "
        "   selection-background-color: #009600; "
        "}"
    );
}

void MainCRTWindow::setEmotionCore(EmotionCoreCPU* core) {
    emotionCore = core;
    consoleOutput->append(QString("[%1] EmotionCore bound successfully").arg(
        QDateTime::currentDateTime().toString("hh:mm:ss")));
}

void MainCRTWindow::addLoadedModule(const std::string& moduleName, const std::string& status) {
    loadedModules.push_back(std::make_pair(moduleName, status));
    updateDisplay();

    consoleOutput->append(QString("[%1] Module loaded: %2 [%3]").arg(
        QDateTime::currentDateTime().toString("hh:mm:ss"),
        QString::fromStdString(moduleName),
        QString::fromStdString(status)));
}

void MainCRTWindow::setSystemStatus(const std::string& status) {
    systemStatusLabel->setText(QString("System Status: %1").arg(QString::fromStdString(status)));
    consoleOutput->append(QString("[%1] Status: %2").arg(
        QDateTime::currentDateTime().toString("hh:mm:ss"),
        QString::fromStdString(status)));
}

void MainCRTWindow::updateDisplay() {
    // Update module display
    QString moduleText;
    moduleText += "╔════════════════════════════════════════════════════════════════════╗\n";
    moduleText += "║  MODULE NAME                      │  STATUS                        ║\n";
    moduleText += "╠════════════════════════════════════════════════════════════════════╣\n";

    if (loadedModules.empty()) {
        moduleText += "║  No modules loaded yet                                            ║\n";
    } else {
        for (const auto& module : loadedModules) {
            QString name = QString::fromStdString(module.first);
            QString status = QString::fromStdString(module.second);

            // Pad to align columns
            name = name.leftJustified(32, ' ');
            status = status.leftJustified(30, ' ');

            moduleText += QString("║  %1 │  %2 ║\n").arg(name, status);
        }
    }

    moduleText += "╚════════════════════════════════════════════════════════════════════╝\n";
    moduleText += QString("\nTotal Modules: %1\n").arg(loadedModules.size());

    if (physicsEngine) {
        moduleText += "PhysX Engine: ACTIVE\n";
    } else {
        moduleText += "PhysX Engine: NOT INITIALIZED\n";
    }

    if (emotionCore) {
        moduleText += "EmotionCore: BOUND\n";
    } else {
        moduleText += "EmotionCore: NOT BOUND\n";
    }

    moduleDisplay->setPlainText(moduleText);
}

void MainCRTWindow::onDomainSelected(const QString& domainName) {
    // Log domain selection to console
    consoleOutput->append(QString("[%1] Galaxy Map: Domain selected - %2").arg(
        QDateTime::currentDateTime().toString("hh:mm:ss"),
        domainName));

    // Update domain activity visualization
    if (galaxyMap) {
        galaxyMap->setDomainActivity(domainName.toStdString(), 1.0f);
    }
}
