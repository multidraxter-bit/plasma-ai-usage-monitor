import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import "Utils.js" as Utils

ColumnLayout {
    id: card

    required property var backend
    property string providerColor: "#9B9B9B"
    property bool collapsed: false

    spacing: 0

    // Card background
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: cardContent.implicitHeight + Kirigami.Units.largeSpacing * 2
        radius: Kirigami.Units.cornerRadius
        color: {
            var base = Kirigami.Theme.backgroundColor;
            return Qt.darker(base, 1.05);
        }
        border.width: 1
        border.color: Qt.alpha(Kirigami.Theme.textColor, 0.1)

        Accessible.role: Accessible.Grouping
        Accessible.name: i18n("Ollama Provider")

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

            // Header row
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                // Provider color indicator
                Rectangle {
                    width: 4
                    Layout.preferredHeight: providerLabel.implicitHeight
                    radius: 2
                    color: card.providerColor
                }

                Kirigami.Icon {
                    source: "server"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                }

                PlasmaExtras.Heading {
                    id: providerLabel
                    level: 4
                    text: i18n("Ollama")
                    Layout.fillWidth: true
                }

                // Connection status
                PlasmaComponents.Label {
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    text: card.backend?.connected ? i18n("Online") : i18n("Offline")
                    color: card.backend?.connected ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.disabledTextColor
                }

                // Loading spinner
                PlasmaComponents.BusyIndicator {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    visible: card.backend?.loading ?? false
                    running: visible
                }

                // Collapse/expand toggle
                PlasmaComponents.ToolButton {
                    icon.name: card.collapsed ? "arrow-down" : "arrow-up"
                    display: PlasmaComponents.AbstractButton.IconOnly
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    onClicked: card.collapsed = !card.collapsed
                }
            }

            // Expanded content
            ColumnLayout {
                Layout.fillWidth: true
                visible: !card.collapsed
                spacing: Kirigami.Units.mediumSpacing

                Kirigami.Separator { Layout.fillWidth: true }

                // Active Models List
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    PlasmaComponents.Label {
                        text: i18n("Active Models")
                        font.bold: true
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.7
                        visible: (card.backend?.activeModels?.length ?? 0) > 0
                    }

                    Repeater {
                        model: card.backend?.activeModels ?? []
                        delegate: RowLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing

                            PlasmaComponents.Label {
                                text: modelData.name
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            PlasmaComponents.Label {
                                text: formatBytes(modelData.size)
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                                opacity: 0.6
                            }
                        }
                    }

                    PlasmaComponents.Label {
                        text: i18n("No active models")
                        font.italic: true
                        opacity: 0.5
                        visible: (card.backend?.activeModels?.length ?? 0) === 0
                    }
                }

                Kirigami.Separator { Layout.fillWidth: true }

                // Memory Usage
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: Kirigami.Units.smallSpacing

                    PlasmaComponents.Label {
                        text: i18n("VRAM Usage:")
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.7
                    }
                    PlasmaComponents.Label {
                        text: formatBytes(card.backend?.vramMemory ?? 0)
                        font.bold: true
                        Layout.alignment: Qt.AlignRight
                    }

                    PlasmaComponents.Label {
                        text: i18n("System RAM:")
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.7
                    }
                    PlasmaComponents.Label {
                        text: formatBytes((card.backend?.totalMemory ?? 0) - (card.backend?.vramMemory ?? 0))
                        font.bold: true
                        Layout.alignment: Qt.AlignRight
                    }
                }

                Kirigami.Separator { Layout.fillWidth: true }

                // Cost Display (Always $0.00 for local Ollama)
                RowLayout {
                    Layout.fillWidth: true
                    
                    PlasmaComponents.Label {
                        text: i18n("Cost:")
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.7
                    }

                    Item { Layout.fillWidth: true }

                    PlasmaComponents.Label {
                        text: "$0.00 " + i18n("(Local)")
                        font.bold: true
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
                        color: Kirigami.Theme.positiveTextColor
                    }
                }

                // Last updated
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: i18n("Updated: %1", Utils.formatRelativeTime(card.backend?.lastRefreshed))
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.4
                }
            }
        }
    }

    function formatBytes(bytes) {
        if (bytes === 0) return "0 B";
        var k = 1024;
        var sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
        var i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    }
}
