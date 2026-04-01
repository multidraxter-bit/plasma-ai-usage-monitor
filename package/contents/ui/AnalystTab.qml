import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import com.github.loofi.aiusagemonitor as AIUsage

/**
 * The Analyst Tab - Deep Visualization & Efficiency
 * Shows Activity Heatmap, Efficiency Metrics, and Intelligence Insights.
 */
Kirigami.ScrollablePage {
    id: analystPage
    
    title: i18n("The Analyst")
    
    // Data properties
    property var activityData: []
    property double maxIntensity: 1.0
    property double avgEfficiency: 0.0
    property string efficiencyTrend: "neutral"
    
    // DB reference from main.qml
    readonly property var db: plasmoid.configuration.historyEnabled ? usageDatabase : null

    onVisibleChanged: {
        if (visible) {
            refreshData();
        }
    }

    function refreshData() {
        if (!db) return;
        
        // Fetch yearly activity for heatmap
        var activity = db.getYearlyActivity(plasmoid.configuration.analystIntensityMode);
        activityData = activity.days;
        maxIntensity = activity.maxIntensity;
        
        // Fetch efficiency series for metric and trend
        var efficiency = db.getEfficiencySeries(30);
        if (efficiency.length > 0) {
            var sum = 0;
            for (var i = 0; i < efficiency.length; i++) {
                sum += efficiency[i].value;
            }
            avgEfficiency = sum / efficiency.length;
            
            // Calculate trend (last 7 days vs previous 7 days)
            if (efficiency.length >= 14) {
                var recentSum = 0;
                var olderSum = 0;
                for (var j = 0; j < 7; j++) {
                    recentSum += efficiency[efficiency.length - 1 - j].value;
                    olderSum += efficiency[efficiency.length - 8 - j].value;
                }
                var recentAvg = recentSum / 7;
                var olderAvg = olderSum / 7;
                
                if (recentAvg > olderAvg * 1.05) efficiencyTrend = "up";
                else if (recentAvg < olderAvg * 0.95) efficiencyTrend = "down";
                else efficiencyTrend = "neutral";
            }
        }
    }

    Controls.Action {
        id: refreshAction
        icon.name: "view-refresh"
        text: i18n("Refresh")
        onTriggered: refreshData()
    }

    actions: [refreshAction]

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing
        
        // KPI Section
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing
            
            EfficiencyMetricCard {
                Layout.fillWidth: true
                efficiencyRatio: avgEfficiency
                trend: efficiencyTrend
            }
            
            Kirigami.Card {
                Layout.fillWidth: true
                header: Kirigami.Heading {
                    text: i18n("Activity Mode")
                    level: 4
                }
                contentItem: ColumnLayout {
                    Controls.ComboBox {
                        Layout.fillWidth: true
                        model: [i18n("Cost Intensity"), i18n("Volume Intensity")]
                        currentIndex: plasmoid.configuration.analystIntensityMode
                        onActivated: (index) => {
                            plasmoid.configuration.analystIntensityMode = index;
                            refreshData();
                        }
                    }
                    Controls.CheckBox {
                        text: i18n("Normalize Outliers")
                        checked: plasmoid.configuration.analystNormalization
                        onToggled: {
                            plasmoid.configuration.analystNormalization = checked;
                            refreshData();
                        }
                    }
                }
            }
        }
        
        // Heatmap Section
        Kirigami.Card {
            Layout.fillWidth: true
            header: Kirigami.Heading {
                text: i18n("Activity Heatmap (Last 365 Days)")
                level: 4
            }
            
            contentItem: ColumnLayout {
                spacing: Kirigami.Units.mediumSpacing
                
                Controls.ScrollView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    contentWidth: heatmap.width
                    clip: true
                    
                    ActivityHeatmap {
                        id: heatmap
                        activityData: analystPage.activityData
                        maxIntensity: analystPage.maxIntensity
                        baseColor: Kirigami.Theme.highlightColor
                        
                        onHovered: (date, val) => {
                            statusLabel.text = i18n("%1: %2", date, 
                                plasmoid.configuration.analystIntensityMode === 0 
                                ? "$" + val.toFixed(2) 
                                : val.toLocaleString() + " tokens");
                        }
                    }
                }
                
                Label {
                    id: statusLabel
                    text: i18n("Hover over a day to see details")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    color: Kirigami.Theme.disabledTextColor
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
        
        // Intelligence Integration Placeholder
        Kirigami.Card {
            Layout.fillWidth: true
            visible: intelligenceEngine && intelligenceEngine.enabled
            
            header: Kirigami.Heading {
                text: i18n("Analyst Insights")
                level: 4
            }
            
            contentItem: ColumnLayout {
                Label {
                    text: intelligenceEngine ? intelligenceEngine.lastAnalystInsight : i18n("No insights available.")
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                
                Controls.Button {
                    text: i18n("Generate New Insight")
                    icon.name: "brain"
                    onClicked: {
                        // Request intelligence update via main.qml
                        generateAnalystInsight();
                    }
                }
            }
        }
    }
}
