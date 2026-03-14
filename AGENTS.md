# Plasma AI Usage Monitor — Agent Instructions

> KDE Plasma 6 panel widget for monitoring AI API token usage, rate limits, and costs.
> C++20 | Qt6/KF6 | QML | CMake

## Build, Test Commands

```bash
# Preferred workflow (Justfile wraps the plain CMake commands below)
just build
just build-debug
just test
just dev           # QML-only dev loop

# Build
cmake -B build && cmake --build build

# Test
cmake --build build --target test

# Install locally
cmake --install build --prefix ~/.local

# Clean rebuild
rm -rf build && cmake -B build && cmake --build build
```

- Use the plain CMake commands above for direct builds.
- Use `just dev` for QML-only changes and `just install` / `just reload` when C++ plugin code changes.
- This repo currently uses plain CMake + ECM/KDEInstallDirs; do not assume `vcpkg.json` or `CMakePresets.json` exist.

## Project Layout

```text
plugin/
├── contents/
│   ├── ui/
│   │   └── main.qml          # Main QML UI
│   └── config/
│       └── config.qml         # Configuration page
├── metadata.json              # KDE plugin metadata
package/
├── contents/
│   └── ui/
│       └── CompactRepresentation.qml
CMakeLists.txt                 # Build system
```

## Code Style

- C++20 standard, Qt6/KF6 APIs
- QML: follow KDE Human Interface Guidelines
- Formatter: clang-format
- Linter: clang-tidy
- CMake: modern target-based API (`target_link_libraries`, `target_include_directories`)
- Use KDE Frameworks conventions for plugin structure

## Key Conventions

- Use `Q_PROPERTY` for QML-exposed properties
- Use signals/slots for async communication
- Follow KDE Plasma applet lifecycle (init, configChanged, etc.)
- Store settings via `Plasma::Applet::config()`
- Use `KLocalizedString` (i18n) for user-visible strings
- Keep `plasma_install_package(package com.github.loofi.aiusagemonitor)` intact when editing packaging/install rules
- Preserve `notifyrc` and AppStream metainfo installation rules in `CMakeLists.txt`

## Commits

Format: `type(scope): description`
Types: feat, fix, refactor, docs, test, chore, ci, perf, revert, style
Scope: kebab-case, max 100 chars subject.

Prefer repo-owned workflows from `README.md` and `Justfile` when choosing build or install commands.
