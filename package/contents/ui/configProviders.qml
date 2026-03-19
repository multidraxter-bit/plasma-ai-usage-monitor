import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import com.github.loofi.aiusagemonitor 1.0

KCM.SimpleKCM {
    id: providersPage

    // URL validation helper
    function isInvalidUrl(url) {
        if (url.length === 0) return false;
        var lower = url.toLowerCase();
        return !lower.startsWith("https://") && !lower.startsWith("http://");
    }

    property alias cfg_loofiEnabled: loofiSwitch.checked
    property alias cfg_loofiServerUrl: loofiServerUrlField.text

    property alias cfg_openaiEnabled: openaiSwitch.checked
    property alias cfg_openaiModel: openaiModelField.text
    property alias cfg_openaiProjectId: openaiProjectField.text
    property alias cfg_openaiCustomBaseUrl: openaiBaseUrlField.text

    property alias cfg_azureEnabled: azureSwitch.checked
    property alias cfg_azureModel: azureModelField.text
    property alias cfg_azureDeploymentId: azureDeploymentField.text
    property alias cfg_azureCustomBaseUrl: azureBaseUrlField.text

    property alias cfg_anthropicEnabled: anthropicSwitch.checked
    property alias cfg_anthropicModel: anthropicModelField.text
    property alias cfg_anthropicCustomBaseUrl: anthropicBaseUrlField.text

    property alias cfg_googleEnabled: googleSwitch.checked
    property alias cfg_googleModel: googleModelField.text
    property string cfg_googleTier: "free"
    property alias cfg_googleCustomBaseUrl: googleBaseUrlField.text

    property alias cfg_mistralEnabled: mistralSwitch.checked
    property alias cfg_mistralModel: mistralModelField.text
    property alias cfg_mistralCustomBaseUrl: mistralBaseUrlField.text

    property alias cfg_deepseekEnabled: deepseekSwitch.checked
    property alias cfg_deepseekModel: deepseekModelField.text
    property alias cfg_deepseekCustomBaseUrl: deepseekBaseUrlField.text

    property alias cfg_groqEnabled: groqSwitch.checked
    property alias cfg_groqModel: groqModelField.text
    property alias cfg_groqCustomBaseUrl: groqBaseUrlField.text

    property alias cfg_xaiEnabled: xaiSwitch.checked
    property alias cfg_xaiModel: xaiModelField.text
    property alias cfg_xaiCustomBaseUrl: xaiBaseUrlField.text

    property alias cfg_openrouterEnabled: openrouterSwitch.checked
    property alias cfg_openrouterModel: openrouterModelField.text
    property alias cfg_openrouterCustomBaseUrl: openrouterBaseUrlField.text

    property alias cfg_togetherEnabled: togetherSwitch.checked
    property alias cfg_togetherModel: togetherModelField.text
    property alias cfg_togetherCustomBaseUrl: togetherBaseUrlField.text

    property alias cfg_cohereEnabled: cohereSwitch.checked
    property alias cfg_cohereModel: cohereModelField.text
    property alias cfg_cohereCustomBaseUrl: cohereBaseUrlField.text

    property alias cfg_googleveoEnabled: googleveoSwitch.checked
    property alias cfg_googleveoModel: googleveoModelField.text
    property string cfg_googleveoTier: "paid"
    property alias cfg_googleveoCustomBaseUrl: googleveoBaseUrlField.text

    // Track whether the user has actually edited each key field
    property bool openaiKeyDirty: false
    property bool anthropicKeyDirty: false
    property bool googleKeyDirty: false
    property bool mistralKeyDirty: false
    property bool deepseekKeyDirty: false
    property bool groqKeyDirty: false
    property bool xaiKeyDirty: false
    property bool openrouterKeyDirty: false
    property bool togetherKeyDirty: false
    property bool cohereKeyDirty: false
    property bool googleveoKeyDirty: false
    property bool azureKeyDirty: false

    // ── KWallet Integration ──
    SecretsManager {
        id: secrets

        onWalletOpenChanged: {
            if (walletOpen) {
                loadKeys();
            }
        }

        onKeyStored: function(provider) {
            console.log("Key stored for", provider);
        }

        onError: function(message) {
            console.warn("SecretsManager error:", message);
        }
    }

    function loadKeys() {
        var providers = [
            { name: "openai", field: openaiKeyField, dirtyProp: "openaiKeyDirty" },
            { name: "anthropic", field: anthropicKeyField, dirtyProp: "anthropicKeyDirty" },
            { name: "google", field: googleKeyField, dirtyProp: "googleKeyDirty" },
            { name: "mistral", field: mistralKeyField, dirtyProp: "mistralKeyDirty" },
            { name: "deepseek", field: deepseekKeyField, dirtyProp: "deepseekKeyDirty" },
            { name: "groq", field: groqKeyField, dirtyProp: "groqKeyDirty" },
            { name: "xai", field: xaiKeyField, dirtyProp: "xaiKeyDirty" },
            { name: "openrouter", field: openrouterKeyField, dirtyProp: "openrouterKeyDirty" },
            { name: "together", field: togetherKeyField, dirtyProp: "togetherKeyDirty" },
            { name: "cohere", field: cohereKeyField, dirtyProp: "cohereKeyDirty" },
            { name: "googleveo", field: googleveoKeyField, dirtyProp: "googleveoKeyDirty" },
            { name: "azure", field: azureKeyField, dirtyProp: "azureKeyDirty" }
        ];

        for (var i = 0; i < providers.length; i++) {
            var p = providers[i];
            if (secrets.hasKey(p.name)) {
                p.field.text = "********";
                providersPage[p.dirtyProp] = false;
            } else {
                p.field.text = "";
            }
        }
    }

    function saveKeys() {
        var providers = [
            { name: "openai", field: openaiKeyField, dirty: openaiKeyDirty },
            { name: "anthropic", field: anthropicKeyField, dirty: anthropicKeyDirty },
            { name: "google", field: googleKeyField, dirty: googleKeyDirty },
            { name: "mistral", field: mistralKeyField, dirty: mistralKeyDirty },
            { name: "deepseek", field: deepseekKeyField, dirty: deepseekKeyDirty },
            { name: "groq", field: groqKeyField, dirty: groqKeyDirty },
            { name: "xai", field: xaiKeyField, dirty: xaiKeyDirty },
            { name: "openrouter", field: openrouterKeyField, dirty: openrouterKeyDirty },
            { name: "together", field: togetherKeyField, dirty: togetherKeyDirty },
            { name: "cohere", field: cohereKeyField, dirty: cohereKeyDirty },
            { name: "googleveo", field: googleveoKeyField, dirty: googleveoKeyDirty },
            { name: "azure", field: azureKeyField, dirty: azureKeyDirty }
        ];

        for (var i = 0; i < providers.length; i++) {
            var p = providers[i];
            if (p.dirty && p.field.text.length > 0 && p.field.text !== "********") {
                secrets.storeKey(p.name, p.field.text);
            } else if (p.dirty && p.field.text.length === 0) {
                secrets.removeKey(p.name);
            }
        }
    }

    Component.onCompleted: {
        if (secrets.walletOpen) {
            loadKeys();
        }
    }

    Component.onDestruction: {
        saveKeys();
    }

    Kirigami.FormLayout {
        anchors.fill: parent

        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: i18n("Enable the providers you actively use, keep their admin or billing credentials in KWallet, and point custom endpoints at self-hosted or compatible services when needed.")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.72
        }

        // ══════════════════════════════════════════════
        // ── Loofi Server ──
        // ══════════════════════════════════════════════

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Loofi Server")
        }

        QQC2.Switch {
            id: loofiSwitch
            Kirigami.FormData.label: i18n("Enable:")
            checked: plasmoid.configuration.loofiEnabled
        }

        QQC2.Label {
            visible: loofiSwitch.checked
            text: i18n("Connects to your self-hosted Loofi server and shows the active model, training stage, GPU usage, and 24-hour request volume.")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.6
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        QQC2.TextField {
            id: loofiServerUrlField
            Kirigami.FormData.label: i18n("Server URL:")
            enabled: loofiSwitch.checked
            text: plasmoid.configuration.loofiServerUrl
            placeholderText: i18n("Leave empty for LOOFI_SERVER_URL or built-in default")
            Layout.fillWidth: true
            QQC2.ToolTip.text: i18n("Base URL for the Loofi server. The widget will poll /api/v2/metrics-summary.")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 500
        }

        QQC2.Label {
            visible: providersPage.isInvalidUrl(loofiServerUrlField.text)
            text: i18n("⚠ URL must start with https:// or http://")
            color: Kirigami.Theme.negativeTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        QQC2.Label {
            visible: loofiServerUrlField.text.toLowerCase().startsWith("http://")
            text: i18n("⚠ Using HTTP is insecure. Prefer HTTPS unless you are polling a trusted local network host.")
            color: Kirigami.Theme.negativeTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        QQC2.Label {
            visible: loofiSwitch.checked
            text: i18n("Authentication stays environment-based via LOOFI_SERVER_TOKEN when your server requires it.")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.5
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        // ══════════════════════════════════════════════
        // ── OpenAI ──
        // ══════════════════════════════════════════════

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("OpenAI")
        }

        QQC2.Switch {
            id: openaiSwitch
            Kirigami.FormData.label: i18n("Enable:")
            checked: plasmoid.configuration.openaiEnabled
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Admin API Key:")
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.TextField {
                id: openaiKeyField
                enabled: openaiSwitch.checked
                echoMode: openaiKeyVisible.checked ? TextInput.Normal : TextInput.Password
                placeholderText: i18n("sk-admin-...")
                Layout.fillWidth: true
                onTextEdited: providersPage.openaiKeyDirty = true
            }

            QQC2.ToolButton {
                id: openaiKeyVisible
                checkable: true; checked: false
                icon.name: checked ? "password-show-off" : "password-show-on"
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: checked ? i18n("Hide key") : i18n("Show key")
                QQC2.ToolTip.visible: hovered
            }

            QQC2.ToolButton {
                icon.name: "edit-clear"
                enabled: openaiKeyField.text.length > 0
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: i18n("Clear key"); QQC2.ToolTip.visible: hovered
                onClicked: { openaiKeyField.text = ""; providersPage.openaiKeyDirty = true; }
            }
        }

        QQC2.Label {
            visible: openaiSwitch.checked
            text: i18n("Requires an Admin API key for usage/costs endpoints")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.6; wrapMode: Text.WordWrap; Layout.fillWidth: true
        }

        QQC2.TextField {
            id: openaiModelField
            Kirigami.FormData.label: i18n("Model filter:")
            enabled: openaiSwitch.checked
            text: plasmoid.configuration.openaiModel
            placeholderText: "gpt-4o"
            Layout.fillWidth: true
            QQC2.ToolTip.text: i18n("Only show usage for this model. Leave empty to show all models.")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 500
        }

        QQC2.TextField {
            id: openaiProjectField
            Kirigami.FormData.label: i18n("Project ID (optional):")
            enabled: openaiSwitch.checked
            text: plasmoid.configuration.openaiProjectId
            placeholderText: "proj_..."
            Layout.fillWidth: true
        }

        QQC2.TextField {
            id: openaiBaseUrlField
            Kirigami.FormData.label: i18n("Custom base URL:")
            enabled: openaiSwitch.checked
            text: plasmoid.configuration.openaiCustomBaseUrl
            placeholderText: i18n("Leave empty for default")
            Layout.fillWidth: true
            QQC2.ToolTip.text: i18n("Override the API endpoint for proxies or self-hosted gateways. Must start with https://")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 500
        }

        QQC2.Label {
            visible: providersPage.isInvalidUrl(openaiBaseUrlField.text)
            text: i18n("⚠ URL must start with https:// or http://")
            color: Kirigami.Theme.negativeTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        QQC2.Label {
            visible: openaiBaseUrlField.text.toLowerCase().startsWith("http://")
            text: i18n("⚠ Using HTTP is insecure. API keys will be sent unencrypted.")
            color: Kirigami.Theme.negativeTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        // ══════════════════════════════════════════════
        // ── Azure OpenAI ──
        // ══════════════════════════════════════════════

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Azure OpenAI")
        }

        QQC2.Switch {
            id: azureSwitch
            Kirigami.FormData.label: i18n("Enable:")
            checked: plasmoid.configuration.azureEnabled
        }

        RowLayout {
            Kirigami.FormData.label: i18n("API Key:")
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.TextField {
                id: azureKeyField
                enabled: azureSwitch.checked
                echoMode: azureKeyVisible.checked ? TextInput.Normal : TextInput.Password
                placeholderText: i18n("Enter Azure OpenAI API key...")
                Layout.fillWidth: true
                onTextEdited: providersPage.azureKeyDirty = true
            }

            QQC2.ToolButton {
                id: azureKeyVisible
                checkable: true; checked: false
                icon.name: checked ? "password-show-off" : "password-show-on"
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: checked ? i18n("Hide key") : i18n("Show key")
                QQC2.ToolTip.visible: hovered
            }

            QQC2.ToolButton {
                icon.name: "edit-clear"
                enabled: azureKeyField.text.length > 0
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: i18n("Clear key"); QQC2.ToolTip.visible: hovered
                onClicked: { azureKeyField.text = ""; providersPage.azureKeyDirty = true; }
            }
        }

        QQC2.Label {
            visible: azureSwitch.checked
            text: i18n("Use your Azure OpenAI resource endpoint and deployment for monitoring")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.6; wrapMode: Text.WordWrap; Layout.fillWidth: true
        }

        QQC2.TextField {
            id: azureModelField
            Kirigami.FormData.label: i18n("Model filter:")
            enabled: azureSwitch.checked
            text: plasmoid.configuration.azureModel
            placeholderText: "gpt-4o"
            Layout.fillWidth: true
        }

        QQC2.TextField {
            id: azureDeploymentField
            Kirigami.FormData.label: i18n("Deployment ID:")
            enabled: azureSwitch.checked
            text: plasmoid.configuration.azureDeploymentId
            placeholderText: i18n("my-deployment")
            Layout.fillWidth: true
        }

        QQC2.TextField {
            id: azureBaseUrlField
            Kirigami.FormData.label: i18n("Endpoint base URL:")
            enabled: azureSwitch.checked
            text: plasmoid.configuration.azureCustomBaseUrl
            placeholderText: i18n("https://<resource>.openai.azure.com")
            Layout.fillWidth: true
            QQC2.ToolTip.text: i18n("Azure endpoint base URL. Must start with https://")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 500
        }

        QQC2.Label {
            visible: providersPage.isInvalidUrl(azureBaseUrlField.text)
            text: i18n("⚠ URL must start with https:// or http://")
            color: Kirigami.Theme.negativeTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        QQC2.Label {
            visible: azureBaseUrlField.text.toLowerCase().startsWith("http://")
            text: i18n("⚠ Using HTTP is insecure. API keys will be sent unencrypted.")
            color: Kirigami.Theme.negativeTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        // ══════════════════════════════════════════════
        // ── Anthropic ──
        // ══════════════════════════════════════════════

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Anthropic")
        }

        QQC2.Switch {
            id: anthropicSwitch
            Kirigami.FormData.label: i18n("Enable:")
            checked: plasmoid.configuration.anthropicEnabled
        }

        RowLayout {
            Kirigami.FormData.label: i18n("API Key:")
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.TextField {
                id: anthropicKeyField
                enabled: anthropicSwitch.checked
                echoMode: anthropicKeyVisible.checked ? TextInput.Normal : TextInput.Password
                placeholderText: i18n("sk-ant-...")
                Layout.fillWidth: true
                onTextEdited: providersPage.anthropicKeyDirty = true
            }

            QQC2.ToolButton {
                id: anthropicKeyVisible
                checkable: true; checked: false
                icon.name: checked ? "password-show-off" : "password-show-on"
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: checked ? i18n("Hide key") : i18n("Show key")
                QQC2.ToolTip.visible: hovered
            }

            QQC2.ToolButton {
                icon.name: "edit-clear"
                enabled: anthropicKeyField.text.length > 0
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: i18n("Clear key"); QQC2.ToolTip.visible: hovered
                onClicked: { anthropicKeyField.text = ""; providersPage.anthropicKeyDirty = true; }
            }
        }

        QQC2.Label {
            visible: anthropicSwitch.checked
            text: i18n("Shows rate limit status only (Anthropic has no usage API)")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.6; wrapMode: Text.WordWrap; Layout.fillWidth: true
        }

        QQC2.ComboBox {
            id: anthropicModelField
            Kirigami.FormData.label: i18n("Model:")
            enabled: anthropicSwitch.checked
            editable: true
            editText: plasmoid.configuration.anthropicModel
            model: [
                "claude-sonnet-4-20250514",
                "claude-opus-4-20250514",
                "claude-haiku-4-20250514",
                "claude-3-7-sonnet-20250219",
                "claude-3-5-sonnet-20241022",
                "claude-3-5-haiku-20241022"
            ]
            onEditTextChanged: plasmoid.configuration.anthropicModel = editText
            property alias text: anthropicModelField.editText
        }

        QQC2.TextField {
            id: anthropicBaseUrlField
            Kirigami.FormData.label: i18n("Custom base URL:")
            enabled: anthropicSwitch.checked
            text: plasmoid.configuration.anthropicCustomBaseUrl
            placeholderText: i18n("Leave empty for default")
            Layout.fillWidth: true
            QQC2.ToolTip.text: i18n("Override the API endpoint for proxies or self-hosted gateways. Must start with https://")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 500
        }

        QQC2.Label {
            visible: providersPage.isInvalidUrl(anthropicBaseUrlField.text)
            text: i18n("⚠ URL must start with https:// or http://")
            color: Kirigami.Theme.negativeTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        QQC2.Label {
            visible: anthropicBaseUrlField.text.toLowerCase().startsWith("http://")
            text: i18n("⚠ Using HTTP is insecure. API keys will be sent unencrypted.")
            color: Kirigami.Theme.negativeTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        // ══════════════════════════════════════════════
        // ── Google Gemini ──
        // ══════════════════════════════════════════════

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Google Gemini")
        }

        QQC2.Switch {
            id: googleSwitch
            Kirigami.FormData.label: i18n("Enable:")
            checked: plasmoid.configuration.googleEnabled
        }

        RowLayout {
            Kirigami.FormData.label: i18n("API Key:")
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.TextField {
                id: googleKeyField
                enabled: googleSwitch.checked
                echoMode: googleKeyVisible.checked ? TextInput.Normal : TextInput.Password
                placeholderText: i18n("AIza...")
                Layout.fillWidth: true
                onTextEdited: providersPage.googleKeyDirty = true
            }

            QQC2.ToolButton {
                id: googleKeyVisible
                checkable: true; checked: false
                icon.name: checked ? "password-show-off" : "password-show-on"
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: checked ? i18n("Hide key") : i18n("Show key")
                QQC2.ToolTip.visible: hovered
            }

            QQC2.ToolButton {
                icon.name: "edit-clear"
                enabled: googleKeyField.text.length > 0
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: i18n("Clear key"); QQC2.ToolTip.visible: hovered
                onClicked: { googleKeyField.text = ""; providersPage.googleKeyDirty = true; }
            }
        }

        QQC2.Label {
            visible: googleSwitch.checked
            text: i18n("Shows connectivity status and known tier limits")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.6; wrapMode: Text.WordWrap; Layout.fillWidth: true
        }

        QQC2.ComboBox {
            id: googleModelField
            Kirigami.FormData.label: i18n("Model:")
            enabled: googleSwitch.checked
            editable: true
            editText: plasmoid.configuration.googleModel
            model: [
                "gemini-2.5-pro",
                "gemini-2.5-flash",
                "gemini-2.0-flash",
                "gemini-2.0-flash-lite",
                "gemini-1.5-pro",
                "gemini-1.5-flash"
            ]
            onEditTextChanged: plasmoid.configuration.googleModel = editText
            property alias text: googleModelField.editText
        }

        QQC2.ComboBox {
            id: googleTierField
            Kirigami.FormData.label: i18n("Pricing tier:")
            enabled: googleSwitch.checked
            model: [
                { text: i18n("Free"), value: "free" },
                { text: i18n("Paid (Pay-as-you-go)"), value: "paid" }
            ]
            textRole: "text"
            valueRole: "value"
            currentIndex: cfg_googleTier === "paid" ? 1 : 0
            onActivated: cfg_googleTier = currentValue
        }

        QQC2.Label {
            visible: googleSwitch.checked && googleTierField.currentIndex === 0
            text: i18n("Free tier has lower rate limits. Select Paid if you have billing enabled.")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.6; wrapMode: Text.WordWrap; Layout.fillWidth: true
        }

        QQC2.TextField {
            id: googleBaseUrlField
            Kirigami.FormData.label: i18n("Custom base URL:")
            enabled: googleSwitch.checked
            text: plasmoid.configuration.googleCustomBaseUrl
            placeholderText: i18n("Leave empty for default")
            Layout.fillWidth: true
            QQC2.ToolTip.text: i18n("Override the API endpoint for proxies or self-hosted gateways. Must start with https://")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 500
        }

        QQC2.Label {
            visible: providersPage.isInvalidUrl(googleBaseUrlField.text)
            text: i18n("⚠ URL must start with https:// or http://")
            color: Kirigami.Theme.negativeTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        QQC2.Label {
            visible: googleBaseUrlField.text.toLowerCase().startsWith("http://")
            text: i18n("⚠ Using HTTP is insecure. API keys will be sent unencrypted.")
            color: Kirigami.Theme.negativeTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        // ══════════════════════════════════════════════
        // ── Mistral AI ──
        // ══════════════════════════════════════════════

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Mistral AI")
        }

        QQC2.Switch {
            id: mistralSwitch
            Kirigami.FormData.label: i18n("Enable:")
            checked: plasmoid.configuration.mistralEnabled
        }

        RowLayout {
            Kirigami.FormData.label: i18n("API Key:")
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.TextField {
                id: mistralKeyField
                enabled: mistralSwitch.checked
                echoMode: mistralKeyVisible.checked ? TextInput.Normal : TextInput.Password
                placeholderText: i18n("Enter Mistral API key...")
                Layout.fillWidth: true
                onTextEdited: providersPage.mistralKeyDirty = true
            }

            QQC2.ToolButton {
                id: mistralKeyVisible
                checkable: true; checked: false
                icon.name: checked ? "password-show-off" : "password-show-on"
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: checked ? i18n("Hide key") : i18n("Show key")
                QQC2.ToolTip.visible: hovered
            }

            QQC2.ToolButton {
                icon.name: "edit-clear"
                enabled: mistralKeyField.text.length > 0
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: i18n("Clear key"); QQC2.ToolTip.visible: hovered
                onClicked: { mistralKeyField.text = ""; providersPage.mistralKeyDirty = true; }
            }
        }

        QQC2.Label {
            visible: mistralSwitch.checked
            text: i18n("Rate limits and token usage via chat/completions endpoint")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.6; wrapMode: Text.WordWrap; Layout.fillWidth: true
        }

        QQC2.ComboBox {
            id: mistralModelField
            Kirigami.FormData.label: i18n("Model:")
            enabled: mistralSwitch.checked
            editable: true
            editText: plasmoid.configuration.mistralModel
            model: [
                "mistral-large-latest",
                "mistral-medium-latest",
                "mistral-small-latest",
                "open-mistral-7b",
                "open-mixtral-8x7b",
                "codestral-latest"
            ]
            onEditTextChanged: plasmoid.configuration.mistralModel = editText
            property alias text: mistralModelField.editText
        }

        QQC2.TextField {
            id: mistralBaseUrlField
            Kirigami.FormData.label: i18n("Custom base URL:")
            enabled: mistralSwitch.checked
            text: plasmoid.configuration.mistralCustomBaseUrl
            placeholderText: i18n("Leave empty for default")
            Layout.fillWidth: true
            QQC2.ToolTip.text: i18n("Override the API endpoint for proxies or self-hosted gateways. Must start with https://")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 500
        }

        QQC2.Label {
            visible: providersPage.isInvalidUrl(mistralBaseUrlField.text)
            text: i18n("⚠ URL must start with https:// or http://")
            color: Kirigami.Theme.negativeTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        QQC2.Label {
            visible: mistralBaseUrlField.text.toLowerCase().startsWith("http://")
            text: i18n("⚠ Using HTTP is insecure. API keys will be sent unencrypted.")
            color: Kirigami.Theme.negativeTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        // ══════════════════════════════════════════════
        // ── DeepSeek ──
        // ══════════════════════════════════════════════

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("DeepSeek")
        }

        QQC2.Switch {
            id: deepseekSwitch
            Kirigami.FormData.label: i18n("Enable:")
            checked: plasmoid.configuration.deepseekEnabled
        }

        RowLayout {
            Kirigami.FormData.label: i18n("API Key:")
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.TextField {
                id: deepseekKeyField
                enabled: deepseekSwitch.checked
                echoMode: deepseekKeyVisible.checked ? TextInput.Normal : TextInput.Password
                placeholderText: i18n("Enter DeepSeek API key...")
                Layout.fillWidth: true
                onTextEdited: providersPage.deepseekKeyDirty = true
            }

            QQC2.ToolButton {
                id: deepseekKeyVisible
                checkable: true; checked: false
                icon.name: checked ? "password-show-off" : "password-show-on"
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: checked ? i18n("Hide key") : i18n("Show key")
                QQC2.ToolTip.visible: hovered
            }

            QQC2.ToolButton {
                icon.name: "edit-clear"
                enabled: deepseekKeyField.text.length > 0
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: i18n("Clear key"); QQC2.ToolTip.visible: hovered
                onClicked: { deepseekKeyField.text = ""; providersPage.deepseekKeyDirty = true; }
            }
        }

        QQC2.Label {
            visible: deepseekSwitch.checked
            text: i18n("Tracks rate limits, token usage, and account balance")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.6; wrapMode: Text.WordWrap; Layout.fillWidth: true
        }

        QQC2.ComboBox {
            id: deepseekModelField
            Kirigami.FormData.label: i18n("Model:")
            enabled: deepseekSwitch.checked
            editable: true
            editText: plasmoid.configuration.deepseekModel
            model: [
                "deepseek-chat",
                "deepseek-coder",
                "deepseek-reasoner"
            ]
            onEditTextChanged: plasmoid.configuration.deepseekModel = editText
            property alias text: deepseekModelField.editText
        }

        QQC2.TextField {
            id: deepseekBaseUrlField
            Kirigami.FormData.label: i18n("Custom base URL:")
            enabled: deepseekSwitch.checked
            text: plasmoid.configuration.deepseekCustomBaseUrl
            placeholderText: i18n("Leave empty for default")
            Layout.fillWidth: true
            QQC2.ToolTip.text: i18n("Override the API endpoint for proxies or self-hosted gateways. Must start with https://")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 500
        }

        QQC2.Label {
            visible: providersPage.isInvalidUrl(deepseekBaseUrlField.text)
            text: i18n("⚠ URL must start with https:// or http://")
            color: Kirigami.Theme.negativeTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        QQC2.Label {
            visible: deepseekBaseUrlField.text.toLowerCase().startsWith("http://")
            text: i18n("⚠ Using HTTP is insecure. API keys will be sent unencrypted.")
            color: Kirigami.Theme.negativeTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        // ══════════════════════════════════════════════
        // ── Groq ──
        // ══════════════════════════════════════════════

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Groq")
        }

        QQC2.Switch {
            id: groqSwitch
            Kirigami.FormData.label: i18n("Enable:")
            checked: plasmoid.configuration.groqEnabled
        }

        RowLayout {
            Kirigami.FormData.label: i18n("API Key:")
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.TextField {
                id: groqKeyField
                enabled: groqSwitch.checked
                echoMode: groqKeyVisible.checked ? TextInput.Normal : TextInput.Password
                placeholderText: i18n("Enter Groq API key...")
                Layout.fillWidth: true
                onTextEdited: providersPage.groqKeyDirty = true
            }

            QQC2.ToolButton {
                id: groqKeyVisible
                checkable: true; checked: false
                icon.name: checked ? "password-show-off" : "password-show-on"
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: checked ? i18n("Hide key") : i18n("Show key")
                QQC2.ToolTip.visible: hovered
            }

            QQC2.ToolButton {
                icon.name: "edit-clear"
                enabled: groqKeyField.text.length > 0
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: i18n("Clear key"); QQC2.ToolTip.visible: hovered
                onClicked: { groqKeyField.text = ""; providersPage.groqKeyDirty = true; }
            }
        }

        QQC2.Label {
            visible: groqSwitch.checked
            text: i18n("OpenAI-compatible API with rate limit headers")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.6; wrapMode: Text.WordWrap; Layout.fillWidth: true
        }

        QQC2.ComboBox {
            id: groqModelField
            Kirigami.FormData.label: i18n("Model:")
            enabled: groqSwitch.checked
            editable: true
            editText: plasmoid.configuration.groqModel
            model: [
                "llama-3.3-70b-versatile",
                "llama-3.1-70b-versatile",
                "llama-3.1-8b-instant",
                "mixtral-8x7b-32768",
                "gemma2-9b-it"
            ]
            onEditTextChanged: plasmoid.configuration.groqModel = editText
            property alias text: groqModelField.editText
        }

        QQC2.TextField {
            id: groqBaseUrlField
            Kirigami.FormData.label: i18n("Custom base URL:")
            enabled: groqSwitch.checked
            text: plasmoid.configuration.groqCustomBaseUrl
            placeholderText: i18n("Leave empty for default")
            Layout.fillWidth: true
            QQC2.ToolTip.text: i18n("Override the API endpoint for proxies or self-hosted gateways. Must start with https://")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 500
        }

        QQC2.Label {
            visible: providersPage.isInvalidUrl(groqBaseUrlField.text)
            text: i18n("⚠ URL must start with https:// or http://")
            color: Kirigami.Theme.negativeTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        QQC2.Label {
            visible: groqBaseUrlField.text.toLowerCase().startsWith("http://")
            text: i18n("⚠ Using HTTP is insecure. API keys will be sent unencrypted.")
            color: Kirigami.Theme.negativeTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        // ══════════════════════════════════════════════
        // ── xAI / Grok ──
        // ══════════════════════════════════════════════

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("xAI / Grok")
        }

        QQC2.Switch {
            id: xaiSwitch
            Kirigami.FormData.label: i18n("Enable:")
            checked: plasmoid.configuration.xaiEnabled
        }

        RowLayout {
            Kirigami.FormData.label: i18n("API Key:")
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.TextField {
                id: xaiKeyField
                enabled: xaiSwitch.checked
                echoMode: xaiKeyVisible.checked ? TextInput.Normal : TextInput.Password
                placeholderText: i18n("Enter xAI API key...")
                Layout.fillWidth: true
                onTextEdited: providersPage.xaiKeyDirty = true
            }

            QQC2.ToolButton {
                id: xaiKeyVisible
                checkable: true; checked: false
                icon.name: checked ? "password-show-off" : "password-show-on"
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: checked ? i18n("Hide key") : i18n("Show key")
                QQC2.ToolTip.visible: hovered
            }

            QQC2.ToolButton {
                icon.name: "edit-clear"
                enabled: xaiKeyField.text.length > 0
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: i18n("Clear key"); QQC2.ToolTip.visible: hovered
                onClicked: { xaiKeyField.text = ""; providersPage.xaiKeyDirty = true; }
            }
        }

        QQC2.Label {
            visible: xaiSwitch.checked
            text: i18n("OpenAI-compatible API for Grok models")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.6; wrapMode: Text.WordWrap; Layout.fillWidth: true
        }

        QQC2.ComboBox {
            id: xaiModelField
            Kirigami.FormData.label: i18n("Model:")
            enabled: xaiSwitch.checked
            editable: true
            editText: plasmoid.configuration.xaiModel
            model: [
                "grok-3",
                "grok-3-mini",
                "grok-2",
                "grok-2-mini"
            ]
            onEditTextChanged: plasmoid.configuration.xaiModel = editText
            property alias text: xaiModelField.editText
        }

        QQC2.TextField {
            id: xaiBaseUrlField
            Kirigami.FormData.label: i18n("Custom base URL:")
            enabled: xaiSwitch.checked
            text: plasmoid.configuration.xaiCustomBaseUrl
            placeholderText: i18n("Leave empty for default")
            Layout.fillWidth: true
            QQC2.ToolTip.text: i18n("Override the API endpoint for proxies or self-hosted gateways. Must start with https://")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 500
        }

        QQC2.Label {
            visible: providersPage.isInvalidUrl(xaiBaseUrlField.text)
            text: i18n("⚠ URL must start with https:// or http://")
            color: Kirigami.Theme.negativeTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        QQC2.Label {
            visible: xaiBaseUrlField.text.toLowerCase().startsWith("http://")
            text: i18n("⚠ Using HTTP is insecure. API keys will be sent unencrypted.")
            color: Kirigami.Theme.negativeTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        // ══════════════════════════════════════════════
        // ── OpenRouter ──
        // ══════════════════════════════════════════════

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("OpenRouter")
        }

        QQC2.Switch {
            id: openrouterSwitch
            Kirigami.FormData.label: i18n("Enable:")
            checked: plasmoid.configuration.openrouterEnabled
        }

        RowLayout {
            Kirigami.FormData.label: i18n("API Key:")
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.TextField {
                id: openrouterKeyField
                enabled: openrouterSwitch.checked
                echoMode: openrouterKeyVisible.checked ? TextInput.Normal : TextInput.Password
                placeholderText: i18n("sk-or-...")
                Layout.fillWidth: true
                onTextEdited: providersPage.openrouterKeyDirty = true
            }

            QQC2.ToolButton {
                id: openrouterKeyVisible
                checkable: true; checked: false
                icon.name: checked ? "password-show-off" : "password-show-on"
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: checked ? i18n("Hide key") : i18n("Show key")
                QQC2.ToolTip.visible: hovered
            }

            QQC2.ToolButton {
                icon.name: "edit-clear"
                enabled: openrouterKeyField.text.length > 0
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: i18n("Clear key"); QQC2.ToolTip.visible: hovered
                onClicked: { openrouterKeyField.text = ""; providersPage.openrouterKeyDirty = true; }
            }
        }

        QQC2.Label {
            visible: openrouterSwitch.checked
            text: i18n("Unified gateway to 600+ models. Shows credits balance and usage.")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.6; wrapMode: Text.WordWrap; Layout.fillWidth: true
        }

        QQC2.ComboBox {
            id: openrouterModelField
            Kirigami.FormData.label: i18n("Model:")
            enabled: openrouterSwitch.checked
            editable: true
            editText: plasmoid.configuration.openrouterModel
            model: [
                "openai/gpt-4o",
                "openai/gpt-4o-mini",
                "openai/gpt-4.1",
                "openai/gpt-4.1-mini",
                "openai/o3",
                "openai/o4-mini",
                "anthropic/claude-sonnet-4",
                "anthropic/claude-opus-4",
                "google/gemini-2.5-pro",
                "google/gemini-2.5-flash",
                "meta-llama/llama-3.3-70b-instruct",
                "meta-llama/llama-4-maverick",
                "deepseek/deepseek-chat-v3",
                "deepseek/deepseek-r1",
                "x-ai/grok-3",
                "x-ai/grok-3-mini",
                "qwen/qwen-2.5-72b-instruct",
                "mistralai/mistral-large"
            ]
            onEditTextChanged: plasmoid.configuration.openrouterModel = editText
            property alias text: openrouterModelField.editText
        }

        QQC2.TextField {
            id: openrouterBaseUrlField
            Kirigami.FormData.label: i18n("Custom base URL:")
            enabled: openrouterSwitch.checked
            text: plasmoid.configuration.openrouterCustomBaseUrl
            placeholderText: i18n("Leave empty for default")
            Layout.fillWidth: true
            QQC2.ToolTip.text: i18n("Override the API endpoint for proxies or self-hosted gateways. Must start with https://")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 500
        }

        QQC2.Label {
            visible: providersPage.isInvalidUrl(openrouterBaseUrlField.text)
            text: i18n("⚠ URL must start with https:// or http://")
            color: Kirigami.Theme.negativeTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        QQC2.Label {
            visible: openrouterBaseUrlField.text.toLowerCase().startsWith("http://")
            text: i18n("⚠ Using HTTP is insecure. API keys will be sent unencrypted.")
            color: Kirigami.Theme.negativeTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        // ══════════════════════════════════════════════
        // ── Together AI ──
        // ══════════════════════════════════════════════

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Together AI")
        }

        QQC2.Switch {
            id: togetherSwitch
            Kirigami.FormData.label: i18n("Enable:")
            checked: plasmoid.configuration.togetherEnabled
        }

        RowLayout {
            Kirigami.FormData.label: i18n("API Key:")
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.TextField {
                id: togetherKeyField
                enabled: togetherSwitch.checked
                echoMode: togetherKeyVisible.checked ? TextInput.Normal : TextInput.Password
                placeholderText: i18n("Enter Together AI API key...")
                Layout.fillWidth: true
                onTextEdited: providersPage.togetherKeyDirty = true
            }

            QQC2.ToolButton {
                id: togetherKeyVisible
                checkable: true; checked: false
                icon.name: checked ? "password-show-off" : "password-show-on"
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: checked ? i18n("Hide key") : i18n("Show key")
                QQC2.ToolTip.visible: hovered
            }

            QQC2.ToolButton {
                icon.name: "edit-clear"
                enabled: togetherKeyField.text.length > 0
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: i18n("Clear key"); QQC2.ToolTip.visible: hovered
                onClicked: { togetherKeyField.text = ""; providersPage.togetherKeyDirty = true; }
            }
        }

        QQC2.Label {
            visible: togetherSwitch.checked
            text: i18n("Fast inference for open-source models (Llama, Qwen, DeepSeek)")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.6; wrapMode: Text.WordWrap; Layout.fillWidth: true
        }

        QQC2.ComboBox {
            id: togetherModelField
            Kirigami.FormData.label: i18n("Model:")
            enabled: togetherSwitch.checked
            editable: true
            editText: plasmoid.configuration.togetherModel
            model: [
                "meta-llama/Llama-3.3-70B-Instruct-Turbo",
                "meta-llama/Meta-Llama-3.1-8B-Instruct-Turbo",
                "meta-llama/Meta-Llama-3.1-405B-Instruct-Turbo",
                "meta-llama/Llama-4-Maverick-17B-128E-Instruct-FP8",
                "meta-llama/Llama-4-Scout-17B-16E-Instruct",
                "Qwen/Qwen2.5-72B-Instruct-Turbo",
                "Qwen/Qwen2.5-7B-Instruct-Turbo",
                "deepseek-ai/DeepSeek-V3",
                "deepseek-ai/DeepSeek-R1",
                "mistralai/Mixtral-8x7B-Instruct-v0.1",
                "google/gemma-2-27b-it"
            ]
            onEditTextChanged: plasmoid.configuration.togetherModel = editText
            property alias text: togetherModelField.editText
        }

        QQC2.TextField {
            id: togetherBaseUrlField
            Kirigami.FormData.label: i18n("Custom base URL:")
            enabled: togetherSwitch.checked
            text: plasmoid.configuration.togetherCustomBaseUrl
            placeholderText: i18n("Leave empty for default")
            Layout.fillWidth: true
            QQC2.ToolTip.text: i18n("Override the API endpoint for proxies or self-hosted gateways. Must start with https://")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 500
        }

        QQC2.Label {
            visible: providersPage.isInvalidUrl(togetherBaseUrlField.text)
            text: i18n("⚠ URL must start with https:// or http://")
            color: Kirigami.Theme.negativeTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        QQC2.Label {
            visible: togetherBaseUrlField.text.toLowerCase().startsWith("http://")
            text: i18n("⚠ Using HTTP is insecure. API keys will be sent unencrypted.")
            color: Kirigami.Theme.negativeTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        // ══════════════════════════════════════════════
        // ── Cohere ──
        // ══════════════════════════════════════════════

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Cohere")
        }

        QQC2.Switch {
            id: cohereSwitch
            Kirigami.FormData.label: i18n("Enable:")
            checked: plasmoid.configuration.cohereEnabled
        }

        RowLayout {
            Kirigami.FormData.label: i18n("API Key:")
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.TextField {
                id: cohereKeyField
                enabled: cohereSwitch.checked
                echoMode: cohereKeyVisible.checked ? TextInput.Normal : TextInput.Password
                placeholderText: i18n("Enter Cohere API key...")
                Layout.fillWidth: true
                onTextEdited: providersPage.cohereKeyDirty = true
            }

            QQC2.ToolButton {
                id: cohereKeyVisible
                checkable: true; checked: false
                icon.name: checked ? "password-show-off" : "password-show-on"
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: checked ? i18n("Hide key") : i18n("Show key")
                QQC2.ToolTip.visible: hovered
            }

            QQC2.ToolButton {
                icon.name: "edit-clear"
                enabled: cohereKeyField.text.length > 0
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: i18n("Clear key"); QQC2.ToolTip.visible: hovered
                onClicked: { cohereKeyField.text = ""; providersPage.cohereKeyDirty = true; }
            }
        }

        QQC2.Label {
            visible: cohereSwitch.checked
            text: i18n("Enterprise RAG and multilingual models via OpenAI-compatible API")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.6; wrapMode: Text.WordWrap; Layout.fillWidth: true
        }

        QQC2.ComboBox {
            id: cohereModelField
            Kirigami.FormData.label: i18n("Model:")
            enabled: cohereSwitch.checked
            editable: true
            editText: plasmoid.configuration.cohereModel
            model: [
                "command-a-03-2025",
                "command-r-plus-08-2024",
                "command-r-plus",
                "command-r-08-2024",
                "command-r",
                "command-light",
                "command"
            ]
            onEditTextChanged: plasmoid.configuration.cohereModel = editText
            property alias text: cohereModelField.editText
        }

        QQC2.TextField {
            id: cohereBaseUrlField
            Kirigami.FormData.label: i18n("Custom base URL:")
            enabled: cohereSwitch.checked
            text: plasmoid.configuration.cohereCustomBaseUrl
            placeholderText: i18n("Leave empty for default")
            Layout.fillWidth: true
            QQC2.ToolTip.text: i18n("Override the API endpoint for proxies or self-hosted gateways. Must start with https://")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 500
        }

        QQC2.Label {
            visible: providersPage.isInvalidUrl(cohereBaseUrlField.text)
            text: i18n("⚠ URL must start with https:// or http://")
            color: Kirigami.Theme.negativeTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        QQC2.Label {
            visible: cohereBaseUrlField.text.toLowerCase().startsWith("http://")
            text: i18n("⚠ Using HTTP is insecure. API keys will be sent unencrypted.")
            color: Kirigami.Theme.negativeTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        // ── Google Veo ──
        // ══════════════════════════════════════════════

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Google Veo")
        }

        QQC2.Switch {
            id: googleveoSwitch
            Kirigami.FormData.label: i18n("Enable:")
            checked: plasmoid.configuration.googleveoEnabled
        }

        RowLayout {
            Kirigami.FormData.label: i18n("API Key:")
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.TextField {
                id: googleveoKeyField
                enabled: googleveoSwitch.checked
                echoMode: googleveoKeyVisible.checked ? TextInput.Normal : TextInput.Password
                placeholderText: i18n("AIza...")
                Layout.fillWidth: true
                onTextEdited: providersPage.googleveoKeyDirty = true
            }

            QQC2.ToolButton {
                id: googleveoKeyVisible
                checkable: true; checked: false
                icon.name: checked ? "password-show-off" : "password-show-on"
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: checked ? i18n("Hide key") : i18n("Show key")
                QQC2.ToolTip.visible: hovered
            }

            QQC2.ToolButton {
                icon.name: "edit-clear"
                enabled: googleveoKeyField.text.length > 0
                display: QQC2.AbstractButton.IconOnly
                QQC2.ToolTip.text: i18n("Clear key"); QQC2.ToolTip.visible: hovered
                onClicked: { googleveoKeyField.text = ""; providersPage.googleveoKeyDirty = true; }
            }
        }

        QQC2.Label {
            visible: googleveoSwitch.checked
            text: i18n("Monitors Google Veo video generation API connectivity and tier limits")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.6; wrapMode: Text.WordWrap; Layout.fillWidth: true
        }

        QQC2.ComboBox {
            id: googleveoModelField
            Kirigami.FormData.label: i18n("Model:")
            enabled: googleveoSwitch.checked
            editable: true
            editText: plasmoid.configuration.googleveoModel
            model: [
                "veo-3",
                "veo-2"
            ]
            onEditTextChanged: plasmoid.configuration.googleveoModel = editText
            property alias text: googleveoModelField.editText
        }

        QQC2.ComboBox {
            id: googleveoTierField
            Kirigami.FormData.label: i18n("Pricing tier:")
            enabled: googleveoSwitch.checked
            model: [
                { text: i18n("Free"), value: "free" },
                { text: i18n("Paid (Pay-as-you-go)"), value: "paid" }
            ]
            textRole: "text"
            valueRole: "value"
            currentIndex: cfg_googleveoTier === "paid" ? 1 : 0
            onActivated: cfg_googleveoTier = currentValue
        }

        QQC2.Label {
            visible: googleveoSwitch.checked && googleveoTierField.currentIndex === 0
            text: i18n("Free tier has very limited video generation quotas.")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.6; wrapMode: Text.WordWrap; Layout.fillWidth: true
        }

        QQC2.TextField {
            id: googleveoBaseUrlField
            Kirigami.FormData.label: i18n("Custom base URL:")
            enabled: googleveoSwitch.checked
            text: plasmoid.configuration.googleveoCustomBaseUrl
            placeholderText: i18n("Leave empty for default")
            Layout.fillWidth: true
            QQC2.ToolTip.text: i18n("Override the API endpoint for proxies or self-hosted gateways. Must start with https://")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 500
        }

        QQC2.Label {
            visible: providersPage.isInvalidUrl(googleveoBaseUrlField.text)
            text: i18n("⚠ URL must start with https:// or http://")
            color: Kirigami.Theme.negativeTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        QQC2.Label {
            visible: googleveoBaseUrlField.text.toLowerCase().startsWith("http://")
            text: i18n("⚠ Using HTTP is insecure. API keys will be sent unencrypted.")
            color: Kirigami.Theme.negativeTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }
}
