// GalaxyMapWidget.cpp - Implementation of galaxy knowledge visualization
#include "GalaxyMapWidget.h"
#include <lumi/physics/AttractorLandscape.h>
#include <QPainter>
#include <QPen>
#include <QBrush>
#include <QFont>
#include <QFontMetrics>
#include <QtMath>
#include <random>

// PhysX vector conversion helper
namespace {
    QPointF pxVec3ToQPoint(const physx::PxVec3& v) {
        return QPointF(v.x, v.y);  // Use x,y; ignore z for 2D projection
    }
}

GalaxyMapWidget::GalaxyMapWidget(QWidget* parent)
    : QWidget(parent)
    , zoomLevel_(1.0f)
    , panX_(0.0f)
    , panY_(0.0f)
    , isPanning_(false)
    , animationTime_(0.0f)
    , attractorLandscape_(nullptr)
    , physicsMode_(false)
    , wasCollapsed_(false)
{
    // Set background color
    QPalette pal = palette();
    pal.setColor(QPalette::Window, QColor(5, 5, 15)); // Deep space blue-black
    setAutoFillBackground(true);
    setPalette(pal);

    // Setup animation timer
    animationTimer_ = new QTimer(this);
    connect(animationTimer_, &QTimer::timeout, this, &GalaxyMapWidget::updateAnimation);
    animationTimer_->start(50); // 20 FPS

    // Generate star field
    std::mt19937 rng(42); // Fixed seed for consistent star field
    std::uniform_real_distribution<float> posDist(-1.5f, 1.5f);
    std::uniform_real_distribution<float> brightDist(0.2f, 1.0f);

    for (int i = 0; i < 200; ++i) {
        stars_.push_back({posDist(rng), posDist(rng), brightDist(rng)});
    }

    setMinimumSize(800, 600);
}

GalaxyMapWidget::~GalaxyMapWidget() {
    // Qt handles cleanup
}

void GalaxyMapWidget::paintEvent(QPaintEvent* /*event*/) {
    QPainter painter(this);
    painter.setRenderHint(QPainter::Antialiasing);
    painter.setRenderHint(QPainter::TextAntialiasing);

    // Draw star field
    drawStarField();

    // If physics mode is active, draw real simulation
    if (physicsMode_ && attractorLandscape_) {
        painter.save();
        painter.translate(width() / 2.0, height() / 2.0);
        painter.scale(zoomLevel_, zoomLevel_);
        painter.translate(panX_, panY_);

        drawPhysicsSimulation(painter);

        painter.restore();

        // Draw UI overlay
        painter.setPen(QColor(0, 255, 0, 128));
        painter.setFont(QFont("Courier New", 10));
        painter.drawText(10, height() - 10,
            QString("PHYSICS MODE | Zoom: %1x | Energy: %2")
                .arg(zoomLevel_, 0, 'f', 2)
                .arg(attractorLandscape_->getSystemEnergy(), 0, 'f', 4));

        return;  // Skip static visualization
    }

    // Otherwise draw static galaxy map
    painter.save();

    // Apply view transformation
    painter.translate(width() / 2.0, height() / 2.0);
    painter.scale(zoomLevel_, zoomLevel_);
    painter.translate(panX_, panY_);

    // Draw connections first (so they're behind nodes)
    for (const auto& conn : connections_) {
        KnowledgeDomain* from = findDomain(conn.first);
        KnowledgeDomain* to = findDomain(conn.second);
        if (from && to) {
            drawConnection(*from, *to);
        }
    }

    // Draw domains
    for (const auto& domain : domains_) {
        painter.save();
        drawDomain(domain);
        painter.restore();
    }

    // Draw labels
    for (const auto& domain : domains_) {
        painter.save();
        drawDomainLabel(domain);
        painter.restore();
    }

    painter.restore();

    // Draw UI overlay (zoom level, etc.)
    painter.setPen(QColor(0, 255, 0, 128));
    painter.setFont(QFont("Courier New", 10));
    painter.drawText(10, height() - 10, QString("Zoom: %1x | Domains: %2")
        .arg(zoomLevel_, 0, 'f', 2)
        .arg(domains_.size()));
}

