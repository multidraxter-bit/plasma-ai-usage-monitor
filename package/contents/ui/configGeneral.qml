pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import com.github.loofi.aiusagemonitor 1.0

KCM.SimpleKCM {
    id: generalPage

    property alias cfg_refreshInterval: refreshSlider.value
    property string cfg_compactDisplayMode: plasmoid.configuration.compactDisplayMode

    property int cfg_openaiRefreshInterval: plasmoid.configuration.openaiRefreshInterval
    property int cfg_anthropicRefreshInterval: plasmoid.configuration.anthropicRefreshInterval
    property int cfg_googleRefreshInterval: plasmoid.configuration.googleRefreshInterval
    property int cfg_mistralRefreshInterval: plasmoid.configuration.mistralRefreshInterval
    property int cfg_deepseekRefreshInterval: plasmoid.configuration.deepseekRefreshInterval
    property int cfg_groqRefreshInterval: plasmoid.configuration.groqRefreshInterval
    property int cfg_xaiRefreshInterval: plasmoid.configuration.xaiRefreshInterval
    property int cfg_ollamaRefreshInterval: plasmoid.configuration.ollamaRefreshInterval
    property int cfg_openrouterRefreshInterval: plasmoid.configuration.openrouterRefreshInterval
    property int cfg_togetherRefreshInterval: plasmoid.configuration.togetherRefreshInterval
    property int cfg_cohereRefreshInterval: plasmoid.configuration.cohereRefreshInterval
    property int cfg_googleveoRefreshInterval: plasmoid.configuration.googleveoRefreshInterval
    property int cfg_azureRefreshInterval: plasmoid.configuration.azureRefreshInterval
    property int cfg_loofiRefreshInterval: plasmoid.configuration.loofiRefreshInterval

    property ProviderCatalog providerCatalog: ProviderCatalog {}

    function refreshValue(refreshConfigKey) {
        return generalPage["cfg_" + refreshConfigKey];
    }

    function setRefreshValue(refreshConfigKey, value) {
        generalPage["cfg_" + refreshConfigKey] = value;
    }

    function formatInterval(secs) {
        if (secs >= 60) {
            var mins = Math.floor(secs / 60);
            return i18np("%1 minute", "%1 minutes", mins);
        }
        return i18np("%1 second", "%1 seconds", secs);
    }

    Kirigami.FormLayout {
        anchors.fill: parent

        ColumnLayout {
            Kirigami.FormData.label: i18n("Default refresh interval:")
            spacing: Kirigami.Units.smallSpacing

            QQC2.Slider {
                id: refreshSlider
                Layout.fillWidth: true
                from: 60
                to: 1800
                stepSize: 60
                value: plasmoid.configuration.refreshInterval
                QQC2.ToolTip.text: i18n("How often to poll provider APIs for updated data (60s–30min)")
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: 500
            }

            QQC2.Label {
                text: generalPage.formatInterval(refreshSlider.value)
                opacity: 0.7
                Layout.alignment: Qt.AlignHCenter
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Panel Display")
        }

        QQC2.ComboBox {
            id: compactModeCombo
            Kirigami.FormData.label: i18n("Show in panel:")
            model: [
                i18n("Icon only"),
                i18n("Total cost"),
                i18n("Active providers count"),
                i18n("Loofi server KPIs")
            ]
            QQC2.ToolTip.text: i18n("Choose what to display next to the icon in the system panel")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 500
            currentIndex: {
                switch (generalPage.cfg_compactDisplayMode) {
                case "cost":
                    return 1;
                case "count":
                    return 2;
                case "loofi":
                    return 3;
                default:
                    return 0;
                }
            }
            onCurrentIndexChanged: {
                switch (currentIndex) {
                case 1:
                    generalPage.cfg_compactDisplayMode = "cost";
                    break;
                case 2:
                    generalPage.cfg_compactDisplayMode = "count";
                    break;
                case 3:
                    generalPage.cfg_compactDisplayMode = "loofi";
                    break;
                default:
                    generalPage.cfg_compactDisplayMode = "icon";
                    break;
                }
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Per-Provider Refresh Intervals")
        }

        QQC2.Label {
            text: i18n("Set to 0 to use the default interval above. Otherwise, each provider refreshes on its own schedule.")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.6
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Repeater {
            model: providerCatalog.providers

            ColumnLayout {
                spacing: 2
                Kirigami.FormData.label: modelData.label + ":"

                QQC2.Slider {
                    id: providerRefreshSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 1800
                    stepSize: 60
                    value: generalPage.refreshValue(modelData.refreshConfigKey)
                    onValueChanged: generalPage.setRefreshValue(modelData.refreshConfigKey, value)
                }

                QQC2.Label {
                    text: providerRefreshSlider.value === 0
                        ? i18n("Use default")
                        : generalPage.formatInterval(providerRefreshSlider.value)
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.7
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("About")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Icon:")

            Kirigami.Icon {
                source: Qt.resolvedUrl("../icons/logo.png")
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
            }

            QQC2.Label {
                text: i18n("AI Usage Monitor")
                opacity: 0.8
            }
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Version:")
            text: (plasmoid.metaData && plasmoid.metaData.version)
                  ? plasmoid.metaData.version
                  : AppInfo.version
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Description:")
            text: i18n("Monitor AI API token usage, rate limits, costs, and budgets across multiple providers")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }
}
