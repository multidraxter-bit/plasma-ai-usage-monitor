pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: scheduler

    visible: false
    width: 0
    height: 0

    required property var configuration
    required property var registry
    required property var browserCookies
    required property var claudeCodeMonitor
    required property var codexCliMonitor
    required property var copilotMonitor
    required property var usageDatabase
    required property bool popupOpen

    onPopupOpenChanged: {
        if (popupOpen) {
            refreshAll();
        }
    }

    function effectiveInterval(providerInterval) {
        var seconds = providerInterval > 0 ? providerInterval : configuration.refreshInterval;
        if (!popupOpen) {
            seconds = Math.max(seconds * 4, 900);
        }
        return seconds * 1000;
    }

    function providerJitter(configKey) {
        var text = configKey || "";
        var hash = 0;
        for (var i = 0; i < text.length; i++) {
            hash = (hash + text.charCodeAt(i) * (i + 1)) % 997;
        }
        return hash * 37;
    }

    function backoffMultiplier(provider) {
        if (!provider || !provider.backend) {
            return 1;
        }
        var errors = provider.backend.consecutiveErrors || 0;
        if (errors <= 0) {
            return 1;
        }
        var errorText = (provider.backend.error || "").toString();
        var terminalBackoff = errorText.indexOf("403") >= 0
            || errorText.indexOf("429") >= 0
            || errorText.toLowerCase().indexOf("network") >= 0;
        return terminalBackoff ? Math.min(8, Math.pow(2, Math.min(errors, 3))) : Math.min(4, errors + 1);
    }

    function scheduledInterval(provider) {
        return effectiveInterval(provider.refreshInterval || 0) * backoffMultiplier(provider)
            + providerJitter(provider.configKey);
    }

    function canRefreshBackend(backend, requiresApiKey) {
        return backend && (!requiresApiKey || backend.hasApiKey());
    }

    function refreshProvider(provider) {
        if (!provider || !provider.enabled || !provider.backend) {
            return;
        }
        if (canRefreshBackend(provider.backend, provider.requiresApiKey !== false)) {
            provider.backend.refresh();
        }
    }

    function refreshAll() {
        var providers = registry.allProviders || [];
        for (var i = 0; i < providers.length; i++) {
            refreshProvider(providers[i]);
        }
    }

    function performBrowserSync() {
        if (!configuration.browserSyncEnabled) {
            return;
        }

        if (configuration.claudeCodeEnabled && claudeCodeMonitor.installed) {
            var claudeHeader = browserCookies.getCookieHeader("claude.ai");
            claudeCodeMonitor.syncFromBrowser(claudeHeader, configuration.browserSyncBrowser);
        }

        if (configuration.codexEnabled && codexCliMonitor.installed) {
            var codexHeader = browserCookies.getCookieHeader("chatgpt.com");
            codexCliMonitor.syncFromBrowser(codexHeader, configuration.browserSyncBrowser);
        }
    }

    Instantiator {
        model: scheduler.registry.allProviders

        delegate: Timer {
            required property var modelData

            interval: scheduler.scheduledInterval(modelData)
            running: modelData.enabled
            repeat: true
            onTriggered: scheduler.refreshProvider(modelData)
        }
    }

    Timer {
        interval: Math.max(60, scheduler.configuration.browserSyncInterval) * 1000
        running: scheduler.configuration.browserSyncEnabled
        repeat: true
        onTriggered: scheduler.performBrowserSync()
    }

    Timer {
        interval: 24 * 60 * 60 * 1000
        running: true
        repeat: true
        onTriggered: scheduler.usageDatabase.pruneOldData()
    }

    Timer {
        interval: Math.max(5, scheduler.configuration.autoExportIntervalMinutes) * 60 * 1000
        running: scheduler.configuration.autoExportEnabled
                 && scheduler.configuration.autoExportDirectory !== ""
        repeat: true
        onTriggered: {
            var formats = [];
            if (scheduler.configuration.autoExportFormat === "json") {
                formats = ["json"];
            } else if (scheduler.configuration.autoExportFormat === "csv") {
                formats = ["csv"];
            } else {
                formats = ["json", "csv"];
            }
            scheduler.usageDatabase.exportAllToDirectory(scheduler.configuration.autoExportDirectory, formats);
        }
    }

    Timer {
        interval: 60 * 60 * 1000
        running: scheduler.configuration.copilotEnabled
                 && scheduler.copilotMonitor.githubToken !== ""
                 && scheduler.copilotMonitor.orgName !== ""
        repeat: true
        onTriggered: scheduler.copilotMonitor.fetchOrgMetrics()
    }
}
