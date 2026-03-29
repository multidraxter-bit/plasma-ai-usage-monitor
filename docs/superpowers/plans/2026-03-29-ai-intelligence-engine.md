# AI Intelligence Engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a local-LLM powered "Intelligence" layer using Ollama to provide natural language insights on AI usage and costs.

**Architecture:** A new `IntelligenceBackend` (C++) handles data aggregation from the SQLite database and communicates with the local Ollama API. New QML components (`IntelligenceTab`, `InsightBanner`) present these insights across the dashboard.

**Tech Stack:** C++20, Qt6 (Network, Qml), KF6, Ollama API, QML.

---

### Task 1: IntelligenceBackend C++ Skeleton

**Files:**
- Create: `plugin/intelligencebackend.h`
- Create: `plugin/intelligencebackend.cpp`
- Modify: `plugin/CMakeLists.txt`

- [ ] **Step 1: Create IntelligenceBackend Header**

```cpp
#ifndef INTELLIGENCEBACKEND_H
#define INTELLIGENCEBACKEND_H

#include <QObject>
#include <QString>
#include <QDateTime>
#include <QNetworkAccessManager>
#include "usagedatabase.h"

class IntelligenceBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString fullInsight READ fullInsight WRITE setFullInsight NOTIFY fullInsightChanged)
    Q_PROPERTY(QString shortSnippet READ shortSnippet WRITE setShortSnippet NOTIFY shortSnippetChanged)
    Q_PROPERTY(QString bannerAlert READ bannerAlert WRITE setBannerAlert NOTIFY bannerAlertChanged)
    Q_PROPERTY(bool isGenerating READ isGenerating NOTIFY isGeneratingChanged)
    Q_PROPERTY(UsageDatabase* database READ database WRITE setDatabase NOTIFY databaseChanged)

public:
    explicit IntelligenceBackend(QObject *parent = nullptr);

    QString fullInsight() const { return m_fullInsight; }
    void setFullInsight(const QString &val);

    QString shortSnippet() const { return m_shortSnippet; }
    void setShortSnippet(const QString &val);

    QString bannerAlert() const { return m_bannerAlert; }
    void setBannerAlert(const QString &val);

    bool isGenerating() const { return m_isGenerating; }

    UsageDatabase* database() const { return m_database; }
    void setDatabase(UsageDatabase* db);

    Q_INVOKABLE void generate(const QString &ollamaUrl, const QString &modelName);

Q_SIGNALS:
    void fullInsightChanged();
    void shortSnippetChanged();
    void bannerAlertChanged();
    void isGeneratingChanged();
    void databaseChanged();
    void generationFinished(bool success, const QString &error = QString());

private Q_SLOTS:
    void onOllamaReply();

private:
    QString m_fullInsight;
    QString m_shortSnippet;
    QString m_bannerAlert;
    bool m_isGenerating = false;
    UsageDatabase* m_database = nullptr;
    QNetworkAccessManager *m_networkManager;
};

#endif
```

- [ ] **Step 2: Create IntelligenceBackend Implementation**

```cpp
#include "intelligencebackend.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QNetworkReply>
#include <QDebug>

IntelligenceBackend::IntelligenceBackend(QObject *parent)
    : QObject(parent), m_networkManager(new QNetworkAccessManager(this))
{}

void IntelligenceBackend::setFullInsight(const QString &val) {
    if (m_fullInsight != val) { m_fullInsight = val; emit fullInsightChanged(); }
}

void IntelligenceBackend::setShortSnippet(const QString &val) {
    if (m_shortSnippet != val) { m_shortSnippet = val; emit shortSnippetChanged(); }
}

void IntelligenceBackend::setBannerAlert(const QString &val) {
    if (m_bannerAlert != val) { m_bannerAlert = val; emit bannerAlertChanged(); }
}

void IntelligenceBackend::setDatabase(UsageDatabase* db) {
    if (m_database != db) { m_database = db; emit databaseChanged(); }
}

void IntelligenceBackend::generate(const QString &ollamaUrl, const QString &modelName) {
    if (m_isGenerating || !m_database) return;
    
    m_isGenerating = true;
    emit isGeneratingChanged();

    // Placeholder for data aggregation and Ollama call
    qDebug() << "Generating insights using" << modelName << "at" << ollamaUrl;
    
    // For now, simulate async finish
    QTimer::singleShot(500, this, [this](){
        m_isGenerating = false;
        emit isGeneratingChanged();
        emit generationFinished(true);
    });
}

void IntelligenceBackend::onOllamaReply() {}
```

- [ ] **Step 3: Add to CMakeLists.txt**

Modify `plugin/CMakeLists.txt` to include `intelligencebackend.cpp` in `aiusagemonitor_SRCS` and `intelligencebackend.h` in `aiusagemonitor_HDRS`.

- [ ] **Step 4: Commit**

```bash
git add plugin/intelligencebackend.h plugin/intelligencebackend.cpp plugin/CMakeLists.txt
git commit -m "feat(plugin): add IntelligenceBackend skeleton"
```

---

### Task 2: Data Aggregation & Prompt Generation

