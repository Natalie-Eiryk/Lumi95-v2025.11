// GalaxyMapWidget.h - Galaxy-style knowledge domain visualization
#pragma once

#include <QWidget>
#include <QTimer>
#include <QPoint>
#include <QColor>
#include <QMouseEvent>
#include <QWheelEvent>
#include <QPaintEvent>
#include <vector>
#include <string>
#include <memory>

// Forward declarations
class CodonPhysicsEngine;
class EmotionCoreCPU;

namespace lumi {
    class AttractorLandscape;
    class CodonParticle;
    struct CognitiveAttractor;
}

// Represents a knowledge domain "starbase"
struct KnowledgeDomain {
    std::string name;
    std::string type; // "core", "domain", "node"
    float x, y;       // Position in galaxy space (-1 to 1)
    float radius;     // Visual size
    QColor color;     // Starbase color
    float activity;   // Activity level (0-1) for pulsing effect
    std::vector<std::string> connectedTo; // Connected domains

    KnowledgeDomain(const std::string& n, const std::string& t, float px, float py, float r, QColor c)
        : name(n), type(t), x(px), y(py), radius(r), color(c), activity(0.5f) {}
};

class GalaxyMapWidget : public QWidget {
    Q_OBJECT

public:
    explicit GalaxyMapWidget(QWidget* parent = nullptr);
    ~GalaxyMapWidget() override;

    // Add a knowledge domain to the galaxy
    void addDomain(const std::string& name, const std::string& type,
                   float x, float y, float radius, QColor color);

    // Connect two domains
    void connectDomains(const std::string& from, const std::string& to);

    // Update activity level for a domain
    void setDomainActivity(const std::string& name, float activity);

    // Initialize default Luminara architecture
    void initializeLuminaraArchitecture();

    // Connect to real physics simulation
    void setAttractorLandscape(lumi::AttractorLandscape* landscape);
    lumi::AttractorLandscape* getAttractorLandscape() { return attractorLandscape_; }

    // Simulation control
    void setPhysicsMode(bool enabled) { physicsMode_ = enabled; update(); }
    bool isPhysicsMode() const { return physicsMode_; }

signals:
    void domainSelected(const QString& domainName);
    void particleSpawned(const QString& symbol);
    void systemCollapsed();

protected:
    void paintEvent(QPaintEvent* event) override;
    void resizeEvent(QResizeEvent* event) override;
    void mousePressEvent(QMouseEvent* event) override;
    void mouseMoveEvent(QMouseEvent* event) override;
    void mouseReleaseEvent(QMouseEvent* event) override;
    void wheelEvent(QWheelEvent* event) override;

private slots:
    void updateAnimation();

private:
    // Rendering helpers
    void drawStarField();
    void drawDomain(const KnowledgeDomain& domain);
    void drawConnection(const KnowledgeDomain& from, const KnowledgeDomain& to);
    void drawDomainLabel(const KnowledgeDomain& domain);

    // Physics visualization
    void drawPhysicsSimulation(QPainter& painter);
    void drawCognitiveAttractor(QPainter& painter, const lumi::CognitiveAttractor& attractor);
    void drawCodonParticle(QPainter& painter, const lumi::CodonParticle* particle);
    void drawParticleTrajectory(QPainter& painter, const lumi::CodonParticle* particle);
    void drawEmotionalFieldGradient(QPainter& painter);
    void drawCollapseState(QPainter& painter);

    // Utility
    KnowledgeDomain* findDomain(const std::string& name);
    QPointF worldToScreen(float x, float y);
    QPointF screenToWorld(int screenX, int screenY);
    QColor emotionalFieldToColor(float valence, float arousal) const;

    // Data
    std::vector<KnowledgeDomain> domains_;
    std::vector<std::pair<std::string, std::string>> connections_;

    // View controls
    float zoomLevel_;
    float panX_, panY_;
    bool isPanning_;
    QPoint lastMousePos_;

    // Animation
    QTimer* animationTimer_;
    float animationTime_;

    // Star field for background
    struct Star {
        float x, y, brightness;
    };
    std::vector<Star> stars_;

    // Selection
    std::string selectedDomain_;

    // Physics simulation
    lumi::AttractorLandscape* attractorLandscape_;
    bool physicsMode_;
    bool wasCollapsed_;
};
