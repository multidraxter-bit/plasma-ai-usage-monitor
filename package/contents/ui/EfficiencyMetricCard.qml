import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

/**
 * A KPI card for displaying AI generation efficiency.
 * Tracks the ratio of Output Tokens / Input Tokens.
 */
Kirigami.Card {
    id: efficiencyCard
    
    property double efficiencyRatio: 1.0
    property string trend: "neutral" // "up", "down", "neutral"
    
    header: Kirigami.Heading {
        text: i18n("Prompt Efficiency")
        level: 4
    }
    
    contentItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing
        
        RowLayout {
            spacing: Kirigami.Units.mediumSpacing
            
            PlasmaComponents.Label {
                text: efficiencyRatio.toFixed(2) + "x"
                font.pointSize: 24
                font.weight: Font.Bold
                color: {
                    if (efficiencyRatio > 1.5) return Kirigami.Theme.positiveTextColor;
                    if (efficiencyRatio < 0.8) return Kirigami.Theme.negativeTextColor;
                    return Kirigami.Theme.textColor;
                }
            }
            
            Kirigami.Icon {
                source: {
                    if (trend === "up") return "arrow-up";
                    if (trend === "down") return "arrow-down";
                    return "dash-symbol";
                }
                width: Kirigami.Units.iconSizes.small
                height: width
                color: {
                    if (trend === "up") return Kirigami.Theme.positiveTextColor;
                    if (trend === "down") return Kirigami.Theme.negativeTextColor;
                    return Kirigami.Theme.disabledTextColor;
                }
                visible: trend !== "neutral"
            }
        }
        
        PlasmaComponents.Label {
            text: i18n("Output / Input Token Ratio")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            color: Kirigami.Theme.disabledTextColor
            Layout.fillWidth: true
            elide: Text.ElideRight
        }
        
        // Contextual description
        PlasmaComponents.Label {
            text: {
                if (efficiencyRatio > 1.5) return i18n("Highly Efficient: Your prompts yield substantial generation.");
                if (efficiencyRatio < 0.8) return i18n("Low Efficiency: Consider more concise prompting.");
                return i18n("Healthy: Standard conversational balance.");
            }
            font.italic: true
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }
}
