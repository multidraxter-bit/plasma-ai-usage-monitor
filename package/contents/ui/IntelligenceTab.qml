import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import com.github.loofi.aiusagemonitor 1.0

Kirigami.ScrollablePage {
    id: root
    
    property IntelligenceBackend intelligence: null
    property string ollamaUrl: "http://localhost:11434"
    property string ollamaModel: "qwen2.5:1.5b"

    title: i18n("AI Intelligence")
    
    actions: [
        Kirigami.Action {
            text: i18n("Generate Insights")
            icon.name: "view-analyze"
            enabled: root.intelligence && !root.intelligence.isGenerating
            onTriggered: root.intelligence.generate(root.ollamaUrl, root.ollamaModel)
        }
    ]

    ColumnLayout {
        spacing: Kirigami.Units.gridUnit

        Kirigami.Card {
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.smallSpacing
            
            contentItem: ColumnLayout {
                spacing: Kirigami.Units.smallSpacing
                
                PlasmaComponents.Label {
                    text: i18n("Natural Language Analysis")
                    font.weight: Font.Bold
                }
                
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: root.intelligence && root.intelligence.isGenerating 
                          ? i18n("Analyzing your usage patterns via local Ollama...") 
                          : (root.intelligence && root.intelligence.fullInsight 
                             ? root.intelligence.fullInsight 
                             : i18n("Click 'Generate Insights' to analyze your last 7 days of AI usage."))
                    wrapMode: Text.WordWrap
                    font.italic: !root.intelligence || !root.intelligence.fullInsight
                    color: Kirigami.Theme.textColor
                    opacity: 0.9
                }
                
                QQC2.BusyIndicator {
                    Layout.alignment: Qt.AlignHCenter
                    running: root.intelligence && root.intelligence.isGenerating
                    visible: running
                }
            }
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.smallSpacing
            text: i18n("Insights are generated locally using your Ollama server. No usage data leaves your machine.")
            type: Kirigami.MessageType.Information
            visible: true
        }
    }
}
