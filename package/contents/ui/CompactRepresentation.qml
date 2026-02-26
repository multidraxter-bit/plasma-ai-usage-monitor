import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

MouseArea {
    id: compactRoot

    readonly property var providers: root.allProviders ?? []
    readonly property var subscriptionTools: root.allSubscriptionTools ?? []
    readonly property double compactTotalCost: {
        var total = 0;
        for (var i = 0; i < providers.length; i++) {
            var provider = providers[i];
            if (provider && provider.enabled && provider.backend && provider.backend.connected)
                total += provider.backend.cost ?? 0;
        }
        for (var j = 0; j < subscriptionTools.length; j++) {
            var tool = subscriptionTools[j];
            if (tool && tool.enabled && tool.monitor && tool.monitor.hasSubscriptionCost)
                total += tool.monitor.subscriptionCost ?? 0;
        }
        return total;
    }

    Accessible.role: Accessible.Button
    Accessible.name: i18n("AI Usage Monitor: %1 providers connected", root.connectedCount ?? 0)

    readonly property bool hasWarning: {
        for (var i = 0; i < providers.length; i++) {
            var p = providers[i];
            if (p && p.enabled && p.backend && p.backend.connected && p.backend.rateLimitRequests > 0) {
                var usedPercent = ((p.backend.rateLimitRequests - p.backend.rateLimitRequestsRemaining) / p.backend.rateLimitRequests) * 100;
                if (usedPercent >= plasmoid.configuration.warningThreshold) return true;
            }
        }
        // Also check subscription tools
        var tools = root.allSubscriptionTools ?? [];
        for (var j = 0; j < tools.length; j++) {
            var t = tools[j];
            if (t && t.enabled && t.monitor && t.monitor.percentUsed >= 80) return true;
        }
        return false;
    }
    readonly property bool hasCritical: {
        for (var i = 0; i < providers.length; i++) {
            var p = providers[i];
            if (p && p.enabled && p.backend && p.backend.connected && p.backend.rateLimitRequests > 0) {
                var usedPercent = ((p.backend.rateLimitRequests - p.backend.rateLimitRequestsRemaining) / p.backend.rateLimitRequests) * 100;
                if (usedPercent >= plasmoid.configuration.criticalThreshold) return true;
            }
        }
        // Also check subscription tools
        var tools = root.allSubscriptionTools ?? [];
        for (var j = 0; j < tools.length; j++) {
            var t = tools[j];
            if (t && t.enabled && t.monitor && (t.monitor.limitReached || t.monitor.percentUsed >= 95)) return true;
        }
        return false;
    }
    readonly property bool anyConnected: {
        for (var i = 0; i < providers.length; i++) {
            if (providers[i] && providers[i].enabled && providers[i].backend && providers[i].backend.connected)
                return true;
        }
        return false;
    }
    readonly property bool anyLoading: {
        for (var i = 0; i < providers.length; i++) {
            if (providers[i] && providers[i].enabled && providers[i].backend && providers[i].backend.loading)
                return true;
        }
        return false;
    }

    readonly property string displayMode: plasmoid.configuration.compactDisplayMode

    hoverEnabled: true
    onClicked: plasmoid.activated()

    // Icon mode (default)
    Kirigami.Icon {
        id: mainIcon
        anchors.fill: parent
        source: Qt.resolvedUrl("../icons/logo.png")
        active: compactRoot.containsMouse
        visible: compactRoot.displayMode === "icon"

        // Overlay badge for status indication
        Rectangle {
            id: statusBadge
            visible: compactRoot.anyConnected
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: Kirigami.Units.smallSpacing * 3
            height: width
            radius: width / 2
            color: {
                if (compactRoot.hasCritical) return Kirigami.Theme.negativeTextColor;
                if (compactRoot.hasWarning) return Kirigami.Theme.neutralTextColor;
                return Kirigami.Theme.positiveTextColor;
            }
            border.width: 1
            border.color: Kirigami.Theme.backgroundColor

            Behavior on color {
                ColorAnimation { duration: 300 }
            }
        }
    }

    // Cost mode
    PlasmaComponents.Label {
        id: costLabel
        anchors.fill: parent
        visible: compactRoot.displayMode === "cost"
        text: "$" + compactRoot.compactTotalCost.toFixed(2)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.bold: true
        font.pointSize: Math.max(Kirigami.Theme.smallFont.pointSize, height * 0.35)
        minimumPointSize: Kirigami.Theme.smallFont.pointSize
        fontSizeMode: Text.Fit
        color: {
            var cost = compactRoot.compactTotalCost;
            if (cost > 10) return Kirigami.Theme.negativeTextColor;
            if (cost > 5) return Kirigami.Theme.neutralTextColor;
            return Kirigami.Theme.textColor;
        }
    }

    // Count mode
    RowLayout {
        anchors.fill: parent
        visible: compactRoot.displayMode === "count"
        spacing: Kirigami.Units.smallSpacing / 2

        Kirigami.Icon {
            source: Qt.resolvedUrl("../icons/logo.png")
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: Kirigami.Units.iconSizes.small
        }

        PlasmaComponents.Label {
            text: (root.connectedCount ?? 0).toString()
            font.bold: true
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // Spinning indicator when loading (all modes)
    PlasmaComponents.BusyIndicator {
        anchors.fill: parent
        visible: compactRoot.anyLoading
        running: visible
    }
}
