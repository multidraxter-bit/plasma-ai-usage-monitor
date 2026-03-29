import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

/**
 * Cost summary card showing aggregate cost across all enabled providers.
 */
ColumnLayout {
    id: costCard

    property var providers: []
    property var subscriptionTools: []
    readonly property bool narrowCard: costCard.width < Kirigami.Units.gridUnit * 18

    readonly property double subscriptionTotalCost: {
        var total = 0;
        for (var i = 0; i < subscriptionTools.length; i++) {
            var tool = subscriptionTools[i];
            if (tool.enabled && tool.monitor && tool.monitor.hasSubscriptionCost)
                total += tool.monitor.subscriptionCost;
        }
        return total;
    }

    readonly property double totalCost: {
        var total = 0;
        for (var i = 0; i < providers.length; i++) {
            if (providers[i].enabled && providers[i].backend && providers[i].backend.connected)
                total += providers[i].backend.cost;
        }
        return total + subscriptionTotalCost;
    }

    readonly property double totalDailyCost: {
        var total = 0;
        for (var i = 0; i < providers.length; i++) {
            if (providers[i].enabled && providers[i].backend && providers[i].backend.connected)
                total += providers[i].backend.dailyCost;
        }
        return total;
    }

    readonly property double totalMonthlyCost: {
        var total = 0;
        for (var i = 0; i < providers.length; i++) {
            if (providers[i].enabled && providers[i].backend && providers[i].backend.connected)
                total += providers[i].backend.monthlyCost;
        }
        return total;
    }

    readonly property double totalDailyBudget: {
        var total = 0;
        for (var i = 0; i < providers.length; i++) {
            if (providers[i].enabled && providers[i].backend)
                total += providers[i].backend.dailyBudget;
        }
        return total;
    }

    readonly property double totalMonthlyBudget: {
        var total = 0;
        for (var i = 0; i < providers.length; i++) {
            if (providers[i].enabled && providers[i].backend)
                total += providers[i].backend.monthlyBudget;
        }
        return total;
    }

    spacing: 0

    // View mode: 0=cumulative, 1=daily, 2=monthly
    property int costViewMode: 0

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: costContent.implicitHeight + Kirigami.Units.largeSpacing * 2
        radius: Kirigami.Units.cornerRadius
        color: Qt.alpha(Kirigami.Theme.highlightColor, 0.08)
        border.width: 1
        border.color: Qt.alpha(Kirigami.Theme.highlightColor, 0.2)

        Accessible.role: Accessible.Grouping
        Accessible.name: i18n("Total cost: $%1", costCard.totalCost.toFixed(4))

        ColumnLayout {
            id: costContent
            anchors {
                fill: parent
                margins: Kirigami.Units.largeSpacing
            }
            spacing: Kirigami.Units.smallSpacing

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    PlasmaExtras.Heading {
                        level: 4
                        text: costCard.costViewMode === 0 ? i18n("Total Cost")
                            : costCard.costViewMode === 1 ? i18n("Today's Cost")
                            : i18n("Monthly Cost")
                        Layout.fillWidth: true
                    }

                    // View mode toggle buttons
                    Row {
                        spacing: 2

                        Repeater {
                            model: [
                                { label: i18n("All"), mode: 0 },
                                { label: i18n("Day"), mode: 1 },
                                { label: i18n("Month"), mode: 2 }
                            ]

                            PlasmaComponents.ToolButton {
                                text: modelData.label
                                checked: costCard.costViewMode === modelData.mode
                                onClicked: costCard.costViewMode = modelData.mode
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                                implicitHeight: Kirigami.Units.gridUnit * 1.2
                            }
                        }
                    }
                }

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: {
                        var val = costCard.costViewMode === 0 ? costCard.totalCost
                                : costCard.costViewMode === 1 ? costCard.totalDailyCost
                                : costCard.totalMonthlyCost;
                        return "$" + val.toFixed(val < 1 ? 4 : 2);
                    }
                    font.bold: true
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.3
                    horizontalAlignment: costCard.narrowCard ? Text.AlignLeft : Text.AlignRight
                    color: {
                        var cost = costCard.costViewMode === 0 ? costCard.totalCost
                                 : costCard.costViewMode === 1 ? costCard.totalDailyCost
                                 : costCard.totalMonthlyCost;
                        if (cost > 50) return Kirigami.Theme.negativeTextColor;
                        if (cost > 20) return Kirigami.Theme.neutralTextColor;
                        return Kirigami.Theme.textColor;
                    }
                }

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    visible: costCard.costViewMode === 2 && root.totalMonthlyProjection > 0
                    text: i18n("Projected: $%1", root.totalMonthlyProjection.toFixed(2))
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                    horizontalAlignment: costCard.narrowCard ? Text.AlignLeft : Text.AlignRight
                }

                // NEW: Budget Health Progress Bar
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    visible: {
                        var budget = costCard.costViewMode === 1 ? costCard.totalDailyBudget : costCard.totalMonthlyBudget;
                        return budget > 0 && costCard.costViewMode !== 0; // Only show for Day/Month
                    }

                    Rectangle {
                        id: budgetBarBg
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        color: Qt.alpha(Kirigami.Theme.textColor, 0.1)

                        Rectangle {
                            id: budgetBarFill
                            height: parent.height
                            radius: parent.radius
                            width: {
                                var cost = costCard.costViewMode === 1 ? costCard.totalDailyCost : costCard.totalMonthlyCost;
                                var budget = costCard.costViewMode === 1 ? costCard.totalDailyBudget : costCard.totalMonthlyBudget;
                                if (budget <= 0) return 0;
                                return Math.min(parent.width, (cost / budget) * parent.width);
                            }
                            color: {
                                var cost = costCard.costViewMode === 1 ? costCard.totalDailyCost : costCard.totalMonthlyCost;
                                var budget = costCard.costViewMode === 1 ? costCard.totalDailyBudget : costCard.totalMonthlyBudget;
                                var percent = (cost / budget) * 100;
                                if (percent >= 95) return Kirigami.Theme.negativeTextColor;
                                if (percent >= 80) return Kirigami.Theme.neutralTextColor;
                                return Kirigami.Theme.positiveTextColor;
                            }
                            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        }
                    }

                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.6
                        horizontalAlignment: Text.AlignRight
                        text: {
                            var budget = costCard.costViewMode === 1 ? costCard.totalDailyBudget : costCard.totalMonthlyBudget;
                            return i18n("Budget: $%1", budget.toFixed(2));
                        }
                    }
                }
            }

            // Per-provider cost breakdown
            Repeater {
                model: costCard.providers

                RowLayout {
                    Layout.fillWidth: true
                    readonly property double providerCost: {
                        if (!modelData.backend) return 0;
                        if (costCard.costViewMode === 1) return modelData.backend.dailyCost ?? 0;
                        if (costCard.costViewMode === 2) return modelData.backend.monthlyCost ?? 0;
                        return modelData.backend.cost ?? 0;
                    }
                    visible: modelData.enabled && modelData.backend && modelData.backend.connected && providerCost > 0
                    spacing: Kirigami.Units.smallSpacing

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: modelData.color
                    }

                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        maximumLineCount: costCard.narrowCard ? 2 : 1
                        wrapMode: costCard.narrowCard ? Text.WordWrap : Text.NoWrap
                        text: modelData.name
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.7
                    }

                    Item { Layout.fillWidth: true }

                    PlasmaComponents.Label {
                        text: "$" + parent.providerCost.toFixed(parent.providerCost < 1 ? 4 : 2)
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                    }
                }
            }

            Repeater {
                model: costCard.subscriptionTools

                RowLayout {
                    Layout.fillWidth: true
                    readonly property double toolCost: {
                        if (!modelData.monitor || !modelData.monitor.hasSubscriptionCost) return 0;
                        return modelData.monitor.subscriptionCost ?? 0;
                    }
                    visible: costCard.costViewMode === 0 && modelData.enabled && toolCost > 0
                    spacing: Kirigami.Units.smallSpacing

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: modelData.monitor?.toolColor ?? Kirigami.Theme.highlightColor
                    }

                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        maximumLineCount: costCard.narrowCard ? 2 : 1
                        wrapMode: costCard.narrowCard ? Text.WordWrap : Text.NoWrap
                        text: i18n("%1 (subscription)", modelData.name)
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.7
                    }

                    Item { Layout.fillWidth: true }

                    PlasmaComponents.Label {
                        text: "$" + parent.toolCost.toFixed(parent.toolCost < 1 ? 4 : 2)
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                    }
                }
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                text: root.intelligence.shortSnippet
                visible: text !== ""
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                font.italic: true
                color: Kirigami.Theme.highlightColor
                wrapMode: Text.WordWrap
                opacity: 0.9
            }
        }
    }
}