void GalaxyMapWidget::resizeEvent(QResizeEvent* /*event*/) {
    // Handle resize if needed
    update();
}

void GalaxyMapWidget::drawStarField() {
    QPainter painter(this);
    painter.setRenderHint(QPainter::Antialiasing);

    for (const auto& star : stars_) {
        QPointF screenPos = worldToScreen(star.x, star.y);
        int brightness = static_cast<int>(star.brightness * 255);
        painter.setPen(QPen(QColor(brightness, brightness, brightness, brightness), 1));
        painter.drawPoint(screenPos);
    }
}

void GalaxyMapWidget::drawDomain(const KnowledgeDomain& domain) {
    QPainter painter(this);
    painter.setRenderHint(QPainter::Antialiasing);

    // Calculate screen position
    float screenRadius = domain.radius * 50.0f * zoomLevel_;
    QPointF center = worldToScreen(domain.x, domain.y);

    // Pulsing effect based on activity
    float pulse = 1.0f + 0.2f * domain.activity * qSin(animationTime_ * 2.0f);
    screenRadius *= pulse;

    // Outer glow
    QRadialGradient glowGradient(center, screenRadius * 1.5f);
    QColor glowColor = domain.color;
    glowColor.setAlpha(60);
    glowGradient.setColorAt(0, glowColor);
    glowColor.setAlpha(0);
    glowGradient.setColorAt(1, glowColor);
    painter.setBrush(glowGradient);
    painter.setPen(Qt::NoPen);
    painter.drawEllipse(center, screenRadius * 1.5f, screenRadius * 1.5f);

    // Core starbase
    QRadialGradient coreGradient(center, screenRadius);
    coreGradient.setColorAt(0, domain.color.lighter(150));
    coreGradient.setColorAt(0.7, domain.color);
    coreGradient.setColorAt(1, domain.color.darker(120));
    painter.setBrush(coreGradient);

    // Highlighted if selected
    if (domain.name == selectedDomain_) {
        painter.setPen(QPen(QColor(255, 255, 0), 2));
    } else {
        painter.setPen(QPen(domain.color.lighter(130), 1));
    }

    painter.drawEllipse(center, screenRadius, screenRadius);

    // Inner detail (hexagonal structure for "starbase" look)
    painter.setPen(QPen(domain.color.lighter(180), 1, Qt::DashLine));
    painter.setBrush(Qt::NoBrush);
    const int hexPoints = 6;
    QPolygonF hexagon;
    for (int i = 0; i < hexPoints; ++i) {
        float angle = (i / static_cast<float>(hexPoints)) * 2.0f * M_PI;
        hexagon << center + QPointF(
            screenRadius * 0.7f * qCos(angle + animationTime_),
            screenRadius * 0.7f * qSin(angle + animationTime_)
        );
    }
    painter.drawPolygon(hexagon);
}

void GalaxyMapWidget::drawConnection(const KnowledgeDomain& from, const KnowledgeDomain& to) {
    QPainter painter(this);
    painter.setRenderHint(QPainter::Antialiasing);

    QPointF start = worldToScreen(from.x, from.y);
    QPointF end = worldToScreen(to.x, to.y);

    // Animated flow along connection
    float flowPos = fmod(animationTime_ * 0.5f, 1.0f);
    QPointF flowPoint = start + (end - start) * flowPos;

    // Draw connection line
    QColor connColor = QColor(0, 200, 200, 80);
    painter.setPen(QPen(connColor, 1, Qt::DotLine));
    painter.drawLine(start, end);

    // Draw flow indicator
    painter.setPen(Qt::NoPen);
    painter.setBrush(QColor(0, 255, 255, 180));
    painter.drawEllipse(flowPoint, 3, 3);
}

