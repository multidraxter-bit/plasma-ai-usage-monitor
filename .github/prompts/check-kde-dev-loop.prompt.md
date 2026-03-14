---
name: "Check KDE dev loop"
description: "Decide whether a Plasma AI Monitor change is QML-only, C++ plugin work, or packaging work, then recommend the safest local verification loop."
argument-hint: "Describe the change you want to verify"
agent: "agent"
---
Review the requested Plasma AI Monitor change.

Return:
1. Whether it is QML-only, C++ plugin, packaging, or mixed work
2. The smallest verification loop (`just dev`, `just test`, `just install`, `just reload`, or direct CMake)
3. Which files and install surfaces must stay aligned
4. Any KDE / Plasma packaging rules that should not be broken
