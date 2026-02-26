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

    property alias cfg_openaiRefreshInterval: openaiRefreshSlider.value
    property alias cfg_anthropicRefreshInterval: anthropicRefreshSlider.value
    property alias cfg_googleRefreshInterval: googleRefreshSlider.value
    property alias cfg_mistralRefreshInterval: mistralRefreshSlider.value
    property alias cfg_deepseekRefreshInterval: deepseekRefreshSlider.value
    property alias cfg_groqRefreshInterval: groqRefreshSlider.value
    property alias cfg_xaiRefreshInterval: xaiRefreshSlider.value
    property alias cfg_googleveoRefreshInterval: googleveoRefreshSlider.value

    Kirigami.FormLayout {
        anchors.fill: parent

        // ── Global Refresh Interval ──
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
                text: formatInterval(refreshSlider.value)
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
                i18n("Active providers count")
            ]
            QQC2.ToolTip.text: i18n("Choose what to display next to the icon in the system panel")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 500
            currentIndex: {
                switch (generalPage.cfg_compactDisplayMode) {
                    case "cost": return 1;
                    case "count": return 2;
                    default: return 0;
                }
            }
            onCurrentIndexChanged: {
                switch (currentIndex) {
                    case 1: generalPage.cfg_compactDisplayMode = "cost"; break;
                    case 2: generalPage.cfg_compactDisplayMode = "count"; break;
                    default: generalPage.cfg_compactDisplayMode = "icon"; break;
                }
            }
        }

        // ── Per-Provider Refresh Intervals ──
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

        // OpenAI
        ColumnLayout {
            Kirigami.FormData.label: i18n("OpenAI:")
            spacing: 2

            QQC2.Slider {
                id: openaiRefreshSlider
                Layout.fillWidth: true
                from: 0; to: 1800; stepSize: 60
                value: plasmoid.configuration.openaiRefreshInterval
            }
            QQC2.Label {
                text: openaiRefreshSlider.value === 0 ? i18n("Use default") : formatInterval(openaiRefreshSlider.value)
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                opacity: 0.7; Layout.alignment: Qt.AlignHCenter
            }
        }

        // Anthropic
        ColumnLayout {
            Kirigami.FormData.label: i18n("Anthropic:")
            spacing: 2

            QQC2.Slider {
                id: anthropicRefreshSlider
                Layout.fillWidth: true
                from: 0; to: 1800; stepSize: 60
                value: plasmoid.configuration.anthropicRefreshInterval
            }
            QQC2.Label {
                text: anthropicRefreshSlider.value === 0 ? i18n("Use default") : formatInterval(anthropicRefreshSlider.value)
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                opacity: 0.7; Layout.alignment: Qt.AlignHCenter
            }
        }

        // Google
        ColumnLayout {
            Kirigami.FormData.label: i18n("Google Gemini:")
            spacing: 2

            QQC2.Slider {
                id: googleRefreshSlider
                Layout.fillWidth: true
                from: 0; to: 1800; stepSize: 60
                value: plasmoid.configuration.googleRefreshInterval
            }
            QQC2.Label {
                text: googleRefreshSlider.value === 0 ? i18n("Use default") : formatInterval(googleRefreshSlider.value)
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                opacity: 0.7; Layout.alignment: Qt.AlignHCenter
            }
        }

        // Mistral
        ColumnLayout {
            Kirigami.FormData.label: i18n("Mistral AI:")
            spacing: 2

            QQC2.Slider {
                id: mistralRefreshSlider
                Layout.fillWidth: true
                from: 0; to: 1800; stepSize: 60
                value: plasmoid.configuration.mistralRefreshInterval
            }
            QQC2.Label {
                text: mistralRefreshSlider.value === 0 ? i18n("Use default") : formatInterval(mistralRefreshSlider.value)
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                opacity: 0.7; Layout.alignment: Qt.AlignHCenter
            }
        }

        // DeepSeek
        ColumnLayout {
            Kirigami.FormData.label: i18n("DeepSeek:")
            spacing: 2

            QQC2.Slider {
                id: deepseekRefreshSlider
                Layout.fillWidth: true
                from: 0; to: 1800; stepSize: 60
                value: plasmoid.configuration.deepseekRefreshInterval
            }
            QQC2.Label {
                text: deepseekRefreshSlider.value === 0 ? i18n("Use default") : formatInterval(deepseekRefreshSlider.value)
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                opacity: 0.7; Layout.alignment: Qt.AlignHCenter
            }
        }

        // Groq
        ColumnLayout {
            Kirigami.FormData.label: i18n("Groq:")
            spacing: 2

            QQC2.Slider {
                id: groqRefreshSlider
                Layout.fillWidth: true
                from: 0; to: 1800; stepSize: 60
                value: plasmoid.configuration.groqRefreshInterval
            }
            QQC2.Label {
                text: groqRefreshSlider.value === 0 ? i18n("Use default") : formatInterval(groqRefreshSlider.value)
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                opacity: 0.7; Layout.alignment: Qt.AlignHCenter
            }
        }

        // xAI
        ColumnLayout {
            Kirigami.FormData.label: i18n("xAI / Grok:")
            spacing: 2

            QQC2.Slider {
                id: xaiRefreshSlider
                Layout.fillWidth: true
                from: 0; to: 1800; stepSize: 60
                value: plasmoid.configuration.xaiRefreshInterval
            }
            QQC2.Label {
                text: xaiRefreshSlider.value === 0 ? i18n("Use default") : formatInterval(xaiRefreshSlider.value)
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                opacity: 0.7; Layout.alignment: Qt.AlignHCenter
            }
        }

        ColumnLayout {
            Kirigami.FormData.label: i18n("Google Veo:")
            spacing: 2

            QQC2.Slider {
                id: googleveoRefreshSlider
                Layout.fillWidth: true
                from: 0; to: 1800; stepSize: 60
                value: plasmoid.configuration.googleveoRefreshInterval
            }
            QQC2.Label {
                text: googleveoRefreshSlider.value === 0 ? i18n("Use default") : formatInterval(googleveoRefreshSlider.value)
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                opacity: 0.7; Layout.alignment: Qt.AlignHCenter
            }
        }

        // ── About ──
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

    function formatInterval(secs) {
        if (secs >= 60) {
            var mins = Math.floor(secs / 60);
            return i18np("%1 minute", "%1 minutes", mins);
        }
        return i18np("%1 second", "%1 seconds", secs);
    }
}
