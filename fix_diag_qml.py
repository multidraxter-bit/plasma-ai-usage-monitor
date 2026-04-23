import re

with open('package/contents/ui/configDiagnostics.qml', 'r') as f:
    content = f.read()

# Add import
content = content.replace(
    'import com.github.loofi.aiusagemonitor 1.0',
    'import com.github.loofi.aiusagemonitor 1.0\nimport QtQuick.Dialogs as Dialogs'
)

# Add FileDialogs
dialogs = """
    Dialogs.FileDialog {
        id: exportDialog
        title: i18n("Export Configuration")
        fileMode: Dialogs.FileDialog.SaveFile
        nameFilters: ["JSON Files (*.json)"]
        currentFile: "ai-usage-monitor-config.json"
        onAccepted: {
            var configData = {
                version: AppInfo.version,
                general: {
                    refreshInterval: plasmoid.configuration.refreshInterval,
                    compactDisplayMode: plasmoid.configuration.compactDisplayMode
                },
                openaiEnabled: plasmoid.configuration.openaiEnabled,
                openaiModel: plasmoid.configuration.openaiModel,
                anthropicEnabled: plasmoid.configuration.anthropicEnabled,
                anthropicModel: plasmoid.configuration.anthropicModel,
                googleEnabled: plasmoid.configuration.googleEnabled,
                googleModel: plasmoid.configuration.googleModel,
                loofiEnabled: plasmoid.configuration.loofiEnabled,
                ollamaEnabled: plasmoid.configuration.ollamaEnabled
            };
            var jsonStr = JSON.stringify(configData, null, 2);
            AppInfo.exportConfig(jsonStr, selectedFile.toString());
        }
    }

    Dialogs.FileDialog {
        id: importDialog
        title: i18n("Import Configuration")
        fileMode: Dialogs.FileDialog.OpenFile
        nameFilters: ["JSON Files (*.json)"]
        onAccepted: {
            var jsonStr = AppInfo.importConfig(selectedFile.toString());
            if (jsonStr.length > 0) {
                try {
                    var configData = JSON.parse(jsonStr);
                    if (configData.general) {
                        if (configData.general.refreshInterval !== undefined) plasmoid.configuration.refreshInterval = configData.general.refreshInterval;
                        if (configData.general.compactDisplayMode !== undefined) plasmoid.configuration.compactDisplayMode = configData.general.compactDisplayMode;
                    }
                    if (configData.openaiEnabled !== undefined) plasmoid.configuration.openaiEnabled = configData.openaiEnabled;
                    if (configData.openaiModel !== undefined) plasmoid.configuration.openaiModel = configData.openaiModel;
                    if (configData.anthropicEnabled !== undefined) plasmoid.configuration.anthropicEnabled = configData.anthropicEnabled;
                    if (configData.anthropicModel !== undefined) plasmoid.configuration.anthropicModel = configData.anthropicModel;
                    if (configData.googleEnabled !== undefined) plasmoid.configuration.googleEnabled = configData.googleEnabled;
                    if (configData.googleModel !== undefined) plasmoid.configuration.googleModel = configData.googleModel;
                    if (configData.loofiEnabled !== undefined) plasmoid.configuration.loofiEnabled = configData.loofiEnabled;
                    if (configData.ollamaEnabled !== undefined) plasmoid.configuration.ollamaEnabled = configData.ollamaEnabled;
                } catch (e) {
                    console.error("Failed to parse imported config:", e);
                }
            }
        }
    }
"""

content = content.replace('Kirigami.FormLayout {\n        anchors.fill: parent', dialogs + '\n    Kirigami.FormLayout {\n        anchors.fill: parent')

# Update buttons to open dialogs
export_btn = """
            QQC2.Button {
                text: i18n("Export...")
                icon.name: "document-export"
                onClicked: {
                    exportDialog.open();
                }
            }
"""

import_btn = """
            QQC2.Button {
                text: i18n("Import...")
                icon.name: "document-import"
                onClicked: {
                    importDialog.open();
                }
            }
"""

content = re.sub(r'QQC2\.Button \{\n\s+text: i18n\("Export\.\.\."\).*?\}\n\s+\}', export_btn.strip(), content, flags=re.DOTALL)
content = re.sub(r'QQC2\.Button \{\n\s+text: i18n\("Import\.\.\."\).*?\}\n\s+\}', import_btn.strip(), content, flags=re.DOTALL)

with open('package/contents/ui/configDiagnostics.qml', 'w') as f:
    f.write(content)
