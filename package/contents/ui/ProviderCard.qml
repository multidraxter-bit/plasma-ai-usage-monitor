import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import "Utils.js" as Utils

ColumnLayout {
    id: card

    required property var modelData
    required property string providerName
    required property string providerIcon
    required property string providerColor
    required property var backend
    property bool showCost: false
    property bool showUsage: false
    property bool collapsed: false
    readonly property bool narrowCard: card.width < Kirigami.Units.gridUnit * 18
    readonly property bool compactDetails: card.width < Kirigami.Units.gridUnit * 16
    readonly property bool isLoofiServer: card.providerName === "Loofi Server"

    spacing: 0

    // Card background
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: cardContent.implicitHeight + Kirigami.Units.largeSpacing * 2
        radius: Kirigami.Units.cornerRadius
        color: Qt.tint(Kirigami.Theme.backgroundColor, Qt.alpha(Kirigami.Theme.highlightColor, 0.03))
        border.width: 1
        border.color: {
            if (card.backend?.error) return Qt.alpha(Kirigami.Theme.negativeTextColor, 0.3);
            if (card.backend?.connected) return Qt.alpha(card.providerColor, 0.28);
            return Qt.alpha(Kirigami.Theme.textColor, 0.12);
        }

        Accessible.role: Accessible.Grouping
        Accessible.name: {
            var status = "";
            if (!card.backend) status = i18n("not available");
            else if (card.backend.error) status = i18n("error");
            else if (card.backend.connected) status = i18n("connected");
            else status = i18n("disconnected");

            var desc = card.providerName + ", " + status;
            if (card.backend && card.backend.connected && card.showCost && !card.isLoofiServer) {
                desc += ", $" + (card.backend.cost ?? 0).toFixed(4);
            }
            return desc;
        }

        Behavior on border.color {
            ColorAnimation { duration: 200 }
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
            color: card.backend?.connected ? card.providerColor : "transparent"
            opacity: card.backend?.connected ? 0.6 : 0
            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }
        }

        clip: true

        ColumnLayout {
            id: cardContent
            anchors {
                fill: parent
                margins: Kirigami.Units.largeSpacing
            }
            spacing: Kirigami.Units.mediumSpacing

            // Header section: title row + wrapping metadata chips
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    // Provider color indicator
                    Rectangle {
                        width: 4
                        Layout.preferredHeight: providerLabel.implicitHeight
                        radius: 2
                        color: card.providerColor

                        Behavior on color {
                            ColorAnimation { duration: 300 }
                        }
                    }

                    Kirigami.Icon {
                        source: card.providerIcon
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    }

                    PlasmaExtras.Heading {
                        id: providerLabel
                        level: 4
                        text: card.providerName
                        Layout.fillWidth: true
                        wrapMode: card.narrowCard ? Text.WordWrap : Text.NoWrap
                        elide: Text.ElideRight
                        maximumLineCount: card.narrowCard ? 2 : 1
                    }

                    PlasmaComponents.ToolButton {
                        icon.name: card.collapsed ? "arrow-down" : "arrow-up"
                        display: PlasmaComponents.AbstractButton.IconOnly
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                        onClicked: card.collapsed = !card.collapsed
                        PlasmaComponents.ToolTip { text: card.collapsed ? i18n("Expand") : i18n("Collapse") }
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    width: parent.width
                    spacing: Kirigami.Units.smallSpacing

                    Rectangle {
                        visible: (card.backend?.model ?? "") !== ""
                        width: Math.min(modelLabel.implicitWidth + Kirigami.Units.smallSpacing * 2,
                                        card.narrowCard ? Kirigami.Units.gridUnit * 8 : Kirigami.Units.gridUnit * 10)
                        height: modelLabel.implicitHeight + 4
                        radius: 3
                        color: Qt.alpha(card.providerColor, 0.15)
                        clip: true

                        PlasmaComponents.Label {
                            id: modelLabel
                            anchors.centerIn: parent
                            width: parent.width - Kirigami.Units.smallSpacing * 2
                            text: card.backend?.model ?? ""
                            font.pointSize: Kirigami.Theme.smallFont.pointSize * 0.9
                            color: Qt.alpha(Kirigami.Theme.textColor, 0.7)
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                        }

                        PlasmaComponents.ToolTip {
                            text: i18n("Model: %1", card.backend?.model ?? "")
                        }
                    }

                    Rectangle {
                        visible: (card.backend?.errorCount ?? 0) > 0
                        width: errorCountLabel.implicitWidth + Kirigami.Units.smallSpacing * 2
                        height: errorCountLabel.implicitHeight + Kirigami.Units.smallSpacing
                        radius: height / 2
                        color: Kirigami.Theme.negativeBackgroundColor

                        PlasmaComponents.Label {
                            id: errorCountLabel
                            anchors.centerIn: parent
                            text: (card.backend?.errorCount ?? 0).toString()
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            color: Kirigami.Theme.negativeTextColor
                        }
                    }

                    Rectangle {
                        width: statusLabel.implicitWidth + Kirigami.Units.smallSpacing * 2
                        height: statusLabel.implicitHeight + 4
                        radius: height / 2
                        color: {
                            if (!card.backend) return Qt.alpha(Kirigami.Theme.textColor, 0.08);
                            if (card.backend.error) return Qt.alpha(Kirigami.Theme.negativeTextColor, 0.15);
                            if (card.backend.connected) return Qt.alpha(Kirigami.Theme.positiveTextColor, 0.15);
                            return Qt.alpha(Kirigami.Theme.textColor, 0.08);
                        }

                        PlasmaComponents.Label {
                            id: statusLabel
                            anchors.centerIn: parent
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            elide: Text.ElideRight
                            text: {
                                if (!card.backend) return i18n("N/A");
                                if (card.backend.loading) return i18n("Loading...");
                                if (card.backend.error) return i18n("Error");
                                if (card.backend.connected) return i18n("Connected");
                                return i18n("Disconnected");
                            }
                            color: {
                                if (!card.backend) return Kirigami.Theme.disabledTextColor;
                                if (card.backend.error) return Kirigami.Theme.negativeTextColor;
                                if (card.backend.connected) return Kirigami.Theme.positiveTextColor;
                                return Kirigami.Theme.disabledTextColor;
                            }
                        }
                    }

                    PlasmaComponents.BusyIndicator {
                        width: Kirigami.Units.iconSizes.small
                        height: Kirigami.Units.iconSizes.small
                        visible: card.backend?.loading ?? false
                        running: visible
                    }

                    Rectangle {
                        visible: card.collapsed && card.showCost && !card.isLoofiServer && (card.backend?.connected ?? false)
                        width: collapsedCostLabel.implicitWidth + Kirigami.Units.smallSpacing * 2
                        height: collapsedCostLabel.implicitHeight + 4
                        radius: height / 2
                        color: Qt.alpha(Kirigami.Theme.textColor, 0.08)

                        PlasmaComponents.Label {
                            id: collapsedCostLabel
                            anchors.centerIn: parent
                            text: "$" + (card.backend?.cost ?? 0).toFixed(2)
                            font.bold: true
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            opacity: 0.75
                        }
                    }
                }
            }

            // Error message (expandable)
            ColumnLayout {
                Layout.fillWidth: true
                visible: !card.collapsed && (card.backend?.error ?? "") !== ""
                spacing: Kirigami.Units.smallSpacing / 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        text: humanizeError(card.backend?.error ?? "")
                        color: Kirigami.Theme.negativeTextColor
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        wrapMode: Text.WordWrap
                        elide: errorExpanded ? Text.ElideNone : Text.ElideRight
                        maximumLineCount: errorExpanded ? -1 : 2
                    }

                    // Retry button
                    PlasmaComponents.ToolButton {
                        icon.name: "view-refresh"
                        display: PlasmaComponents.AbstractButton.IconOnly
                        PlasmaComponents.ToolTip { text: i18n("Retry") }
                        onClicked: {
                            if (card.backend) card.backend.refresh();
                        }
                    }

                    // Expand/collapse error details
                    PlasmaComponents.ToolButton {
                        icon.name: errorExpanded ? "arrow-up" : "arrow-down"
                        display: PlasmaComponents.AbstractButton.IconOnly
                        visible: (card.backend?.consecutiveErrors ?? 0) > 1
                        PlasmaComponents.ToolTip { text: errorExpanded ? i18n("Collapse") : i18n("Details") }
                        onClicked: errorExpanded = !errorExpanded
                    }
                }

                // Expanded error details
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    visible: errorExpanded && (card.backend?.consecutiveErrors ?? 0) > 1
                    text: i18n("%1 consecutive errors", card.backend?.consecutiveErrors ?? 0)
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                }
            }

            // Separator
            Kirigami.Separator {
                Layout.fillWidth: true
                visible: !card.collapsed && (card.backend?.connected ?? false)
            }

            // Usage data (for providers with usage APIs)
            ColumnLayout {
                Layout.fillWidth: true
                visible: !card.collapsed && card.isLoofiServer && (card.backend?.connected ?? false)
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    text: i18n("Server KPIs")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    font.bold: true
                    opacity: 0.8
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: card.compactDetails ? 1 : 2
                    columnSpacing: Kirigami.Units.largeSpacing
                    rowSpacing: Kirigami.Units.smallSpacing

                    PlasmaComponents.Label {
                        text: i18n("Active model:")
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.7
                    }
                    PlasmaComponents.Label {
                        text: card.backend?.activeModel || i18n("Unknown")
                        font.bold: true
                        Layout.alignment: card.compactDetails ? Qt.AlignLeft : Qt.AlignRight
                        elide: Text.ElideRight
                        wrapMode: card.compactDetails ? Text.WordWrap : Text.NoWrap
                    }

                    PlasmaComponents.Label {
                        text: i18n("Training stage:")
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.7
                    }
                    PlasmaComponents.Label {
                        text: card.backend?.trainingStage || i18n("idle")
                        font.bold: true
                        Layout.alignment: card.compactDetails ? Qt.AlignLeft : Qt.AlignRight
                        elide: Text.ElideRight
                        wrapMode: card.compactDetails ? Text.WordWrap : Text.NoWrap
                    }

                    PlasmaComponents.Label {
                        text: i18n("GPU memory:")
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.7
                    }
                    PlasmaComponents.Label {
                        text: formatPercent(card.backend?.gpuMemoryPct ?? -1)
                        font.bold: true
                        Layout.alignment: card.compactDetails ? Qt.AlignLeft : Qt.AlignRight
                    }

                    PlasmaComponents.Label {
                        text: i18n("Requests (24h):")
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.7
                    }
                    PlasmaComponents.Label {
                        text: formatNumber(card.backend?.requestCount ?? 0)
                        font.bold: true
                        Layout.alignment: card.compactDetails ? Qt.AlignLeft : Qt.AlignRight
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                visible: !card.collapsed && card.showUsage && !card.isLoofiServer && (card.backend?.connected ?? false)
                columns: card.compactDetails ? 1 : 2
                columnSpacing: Kirigami.Units.largeSpacing
                rowSpacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    text: i18n("Input tokens:")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.7
                }
                PlasmaComponents.Label {
                    text: formatNumber(card.backend?.inputTokens ?? 0)
                    font.bold: true
                    Layout.alignment: card.compactDetails ? Qt.AlignLeft : Qt.AlignRight
                }

                PlasmaComponents.Label {
                    text: i18n("Output tokens:")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.7
                }
                PlasmaComponents.Label {
                    text: formatNumber(card.backend?.outputTokens ?? 0)
                    font.bold: true
                    Layout.alignment: card.compactDetails ? Qt.AlignLeft : Qt.AlignRight
                }

                PlasmaComponents.Label {
                    text: i18n("Requests:")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.7
                }
                PlasmaComponents.Label {
                    text: formatNumber(card.backend?.requestCount ?? 0)
                    font.bold: true
                    Layout.alignment: card.compactDetails ? Qt.AlignLeft : Qt.AlignRight
                }
            }

            // Cost display
            RowLayout {
                Layout.fillWidth: true
                visible: !card.collapsed && card.showCost && !card.isLoofiServer && (card.backend?.connected ?? false)
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    text: (card.backend?.isEstimatedCost ?? false) ? i18n("Est. Cost:") : i18n("Cost:")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.7
                }

                // Estimated cost indicator
                PlasmaComponents.Label {
                    visible: card.backend?.isEstimatedCost ?? false
                    text: "~"
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    font.italic: true
                    opacity: 0.5
                    PlasmaComponents.ToolTip {
                        text: i18n("Estimated from token usage and model pricing. Not from billing API.")
                    }
                }

                Item { Layout.fillWidth: true }

                PlasmaComponents.Label {
                    text: "$" + (card.backend?.cost ?? 0).toFixed(4)
                    font.bold: true
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
                    wrapMode: card.compactDetails ? Text.WordWrap : Text.NoWrap
                    color: {
                        var c = card.backend?.cost ?? 0;
                        if (c > 10) return Kirigami.Theme.negativeTextColor;
                        if (c > 5) return Kirigami.Theme.neutralTextColor;
                        return Kirigami.Theme.textColor;
                    }
                }
            }

            // DeepSeek balance display
            RowLayout {
                Layout.fillWidth: true
                visible: !card.collapsed && (card.backend?.connected ?? false)
                         && card.providerName === "DeepSeek"
                         && (card.backend?.balance ?? 0) > 0
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    text: i18n("Account Balance:")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.7
                }

                Item { Layout.fillWidth: true }

                PlasmaComponents.Label {
                    text: "$" + (card.backend?.balance ?? 0).toFixed(2)
                    font.bold: true
                    color: {
                        var b = card.backend?.balance ?? 0;
                        if (b < 1) return Kirigami.Theme.negativeTextColor;
                        if (b < 5) return Kirigami.Theme.neutralTextColor;
                        return Kirigami.Theme.positiveTextColor;
                    }
                }
            }

            // Budget progress bars
            ColumnLayout {
                Layout.fillWidth: true
                visible: !card.collapsed && (card.backend?.connected ?? false)
                spacing: Kirigami.Units.smallSpacing

                // Daily budget bar
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: (card.backend?.dailyBudget ?? 0) > 0
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        PlasmaComponents.Label {
                            text: i18n("Daily budget")
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            opacity: 0.7
                        }
                        Item { Layout.fillWidth: true }
                        PlasmaComponents.Label {
                            Layout.preferredWidth: card.compactDetails ? Kirigami.Units.gridUnit * 8 : -1
                            text: "$" + (card.backend?.dailyCost ?? 0).toFixed(2) + " / $" + (card.backend?.dailyBudget ?? 0).toFixed(2)
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            horizontalAlignment: card.compactDetails ? Text.AlignRight : Text.AlignLeft
                            wrapMode: card.compactDetails ? Text.WordWrap : Text.NoWrap
                        }
                    }

                    QQC2.ProgressBar {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 4
                        from: 0
                        to: card.backend?.dailyBudget ?? 1
                        value: Math.min(card.backend?.dailyCost ?? 0, card.backend?.dailyBudget ?? 1)

                        Accessible.name: i18n("Daily budget: %1 of %2 used",
                            "$" + (card.backend?.dailyCost ?? 0).toFixed(2),
                            "$" + (card.backend?.dailyBudget ?? 0).toFixed(2))

                        background: Rectangle {
                            implicitHeight: 4
                            radius: 2
                            color: Qt.alpha(Kirigami.Theme.textColor, 0.1)
                        }

                        contentItem: Rectangle {
                            width: parent.visualPosition * parent.width
                            height: 4
                            radius: 2
                            color: budgetColor(card.backend?.dailyCost ?? 0, card.backend?.dailyBudget ?? 1)

                            Behavior on width {
                                NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
                            }
                            Behavior on color {
                                ColorAnimation { duration: 300 }
                            }
                        }
                    }
                }

                // Monthly budget bar
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: (card.backend?.monthlyBudget ?? 0) > 0
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        PlasmaComponents.Label {
                            text: i18n("Monthly budget")
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            opacity: 0.7
                        }
                        Item { Layout.fillWidth: true }
                        PlasmaComponents.Label {
                            Layout.preferredWidth: card.compactDetails ? Kirigami.Units.gridUnit * 8 : -1
                            text: "$" + (card.backend?.monthlyCost ?? 0).toFixed(2) + " / $" + (card.backend?.monthlyBudget ?? 0).toFixed(2)
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            horizontalAlignment: card.compactDetails ? Text.AlignRight : Text.AlignLeft
                            wrapMode: card.compactDetails ? Text.WordWrap : Text.NoWrap
                        }
                    }

                    QQC2.ProgressBar {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 4
                        from: 0
                        to: card.backend?.monthlyBudget ?? 1
                        value: Math.min(card.backend?.monthlyCost ?? 0, card.backend?.monthlyBudget ?? 1)

                        background: Rectangle {
                            implicitHeight: 4
                            radius: 2
                            color: Qt.alpha(Kirigami.Theme.textColor, 0.1)
                        }

                        contentItem: Rectangle {
                            width: parent.visualPosition * parent.width
                            height: 4
                            radius: 2
                            color: budgetColor(card.backend?.monthlyCost ?? 0, card.backend?.monthlyBudget ?? 1)

                            Behavior on width {
                                NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
                            }
                            Behavior on color {
                                ColorAnimation { duration: 300 }
                            }
                        }
                    }

                    // Estimated monthly cost
                    PlasmaComponents.Label {
                        visible: (card.backend?.estimatedMonthlyCost ?? 0) > 0
                        text: i18n("Est. monthly: $%1", (card.backend?.estimatedMonthlyCost ?? 0).toFixed(2))
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        font.italic: true
                        opacity: 0.5
                    }
                }
            }

            // Separator before rate limits
            Kirigami.Separator {
                Layout.fillWidth: true
                visible: !card.collapsed && (card.backend?.connected ?? false)
            }

            // Rate limits section
            ColumnLayout {
                Layout.fillWidth: true
                visible: !card.collapsed && (card.backend?.connected ?? false)
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    text: i18n("Rate Limits")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    font.bold: true
                    opacity: 0.8
                }

                // Requests rate limit bar
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    visible: (card.backend?.rateLimitRequests ?? 0) > 0

                    RowLayout {
                        Layout.fillWidth: true
                        PlasmaComponents.Label {
                            text: i18n("Requests/min")
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            opacity: 0.7
                        }
                        Item { Layout.fillWidth: true }
                        PlasmaComponents.Label {
                            readonly property int used: (card.backend?.rateLimitRequests ?? 0) - (card.backend?.rateLimitRequestsRemaining ?? 0)
                            Layout.preferredWidth: card.compactDetails ? Kirigami.Units.gridUnit * 8 : -1
                            text: used + " / " + (card.backend?.rateLimitRequests ?? 0) + " " + i18n("used")
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            horizontalAlignment: card.compactDetails ? Text.AlignRight : Text.AlignLeft
                            wrapMode: card.compactDetails ? Text.WordWrap : Text.NoWrap
                        }
                    }

                    QQC2.ProgressBar {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 6
                        from: 0
                        to: card.backend?.rateLimitRequests ?? 1
                        value: (card.backend?.rateLimitRequests ?? 0) - (card.backend?.rateLimitRequestsRemaining ?? 0)

                        background: Rectangle {
                            implicitHeight: 6
                            radius: 3
                            color: Qt.alpha(Kirigami.Theme.textColor, 0.1)
                        }

                        contentItem: Rectangle {
                            width: parent.visualPosition * parent.width
                            height: 6
                            radius: 3
                            color: rateLimitColor(
                                card.backend?.rateLimitRequestsRemaining ?? 0,
                                card.backend?.rateLimitRequests ?? 1
                            )

                            Behavior on width {
                                NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
                            }
                            Behavior on color {
                                ColorAnimation { duration: 300 }
                            }
                        }
                    }
                }

                // Tokens rate limit bar
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    visible: (card.backend?.rateLimitTokens ?? 0) > 0

                    RowLayout {
                        Layout.fillWidth: true
                        PlasmaComponents.Label {
                            text: i18n("Tokens/min")
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            opacity: 0.7
                        }
                        Item { Layout.fillWidth: true }
                        PlasmaComponents.Label {
                            readonly property int used: (card.backend?.rateLimitTokens ?? 0) - (card.backend?.rateLimitTokensRemaining ?? 0)
                            Layout.preferredWidth: card.compactDetails ? Kirigami.Units.gridUnit * 8 : -1
                            text: formatNumber(used) + " / " + formatNumber(card.backend?.rateLimitTokens ?? 0) + " " + i18n("used")
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            horizontalAlignment: card.compactDetails ? Text.AlignRight : Text.AlignLeft
                            wrapMode: card.compactDetails ? Text.WordWrap : Text.NoWrap
                        }
                    }

                    QQC2.ProgressBar {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 6
                        from: 0
                        to: card.backend?.rateLimitTokens ?? 1
                        value: (card.backend?.rateLimitTokens ?? 0) - (card.backend?.rateLimitTokensRemaining ?? 0)

                        background: Rectangle {
                            implicitHeight: 6
                            radius: 3
                            color: Qt.alpha(Kirigami.Theme.textColor, 0.1)
                        }

                        contentItem: Rectangle {
                            width: parent.visualPosition * parent.width
                            height: 6
                            radius: 3
                            color: rateLimitColor(
                                card.backend?.rateLimitTokensRemaining ?? 0,
                                card.backend?.rateLimitTokens ?? 1
                            )

                            Behavior on width {
                                NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
                            }
                            Behavior on color {
                                ColorAnimation { duration: 300 }
                            }
                        }
                    }
                }

                // Reset time
                PlasmaComponents.Label {
                    visible: (card.backend?.rateLimitResetTime ?? "") !== ""
                    text: i18n("Resets: %1", card.backend?.rateLimitResetTime ?? "")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.5
                }
            }

            // Last refreshed with relative time
            PlasmaComponents.Label {
                Layout.fillWidth: true
                visible: !card.collapsed && (card.backend?.connected ?? false)
                horizontalAlignment: card.compactDetails ? Text.AlignLeft : Text.AlignRight
                text: {
                    var lr = card.backend?.lastRefreshed;
                    if (!lr) return "";
                    return i18n("Updated: %1 (#%2)",
                        formatRelativeTime(lr),
                        card.backend?.refreshCount ?? 0);
                }
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                opacity: 0.4
            }
        }
    }

    // ── State ──
    property bool errorExpanded: false

    // ── Helper functions ──

    function humanizeError(raw) {
        if (!raw) return "";
        const s = raw.toString();
        if (s.includes("403") && card.providerName === "OpenAI")
            return s + "\nHint: OpenAI requires an Admin API key (not a regular key). Get one at platform.openai.com/settings/organization/api-keys";
        if (s.includes("403") || s.includes("401"))
            return s + "\nHint: Check your API key in Settings \u2192 Providers";
        if (s.includes("429"))
            return s + "\nHint: Rate limit hit. Try a longer refresh interval in Settings \u2192 General";
        if (s.includes("NetworkError") || s.includes("network error") || s.includes("host not found") || s.includes("Connection refused"))
            return s + "\nHint: Cannot reach the API. Check your internet connection or proxy settings";
        if (s.includes("KWallet"))
            return s + "\nHint: Enable KWallet in System Settings \u2192 KDE Wallet";
        return s;
    }

    function rateLimitColor(remaining, total) {
        return Utils.rateLimitColor(remaining, total, Kirigami.Theme);
    }

    function budgetColor(spent, budget) {
        return Utils.budgetColor(spent, budget, Kirigami.Theme);
    }

    function formatNumber(n) {
        return Utils.formatNumber(n);
    }

    function formatPercent(value) {
        if (value < 0)
            return i18n("Unknown");
        return Math.round(value) + "%";
    }

    function formatRelativeTime(dateTime) {
        return Utils.formatRelativeTime(dateTime);
    }
}
