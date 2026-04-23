import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import "Utils.js" as Utils

ColumnLayout {
    id: toolCard

    required property var modelData
    required property string toolName
    required property string toolIcon
    required property string toolColor
    required property var monitor
    property bool collapsed: false
    readonly property bool narrowCard: toolCard.width < Kirigami.Units.gridUnit * 14

    spacing: 0

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: toolContent.implicitHeight + Kirigami.Units.largeSpacing * 2
        radius: Kirigami.Units.cornerRadius
        color: Kirigami.Theme.backgroundColor
        border.width: 1
        border.color: {
            if (!(toolCard.monitor?.installed ?? false)) return Qt.alpha(Kirigami.Theme.disabledTextColor, 0.2);
            if (toolCard.monitor?.limitReached ?? false) return Qt.alpha(Kirigami.Theme.negativeTextColor, 0.3);
            return Qt.alpha(toolCard.toolColor, 0.3);
        }

        Behavior on Layout.preferredHeight { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 4
            radius: Kirigami.Units.cornerRadius
            color: (toolCard.monitor?.limitReached ?? false) ? Kirigami.Theme.negativeTextColor : toolCard.toolColor
            opacity: toolCard.monitor?.installed ? 0.8 : 0.2
            Behavior on opacity { NumberAnimation { duration: 300 } }
        }

        clip: true

        ColumnLayout {
            id: toolContent
            anchors {
                fill: parent
                margins: Kirigami.Units.largeSpacing
                leftMargin: Kirigami.Units.largeSpacing + 4
            }
            spacing: Kirigami.Units.mediumSpacing

            // Header Section
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: toolCard.toolIcon
                    Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                    color: (toolCard.monitor?.limitReached ?? false) ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    PlasmaExtras.Heading {
                        level: 4
                        text: toolCard.toolName
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    PlasmaComponents.Label {
                        text: {
                            if (!toolCard.monitor) return i18n("N/A");
                            if (!toolCard.monitor.installed) return i18n("Not Installed");
                            let parts = [];
                            if (toolCard.monitor.limitReached) parts.push(i18n("Limit Reached"));
                            else parts.push(i18n("Active"));
                            if (toolCard.monitor.planTier) parts.push(toolCard.monitor.planTier);
                            return parts.join(" • ");
                        }
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        color: (toolCard.monitor?.limitReached ?? false) ? Kirigami.Theme.negativeTextColor : Qt.alpha(Kirigami.Theme.textColor, 0.7)
                        elide: Text.ElideRight
                    }
                }

                RowLayout {
                    visible: toolCard.collapsed && (toolCard.monitor?.usageLimit ?? 0) > 0
                    spacing: Kirigami.Units.smallSpacing
                    PlasmaComponents.Label {
                        text: (toolCard.monitor?.usageCount ?? 0) + "/" + (toolCard.monitor?.usageLimit ?? 0)
                        font.bold: true
                        color: Kirigami.Theme.textColor
                    }
                }

                PlasmaComponents.ToolButton {
                    activeFocusOnTab: true
                    icon.name: toolCard.collapsed ? "arrow-down" : "arrow-up"
                    display: PlasmaComponents.AbstractButton.IconOnly
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    onClicked: toolCard.collapsed = !toolCard.collapsed
                    PlasmaComponents.ToolTip { text: toolCard.collapsed ? i18n("Expand") : i18n("Collapse") }
                }
            }

            Kirigami.Separator {
                Layout.fillWidth: true
                visible: !toolCard.collapsed && (toolCard.monitor?.installed ?? false)
            }

            // Primary usage bar
            ColumnLayout {
                Layout.fillWidth: true
                visible: !toolCard.collapsed && (toolCard.monitor?.installed ?? false) && (toolCard.monitor?.usageLimit ?? 0) > 0
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    PlasmaComponents.Label {
                        text: toolCard.monitor?.periodLabel ?? i18n("Usage")
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.7
                    }
                    Item { Layout.fillWidth: true }
                    PlasmaComponents.Label {
                        text: (toolCard.monitor?.usageCount ?? 0) + " / " + (toolCard.monitor?.usageLimit ?? 0)
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        font.bold: true
                    }
                }

                QQC2.ProgressBar {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6
                    from: 0; to: toolCard.monitor?.usageLimit ?? 1
                    value: Math.min(toolCard.monitor?.usageCount ?? 0, toolCard.monitor?.usageLimit ?? 1)
                    background: Rectangle { implicitHeight: 6; radius: 3; color: Qt.alpha(Kirigami.Theme.textColor, 0.1) }
                    contentItem: Rectangle {
                        width: parent.visualPosition * parent.width
                        height: 6; radius: 3
                        color: usageColor(toolCard.monitor?.percentUsed ?? 0)
                        Behavior on width { NumberAnimation { duration: 300 } }
                        Behavior on color { ColorAnimation { duration: 300 } }
                    }
                }
                PlasmaComponents.Label {
                    text: i18n("Resets in %1", toolCard.monitor?.timeUntilReset ?? "N/A")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.5
                }
            }

            // Organization metrics (Copilot)
            ColumnLayout {
                Layout.fillWidth: true
                visible: !toolCard.collapsed && (toolCard.monitor?.hasOrgMetrics ?? false)
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    PlasmaComponents.Label {
                        text: i18n("Org Seats")
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.7
                    }
                    Item { Layout.fillWidth: true }
                    PlasmaComponents.Label {
                        text: (toolCard.monitor?.orgActiveUsers ?? 0) + " / " + (toolCard.monitor?.orgTotalSeats ?? 0)
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        font.bold: true
                    }
                }

                QQC2.ProgressBar {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 4
                    from: 0; to: Math.max(toolCard.monitor?.orgTotalSeats ?? 1, 1)
                    value: toolCard.monitor?.orgActiveUsers ?? 0
                    background: Rectangle { implicitHeight: 4; radius: 2; color: Qt.alpha(Kirigami.Theme.textColor, 0.1) }
                    contentItem: Rectangle {
                        width: parent.visualPosition * parent.width
                        height: 4; radius: 2
                        color: toolCard.toolColor
                    }
                }
            }

            // Sync and Actions
            RowLayout {
                Layout.fillWidth: true
                visible: !toolCard.collapsed && (toolCard.monitor?.installed ?? false)
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: (toolCard.monitor?.syncStatus && toolCard.monitor.syncStatus !== "idle") ? toolCard.monitor.syncStatus : i18n("Ready")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                    elide: Text.ElideRight
                }

                PlasmaComponents.ToolButton {
                    activeFocusOnTab: true
                    icon.name: "view-refresh"
                    text: toolCard.monitor?.syncing ? i18n("Syncing...") : i18n("Sync")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    enabled: !(toolCard.monitor?.syncing ?? false) && toolCard.monitor?.syncEnabled
                    visible: toolCard.monitor?.syncEnabled ?? false
                    onClicked: if (toolCard.monitor && typeof toolCard.monitor.syncFromBrowser === "function") toolCard.triggerSync()
                }
            }
        }
    }

    signal syncRequested()
    function triggerSync() { syncRequested(); }
    function usageColor(percent) { return Utils.usageColor(percent, Kirigami.Theme); }
}
