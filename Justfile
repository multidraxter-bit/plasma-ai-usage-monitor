# Justfile — Plasma AI Usage Monitor
# Usage: just <recipe>  (requires https://github.com/casey/just)
# Install: cargo install just  OR  sudo dnf install just

# List all available recipes
default:
    @just --list

# ── Build & Test ──────────────────────────────────────────────────────────────

# Configure and build (Release mode)
build:
    cmake -S . -B build -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release
    cmake --build build --parallel $(nproc)

# Configure and build (Debug mode, enables unit tests)
build-debug:
    cmake -S . -B build -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON
    cmake --build build --parallel $(nproc)

# Run unit tests
test: build-debug
    ctest --test-dir build --output-on-failure

# Check version consistency across all 4 version files
check:
    bash scripts/check_version_consistency.sh
    bash scripts/check_no_hardcoded_versions.sh

# Validate install prerequisites (dependencies + runtime commands)
doctor:
    bash scripts/install_doctor.sh

# Validate and install missing Fedora dependencies automatically
doctor-fix:
    bash scripts/install_doctor.sh --install-missing

# Show installed versions: repo vs user-local vs system
versions:
    bash scripts/show_installed_versions.sh

# Clean the build directory
clean:
    rm -rf build

# ── System-Wide Install (requires sudo) ───────────────────────────────────────

# Build then install to /usr (requires sudo)
install: build
    sudo cmake --install build

# Reinstall: uninstall then install
reinstall: uninstall install

# Uninstall system-wide install using CMake's install manifest
uninstall:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -f build/install_manifest.txt ]; then
        sudo xargs rm -f < build/install_manifest.txt
        sudo ldconfig
        echo "Uninstalled. Removed files listed in build/install_manifest.txt"
    else
        echo "No build/install_manifest.txt found."
        echo "Run 'just install' first, or use 'just copr-remove' for COPR installs."
        exit 1
    fi

# Guided interactive uninstall: detects and removes user-local and/or system installs
uninstall-guided:
    bash uninstall.sh

# ── User-Local Install (no sudo, QML package only) ───────────────────────────

# Install QML package to ~/.local/share/plasma/plasmoids/ (no sudo needed)
install-user:
    bash scripts/install_local_plasmoid.sh

# Uninstall the user-local QML package
uninstall-user:
    kpackagetool6 --type Plasma/Applet --remove com.github.loofi.aiusagemonitor

# Restart plasmashell to pick up QML changes
reload:
    bash scripts/reload_plasma.sh

# One-step dev iteration: install user-local package + reload plasmashell
dev: install-user reload

# Guided bootstrap installer (auto picks COPR on Fedora, source elsewhere)
bootstrap:
    bash scripts/install_bootstrap.sh

# Guided source build/install with dependency auto-fix on Fedora
bootstrap-source:
    bash scripts/install_bootstrap.sh --method source --install-missing

# Guided COPR installation on Fedora
bootstrap-copr:
    bash scripts/install_bootstrap.sh --method copr

# User-local plasmoid-only install + reload (no system plugin install)
bootstrap-user:
    bash scripts/install_bootstrap.sh --method user

# ── COPR / DNF ────────────────────────────────────────────────────────────────

# Enable the COPR repository
copr-enable:
    sudo dnf copr enable loofitheboss/plasma-ai-usage-monitor

# Enable COPR and install the package
copr-install: copr-enable
    sudo dnf install plasma-ai-usage-monitor

# Upgrade the installed COPR package to the latest version
copr-update:
    sudo dnf upgrade plasma-ai-usage-monitor

# Remove the package and the COPR repository
copr-remove:
    sudo dnf remove plasma-ai-usage-monitor
    sudo dnf copr remove loofitheboss/plasma-ai-usage-monitor

# ── Version Management ────────────────────────────────────────────────────────

# Bump version across all 4 files: just bump VERSION=3.3.0
bump VERSION:
    bash scripts/bump_version.sh {{VERSION}}