**Files:**
- Modify: `plugin/intelligencebackend.cpp`
- Modify: `plugin/usagedatabase.h`
- Modify: `plugin/usagedatabase.cpp`

- [ ] **Step 1: Add History Retrieval Method to UsageDatabase**

Implement `getRecentHistoryJson(int days)` in `UsageDatabase` that returns a JSON string or object summarizing the last N days of costs and models.

- [ ] **Step 2: Implement Prompt Construction**

In `IntelligenceBackend::generate`, call `database->getRecentHistoryJson(7)` and wrap it in a system prompt that requests a structured response.

- [ ] **Step 3: Commit**

```bash
git add plugin/intelligencebackend.cpp plugin/usagedatabase.h plugin/usagedatabase.cpp
git commit -m "feat(intelligence): implement history aggregation and prompt generation"
```

---

### Task 3: Ollama API Integration

**Files:**
- Modify: `plugin/intelligencebackend.cpp`

- [ ] **Step 1: Implement Ollama POST Request**

In `IntelligenceBackend::generate`, send a POST request to `${ollamaUrl}/api/generate` with the prompt and `stream: false`.

- [ ] **Step 2: Implement Parsing Logic**

In `onOllamaReply`, parse the JSON response. Expect the LLM to provide a structured response (e.g., using markers like `[BANNER]`, `[SNIPPET]`, `[FULL]`).

- [ ] **Step 3: Commit**

```bash
git add plugin/intelligencebackend.cpp
git commit -m "feat(intelligence): connect to Ollama API and parse response"
```

---

### Task 4: QML Plugin Registration

**Files:**
- Modify: `plugin/aiusageplugin.cpp`

- [ ] **Step 1: Register IntelligenceBackend**

Add `qmlRegisterType<IntelligenceBackend>(uri, 1, 0, "IntelligenceBackend");` to `AIUsagePlugin::registerTypes`.

- [ ] **Step 2: Commit**

```bash
git add plugin/aiusageplugin.cpp
git commit -m "feat(plugin): register IntelligenceBackend for QML"
```

---

### Task 5: UI Components (Banner & Tab)

**Files:**
- Create: `package/contents/ui/InsightBanner.qml`
- Create: `package/contents/ui/IntelligenceTab.qml`

- [ ] **Step 1: Create InsightBanner.qml**

Implement a dismissible card using `Kirigami.InlineMessage` or a custom `Rectangle`.

- [ ] **Step 2: Create IntelligenceTab.qml**

Implement the tab with a large text area for `fullInsight` and the "Generate" button.

- [ ] **Step 3: Commit**

```bash
git add package/contents/ui/InsightBanner.qml package/contents/ui/IntelligenceTab.qml
git commit -m "feat(ui): add InsightBanner and IntelligenceTab components"
```

---

### Task 4: Integration in main.qml

**Files:**
- Modify: `package/contents/ui/main.qml`

- [ ] **Step 1: Instantiate IntelligenceBackend**

```qml
IntelligenceBackend {
    id: intelligence
    database: usageDatabase
    fullInsight: plasmoid.configuration.lastFullInsight
    shortSnippet: plasmoid.configuration.lastShortSnippet
    bannerAlert: plasmoid.configuration.lastBannerAlert
}
```

- [ ] **Step 2: Add Intelligence Tab to UI**

Add the new tab to the `Kirigami.TabGroup` or equivalent structure in `main.qml`.

- [ ] **Step 3: Add Banner to Dashboard**

Place `InsightBanner` at the top of the main scroll view.

- [ ] **Step 4: Commit**

```bash
git add package/contents/ui/main.qml
git commit -m "feat(ui): integrate intelligence backend and components into main view"
```

---

### Task 7: Update CostSummaryCard

**Files:**
- Modify: `package/contents/ui/CostSummaryCard.qml`

- [ ] **Step 1: Show Snippet**

Add a `PlasmaComponents.Label` at the bottom of the card showing `intelligence.shortSnippet`.

- [ ] **Step 2: Commit**

```bash
git add package/contents/ui/CostSummaryCard.qml
git commit -m "feat(ui): show insight snippet in CostSummaryCard"
```

---

### Task 8: Configuration & Persistence

**Files:**
- Modify: `package/metadata.json`
- Modify: `package/contents/ui/configGeneral.qml`

- [ ] **Step 1: Add Config Keys**

Add keys for `lastFullInsight`, `lastShortSnippet`, `lastBannerAlert`, `ollamaUrl`, and `ollamaModel`.

- [ ] **Step 2: Add Config UI**

Add inputs for `ollamaUrl` and `ollamaModel` to the settings page.

- [ ] **Step 3: Commit**

```bash
git add package/metadata.json package/contents/ui/configGeneral.qml
git commit -m "feat(config): add settings for Ollama and persist last insights"
```

---

### Task 9: Verification

- [ ] **Step 1: Build and Install**

Run: `just build && just install && just reload`

- [ ] **Step 2: Verify Ollama Connection**

Start Ollama, trigger generation, and verify insights appear in all three locations.

- [ ] **Step 3: Verify Persistence**

Reload Plasma and ensure the last generated insights are still visible.