void GalaxyMapWidget::drawDomainLabel(const KnowledgeDomain& domain) {
    QPainter painter(this);
    painter.setRenderHint(QPainter::TextAntialiasing);

    QPointF center = worldToScreen(domain.x, domain.y);
    float screenRadius = domain.radius * 50.0f * zoomLevel_;

    // Label below the domain
    QFont font("Courier New", 9, QFont::Bold);
    painter.setFont(font);
    QFontMetrics fm(font);

    QString label = QString::fromStdString(domain.name);
    int textWidth = fm.horizontalAdvance(label);
    QPointF textPos = center + QPointF(-textWidth / 2.0f, screenRadius + 15);

    // Text shadow for readability
    painter.setPen(QColor(0, 0, 0, 200));
    painter.drawText(textPos + QPointF(1, 1), label);

    // Main text
    painter.setPen(domain.color.lighter(150));
    painter.drawText(textPos, label);
}

void GalaxyMapWidget::updateAnimation() {
    animationTime_ += 0.05f;
    update(); // Trigger repaint
}

void GalaxyMapWidget::mousePressEvent(QMouseEvent* event) {
    if (event->button() == Qt::LeftButton) {
        // Check if clicked on a domain
        QPointF worldPos = screenToWorld(event->pos().x(), event->pos().y());
        for (const auto& domain : domains_) {
            float dx = worldPos.x() - domain.x;
            float dy = worldPos.y() - domain.y;
            float dist = qSqrt(dx * dx + dy * dy);
            if (dist < domain.radius) {
                selectedDomain_ = domain.name;
                emit domainSelected(QString::fromStdString(domain.name));
                update();
                return;
            }
        }
        selectedDomain_.clear();
    }

    if (event->button() == Qt::MiddleButton || event->button() == Qt::RightButton) {
        isPanning_ = true;
        lastMousePos_ = event->pos();
    }
}

void GalaxyMapWidget::mouseMoveEvent(QMouseEvent* event) {
    if (isPanning_) {
        QPoint delta = event->pos() - lastMousePos_;
        panX_ += delta.x() / zoomLevel_;
        panY_ += delta.y() / zoomLevel_;
        lastMousePos_ = event->pos();
        update();
    }
}

void GalaxyMapWidget::mouseReleaseEvent(QMouseEvent* event) {
    if (event->button() == Qt::MiddleButton || event->button() == Qt::RightButton) {
        isPanning_ = false;
    }
}

void GalaxyMapWidget::wheelEvent(QWheelEvent* event) {
    float zoomFactor = 1.1f;
    if (event->angleDelta().y() > 0) {
        zoomLevel_ *= zoomFactor;
    } else {
        zoomLevel_ /= zoomFactor;
    }
    zoomLevel_ = qBound(0.3f, zoomLevel_, 5.0f);
    update();
}

void GalaxyMapWidget::addDomain(const std::string& name, const std::string& type,
                                float x, float y, float radius, QColor color) {
    domains_.emplace_back(name, type, x, y, radius, color);
    update();
}

void GalaxyMapWidget::connectDomains(const std::string& from, const std::string& to) {
    connections_.push_back({from, to});
    update();
}

void GalaxyMapWidget::setDomainActivity(const std::string& name, float activity) {
    KnowledgeDomain* domain = findDomain(name);
    if (domain) {
        domain->activity = qBound(0.0f, activity, 1.0f);
    }
}

