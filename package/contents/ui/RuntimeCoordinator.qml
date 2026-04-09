import QtQuick

Item {
    id: runtime

    visible: false
    width: 0
    height: 0

    required property var configuration
    required property var registry
    required property var secrets
    required property var usageDatabase
    required property var notificationController
    required property var scheduler
    required property var claudeCodeMonitor
    required property var codexCliMonitor
    required property var copilotMonitor

    function loadApiKeys() {
        var providers = registry.allProviders || [];
        for (var i = 0; i < providers.length; i++) {
            var provider = providers[i];
            if (provider.enabled && provider.requiresApiKey !== false) {
                var key = secrets.getKey(provider.configKey);
                if (key) {
                    provider.backend.setApiKey(key);
                }
            }
        }

        scheduler.refreshAll();
    }

    function recordProviderSnapshot(providerName, backend) {
        if (!usageDatabase.enabled || !backend) {
            return;
        }

        var activeModel = "";
        if (backend.model !== undefined && backend.model !== null) {
            activeModel = backend.model;
        }

        usageDatabase.recordSnapshot(
            providerName,
            backend.inputTokens,
            backend.outputTokens,
            backend.requestCount,
            backend.cost,
            backend.dailyCost,
            backend.monthlyCost,
            backend.rateLimitRequests,
            backend.rateLimitRequestsRemaining,
            backend.rateLimitTokens,
            backend.rateLimitTokensRemaining,
            activeModel,
            backend.isEstimatedCost
        );
    }

    function recordToolUsageSnapshot(monitor) {
        if (!usageDatabase.enabled || !monitor) {
            return;
        }

        usageDatabase.recordToolSnapshot(
            monitor.toolName,
            monitor.usageCount,
            monitor.usageLimit,
            monitor.periodLabel,
            monitor.planTier,
            monitor.limitReached
        );
    }

    function connectProviderSignals() {
        var providers = registry.allProviders || [];
        for (var i = 0; i < providers.length; i++) {
            var provider = providers[i];
            var backend = provider.backend;

            backend.quotaWarning.connect(notificationController.handleQuotaWarning);
            backend.budgetWarning.connect(notificationController.handleBudgetWarning);
            backend.budgetExceeded.connect(notificationController.handleBudgetExceeded);
            backend.providerDisconnected.connect(notificationController.handleProviderDisconnected);
            backend.providerReconnected.connect(notificationController.handleProviderReconnected);
            backend.errorChanged.connect(makeErrorHandler(provider.name, provider.configKey, backend));
            backend.dataUpdated.connect(makeSnapshotHandler(provider.dbName, backend));
        }
    }

    function connectToolSignals() {
        var tools = registry.allSubscriptionTools || [];
        for (var i = 0; i < tools.length; i++) {
            var monitor = tools[i].monitor;
            monitor.limitWarning.connect(notificationController.handleToolLimitWarning);
            monitor.limitReached.connect(notificationController.handleToolLimitReached);
            monitor.syncDiagnostic.connect(notificationController.handleToolSyncDiagnostic);
            monitor.usageUpdated.connect(makeToolSnapshotHandler(monitor));
        }
    }

    function makeErrorHandler(displayName, configKey, backend) {
        return function() {
            if (backend.error
                    && configuration.notifyOnError
                    && configuration[configKey + "NotificationsEnabled"]) {
                notificationController.sendErrorNotification(i18n("%1 Error", displayName), backend.error);
            }
        };
    }

    function makeSnapshotHandler(dbName, backend) {
        return function() {
            recordProviderSnapshot(dbName, backend);
        };
    }

    function makeToolSnapshotHandler(monitor) {
        return function() {
            recordToolUsageSnapshot(monitor);
        };
    }

    Component.onCompleted: {
        connectProviderSignals();
        connectToolSignals();
        usageDatabase.init();
        startupTimer.start();
        initialPruneTimer.start();
        if (configuration.browserSyncEnabled) {
            initialSyncTimer.start();
        }
    }

    Connections {
        target: runtime.secrets

        function onWalletOpenChanged() {
            if (runtime.secrets.walletOpen) {
                runtime.loadApiKeys();
            }
        }
    }

    Connections {
        target: runtime.configuration

        function onOpenaiEnabledChanged() { runtime.loadApiKeys(); }
        function onAnthropicEnabledChanged() { runtime.loadApiKeys(); }
        function onGoogleEnabledChanged() { runtime.loadApiKeys(); }
        function onMistralEnabledChanged() { runtime.loadApiKeys(); }
        function onDeepseekEnabledChanged() { runtime.loadApiKeys(); }
        function onGroqEnabledChanged() { runtime.loadApiKeys(); }
        function onXaiEnabledChanged() { runtime.loadApiKeys(); }
        function onOllamaEnabledChanged() { runtime.loadApiKeys(); }
        function onOpenrouterEnabledChanged() { runtime.loadApiKeys(); }
        function onTogetherEnabledChanged() { runtime.loadApiKeys(); }
        function onCohereEnabledChanged() { runtime.loadApiKeys(); }
        function onGoogleveoEnabledChanged() { runtime.loadApiKeys(); }
        function onAzureEnabledChanged() { runtime.loadApiKeys(); }
        function onLoofiEnabledChanged() { runtime.scheduler.refreshAll(); }
        function onLoofiServerUrlChanged() {
            var loofiProvider = runtime.registry.providerByConfigKey("loofi");
            if (runtime.configuration.loofiEnabled && loofiProvider && loofiProvider.backend) {
                loofiProvider.backend.refresh();
            }
        }

        function onClaudeCodeEnabledChanged() {
            if (runtime.claudeCodeMonitor.enabled) {
                runtime.claudeCodeMonitor.checkToolInstalled();
            }
        }

        function onCodexEnabledChanged() {
            if (runtime.codexCliMonitor.enabled) {
                runtime.codexCliMonitor.checkToolInstalled();
            }
        }

        function onCopilotEnabledChanged() {
            if (runtime.copilotMonitor.enabled) {
                runtime.copilotMonitor.checkToolInstalled();
            }
        }
    }

    Timer {
        id: startupTimer
        interval: 200
        repeat: false
        onTriggered: {
            if (runtime.secrets.walletOpen) {
                runtime.loadApiKeys();
            } else {
                runtime.scheduler.refreshAll();
            }
        }
    }

    Timer {
        id: initialPruneTimer
        interval: 2000
        repeat: false
        onTriggered: runtime.usageDatabase.pruneOldData()
    }

    Timer {
        id: initialSyncTimer
        interval: 5000
        repeat: false
        onTriggered: runtime.scheduler.performBrowserSync()
    }
}
