import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: alertsPage

    property alias cfg_alertsEnabled: alertsSwitch.checked
    property alias cfg_warningThreshold: warningSlider.value
    property alias cfg_criticalThreshold: criticalSlider.value
    property alias cfg_notifyOnError: errorNotifySwitch.checked
    property alias cfg_notifyOnBudgetWarning: budgetNotifySwitch.checked
    property alias cfg_notifyOnDisconnect: disconnectNotifySwitch.checked
    property alias cfg_notifyOnReconnect: reconnectNotifySwitch.checked
    property alias cfg_notificationCooldownMinutes: cooldownSlider.value
    // DND hours: config stores -1 (disabled) or 0-23 (hour).
    // ComboBox index: 0 = "Disabled", 1-24 = hours 0-23.
    // We use explicit properties instead of alias to handle the mapping.
    property int cfg_dndStartHour: plasmoid.configuration.dndStartHour
    property int cfg_dndEndHour: plasmoid.configuration.dndEndHour

    // Per-provider notification toggles
    property alias cfg_openaiNotificationsEnabled: openaiNotifySwitch.checked
    property alias cfg_anthropicNotificationsEnabled: anthropicNotifySwitch.checked
    property alias cfg_googleNotificationsEnabled: googleNotifySwitch.checked
    property alias cfg_mistralNotificationsEnabled: mistralNotifySwitch.checked
    property alias cfg_deepseekNotificationsEnabled: deepseekNotifySwitch.checked
    property alias cfg_groqNotificationsEnabled: groqNotifySwitch.checked
    property alias cfg_xaiNotificationsEnabled: xaiNotifySwitch.checked
    property alias cfg_openrouterNotificationsEnabled: openrouterNotifySwitch.checked
    property alias cfg_togetherNotificationsEnabled: togetherNotifySwitch.checked
    property alias cfg_cohereNotificationsEnabled: cohereNotifySwitch.checked
    property alias cfg_googleveoNotificationsEnabled: googleveoNotifySwitch.checked
    property alias cfg_azureNotificationsEnabled: azureNotifySwitch.checked
    property alias cfg_loofiNotificationsEnabled: loofiNotifySwitch.checked
    property alias cfg_notifyOnUpdate: updateNotifySwitch.checked
    property alias cfg_updateCheckInterval: updateCheckSpinBox.value

    Kirigami.FormLayout {
        anchors.fill: parent

        // ── Master Toggle ──
        QQC2.Switch {
            id: alertsSwitch
            Kirigami.FormData.label: i18n("Enable alerts:")
            checked: plasmoid.configuration.alertsEnabled
        }

        // ── Rate Limit Thresholds ──
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Rate Limit Thresholds")
        }

        ColumnLayout {
            Kirigami.FormData.label: i18n("Warning threshold:")
            enabled: alertsSwitch.checked
            spacing: Kirigami.Units.smallSpacing

            QQC2.Slider {
                id: warningSlider
                Layout.fillWidth: true
                from: 50; to: 95; stepSize: 5
                value: plasmoid.configuration.warningThreshold

                onValueChanged: {
                    if (value >= criticalSlider.value) {
                        value = criticalSlider.value - 5;
                    }
                }
            }

            QQC2.Label {
                text: i18n("%1% of rate limit used", warningSlider.value)
                opacity: 0.7; Layout.alignment: Qt.AlignHCenter
            }

            QQC2.Label {
                text: i18n("Shows yellow warning indicator and optional notification")
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                opacity: 0.5; wrapMode: Text.WordWrap; Layout.fillWidth: true
            }
        }

        ColumnLayout {
            Kirigami.FormData.label: i18n("Critical threshold:")
            enabled: alertsSwitch.checked
            spacing: Kirigami.Units.smallSpacing

            QQC2.Slider {
                id: criticalSlider
                Layout.fillWidth: true
                from: 60; to: 100; stepSize: 5
                value: plasmoid.configuration.criticalThreshold

                onValueChanged: {
                    if (value <= warningSlider.value) {
                        value = warningSlider.value + 5;
                    }
                }
            }

            QQC2.Label {
                text: i18n("%1% of rate limit used", criticalSlider.value)
                opacity: 0.7; Layout.alignment: Qt.AlignHCenter
            }

            QQC2.Label {
                text: i18n("Shows red critical indicator and urgent notification")
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                opacity: 0.5; wrapMode: Text.WordWrap; Layout.fillWidth: true
            }
        }

        // ── Notification Types ──
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Notification Types")
        }

        QQC2.Switch {
            id: errorNotifySwitch
            Kirigami.FormData.label: i18n("API errors:")
            enabled: alertsSwitch.checked
            checked: plasmoid.configuration.notifyOnError
        }

        QQC2.Switch {
            id: budgetNotifySwitch
            Kirigami.FormData.label: i18n("Budget warnings:")
            enabled: alertsSwitch.checked
            checked: plasmoid.configuration.notifyOnBudgetWarning
        }

        QQC2.Switch {
            id: disconnectNotifySwitch
            Kirigami.FormData.label: i18n("Provider disconnected:")
            enabled: alertsSwitch.checked
            checked: plasmoid.configuration.notifyOnDisconnect
        }

        QQC2.Switch {
            id: reconnectNotifySwitch
            Kirigami.FormData.label: i18n("Provider reconnected:")
            enabled: alertsSwitch.checked
            checked: plasmoid.configuration.notifyOnReconnect
        }

        // ── Per-Provider Toggles ──
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Per-Provider Notifications")
        }

        QQC2.Label {
            text: i18n("Disable notifications for specific providers. Global types above still apply.")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.6; wrapMode: Text.WordWrap; Layout.fillWidth: true
        }

        QQC2.Switch {
            id: openaiNotifySwitch
            Kirigami.FormData.label: i18n("OpenAI:")
            enabled: alertsSwitch.checked
            checked: plasmoid.configuration.openaiNotificationsEnabled
        }

        QQC2.Switch {
            id: anthropicNotifySwitch
            Kirigami.FormData.label: i18n("Anthropic:")
            enabled: alertsSwitch.checked
            checked: plasmoid.configuration.anthropicNotificationsEnabled
        }

        QQC2.Switch {
            id: googleNotifySwitch
            Kirigami.FormData.label: i18n("Google Gemini:")
            enabled: alertsSwitch.checked
            checked: plasmoid.configuration.googleNotificationsEnabled
        }

        QQC2.Switch {
            id: mistralNotifySwitch
            Kirigami.FormData.label: i18n("Mistral AI:")
            enabled: alertsSwitch.checked
            checked: plasmoid.configuration.mistralNotificationsEnabled
        }

        QQC2.Switch {
            id: deepseekNotifySwitch
            Kirigami.FormData.label: i18n("DeepSeek:")
            enabled: alertsSwitch.checked
            checked: plasmoid.configuration.deepseekNotificationsEnabled
        }

        QQC2.Switch {
            id: groqNotifySwitch
            Kirigami.FormData.label: i18n("Groq:")
            enabled: alertsSwitch.checked
            checked: plasmoid.configuration.groqNotificationsEnabled
        }

        QQC2.Switch {
            id: xaiNotifySwitch
            Kirigami.FormData.label: i18n("xAI / Grok:")
            enabled: alertsSwitch.checked
            checked: plasmoid.configuration.xaiNotificationsEnabled
        }

        QQC2.Switch {
            id: openrouterNotifySwitch
            Kirigami.FormData.label: i18n("OpenRouter:")
            enabled: alertsSwitch.checked
            checked: plasmoid.configuration.openrouterNotificationsEnabled
        }

        QQC2.Switch {
            id: togetherNotifySwitch
            Kirigami.FormData.label: i18n("Together AI:")
            enabled: alertsSwitch.checked
            checked: plasmoid.configuration.togetherNotificationsEnabled
        }

        QQC2.Switch {
            id: cohereNotifySwitch
            Kirigami.FormData.label: i18n("Cohere:")
            enabled: alertsSwitch.checked
            checked: plasmoid.configuration.cohereNotificationsEnabled
        }

        QQC2.Switch {
            id: googleveoNotifySwitch
            Kirigami.FormData.label: i18n("Google Veo:")
            enabled: alertsSwitch.checked
            checked: plasmoid.configuration.googleveoNotificationsEnabled
        }

        QQC2.Switch {
            id: azureNotifySwitch
            Kirigami.FormData.label: i18n("Azure OpenAI:")
            enabled: alertsSwitch.checked
            checked: plasmoid.configuration.azureNotificationsEnabled
        }

        QQC2.Switch {
            id: loofiNotifySwitch
            Kirigami.FormData.label: i18n("Loofi Server:")
            enabled: alertsSwitch.checked
            checked: plasmoid.configuration.loofiNotificationsEnabled
        }

        // ── Update Notifications ──
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Update Notifications")
        }

        QQC2.Switch {
            id: updateNotifySwitch
            Kirigami.FormData.label: i18n("Notify on new version:")
            enabled: alertsSwitch.checked
            checked: plasmoid.configuration.notifyOnUpdate
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Check every:")
            enabled: alertsSwitch.checked && updateNotifySwitch.checked
            spacing: Kirigami.Units.smallSpacing

            QQC2.SpinBox {
                id: updateCheckSpinBox
                from: 1; to: 168; stepSize: 1
                value: plasmoid.configuration.updateCheckInterval
            }

            QQC2.Label {
                text: i18n("hours")
                opacity: 0.7
            }
        }

        QQC2.Label {
            text: i18n("Checks GitHub for new releases and shows a KDE notification when an update is available.")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.5; wrapMode: Text.WordWrap; Layout.fillWidth: true
            enabled: alertsSwitch.checked
        }

        // ── Cooldown & DND ──
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Cooldown & Do Not Disturb")
        }

        ColumnLayout {
            Kirigami.FormData.label: i18n("Notification cooldown:")
            enabled: alertsSwitch.checked
            spacing: Kirigami.Units.smallSpacing

            QQC2.Slider {
                id: cooldownSlider
                Layout.fillWidth: true
                from: 1; to: 60; stepSize: 1
                value: plasmoid.configuration.notificationCooldownMinutes
            }

            QQC2.Label {
                text: i18np("%1 minute between repeated notifications", "%1 minutes between repeated notifications", cooldownSlider.value)
                opacity: 0.7; Layout.alignment: Qt.AlignHCenter
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                wrapMode: Text.WordWrap; Layout.fillWidth: true
            }
        }

        // DND schedule
        RowLayout {
            Kirigami.FormData.label: i18n("Do Not Disturb:")
            enabled: alertsSwitch.checked
            spacing: Kirigami.Units.smallSpacing

            QQC2.ComboBox {
                id: dndStartCombo
                model: buildHourModel()
                currentIndex: cfg_dndStartHour >= 0 ? cfg_dndStartHour + 1 : 0
                onCurrentIndexChanged: {
                    cfg_dndStartHour = currentIndex === 0 ? -1 : currentIndex - 1;
                }
            }

            QQC2.Label { text: i18n("to") }

            QQC2.ComboBox {
                id: dndEndCombo
                enabled: dndStartCombo.currentIndex > 0
                model: buildHourModel()
                currentIndex: cfg_dndEndHour >= 0 ? cfg_dndEndHour + 1 : 0
                onCurrentIndexChanged: {
                    cfg_dndEndHour = currentIndex === 0 ? -1 : currentIndex - 1;
                }
            }
        }

        QQC2.Label {
            enabled: alertsSwitch.checked
            text: i18n("Suppress all notifications during this time window. Set start to 'Disabled' to turn off DND.")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.5; wrapMode: Text.WordWrap; Layout.fillWidth: true
        }

        // ── Preview ──
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Preview")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Status colors:")
            spacing: Kirigami.Units.largeSpacing

            RowLayout {
                spacing: Kirigami.Units.smallSpacing
                Rectangle { width: 12; height: 12; radius: 6; color: Kirigami.Theme.positiveTextColor }
                QQC2.Label { text: i18n("OK"); font.pointSize: Kirigami.Theme.smallFont.pointSize }
            }

            RowLayout {
                spacing: Kirigami.Units.smallSpacing
                Rectangle { width: 12; height: 12; radius: 6; color: Kirigami.Theme.neutralTextColor }
                QQC2.Label { text: i18n("Warning"); font.pointSize: Kirigami.Theme.smallFont.pointSize }
            }

            RowLayout {
                spacing: Kirigami.Units.smallSpacing
                Rectangle { width: 12; height: 12; radius: 6; color: Kirigami.Theme.negativeTextColor }
                QQC2.Label { text: i18n("Critical"); font.pointSize: Kirigami.Theme.smallFont.pointSize }
            }
        }
    }

    function buildHourModel() {
        var items = [i18n("Disabled")];
        for (var h = 0; h < 24; h++) {
            items.push(h.toString().padStart(2, '0') + ":00");
        }
        return items;
    }
}