void GalaxyMapWidget::initializeLuminaraArchitecture() {
    // Central domains (Identity, Inception, Memory)
    addDomain("IDENTITY", "domain", 0.0f, 0.0f, 0.15f, QColor(255, 100, 255)); // Magenta
    addDomain("INCEPTION", "domain", -0.5f, 0.3f, 0.12f, QColor(100, 255, 255)); // Cyan
    addDomain("MEMORY", "domain", 0.5f, 0.3f, 0.12f, QColor(255, 255, 100)); // Yellow

    // Eight Cognitive Cores arranged in circle
    const float coreRadius = 0.6f;
    const int numCores = 8;
    struct CoreInfo {
        std::string name;
        QColor color;
    };
    std::vector<CoreInfo> cores = {
        {"EmotionCore", QColor(255, 50, 50)},      // Red
        {"LogicCore", QColor(50, 150, 255)},       // Blue
        {"WisdomCore", QColor(200, 150, 255)},     // Purple
        {"MemoryCore", QColor(255, 215, 0)},       // Gold
        {"NarrativeCore", QColor(100, 255, 150)},  // Green-cyan
        {"IntuitionCore", QColor(255, 150, 255)},  // Pink
        {"SomaticCore", QColor(255, 180, 100)},    // Orange
        {"ExecutiveCore", QColor(150, 255, 255)}   // Light cyan
    };

    for (int i = 0; i < numCores; ++i) {
        float angle = (i / static_cast<float>(numCores)) * 2.0f * M_PI - M_PI / 2.0f;
        float x = coreRadius * qCos(angle);
        float y = coreRadius * qSin(angle);
        addDomain(cores[i].name, "core", x, y, 0.08f, cores[i].color);

        // Connect each core to central IDENTITY domain
        connectDomains(cores[i].name, "IDENTITY");
    }

    // Connect domains
    connectDomains("IDENTITY", "INCEPTION");
    connectDomains("IDENTITY", "MEMORY");
    connectDomains("INCEPTION", "MEMORY");

    // Core interconnections (example - EmotionCore <-> LogicCore)
    connectDomains("EmotionCore", "LogicCore");
    connectDomains("LogicCore", "WisdomCore");
    connectDomains("WisdomCore", "MemoryCore");
    connectDomains("MemoryCore", "NarrativeCore");
    connectDomains("NarrativeCore", "IntuitionCore");
    connectDomains("IntuitionCore", "SomaticCore");
    connectDomains("SomaticCore", "ExecutiveCore");
    connectDomains("ExecutiveCore", "EmotionCore");

    update();
}

KnowledgeDomain* GalaxyMapWidget::findDomain(const std::string& name) {
    for (auto& domain : domains_) {
        if (domain.name == name) {
            return &domain;
        }
    }
    return nullptr;
}

QPointF GalaxyMapWidget::worldToScreen(float x, float y) {
    float screenX = (x + panX_) * zoomLevel_ * width() / 2.0f + width() / 2.0f;
    float screenY = (y + panY_) * zoomLevel_ * height() / 2.0f + height() / 2.0f;
    return QPointF(screenX, screenY);
}

QPointF GalaxyMapWidget::screenToWorld(int screenX, int screenY) {
    float worldX = ((screenX - width() / 2.0f) / zoomLevel_ / (width() / 2.0f)) - panX_;
    float worldY = ((screenY - height() / 2.0f) / zoomLevel_ / (height() / 2.0f)) - panY_;
    return QPointF(worldX, worldY);
}

// ============================================================
// PHYSICS SIMULATION VISUALIZATION
// ============================================================

void GalaxyMapWidget::setAttractorLandscape(lumi::AttractorLandscape* landscape) {
    attractorLandscape_ = landscape;
    physicsMode_ = (landscape != nullptr);
    update();
}

void GalaxyMapWidget::drawPhysicsSimulation(QPainter& painter) {
    if (!attractorLandscape_) return;

    painter.save();

    // Draw emotional field gradient
    drawEmotionalFieldGradient(painter);

    // Draw cognitive attractors
    for (const auto& attractor : attractorLandscape_->getAttractors()) {
        drawCognitiveAttractor(painter, attractor);
    }

    // Draw codon particles
    for (const auto& particle : attractorLandscape_->getParticles()) {
        drawParticleTrajectory(painter, particle.get());
        drawCodonParticle(painter, particle.get());
    }

    // Draw collapse state if system has collapsed
    if (attractorLandscape_->hasCollapsed()) {
        if (!wasCollapsed_) {
            wasCollapsed_ = true;
            emit systemCollapsed();
        }
        drawCollapseState(painter);
    } else {
        wasCollapsed_ = false;
    }

    painter.restore();
}

