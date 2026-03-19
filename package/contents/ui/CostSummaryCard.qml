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
    readonly property int activeProviderCount: {
        var count = 0;
        for (var i = 0; i < providers.length; i++) {
            if (providers[i].enabled && providers[i].backend && providers[i].backend.connected)
                count++;
        }
        return count;
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

            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    PlasmaExtras.Heading {
                        level: 4
                        text: costCard.costViewMode === 0 ? i18n("Cost Snapshot")
                            : costCard.costViewMode === 1 ? i18n("Today's Cost")
                            : i18n("Monthly Cost")
                    }

                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: {
                            if (costCard.costViewMode === 0)
                                return i18n("%1 providers and %2 subscription tools are contributing to the total.",
                                            costCard.activeProviderCount,
                                            costCard.subscriptionTotalCost > 0 ? 1 : 0);
                            if (costCard.costViewMode === 1)
                                return i18n("Use this to catch fast cost spikes before monthly budgets drift.");
                            return i18n("Monthly estimates combine live provider spend and fixed subscription tooling.");
                        }
                        opacity: 0.65
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                    }
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

                PlasmaComponents.Label {
                    text: {
                        var val = costCard.costViewMode === 0 ? costCard.totalCost
                                : costCard.costViewMode === 1 ? costCard.totalDailyCost
                                : costCard.totalMonthlyCost;
                        return "$" + val.toFixed(val < 1 ? 4 : 2);
                    }
                    font.bold: true
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.3
                    color: {
                        var cost = costCard.costViewMode === 0 ? costCard.totalCost
                                 : costCard.costViewMode === 1 ? costCard.totalDailyCost
                                 : costCard.totalMonthlyCost;
                        if (cost > 50) return Kirigami.Theme.negativeTextColor;
                        if (cost > 20) return Kirigami.Theme.neutralTextColor;
                        return Kirigami.Theme.textColor;
                    }
                }
            }

            Flow {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Repeater {
                    model: [
                        {
                            label: i18n("Live providers"),
                            value: i18n("%1 active", costCard.activeProviderCount),
                            tint: Kirigami.Theme.positiveTextColor
                        },
                        {
                            label: i18n("Subscriptions"),
                            value: i18n("$%1", costCard.subscriptionTotalCost.toFixed(costCard.subscriptionTotalCost < 1 ? 4 : 2)),
                            tint: Kirigami.Theme.textColor
                        },
                        {
                            label: i18n("Today"),
                            value: i18n("$%1", costCard.totalDailyCost.toFixed(costCard.totalDailyCost < 1 ? 4 : 2)),
                            tint: costCard.totalDailyCost > 20 ? Kirigami.Theme.neutralTextColor : Kirigami.Theme.textColor
                        },
                        {
                            label: i18n("Month"),
                            value: i18n("$%1", costCard.totalMonthlyCost.toFixed(costCard.totalMonthlyCost < 1 ? 4 : 2)),
                            tint: costCard.totalMonthlyCost > 50 ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
                        }
                    ]

                    Rectangle {
                        width: Math.max(Kirigami.Units.gridUnit * 5,
                                        (costCard.width - Kirigami.Units.largeSpacing * 2 - Kirigami.Units.smallSpacing * 3) / 4)
                        height: statColumn.implicitHeight + Kirigami.Units.smallSpacing * 2
                        radius: Kirigami.Units.smallSpacing
                        color: Qt.alpha(modelData.tint, 0.08)
                        border.width: 1
                        border.color: Qt.alpha(modelData.tint, 0.14)

                        ColumnLayout {
                            id: statColumn
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing
                            spacing: 2

                            PlasmaComponents.Label {
                                text: modelData.label
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                                opacity: 0.6
                                elide: Text.ElideRight
                            }

                            PlasmaComponents.Label {
                                text: modelData.value
                                font.bold: true
                                color: modelData.tint
                                elide: Text.ElideRight
                            }
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
        }
    }
}
