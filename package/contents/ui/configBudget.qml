import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: budgetPage

    // Config stores cents (Int). SpinBox value is also cents.
    property int cfg_openaiDailyBudget
    property int cfg_openaiMonthlyBudget
    property int cfg_anthropicDailyBudget
    property int cfg_anthropicMonthlyBudget
    property int cfg_googleDailyBudget
    property int cfg_googleMonthlyBudget
    property int cfg_mistralDailyBudget
    property int cfg_mistralMonthlyBudget
    property int cfg_deepseekDailyBudget
    property int cfg_deepseekMonthlyBudget
    property int cfg_groqDailyBudget
    property int cfg_groqMonthlyBudget
    property int cfg_xaiDailyBudget
    property int cfg_xaiMonthlyBudget
    property int cfg_ollamaDailyBudget
    property int cfg_ollamaMonthlyBudget
    property int cfg_openrouterDailyBudget
    property int cfg_openrouterMonthlyBudget
    property int cfg_togetherDailyBudget
    property int cfg_togetherMonthlyBudget
    property int cfg_cohereDailyBudget
    property int cfg_cohereMonthlyBudget
    property int cfg_azureDailyBudget
    property int cfg_azureMonthlyBudget
    property int cfg_googleveoDailyBudget
    property int cfg_googleveoMonthlyBudget
    property alias cfg_budgetWarningPercent: warningPercentSlider.value

    // Model for all providers
    readonly property var providerBudgets: [
        { name: "OpenAI",        dailyKey: "openaiDailyBudget",    monthlyKey: "openaiMonthlyBudget"    },
        { name: "Anthropic",     dailyKey: "anthropicDailyBudget", monthlyKey: "anthropicMonthlyBudget" },
        { name: "Google Gemini", dailyKey: "googleDailyBudget",    monthlyKey: "googleMonthlyBudget"    },
        { name: "Mistral AI",    dailyKey: "mistralDailyBudget",   monthlyKey: "mistralMonthlyBudget"   },
        { name: "DeepSeek",      dailyKey: "deepseekDailyBudget",  monthlyKey: "deepseekMonthlyBudget"  },
        { name: "Groq",          dailyKey: "groqDailyBudget",      monthlyKey: "groqMonthlyBudget"      },
        { name: "xAI / Grok",    dailyKey: "xaiDailyBudget",       monthlyKey: "xaiMonthlyBudget"       },
        { name: "Ollama Cloud",  dailyKey: "ollamaDailyBudget",    monthlyKey: "ollamaMonthlyBudget"    },
        { name: "OpenRouter",    dailyKey: "openrouterDailyBudget", monthlyKey: "openrouterMonthlyBudget" },
        { name: "Together AI",   dailyKey: "togetherDailyBudget",   monthlyKey: "togetherMonthlyBudget"   },
        { name: "Cohere",        dailyKey: "cohereDailyBudget",    monthlyKey: "cohereMonthlyBudget"    },
        { name: "Azure OpenAI",  dailyKey: "azureDailyBudget",     monthlyKey: "azureMonthlyBudget"     },
        { name: "Google Veo",    dailyKey: "googleveoDailyBudget", monthlyKey: "googleveoMonthlyBudget" }
    ]

    // Shared formatting functions
    function centsToText(value) {
        return "$" + (value / 100).toFixed(2);
    }

    function textToCents(text) {
        var val = parseFloat(text.replace("$", ""));
        return isNaN(val) ? 0 : Math.round(val * 100);
    }

    Kirigami.FormLayout {
        anchors.fill: parent

        QQC2.Label {
            text: i18n("Set daily and monthly budget limits per provider. Set to $0.00 to disable budget tracking for that provider.")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.6
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Warning Threshold")
        }

        ColumnLayout {
            Kirigami.FormData.label: i18n("Warn at:")
            spacing: Kirigami.Units.smallSpacing

            QQC2.Slider {
                id: warningPercentSlider
                Layout.fillWidth: true
                from: 50
                to: 100
                stepSize: 5
                QQC2.ToolTip.text: i18n("Trigger a desktop notification when spending reaches this percentage of the budget")
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: 500
            }

            QQC2.Label {
                text: i18n("%1% of budget", warningPercentSlider.value)
                opacity: 0.7
                Layout.alignment: Qt.AlignHCenter
            }
        }

        // ── Per-provider budget sections (data-driven) ──
        Repeater {
            model: budgetPage.providerBudgets

            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true

                Kirigami.Separator {
                    Kirigami.FormData.isSection: true
                    Kirigami.FormData.label: modelData.name
                    Layout.fillWidth: true
                }

                QQC2.SpinBox {
                    id: dailyField
                    Kirigami.FormData.label: i18n("Daily budget ($):")
                    from: 0; to: 100000; stepSize: 100
                    value: budgetPage["cfg_" + modelData.dailyKey]

                    textFromValue: function(value, locale) {
                        return budgetPage.centsToText(value);
                    }
                    valueFromText: function(text, locale) {
                        return budgetPage.textToCents(text);
                    }

                    onValueModified: {
                        budgetPage["cfg_" + modelData.dailyKey] = value;
                    }

                    Component.onCompleted: {
                        value = budgetPage["cfg_" + modelData.dailyKey];
                    }
                }

                QQC2.SpinBox {
                    id: monthlyField
                    Kirigami.FormData.label: i18n("Monthly budget ($):")
                    from: 0; to: 1000000; stepSize: 500
                    value: budgetPage["cfg_" + modelData.monthlyKey]

                    textFromValue: function(value, locale) {
                        return budgetPage.centsToText(value);
                    }
                    valueFromText: function(text, locale) {
                        return budgetPage.textToCents(text);
                    }

                    onValueModified: {
                        budgetPage["cfg_" + modelData.monthlyKey] = value;
                    }

                    Component.onCompleted: {
                        value = budgetPage["cfg_" + modelData.monthlyKey];
                    }
                }
            }
        }
    }
}