void GalaxyMapWidget::drawCognitiveAttractor(QPainter& painter, const lumi::CognitiveAttractor& attractor) {
    if (!attractor.active) return;

    // Convert 3D position to 2D screen
    QPointF screenPos = worldToScreen(attractor.position.x, attractor.position.y);
    float screenRadius = attractor.radius * 50.0f * zoomLevel_;

    // Color based on emotional signature
    QColor attractorColor = emotionalFieldToColor(
        attractor.emotionalSignature.valence,
        attractor.emotionalSignature.arousal
    );

    // Pulsing effect
    float pulse = 1.0f + 0.15f * qSin(animationTime_ * 3.0f);
    screenRadius *= pulse;

    // Outer influence field
    QRadialGradient influenceGradient(screenPos, screenRadius * 1.5f);
    QColor fieldColor = attractorColor;
    fieldColor.setAlpha(40);
    influenceGradient.setColorAt(0, fieldColor);
    fieldColor.setAlpha(0);
    influenceGradient.setColorAt(1, fieldColor);

    painter.setBrush(influenceGradient);
    painter.setPen(Qt::NoPen);
    painter.drawEllipse(screenPos, screenRadius * 1.5f, screenRadius * 1.5f);

    // Core attractor
    QRadialGradient coreGradient(screenPos, screenRadius);
    coreGradient.setColorAt(0, attractorColor.lighter(180));
    coreGradient.setColorAt(0.5, attractorColor);
    coreGradient.setColorAt(1, attractorColor.darker(150));

    painter.setBrush(coreGradient);
    painter.setPen(QPen(attractorColor.lighter(150), 2));
    painter.drawEllipse(screenPos, screenRadius, screenRadius);

    // Draw attractor name
    painter.setPen(attractorColor.lighter(170));
    QFont font("Courier New", 9, QFont::Bold);
    painter.setFont(font);
    painter.drawText(screenPos + QPointF(-30, screenRadius + 15),
                    QString::fromUtf8(coreTypeToString(attractor.coreType)));
}

void GalaxyMapWidget::drawCodonParticle(QPainter& painter, const lumi::CodonParticle* particle) {
    if (!particle) return;

    auto pos = particle->getPhysicsBody()->getGlobalPose();
    QPointF screenPos = worldToScreen(pos.x, pos.y);

    // Particle size
    float particleRadius = 5.0f * zoomLevel_;

    // Color based on emotional charge
    auto charge = particle->getEmotionalCharge();
    QColor particleColor = emotionalFieldToColor(charge.valence, charge.arousal);

    // Glowing particle
    QRadialGradient particleGradient(screenPos, particleRadius * 2.0f);
    QColor glowColor = particleColor;
    glowColor.setAlpha(200);
    particleGradient.setColorAt(0, glowColor);
    glowColor.setAlpha(0);
    particleGradient.setColorAt(1, glowColor);

    painter.setBrush(particleGradient);
    painter.setPen(Qt::NoPen);
    painter.drawEllipse(screenPos, particleRadius * 2.0f, particleRadius * 2.0f);

    // Core particle
    painter.setBrush(particleColor.lighter(180));
    painter.setPen(QPen(particleColor.lighter(200), 1));
    painter.drawEllipse(screenPos, particleRadius, particleRadius);
}

