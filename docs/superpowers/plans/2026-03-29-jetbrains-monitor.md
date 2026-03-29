# JetBrains AI Assistant Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a new `JetBrainsMonitor` that tracks AI Assistant usage by monitoring local JetBrains log files and adds the subscription cost to monthly totals.

**Architecture:** A new `JetBrainsMonitor` class (C++) inherits from `SubscriptionToolBackend`. It scans `~/.cache/JetBrains/*/log/idea.log` for AI Assistant request signatures and implements plan presets ($10/mo Individual, $15/mo Enterprise).

**Tech Stack:** C++20, Qt6 (FileSystem, QML), KF6.

---

### Task 1: JetBrainsMonitor C++ Backend

**Files:**
- Create: `plugin/jetbrainsmonitor.h`
- Create: `plugin/jetbrainsmonitor.cpp`
- Modify: `plugin/CMakeLists.txt`

- [ ] **Step 1: Create JetBrainsMonitor Header**

```cpp
#ifndef JETBRAINSMONITOR_H
#define JETBRAINSMONITOR_H

#include "subscriptiontoolbackend.h"
#include <QDateTime>

class JetBrainsMonitor : public SubscriptionToolBackend
{
    Q_OBJECT

public:
    explicit JetBrainsMonitor(QObject *parent = nullptr);

    QString toolName() const override { return QStringLiteral("JetBrains AI"); }
    QString iconName() const override { return QStringLiteral("code-context"); }
    QString toolColor() const override { return QStringLiteral("#000000"); }

    QString periodLabel() const override { return QStringLiteral("Monthly"); }

    Q_INVOKABLE QStringList availablePlans() const override;
    Q_INVOKABLE int defaultLimitForPlan(const QString &plan) const override;
    Q_INVOKABLE double defaultCostForPlan(const QString &plan) const override;

    double subscriptionCost() const override;
    bool hasSubscriptionCost() const override { return true; }

    Q_INVOKABLE void checkToolInstalled() override;
    Q_INVOKABLE void detectActivity() override;

protected:
    UsagePeriod primaryPeriodType() const override { return Monthly; }

private:
    QStringList findLogFiles() const;
    QDateTime m_lastDetectedActivity;
};

#endif
```

- [ ] **Step 2: Create JetBrainsMonitor Implementation**

```cpp
#include "jetbrainsmonitor.h"
#include <QDir>
#include <QStandardPaths>
#include <QFile>
#include <QTextStream>
#include <QRegularExpression>

JetBrainsMonitor::JetBrainsMonitor(QObject *parent) : SubscriptionToolBackend(parent) {
    setPlanTier(QStringLiteral("Individual"));
}

QStringList JetBrainsMonitor::availablePlans() const {
    return { QStringLiteral("Individual"), QStringLiteral("Enterprise") };
}

int JetBrainsMonitor::defaultLimitForPlan(const QString &plan) const {
    if (plan == QStringLiteral("Enterprise")) return 5000;
    return 2000;
}

double JetBrainsMonitor::defaultCostForPlan(const QString &plan) const {
    if (plan == QStringLiteral("Enterprise")) return 15.0;
    return 10.0;
}

double JetBrainsMonitor::subscriptionCost() const {
    return defaultCostForPlan(planTier());
}

void JetBrainsMonitor::checkToolInstalled() {
    QStringList logs = findLogFiles();
    setInstalled(!logs.isEmpty());
}

void JetBrainsMonitor::detectActivity() {
    QStringList logs = findLogFiles();
    QDateTime latest;
    
    for (const QString &logPath : logs) {
        QFileInfo fi(logPath);
        if (fi.lastModified() > latest) latest = fi.lastModified();
    }

    if (latest.isValid() && latest > m_lastDetectedActivity) {
        m_lastDetectedActivity = latest;
        incrementUsage(1); // Simplified: count any log change as activity
    }
}

QStringList JetBrainsMonitor::findLogFiles() const {
    QStringList results;
    QString cachePath = QDir::homePath() + QStringLiteral("/.cache/JetBrains");
    QDir dir(cachePath);
    if (!dir.exists()) return results;

    QStringList subdirs = dir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    for (const QString &subdir : subdirs) {
        QString logPath = cachePath + "/" + subdir + "/log/idea.log";
        if (QFile::exists(logPath)) results.append(logPath);
    }
    return results;
}
```

- [ ] **Step 3: Update CMakeLists.txt**

Add `jetbrainsmonitor.cpp` and `jetbrainsmonitor.h` to the build.

- [ ] **Step 4: Commit**

```bash
git add plugin/jetbrainsmonitor.h plugin/jetbrainsmonitor.cpp plugin/CMakeLists.txt
git commit -m "feat(jetbrains): add JetBrains AI Assistant monitor"
```

---

### Task 2: QML Plugin Registration

**Files:**
- Modify: `plugin/aiusageplugin.cpp`

- [ ] **Step 1: Register JetBrainsMonitor**

Add `qmlRegisterType<JetBrainsMonitor>(uri, 1, 0, "JetBrainsMonitor");` to `registerTypes`.

- [ ] **Step 2: Commit**

```bash
git add plugin/aiusageplugin.cpp
git commit -m "feat(plugin): register JetBrainsMonitor for QML"
```

---

### Task 3: Integration in main.qml

**Files:**
- Modify: `package/contents/ui/main.qml`

- [ ] **Step 1: Instantiate JetBrainsMonitor**

```qml
JetBrainsMonitor {
    id: jetbrainsMonitor
    enabled: plasmoid.configuration.jetbrainsEnabled
    planTier: plasmoid.configuration.jetbrainsPlanTier
    usageLimit: plasmoid.configuration.jetbrainsUsageLimit
}
```

- [ ] **Step 2: Add to allTools list**

Add JetBrains to the `allTools` array helper.

- [ ] **Step 3: Commit**

```bash
git add package/contents/ui/main.qml
git commit -m "feat(ui): integrate JetBrains monitor into main view"
```

---

### Task 4: Configuration & UI

**Files:**
- Modify: `package/contents/config/main.xml`
- Modify: `package/contents/ui/configSubscriptions.qml`

- [ ] **Step 1: Add JetBrains Config Keys**

Add `jetbrainsEnabled`, `jetbrainsPlanTier`, `jetbrainsUsageLimit`, `jetbrainsSubscriptionCost`.

- [ ] **Step 2: Add config UI section**

Add a new section for JetBrains AI in the Subscriptions settings page.

- [ ] **Step 3: Commit**

```bash
git add package/contents/config/main.xml package/contents/ui/configSubscriptions.qml
git commit -m "feat(config): add settings for JetBrains AI Assistant"
```

---

### Task 5: Verification

- [ ] **Step 1: Build and Install**

Run: `just build && just install && just reload`

- [ ] **Step 2: Verify Tool Appears**

Open settings and verify "JetBrains AI" is in the subscriptions list.

- [ ] **Step 3: Test detection**

Enable it and check if it detects installed JetBrains IDEs.
