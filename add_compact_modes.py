import re

# Update main.xml
with open('package/contents/config/main.xml', 'r') as f:
    main_xml = f.read()
main_xml = main_xml.replace('<default>icon</default>\n            <label>What to show in compact mode: icon, cost, count</label>', '<default>icon</default>\n            <label>What to show in compact mode: icon, cost, count, loofi, dailycost, requests, critical</label>')
with open('package/contents/config/main.xml', 'w') as f:
    f.write(main_xml)

# Update configGeneral.qml
with open('package/contents/ui/configGeneral.qml', 'r') as f:
    config_qml = f.read()

model_str = """
            model: [
                i18n("Icon only"),
                i18n("Total cost"),
                i18n("Active providers count"),
                i18n("Loofi server KPIs"),
                i18n("Daily cost"),
                i18n("Remaining requests"),
                i18n("Most critical provider")
            ]
"""
config_qml = re.sub(r'model: \[\n.*?\n\s+\]', model_str.strip(), config_qml, flags=re.DOTALL)

switch_idx = """
            currentIndex: {
                switch (generalPage.cfg_compactDisplayMode) {
                case "cost": return 1;
                case "count": return 2;
                case "loofi": return 3;
                case "dailycost": return 4;
                case "requests": return 5;
                case "critical": return 6;
                default: return 0;
                }
            }
"""
config_qml = re.sub(r'currentIndex: \{\n\s+switch.*?\}\n\s+\}', switch_idx.strip(), config_qml, flags=re.DOTALL)

on_idx_changed = """
            onCurrentIndexChanged: {
                switch (currentIndex) {
                case 1: generalPage.cfg_compactDisplayMode = "cost"; break;
                case 2: generalPage.cfg_compactDisplayMode = "count"; break;
                case 3: generalPage.cfg_compactDisplayMode = "loofi"; break;
                case 4: generalPage.cfg_compactDisplayMode = "dailycost"; break;
                case 5: generalPage.cfg_compactDisplayMode = "requests"; break;
                case 6: generalPage.cfg_compactDisplayMode = "critical"; break;
                default: generalPage.cfg_compactDisplayMode = "icon"; break;
                }
            }
"""
config_qml = re.sub(r'onCurrentIndexChanged: \{\n\s+switch.*?\}\n\s+\}', on_idx_changed.strip(), config_qml, flags=re.DOTALL)

with open('package/contents/ui/configGeneral.qml', 'w') as f:
    f.write(config_qml)

# Update CompactRepresentation.qml
with open('package/contents/ui/CompactRepresentation.qml', 'r') as f:
    compact_qml = f.read()

# Add logic for new modes
new_modes = """
    readonly property double compactDailyCost: {
        var total = 0;
        for (var i = 0; i < providers.length; i++) {
            var provider = providers[i];
            if (provider && provider.enabled && provider.backend && provider.backend.connected)
                total += provider.backend.dailyCost ?? 0;
        }
        return total;
    }

    readonly property int totalRequestsRemaining: {
        var req = 0;
        for (var i = 0; i < providers.length; i++) {
            var p = providers[i];
            if (p && p.enabled && p.backend && p.backend.connected && p.backend.rateLimitRequestsRemaining > 0)
                req += p.backend.rateLimitRequestsRemaining;
        }
        return req;
    }

    readonly property string criticalProviderText: {
        var worst = "";
        var worstPercent = 0;
        for (var i = 0; i < providers.length; i++) {
            var p = providers[i];
            if (p && p.enabled && p.backend && p.backend.connected && p.backend.rateLimitRequests > 0) {
                var pct = ((p.backend.rateLimitRequests - p.backend.rateLimitRequestsRemaining) / p.backend.rateLimitRequests) * 100;
                if (pct > worstPercent) {
                    worstPercent = pct;
                    worst = p.name;
                }
            }
        }
        return worst !== "" ? worst + " (" + Math.round(worstPercent) + "%)" : i18n("All healthy");
    }

    // Daily cost mode
    PlasmaComponents.Label {
        anchors.fill: parent
        visible: compactRoot.displayMode === "dailycost"
        text: "$" + compactRoot.compactDailyCost.toFixed(2)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.bold: true
        font.pointSize: Math.max(Kirigami.Theme.smallFont.pointSize, height * 0.35)
        fontSizeMode: Text.Fit
    }

    // Requests mode
    PlasmaComponents.Label {
        anchors.fill: parent
        visible: compactRoot.displayMode === "requests"
        text: compactRoot.totalRequestsRemaining + " req"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.bold: true
        font.pointSize: Math.max(Kirigami.Theme.smallFont.pointSize, height * 0.35)
        fontSizeMode: Text.Fit
    }

    // Critical mode
    PlasmaComponents.Label {
        anchors.fill: parent
        visible: compactRoot.displayMode === "critical"
        text: compactRoot.criticalProviderText
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.bold: true
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        fontSizeMode: Text.Fit
        wrapMode: Text.WordWrap
    }
"""
compact_qml = compact_qml.replace('    // Spinning indicator when loading (all modes)', new_modes + '\n    // Spinning indicator when loading (all modes)')

with open('package/contents/ui/CompactRepresentation.qml', 'w') as f:
    f.write(compact_qml)

# Update main.qml context menu
with open('package/contents/ui/main.qml', 'r') as f:
    main_qml = f.read()

context_actions = """
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Refresh All")
            icon.name: "view-refresh"
            onTriggered: root.refreshAll()
        },
        PlasmaCore.Action {
            text: i18n("Configure Settings")
            icon.name: "configure"
            onTriggered: plasmoid.internalAction("configure").trigger()
        },
        PlasmaCore.Action {
            text: i18n("Open Dashboard")
            icon.name: "window-new"
            onTriggered: plasmoid.expanded = true
        },
        PlasmaCore.Action {
            text: plasmoid.configuration.alertsEnabled ? i18n("Mute Alerts") : i18n("Unmute Alerts")
            icon.name: plasmoid.configuration.alertsEnabled ? "notifications-disabled" : "notifications"
            onTriggered: plasmoid.configuration.alertsEnabled = !plasmoid.configuration.alertsEnabled
        }
    ]
"""
main_qml = re.sub(r'Plasmoid\.contextualActions: \[\n.*?\]', context_actions.strip(), main_qml, flags=re.DOTALL)

with open('package/contents/ui/main.qml', 'w') as f:
    f.write(main_qml)

