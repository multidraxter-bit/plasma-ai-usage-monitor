---
description: 'Use when editing CMake, C++ plugin code, or KDE packaging for Plasma AI Monitor. Covers plain CMake + ECM workflows, Qt6/KF6 integration, and this repo''s no-vcpkg/no-CMakePresets setup.'
applyTo: '**/*.cmake, **/CMakeLists.txt, **/*.cpp, **/*.h, **/*.hpp'
---

# KDE / CMake Guidance

- This repository currently uses **plain CMake + ECM/KDEInstallDirs**, not `vcpkg` manifest mode and not `CMakePresets.json`.
- Prefer repo-owned workflows from `README.md` and `Justfile`: `just build`, `just build-debug`, `just test`, `just dev`, `just install`, `just reload`.
- Keep build advice aligned with the committed root `CMakeLists.txt`:
	- `find_package(Qt6 REQUIRED COMPONENTS Core Qml Quick Network Sql)`
	- `find_package(Plasma REQUIRED)`
	- `find_package(KF6Wallet REQUIRED)`
	- `find_package(KF6Notifications REQUIRED)`
	- `find_package(KF6I18n REQUIRED)`
- Preserve `plasma_install_package(package com.github.loofi.aiusagemonitor)` and the `notifyrc` / AppStream install rules unless the change explicitly targets packaging behavior.
- Use modern target-based CMake APIs when adding new plugin code or tests.
- When changing install paths, respect `KDEInstallDirs` and the existing KF6 install destinations rather than hardcoding paths.
- For QML-only work, prefer the user-local plasmoid loop (`just dev`) instead of suggesting full system installs.
- For C++ plugin changes, note that the repo builds the plugin from `plugin/` and installs the plasmoid package from `package/`; both surfaces may need verification.
