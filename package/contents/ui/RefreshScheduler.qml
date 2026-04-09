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

    function effectiveInterval(providerInterval) {
        return (providerInterval > 0 ? providerInterval : configuration.refreshInterval) * 1000;
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
            interval: scheduler.effectiveInterval(modelData.refreshInterval || 0)
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
        interval: 60 * 60 * 1000
        running: scheduler.configuration.copilotEnabled
                 && scheduler.copilotMonitor.githubToken !== ""
                 && scheduler.copilotMonitor.orgName !== ""
        repeat: true
        onTriggered: scheduler.copilotMonitor.fetchOrgMetrics()
    }
}