void GalaxyMapWidget::drawParticleTrajectory(QPainter& painter, const lumi::CodonParticle* particle) {
    if (!particle) return;

    const auto& trajectory = particle->getTrajectory();
    if (trajectory.size() < 2) return;

    auto charge = particle->getEmotionalCharge();
    QColor trailColor = emotionalFieldToColor(charge.valence, charge.arousal);
    trailColor.setAlpha(100);

    QPen trailPen(trailColor, 1.5f);
    painter.setPen(trailPen);

    // Draw trail as connected line segments
    for (size_t i = 1; i < trajectory.size(); ++i) {
        QPointF p1 = worldToScreen(trajectory[i-1].x, trajectory[i-1].y);
        QPointF p2 = worldToScreen(trajectory[i].x, trajectory[i].y);

        // Fade trail toward older positions
        float alpha = (float)i / trajectory.size();
        trailColor.setAlpha((int)(alpha * 80));
        painter.setPen(QPen(trailColor, 1.0f));

        painter.drawLine(p1, p2);
    }
}

void GalaxyMapWidget::drawEmotionalFieldGradient(QPainter& painter) {
    // Draw field lines showing emotional gradient

    // Sample emotional field at various points
    const int gridSize = 8;
    const float worldSize = 10.0f;

    painter.setPen(QPen(QColor(0, 200, 200, 30), 1, Qt::DotLine));

    for (int i = 0; i < gridSize; ++i) {
        for (int j = 0; j < gridSize; ++j) {
            float x = -worldSize + (i / (float)gridSize) * 2.0f * worldSize;
            float y = -worldSize + (j / (float)gridSize) * 2.0f * worldSize;

            physx::PxVec3 worldPos(x, y, 0);
            auto field = attractorLandscape_->computeEmotionalFieldAt(worldPos);

            QPointF screenPos = worldToScreen(x, y);

            // Draw small indicator based on field properties
            QColor fieldColor = emotionalFieldToColor(field.valence, field.arousal);
            fieldColor.setAlpha(40);
            painter.setBrush(fieldColor);
            painter.drawEllipse(screenPos, 2, 2);
        }
    }
}

void GalaxyMapWidget::drawCollapseState(QPainter& painter) {
    if (!attractorLandscape_->hasCollapsed()) return;

    auto collapse = attractorLandscape_->getCollapseState();

    // Draw collapse indicator in corner
    painter.setPen(QColor(255, 255, 0));
    QFont font("Courier New", 10, QFont::Bold);
    painter.setFont(font);

    painter.drawText(10, 30, "SYSTEM COLLAPSED");
    painter.drawText(10, 45, QString("Energy: %1").arg(collapse.totalEnergy, 0, 'f', 4));
    painter.drawText(10, 60, QString("Particles: %1").arg(collapse.particleCount));

    // Draw core activations
    int y = 80;
    painter.drawText(10, y, "Core Activations:");
    y += 15;

    for (const auto& [core, activation] : collapse.coreActivations) {
        QString coreName = QString::fromUtf8(coreTypeToString(core));
        QString activationText = QString("%1: %2%")
            .arg(coreName, -15)
            .arg((int)(activation * 100));

        QColor barColor = emotionalFieldToColor(activation, activation);
        painter.setPen(barColor);
        painter.drawText(10, y, activationText);

        // Draw activation bar
        int barWidth = (int)(activation * 100);
        painter.fillRect(140, y - 10, barWidth, 10, barColor);

        y += 15;
    }
}

QColor GalaxyMapWidget::emotionalFieldToColor(float valence, float arousal) const {
    // Map valence (-1 to +1) and arousal (0 to 1) to color

    // Valence: negative = red/blue, positive = green/yellow
    // Arousal: low = darker, high = brighter

    int r, g, b;

    if (valence < 0) {
        // Negative valence: red-blue spectrum
        float negValence = -valence;  // 0-1
        r = (int)(255 * negValence);
        g = 50;
        b = (int)(200 * (1.0f - negValence));
    } else {
        // Positive valence: yellow-green spectrum
        r = (int)(200 * (1.0f - valence));
        g = 255;
        b = 50;
    }

    // Modulate brightness by arousal
    float brightness = 0.4f + (arousal * 0.6f);
    r = (int)(r * brightness);
    g = (int)(g * brightness);
    b = (int)(b * brightness);

    return QColor(r, g, b);
}
