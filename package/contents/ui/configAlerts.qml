pragma ComponentBehavior: Bound

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
    property alias cfg_notifyOnUpdate: updateNotifySwitch.checked
    property alias cfg_updateCheckInterval: updateCheckSpinBox.value

    property bool cfg_openaiNotificationsEnabled: plasmoid.configuration.openaiNotificationsEnabled
    property bool cfg_anthropicNotificationsEnabled: plasmoid.configuration.anthropicNotificationsEnabled
    property bool cfg_googleNotificationsEnabled: plasmoid.configuration.googleNotificationsEnabled
    property bool cfg_mistralNotificationsEnabled: plasmoid.configuration.mistralNotificationsEnabled
    property bool cfg_deepseekNotificationsEnabled: plasmoid.configuration.deepseekNotificationsEnabled
    property bool cfg_groqNotificationsEnabled: plasmoid.configuration.groqNotificationsEnabled
    property bool cfg_xaiNotificationsEnabled: plasmoid.configuration.xaiNotificationsEnabled
    property bool cfg_ollamaNotificationsEnabled: plasmoid.configuration.ollamaNotificationsEnabled
    property bool cfg_openrouterNotificationsEnabled: plasmoid.configuration.openrouterNotificationsEnabled
    property bool cfg_togetherNotificationsEnabled: plasmoid.configuration.togetherNotificationsEnabled
    property bool cfg_cohereNotificationsEnabled: plasmoid.configuration.cohereNotificationsEnabled
    property bool cfg_googleveoNotificationsEnabled: plasmoid.configuration.googleveoNotificationsEnabled
    property bool cfg_azureNotificationsEnabled: plasmoid.configuration.azureNotificationsEnabled
    property bool cfg_loofiNotificationsEnabled: plasmoid.configuration.loofiNotificationsEnabled

    // DND hours: config stores -1 (disabled) or 0-23 (hour).
    // ComboBox index: 0 = "Disabled", 1-24 = hours 0-23.
    property int cfg_dndStartHour: plasmoid.configuration.dndStartHour
    property int cfg_dndEndHour: plasmoid.configuration.dndEndHour

    property ProviderCatalog providerCatalog: ProviderCatalog {}

    function notificationEnabled(notificationsConfigKey) {
        return alertsPage["cfg_" + notificationsConfigKey];
    }

    function setNotificationEnabled(notificationsConfigKey, enabled) {
        alertsPage["cfg_" + notificationsConfigKey] = enabled;
    }

    function buildHourModel() {
        var items = [i18n("Disabled")];
        for (var h = 0; h < 24; h++) {
            items.push(h.toString().padStart(2, "0") + ":00");
        }
        return items;
    }

    Kirigami.FormLayout {
        anchors.fill: parent

        QQC2.Switch {
            id: alertsSwitch
            Kirigami.FormData.label: i18n("Enable alerts:")
            checked: plasmoid.configuration.alertsEnabled
        }

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
                from: 50
                to: 95
                stepSize: 5
                value: plasmoid.configuration.warningThreshold

                onValueChanged: {
                    if (value >= criticalSlider.value) {
                        value = criticalSlider.value - 5;
                    }
                }
            }

            QQC2.Label {
                text: i18n("%1% of rate limit used", warningSlider.value)
                opacity: 0.7
                Layout.alignment: Qt.AlignHCenter
            }

            QQC2.Label {
                text: i18n("Shows yellow warning indicator and optional notification")
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                opacity: 0.5
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        ColumnLayout {
            Kirigami.FormData.label: i18n("Critical threshold:")
            enabled: alertsSwitch.checked
            spacing: Kirigami.Units.smallSpacing

            QQC2.Slider {
                id: criticalSlider
                Layout.fillWidth: true
                from: 60
                to: 100
                stepSize: 5
                value: plasmoid.configuration.criticalThreshold

                onValueChanged: {
                    if (value <= warningSlider.value) {
                        value = warningSlider.value + 5;
                    }
                }
            }

            QQC2.Label {
                text: i18n("%1% of rate limit used", criticalSlider.value)
                opacity: 0.7
                Layout.alignment: Qt.AlignHCenter
            }

            QQC2.Label {
                text: i18n("Shows red critical indicator and urgent notification")
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                opacity: 0.5
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

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

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Per-Provider Notifications")
        }

        QQC2.Label {
            text: i18n("Disable notifications for specific providers. Global types above still apply.")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.6
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Repeater {
            model: providerCatalog.providers

            QQC2.Switch {
                checked: alertsPage.notificationEnabled(modelData.notificationsConfigKey)
                Kirigami.FormData.label: modelData.label + ":"
                enabled: alertsSwitch.checked
                onToggled: alertsPage.setNotificationEnabled(modelData.notificationsConfigKey, checked)
            }
        }

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
                from: 1
                to: 168
                stepSize: 1
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
            opacity: 0.5
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            enabled: alertsSwitch.checked
        }

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
                from: 1
                to: 60
                stepSize: 1
                value: plasmoid.configuration.notificationCooldownMinutes
            }

            QQC2.Label {
                text: i18np("%1 minute between repeated notifications",
                            "%1 minutes between repeated notifications",
                            cooldownSlider.value)
                opacity: 0.7
                Layout.alignment: Qt.AlignHCenter
                font.pointSize: Kirigami.Theme.smallFont.pointSize
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Do Not Disturb:")
            enabled: alertsSwitch.checked
            spacing: Kirigami.Units.smallSpacing

            QQC2.ComboBox {
                id: dndStartCombo
                model: alertsPage.buildHourModel()
                currentIndex: cfg_dndStartHour >= 0 ? cfg_dndStartHour + 1 : 0
                onCurrentIndexChanged: cfg_dndStartHour = currentIndex === 0 ? -1 : currentIndex - 1
            }

            QQC2.Label {
                text: i18n("to")
            }

            QQC2.ComboBox {
                id: dndEndCombo
                enabled: dndStartCombo.currentIndex > 0
                model: alertsPage.buildHourModel()
                currentIndex: cfg_dndEndHour >= 0 ? cfg_dndEndHour + 1 : 0
                onCurrentIndexChanged: cfg_dndEndHour = currentIndex === 0 ? -1 : currentIndex - 1
            }
        }

        QQC2.Label {
            enabled: alertsSwitch.checked
            text: i18n("Suppress all notifications during this time window. Set start to 'Disabled' to turn off DND.")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.5
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Preview")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Status colors:")
            spacing: Kirigami.Units.largeSpacing

            RowLayout {
                spacing: Kirigami.Units.smallSpacing
                Rectangle { implicitWidth: 12; implicitHeight: 12; radius: 6; color: Kirigami.Theme.positiveTextColor }
                QQC2.Label { text: i18n("OK"); font.pointSize: Kirigami.Theme.smallFont.pointSize }
            }

            RowLayout {
                spacing: Kirigami.Units.smallSpacing
                Rectangle { implicitWidth: 12; implicitHeight: 12; radius: 6; color: Kirigami.Theme.neutralTextColor }
                QQC2.Label { text: i18n("Warning"); font.pointSize: Kirigami.Theme.smallFont.pointSize }
            }

            RowLayout {
                spacing: Kirigami.Units.smallSpacing
                Rectangle { implicitWidth: 12; implicitHeight: 12; radius: 6; color: Kirigami.Theme.negativeTextColor }
                QQC2.Label { text: i18n("Critical"); font.pointSize: Kirigami.Theme.smallFont.pointSize }
            }
        }
    }
}
