# Ollama Monitoring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate local Ollama server monitoring (status, loaded models, VRAM usage) into the dashboard.

**Architecture:** Create a new `OllamaProvider` C++ class that polls the local Ollama API. Create a specialized `OllamaCard.qml` for resource-centric visualization.

**Tech Stack:** C++20, Qt6 (Network, JSON), QML

---

### Task 1: OllamaProvider Backend (C++)

**Files:**
- Create: `plugin/ollamaprovider.h`
- Create: `plugin/ollamaprovider.cpp`

- [ ] **Step 1: Create ollamaprovider.h**
Implement the header inheriting from `ProviderBackend`. Add properties for `activeModels` (QVariantList), `totalMemory` (double), and `vramMemory` (double).

- [ ] **Step 2: Create ollamaprovider.cpp**
Implement polling of `http://localhost:11434/api/ps`.
Parse the response:
```json
{
  "models": [
    {
      "name": "llama3:latest",
      "size": 4661224677,
      "vram_size": 4661224677,
      "expires_at": "2024-06-04T14:36:17.156930449-07:00"
    }
  ]
}
```
Calculate aggregate memory and update the model list.

- [ ] **Step 3: Commit**
```bash
git add plugin/ollamaprovider.*
git commit -m "feat(cpp): implement OllamaProvider backend"
```

### Task 2: Registration & Configuration

**Files:**
- Modify: `plugin/CMakeLists.txt`
- Modify: `plugin/aiusageplugin.cpp`
- Modify: `package/contents/config/main.xml`

- [ ] **Step 1: Update CMakeLists.txt**
Add `ollamaprovider.cpp` and `ollamaprovider.h` to the build.

- [ ] **Step 2: Register type in aiusageplugin.cpp**
```cpp
qmlRegisterType<OllamaProvider>(uri, 1, 0, "OllamaProvider");
```

- [ ] **Step 3: Add config keys to main.xml**
Add `ollamaEnabled` (Bool, default false) and `ollamaServerUrl` (String, default http://localhost:11434) to the `Providers` group.

- [ ] **Step 4: Commit**
```bash
git add plugin/CMakeLists.txt plugin/aiusageplugin.cpp package/contents/config/main.xml
git commit -m "chore: register Ollama provider and config keys"
```

### Task 3: UI Implementation

**Files:**
- Create: `package/contents/ui/OllamaCard.qml`
- Modify: `package/contents/ui/main.qml`
- Modify: `package/contents/ui/FullRepresentation.qml`

- [ ] **Step 1: Create OllamaCard.qml**
Design a card that shows:
- "Online/Offline" status.
- A list of active models.
- Progress bars for VRAM usage (if `vram_size > 0`).

- [ ] **Step 2: Wire into main.qml**
Instantiate `OllamaProvider` and add it to the `allProviders` list.

- [ ] **Step 3: Add to FullRepresentation.qml**
Ensure the `OllamaCard` renders in the "Live" tab alongside other provider cards.

- [ ] **Step 4: Commit**
```bash
git add package/contents/ui/OllamaCard.qml package/contents/ui/main.qml package/contents/ui/FullRepresentation.qml
git commit -m "feat(ui): add Ollama monitoring card to dashboard"
```
