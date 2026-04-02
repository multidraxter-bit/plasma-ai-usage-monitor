import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import "Utils.js" as Utils

/**
 * Full-dashboard card for subscription tool usage (Claude Code, Codex, Copilot).
 * Shows detailed usage data: primary/secondary limits, session info, extra usage,
 * tertiary limits, credits, subscription cost, and sync status.
 */
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

    // Card background
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: toolContent.implicitHeight + Kirigami.Units.largeSpacing * 2
        radius: Kirigami.Units.cornerRadius
        color: Qt.tint(Kirigami.Theme.backgroundColor, Qt.alpha(toolCard.toolColor, 0.035))
        border.width: 1
        border.color: {
            if (!(toolCard.monitor?.installed ?? false)) return Qt.alpha(Kirigami.Theme.textColor, 0.12);
            if (toolCard.monitor?.limitReached ?? false) return Qt.alpha(Kirigami.Theme.negativeTextColor, 0.3);
            return Qt.alpha(toolCard.toolColor, 0.24);
        }

        Accessible.role: Accessible.Grouping
        Accessible.name: {
            var status = "";
            if (!toolCard.monitor) status = i18n("not available");
            else if (!toolCard.monitor.installed) status = i18n("not installed");
            else if (toolCard.monitor.limitReached) status = i18n("limit reached");
            else status = i18n("active");

            var desc = toolCard.toolName + ", " + status;
            if (toolCard.monitor && toolCard.monitor.usageLimit > 0) {
                desc += ", " + toolCard.monitor.usageCount + "/" + toolCard.monitor.usageLimit;
            }
            return desc;
        }

        Behavior on Layout.preferredHeight {
            NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
        }

        // Accent stripe on the left edge
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 3
            radius: Kirigami.Units.cornerRadius
            color: toolCard.monitor?.installed ? toolCard.toolColor : "transparent"
            opacity: toolCard.monitor?.installed ? 0.6 : 0
            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }
        }

        clip: true

        ColumnLayout {
            id: toolContent
            anchors {
                fill: parent
                margins: Kirigami.Units.largeSpacing
            }
            spacing: Kirigami.Units.mediumSpacing

            // ═══ Header section ═══
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    Rectangle {
                        width: 4
                        Layout.preferredHeight: toolLabel.implicitHeight
                        radius: 2
                        color: toolCard.toolColor
                    }

                    Kirigami.Icon {
                        source: toolCard.toolIcon
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    }

                    PlasmaExtras.Heading {
                        id: toolLabel
                        level: 4
                        text: toolCard.toolName
                        Layout.fillWidth: true
                        wrapMode: toolCard.narrowCard ? Text.WordWrap : Text.NoWrap
                        elide: Text.ElideRight
                        maximumLineCount: toolCard.narrowCard ? 2 : 1
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

                Flow {
                    Layout.fillWidth: true
                    width: parent.width
                    spacing: Kirigami.Units.smallSpacing

                    Rectangle {
                        visible: (toolCard.monitor?.planTier ?? "") !== ""
                        width: Math.min(tierLabel.implicitWidth + Kirigami.Units.smallSpacing * 2,
                                        toolCard.narrowCard ? Kirigami.Units.gridUnit * 8 : Kirigami.Units.gridUnit * 10)
                        height: tierLabel.implicitHeight + Kirigami.Units.smallSpacing
                        radius: height / 2
                        color: Qt.alpha(toolCard.toolColor, 0.2)
                        clip: true

                        PlasmaComponents.Label {
                            id: tierLabel
                            anchors.centerIn: parent
                            width: parent.width - Kirigami.Units.smallSpacing * 2
                            text: toolCard.monitor?.planTier ?? ""
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            color: toolCard.toolColor
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    Rectangle {
                        visible: toolCard.monitor?.hasSubscriptionCost ?? false
                        width: costLabel.implicitWidth + Kirigami.Units.smallSpacing * 2
                        height: costLabel.implicitHeight + Kirigami.Units.smallSpacing
                        radius: height / 2
                        color: Qt.alpha(Kirigami.Theme.textColor, 0.08)

                        PlasmaComponents.Label {
                            id: costLabel
                            anchors.centerIn: parent
                            text: "$" + (toolCard.monitor?.subscriptionCost ?? 0).toFixed(0) + "/mo"
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            opacity: 0.7
                        }
                    }

                    Rectangle {
                        width: toolStatusLabel.implicitWidth + Kirigami.Units.smallSpacing * 2
                        height: toolStatusLabel.implicitHeight + 4
                        radius: height / 2
                        color: {
                            if (!toolCard.monitor || !toolCard.monitor.installed) return Qt.alpha(Kirigami.Theme.textColor, 0.08);
                            if (toolCard.monitor.limitReached) return Qt.alpha(Kirigami.Theme.negativeTextColor, 0.15);
                            return Qt.alpha(Kirigami.Theme.positiveTextColor, 0.15);
                        }

                        PlasmaComponents.Label {
                            id: toolStatusLabel
                            anchors.centerIn: parent
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            elide: Text.ElideRight
                            text: {
                                if (!toolCard.monitor) return i18n("N/A");
                                if (!toolCard.monitor.installed) return i18n("Not Installed");
                                if (toolCard.monitor.limitReached) return i18n("Limit Reached");
                                return i18n("Active");
                            }
                            color: {
                                if (!toolCard.monitor) return Kirigami.Theme.disabledTextColor;
                                if (!toolCard.monitor.installed) return Kirigami.Theme.disabledTextColor;
                                if (toolCard.monitor.limitReached) return Kirigami.Theme.negativeTextColor;
                                return Kirigami.Theme.positiveTextColor;
                            }
                        }
                    }

                    Rectangle {
                        visible: toolCard.collapsed && (toolCard.monitor?.usageLimit ?? 0) > 0
                        width: collapsedUsageLabel.implicitWidth + Kirigami.Units.smallSpacing * 2
                        height: collapsedUsageLabel.implicitHeight + 4
                        radius: height / 2
                        color: Qt.alpha(Kirigami.Theme.textColor, 0.08)

                        PlasmaComponents.Label {
                            id: collapsedUsageLabel
                            anchors.centerIn: parent
                            text: (toolCard.monitor?.usageCount ?? 0) + "/" + (toolCard.monitor?.usageLimit ?? 0)
                            font.bold: true
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            opacity: 0.75
                        }
                    }
                }
            }

            // Not installed message
            PlasmaComponents.Label {
                Layout.fillWidth: true
                visible: !toolCard.collapsed && !(toolCard.monitor?.installed ?? false)
                text: i18n("Tool not detected on this system")
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                font.italic: true
                opacity: 0.6
                wrapMode: Text.WordWrap
            }

            // Separator
            Kirigami.Separator {
                Layout.fillWidth: true
                visible: !toolCard.collapsed && (toolCard.monitor?.installed ?? false)
            }

            // ═══ Session info (Claude: current session % used) ═══
            ColumnLayout {
                Layout.fillWidth: true
                visible: !toolCard.collapsed && (toolCard.monitor?.hasSessionInfo ?? false)
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    Layout.fillWidth: true
                    PlasmaComponents.Label {
                        text: i18n("Current session")
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.7
                    }
                    Item { Layout.fillWidth: true }
                    PlasmaComponents.Label {
                        text: Math.round(toolCard.monitor?.sessionPercentUsed ?? 0) + "% " + i18n("used")
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        font.bold: true
                        color: usageColor(toolCard.monitor?.sessionPercentUsed ?? 0)
                    }
                }

                QQC2.ProgressBar {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 4
                    from: 0; to: 100
                    value: toolCard.monitor?.sessionPercentUsed ?? 0

                    background: Rectangle {
                        implicitHeight: 4; radius: 2
                        color: Qt.alpha(Kirigami.Theme.textColor, 0.1)
                    }
                    contentItem: Rectangle {
                        width: parent.visualPosition * parent.width
                        height: 4; radius: 2
                        color: usageColor(toolCard.monitor?.sessionPercentUsed ?? 0)
                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
                    }
                }
            }

            // ═══ Primary usage bar ═══
            ColumnLayout {
                Layout.fillWidth: true
                visible: !toolCard.collapsed && (toolCard.monitor?.installed ?? false)
                         && (toolCard.monitor?.usageLimit ?? 0) > 0
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    Layout.fillWidth: true

                    PlasmaComponents.Label {
                        text: toolCard.monitor?.periodLabel ?? ""
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
                    from: 0
                    to: toolCard.monitor?.usageLimit ?? 1
                    value: Math.min(toolCard.monitor?.usageCount ?? 0, toolCard.monitor?.usageLimit ?? 1)

                    Accessible.name: i18n("Usage: %1 of %2, %3% used",
                        toolCard.monitor?.usageCount ?? 0,
                        toolCard.monitor?.usageLimit ?? 0,
                        Math.round(toolCard.monitor?.percentUsed ?? 0))

                    background: Rectangle {
                        implicitHeight: 6; radius: 3
                        color: Qt.alpha(Kirigami.Theme.textColor, 0.1)
                    }

                    contentItem: Rectangle {
                        width: parent.visualPosition * parent.width
                        height: 6; radius: 3
                        color: usageColor(toolCard.monitor?.percentUsed ?? 0)
                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
                        Behavior on color { ColorAnimation { duration: 300 } }
                    }
                }

                // Percentage + remaining text
                RowLayout {
                    Layout.fillWidth: true
                    PlasmaComponents.Label {
                        text: Math.round(toolCard.monitor?.percentUsed ?? 0) + "% " + i18n("used")
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.5
                        color: usageColor(toolCard.monitor?.percentUsed ?? 0)
                    }
                    Item { Layout.fillWidth: true }
                    PlasmaComponents.Label {
                        visible: (toolCard.monitor?.usageLimit ?? 0) > 0
                        text: Math.max(0, (toolCard.monitor?.usageLimit ?? 0) - (toolCard.monitor?.usageCount ?? 0)) + " " + i18n("remaining")
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.4
                    }
                }
            }

            // ═══ Secondary usage bar (e.g., weekly for Claude Code / Codex) ═══
            ColumnLayout {
                Layout.fillWidth: true
                visible: !toolCard.collapsed && (toolCard.monitor?.installed ?? false)
                         && (toolCard.monitor?.hasSecondaryLimit ?? false)
                         && (toolCard.monitor?.secondaryUsageLimit ?? 0) > 0
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    Layout.fillWidth: true

                    PlasmaComponents.Label {
                        text: toolCard.monitor?.secondaryPeriodLabel ?? ""
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.7
                    }
                    Item { Layout.fillWidth: true }
                    PlasmaComponents.Label {
                        text: (toolCard.monitor?.secondaryUsageCount ?? 0) + " / " + (toolCard.monitor?.secondaryUsageLimit ?? 0)
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        font.bold: true
                    }
                }

                QQC2.ProgressBar {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6
                    from: 0
                    to: toolCard.monitor?.secondaryUsageLimit ?? 1
                    value: Math.min(toolCard.monitor?.secondaryUsageCount ?? 0, toolCard.monitor?.secondaryUsageLimit ?? 1)

                    background: Rectangle {
                        implicitHeight: 6; radius: 3
                        color: Qt.alpha(Kirigami.Theme.textColor, 0.1)
                    }

                    contentItem: Rectangle {
                        width: parent.visualPosition * parent.width
                        height: 6; radius: 3
                        color: usageColor(toolCard.monitor?.secondaryPercentUsed ?? 0)
                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
                        Behavior on color { ColorAnimation { duration: 300 } }
                    }
                }

                // Secondary reset info
                RowLayout {
                    Layout.fillWidth: true
                    PlasmaComponents.Label {
                        text: Math.round(toolCard.monitor?.secondaryPercentUsed ?? 0) + "% " + i18n("used")
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.4
                        color: usageColor(toolCard.monitor?.secondaryPercentUsed ?? 0)
                    }
                    Item { Layout.fillWidth: true }
                    PlasmaComponents.Label {
                        visible: (toolCard.monitor?.secondaryTimeUntilReset ?? "") !== ""
                        text: i18n("Resets in %1", toolCard.monitor?.secondaryTimeUntilReset ?? "")
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.4
                    }
                }
            }

            // ═══ Tertiary limit (e.g., Codex code review) ═══
            ColumnLayout {
                Layout.fillWidth: true
                visible: !toolCard.collapsed && (toolCard.monitor?.hasTertiaryLimit ?? false)
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    Layout.fillWidth: true
                    PlasmaComponents.Label {
                        text: toolCard.monitor?.tertiaryPeriodLabel ?? ""
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.7
                    }
                    Item { Layout.fillWidth: true }
                    PlasmaComponents.Label {
                        text: Math.round(toolCard.monitor?.tertiaryPercentRemaining ?? 0) + "% " + i18n("remaining")
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        font.bold: true
                        color: usageColor(100 - (toolCard.monitor?.tertiaryPercentRemaining ?? 100))
                    }
                }

                QQC2.ProgressBar {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 4
                    from: 0; to: 100
                    value: toolCard.monitor?.tertiaryPercentRemaining ?? 0

                    background: Rectangle {
                        implicitHeight: 4; radius: 2
                        color: Qt.alpha(Kirigami.Theme.textColor, 0.1)
                    }
                    contentItem: Rectangle {
                        width: parent.visualPosition * parent.width
                        height: 4; radius: 2
                        color: Kirigami.Theme.positiveTextColor
                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
                    }
                }

                PlasmaComponents.Label {
                    visible: toolCard.monitor?.tertiaryResetDate?.getTime() > 0
                    text: i18n("Resets %1", Qt.formatDate(toolCard.monitor?.tertiaryResetDate, "MMM d"))
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.4
                }
            }

            // ═══ Extra usage / spending (Claude) ═══
            Rectangle {
                Layout.fillWidth: true
                visible: !toolCard.collapsed && (toolCard.monitor?.hasExtraUsage ?? false)
                height: extraUsageCol.implicitHeight + Kirigami.Units.smallSpacing * 2
                radius: Kirigami.Units.cornerRadius
                color: Qt.alpha(Kirigami.Theme.neutralTextColor, 0.08)
                border.width: 1
                border.color: Qt.alpha(Kirigami.Theme.neutralTextColor, 0.15)

                ColumnLayout {
                    id: extraUsageCol
                    anchors {
                        fill: parent
                        margins: Kirigami.Units.smallSpacing
                    }
                    spacing: Kirigami.Units.smallSpacing

                    RowLayout {
                        Layout.fillWidth: true
                        PlasmaComponents.Label {
                            text: i18n("Extra usage")
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            font.bold: true
                            opacity: 0.7
                        }
                        Item { Layout.fillWidth: true }
                        PlasmaComponents.Label {
                            text: {
                                var sym = toolCard.monitor?.currencySymbol ?? "$";
                                var spent = (toolCard.monitor?.extraUsageSpent ?? 0).toFixed(2);
                                var limit = (toolCard.monitor?.extraUsageLimit ?? 0).toFixed(0);
                                return sym + spent + " / " + sym + limit;
                            }
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            font.bold: true
                        }
                    }

                    QQC2.ProgressBar {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 4
                        from: 0; to: 100
                        value: toolCard.monitor?.extraUsagePercent ?? 0

                        background: Rectangle {
                            implicitHeight: 4; radius: 2
                            color: Qt.alpha(Kirigami.Theme.textColor, 0.1)
                        }
                        contentItem: Rectangle {
                            width: parent.visualPosition * parent.width
                            height: 4; radius: 2
                            color: usageColor(toolCard.monitor?.extraUsagePercent ?? 0)
                            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        PlasmaComponents.Label {
                            text: Math.round(toolCard.monitor?.extraUsagePercent ?? 0) + "% " + i18n("used")
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            opacity: 0.4
                        }
                        Item { Layout.fillWidth: true }
                        PlasmaComponents.Label {
                            visible: toolCard.monitor?.extraUsageResetDate?.getTime() > 0
                            text: i18n("Resets %1", Qt.formatDate(toolCard.monitor?.extraUsageResetDate, "MMM d"))
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            opacity: 0.4
                        }
                    }
                }
            }

            // ═══ Remaining credits (Codex) ═══
            RowLayout {
                Layout.fillWidth: true
                visible: !toolCard.collapsed && (toolCard.monitor?.hasCredits ?? false)
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: "wallet-open"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    opacity: 0.6
                }
                PlasmaComponents.Label {
                    text: i18n("Remaining credits:")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.7
                }
                PlasmaComponents.Label {
                    text: "$" + (toolCard.monitor?.remainingCredits ?? 0).toFixed(2)
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    font.bold: true
                    color: (toolCard.monitor?.remainingCredits ?? 0) <= 0
                           ? Kirigami.Theme.negativeTextColor
                           : Kirigami.Theme.textColor
                }
            }

            // ═══ Organization metrics (GitHub Copilot) ═══
            Rectangle {
                Layout.fillWidth: true
                visible: !toolCard.collapsed && (toolCard.monitor?.hasOrgMetrics ?? false)
                height: orgMetricsCol.implicitHeight + Kirigami.Units.smallSpacing * 2
                radius: Kirigami.Units.cornerRadius
                color: Qt.alpha(toolCard.toolColor, 0.06)
                border.width: 1
                border.color: Qt.alpha(toolCard.toolColor, 0.15)

                ColumnLayout {
                    id: orgMetricsCol
                    anchors {
                        fill: parent
                        margins: Kirigami.Units.smallSpacing
                    }
                    spacing: Kirigami.Units.smallSpacing

                    RowLayout {
                        Layout.fillWidth: true
                        Kirigami.Icon {
                            source: "group"
                            Layout.preferredWidth: Kirigami.Units.iconSizes.small
                            Layout.preferredHeight: Kirigami.Units.iconSizes.small
                            opacity: 0.7
                        }
                        PlasmaComponents.Label {
                            text: i18n("Organization")
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            font.bold: true
                            opacity: 0.7
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        PlasmaComponents.Label {
                            text: i18n("Active users:")
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            opacity: 0.6
                        }
                        Item { Layout.fillWidth: true }
                        PlasmaComponents.Label {
                            text: (toolCard.monitor?.orgActiveUsers ?? 0) + " / " + (toolCard.monitor?.orgTotalSeats ?? 0) + " " + i18n("seats")
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            font.bold: true
                        }
                    }

                    QQC2.ProgressBar {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 4
                        from: 0
                        to: Math.max(toolCard.monitor?.orgTotalSeats ?? 1, 1)
                        value: toolCard.monitor?.orgActiveUsers ?? 0

                        background: Rectangle {
                            implicitHeight: 4; radius: 2
                            color: Qt.alpha(Kirigami.Theme.textColor, 0.1)
                        }
                        contentItem: Rectangle {
                            width: parent.visualPosition * parent.width
                            height: 4; radius: 2
                            color: toolCard.toolColor
                            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
                        }
                    }
                }
            }

            // ═══ Time until reset ═══
            RowLayout {
                Layout.fillWidth: true
                visible: !toolCard.collapsed && (toolCard.monitor?.installed ?? false)
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: "chronometer"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    opacity: 0.6
                }

                PlasmaComponents.Label {
                    text: i18n("Resets in: %1", toolCard.monitor?.timeUntilReset ?? "")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                }

                Item { Layout.fillWidth: true }

                // Sync status badge
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    visible: (toolCard.monitor?.syncStatus ?? "") !== ""
                             && toolCard.monitor?.syncStatus !== "idle"
                    text: toolCard.monitor?.syncStatus ?? ""
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.7
                    font.italic: true
                    elide: Text.ElideRight
                    color: {
                        var status = toolCard.monitor?.syncStatus ?? "";
                        if (status === i18n("Synced"))
                            return Kirigami.Theme.positiveTextColor;
                        if (status === i18n("Session expired") || status === i18n("Not logged in")
                            || status === i18n("Browser unsupported")
                            || status === i18n("Sync failed") || status === i18n("Invalid response")
                            || status === i18n("No organization"))
                            return Kirigami.Theme.negativeTextColor;
                        return Kirigami.Theme.disabledTextColor;
                    }
                }

                // Last activity
                PlasmaComponents.Label {
                    visible: toolCard.monitor?.lastActivity?.getTime() > 0
                             && (toolCard.monitor?.syncStatus ?? "") === ""
                    text: i18n("Last: %1", formatRelativeTime(toolCard.monitor?.lastActivity))
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.4
                    elide: Text.ElideRight
                }
            }

            // ═══ Limit reached warning ═══
            Rectangle {
                Layout.fillWidth: true
                visible: !toolCard.collapsed && (toolCard.monitor?.limitReached ?? false)
                height: limitWarningLabel.implicitHeight + Kirigami.Units.smallSpacing * 2
                radius: Kirigami.Units.cornerRadius
                color: Qt.alpha(Kirigami.Theme.negativeBackgroundColor, 0.3)
                border.width: 1
                border.color: Qt.alpha(Kirigami.Theme.negativeTextColor, 0.3)

                PlasmaComponents.Label {
                    id: limitWarningLabel
                    anchors {
                        fill: parent
                        margins: Kirigami.Units.smallSpacing
                    }
                    text: i18n("Usage limit reached! Resets in %1.", toolCard.monitor?.timeUntilReset ?? "")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    color: Kirigami.Theme.negativeTextColor
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            // ═══ Action buttons ═══
            RowLayout {
                Layout.fillWidth: true
                visible: !toolCard.collapsed && (toolCard.monitor?.installed ?? false)
                spacing: Kirigami.Units.smallSpacing

                Item { Layout.fillWidth: true }

                PlasmaComponents.ToolButton {
                        activeFocusOnTab: true
                    icon.name: "view-refresh"
                    text: toolCard.monitor?.syncing ? i18n("Syncing...") : i18n("Sync")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    enabled: !(toolCard.monitor?.syncing ?? false) && toolCard.monitor?.syncEnabled
                    visible: toolCard.monitor?.syncEnabled ?? false
                    onClicked: {
                        if (toolCard.monitor && typeof toolCard.monitor.syncFromBrowser === "function") {
                            toolCard.triggerSync();
                        }
                    }
                    PlasmaComponents.ToolTip { text: i18n("Sync usage data from browser cookies") }
                }

                PlasmaComponents.ToolButton {
                        activeFocusOnTab: true
                    icon.name: "list-add"
                    text: i18n("+1 Usage")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    onClicked: {
                        if (toolCard.monitor) toolCard.monitor.incrementUsage();
                    }
                    PlasmaComponents.ToolTip { text: i18n("Manually record one usage") }
                }

                PlasmaComponents.ToolButton {
                        activeFocusOnTab: true
                    icon.name: "edit-clear"
                    text: i18n("Reset")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    onClicked: {
                        if (toolCard.monitor) toolCard.monitor.resetUsage();
                    }
                    PlasmaComponents.ToolTip { text: i18n("Reset usage counter for current period") }
                }
            }
        }
    }

    // ── Sync trigger (called from button or timer) ──
    signal syncRequested()

    function triggerSync() {
        syncRequested();
    }

    // ── Helper functions (delegated to Utils.js) ──

    function usageColor(percent) {
        return Utils.usageColor(percent, Kirigami.Theme);
    }

    function formatRelativeTime(dateTime) {
        return Utils.formatRelativeTime(dateTime, Qt, i18n);
    }
}
