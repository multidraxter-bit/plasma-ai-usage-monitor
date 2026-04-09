import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import com.github.loofi.aiusagemonitor 1.0

PlasmoidItem {
    id: root

    switchWidth: Kirigami.Units.gridUnit * 12
    switchHeight: Kirigami.Units.gridUnit * 12

    toolTipMainText: i18n("AI Usage Monitor")
    toolTipSubText: {
        var lines = [];
        var providers = root.allProviders || [];
        for (var i = 0; i < providers.length; i++) {
            var provider = providers[i];
            if (provider.enabled && provider.backend && provider.backend.connected) {
                var info = provider.name + ": ";
                if (provider.configKey === "loofi") {
                    info += (provider.backend.activeModel || i18n("No model")) + " | ";
                    info += (provider.backend.trainingStage || i18n("idle")) + " | ";
                    info += i18n("GPU %1%", Math.round(Math.max(0, provider.backend.gpuMemoryPct || 0))) + " | ";
                    info += i18n("%1 req/24h", root.formatCompactMetric(provider.backend.requestCount || 0));
                } else {
                    if (provider.backend.cost > 0) {
                        info += "$" + provider.backend.cost.toFixed(2) + " | ";
                    }
                    info += provider.backend.rateLimitRequestsRemaining + " req left";
                }
                lines.push(info);
            }
        }
        return lines.length > 0 ? lines.join("\n") : i18n("Click to configure providers");
    }

    property alias openai: openaiBackend
    property alias anthropic: anthropicBackend
    property alias google: googleBackend
    property alias mistral: mistralBackend
    property alias deepseek: deepseekBackend
    property alias groq: groqBackend
    property alias xai: xaiBackend
    property alias ollama: ollamaBackend
    property alias openrouter: openrouterBackend
    property alias together: togetherBackend
    property alias cohere: cohereBackend
    property alias googleveo: googleveoBackend
    property alias azure: azureBackend
    property alias loofi: loofiBackend
    property alias usageDb: usageDatabase

    property alias claudeCode: claudeCodeMonitor
    property alias codexCli: codexCliMonitor
    property alias copilot: copilotMonitor
    property alias intelligenceEngine: analystIntelligence

    readonly property var allProviders: providerRegistry.allProviders
    readonly property var allSubscriptionTools: providerRegistry.allSubscriptionTools
    readonly property int enabledToolCount: providerRegistry.enabledToolCount
    readonly property int connectedCount: providerRegistry.connectedCount
    readonly property double totalCost: providerRegistry.totalCost

    function formatCompactMetric(value) {
        return providerRegistry.formatCompactMetric(value);
    }

    function refreshAll() {
        refreshScheduler.refreshAll();
    }

    function performBrowserSync() {
        refreshScheduler.performBrowserSync();
    }

    function generateAnalystInsight() {
        if (!analystIntelligence) {
            return;
        }

        var activity = usageDatabase.getYearlyActivity(plasmoid.configuration.analystIntensityMode);
        var efficiency = usageDatabase.getEfficiencySeries(14);
        var overview = usageDatabase.getAnalystOverview(30);

        analystIntelligence.generateInsight(activity.days, efficiency, overview);
    }

    SecretsManager {
        id: secrets
    }

    UsageDatabase {
        id: usageDatabase
        enabled: plasmoid.configuration.historyEnabled
        retentionDays: plasmoid.configuration.historyRetentionDays
    }

    OpenAIProvider {
        id: openaiBackend
        model: plasmoid.configuration.openaiModel
        projectId: plasmoid.configuration.openaiProjectId
        customBaseUrl: plasmoid.configuration.openaiCustomBaseUrl
        dailyBudget: plasmoid.configuration.openaiDailyBudget / 100.0
        monthlyBudget: plasmoid.configuration.openaiMonthlyBudget / 100.0
        budgetWarningPercent: plasmoid.configuration.budgetWarningPercent
    }

    AzureOpenAIProvider {
        id: azureBackend
        model: plasmoid.configuration.azureModel
        deploymentId: plasmoid.configuration.azureDeploymentId
        customBaseUrl: plasmoid.configuration.azureCustomBaseUrl
        dailyBudget: plasmoid.configuration.azureDailyBudget / 100.0
        monthlyBudget: plasmoid.configuration.azureMonthlyBudget / 100.0
        budgetWarningPercent: plasmoid.configuration.budgetWarningPercent
    }

    AnthropicProvider {
        id: anthropicBackend
        model: plasmoid.configuration.anthropicModel
        customBaseUrl: plasmoid.configuration.anthropicCustomBaseUrl
        dailyBudget: plasmoid.configuration.anthropicDailyBudget / 100.0
        monthlyBudget: plasmoid.configuration.anthropicMonthlyBudget / 100.0
        budgetWarningPercent: plasmoid.configuration.budgetWarningPercent
    }

    GoogleProvider {
        id: googleBackend
        model: plasmoid.configuration.googleModel
        tier: plasmoid.configuration.googleTier
        customBaseUrl: plasmoid.configuration.googleCustomBaseUrl
        dailyBudget: plasmoid.configuration.googleDailyBudget / 100.0
        monthlyBudget: plasmoid.configuration.googleMonthlyBudget / 100.0
        budgetWarningPercent: plasmoid.configuration.budgetWarningPercent
    }

    MistralProvider {
        id: mistralBackend
        model: plasmoid.configuration.mistralModel
        customBaseUrl: plasmoid.configuration.mistralCustomBaseUrl
        dailyBudget: plasmoid.configuration.mistralDailyBudget / 100.0
        monthlyBudget: plasmoid.configuration.mistralMonthlyBudget / 100.0
        budgetWarningPercent: plasmoid.configuration.budgetWarningPercent
    }

    DeepSeekProvider {
        id: deepseekBackend
        model: plasmoid.configuration.deepseekModel
        customBaseUrl: plasmoid.configuration.deepseekCustomBaseUrl
        dailyBudget: plasmoid.configuration.deepseekDailyBudget / 100.0
        monthlyBudget: plasmoid.configuration.deepseekMonthlyBudget / 100.0
        budgetWarningPercent: plasmoid.configuration.budgetWarningPercent
    }

    GroqProvider {
        id: groqBackend
        model: plasmoid.configuration.groqModel
        customBaseUrl: plasmoid.configuration.groqCustomBaseUrl
        dailyBudget: plasmoid.configuration.groqDailyBudget / 100.0
        monthlyBudget: plasmoid.configuration.groqMonthlyBudget / 100.0
        budgetWarningPercent: plasmoid.configuration.budgetWarningPercent
    }

    XAIProvider {
        id: xaiBackend
        model: plasmoid.configuration.xaiModel
        customBaseUrl: plasmoid.configuration.xaiCustomBaseUrl
        dailyBudget: plasmoid.configuration.xaiDailyBudget / 100.0
        monthlyBudget: plasmoid.configuration.xaiMonthlyBudget / 100.0
        budgetWarningPercent: plasmoid.configuration.budgetWarningPercent
    }

    OllamaCloudProvider {
        id: ollamaBackend
        model: plasmoid.configuration.ollamaModel
        customBaseUrl: plasmoid.configuration.ollamaCustomBaseUrl
        dailyBudget: plasmoid.configuration.ollamaDailyBudget / 100.0
        monthlyBudget: plasmoid.configuration.ollamaMonthlyBudget / 100.0
        budgetWarningPercent: plasmoid.configuration.budgetWarningPercent
    }

    OpenRouterProvider {
        id: openrouterBackend
        model: plasmoid.configuration.openrouterModel
        customBaseUrl: plasmoid.configuration.openrouterCustomBaseUrl
        dailyBudget: plasmoid.configuration.openrouterDailyBudget / 100.0
        monthlyBudget: plasmoid.configuration.openrouterMonthlyBudget / 100.0
        budgetWarningPercent: plasmoid.configuration.budgetWarningPercent
    }

    TogetherProvider {
        id: togetherBackend
        model: plasmoid.configuration.togetherModel
        customBaseUrl: plasmoid.configuration.togetherCustomBaseUrl
        dailyBudget: plasmoid.configuration.togetherDailyBudget / 100.0
        monthlyBudget: plasmoid.configuration.togetherMonthlyBudget / 100.0
        budgetWarningPercent: plasmoid.configuration.budgetWarningPercent
    }

    CohereProvider {
        id: cohereBackend
        model: plasmoid.configuration.cohereModel
        customBaseUrl: plasmoid.configuration.cohereCustomBaseUrl
        dailyBudget: plasmoid.configuration.cohereDailyBudget / 100.0
        monthlyBudget: plasmoid.configuration.cohereMonthlyBudget / 100.0
        budgetWarningPercent: plasmoid.configuration.budgetWarningPercent
    }

    GoogleVeoProvider {
        id: googleveoBackend
        model: plasmoid.configuration.googleveoModel
        tier: plasmoid.configuration.googleveoTier
        customBaseUrl: plasmoid.configuration.googleveoCustomBaseUrl
        dailyBudget: plasmoid.configuration.googleveoDailyBudget / 100.0
        monthlyBudget: plasmoid.configuration.googleveoMonthlyBudget / 100.0
        budgetWarningPercent: plasmoid.configuration.budgetWarningPercent
    }

    LoofiServerProvider {
        id: loofiBackend
        customBaseUrl: plasmoid.configuration.loofiServerUrl
    }

    BrowserCookieExtractor {
        id: browserCookies
        browserType: plasmoid.configuration.browserSyncBrowser
        selectedFirefoxProfile: plasmoid.configuration.browserSyncProfile
    }

    ClaudeCodeMonitor {
        id: claudeCodeMonitor
        enabled: plasmoid.configuration.claudeCodeEnabled
        usageLimit: plasmoid.configuration.claudeCodeCustomLimit

        Component.onCompleted: {
            checkToolInstalled();
            syncEnabled = Qt.binding(function() { return plasmoid.configuration.browserSyncEnabled; });
            var plans = availablePlans();
            var idx = plasmoid.configuration.claudeCodePlan;
            if (idx >= 0 && idx < plans.length) {
                planTier = plans[idx];
                if (usageLimit === 0) {
                    usageLimit = defaultLimitForPlan(plans[idx]);
                }
                if (hasSecondaryLimit) {
                    secondaryUsageLimit = defaultSecondaryLimitForPlan(plans[idx]);
                }
            }
        }
    }

    CodexCliMonitor {
        id: codexCliMonitor
        enabled: plasmoid.configuration.codexEnabled
        usageLimit: plasmoid.configuration.codexCustomLimit

        Component.onCompleted: {
            checkToolInstalled();
            syncEnabled = Qt.binding(function() { return plasmoid.configuration.browserSyncEnabled; });
            var plans = availablePlans();
            var idx = plasmoid.configuration.codexPlan;
            if (idx >= 0 && idx < plans.length) {
                planTier = plans[idx];
                if (usageLimit === 0) {
                    usageLimit = defaultLimitForPlan(plans[idx]);
                }
                if (hasSecondaryLimit) {
                    secondaryUsageLimit = defaultSecondaryLimitForPlan(plans[idx]);
                }
            }
        }
    }

    CopilotMonitor {
        id: copilotMonitor
        enabled: plasmoid.configuration.copilotEnabled
        usageLimit: plasmoid.configuration.copilotCustomLimit
        orgName: plasmoid.configuration.copilotOrgName

        Component.onCompleted: {
            checkToolInstalled();
            var plans = availablePlans();
            var idx = plasmoid.configuration.copilotPlan;
            if (idx >= 0 && idx < plans.length) {
                planTier = plans[idx];
                if (usageLimit === 0) {
                    usageLimit = defaultLimitForPlan(plans[idx]);
                }
            }
            if (secrets.walletOpen && secrets.hasKey("copilot_github")) {
                githubToken = secrets.getKey("copilot_github");
            }
            fetchOrgMetrics();
        }
    }

    ProviderRegistry {
        id: providerRegistry
        configuration: plasmoid.configuration

        openaiBackend: openaiBackend
        anthropicBackend: anthropicBackend
        googleBackend: googleBackend
        mistralBackend: mistralBackend
        deepseekBackend: deepseekBackend
        groqBackend: groqBackend
        xaiBackend: xaiBackend
        ollamaBackend: ollamaBackend
        openrouterBackend: openrouterBackend
        togetherBackend: togetherBackend
        cohereBackend: cohereBackend
        googleveoBackend: googleveoBackend
        azureBackend: azureBackend
        loofiBackend: loofiBackend

        claudeCodeMonitor: claudeCodeMonitor
        codexCliMonitor: codexCliMonitor
        copilotMonitor: copilotMonitor
    }

    NotificationController {
        id: notificationController
        configuration: plasmoid.configuration
        registry: providerRegistry
        usageDatabase: usageDatabase
    }

    RefreshScheduler {
        id: refreshScheduler
        configuration: plasmoid.configuration
        registry: providerRegistry
        browserCookies: browserCookies
        claudeCodeMonitor: claudeCodeMonitor
        codexCliMonitor: codexCliMonitor
        copilotMonitor: copilotMonitor
        usageDatabase: usageDatabase
    }

    RuntimeCoordinator {
        id: runtimeCoordinator
        configuration: plasmoid.configuration
        registry: providerRegistry
        secrets: secrets
        usageDatabase: usageDatabase
        notificationController: notificationController
        scheduler: refreshScheduler
        claudeCodeMonitor: claudeCodeMonitor
        codexCliMonitor: codexCliMonitor
        copilotMonitor: copilotMonitor
    }

    UpdateChecker {
        id: updateChecker
        currentVersion: (plasmoid.metaData && plasmoid.metaData.version)
                        ? plasmoid.metaData.version
                        : AppInfo.version
        checkIntervalHours: plasmoid.configuration.updateCheckInterval || 12

        onUpdateAvailable: function(latestVersion, releaseUrl) {
            notificationController.sendUpdateAvailable(latestVersion, releaseUrl);
        }
    }

    IntelligenceEngine {
        id: analystIntelligence
    }

    compactRepresentation: CompactRepresentation {}
    fullRepresentation: FullRepresentation {}

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Refresh All")
            icon.name: "view-refresh"
            onTriggered: root.refreshAll()
        }
    ]
}
