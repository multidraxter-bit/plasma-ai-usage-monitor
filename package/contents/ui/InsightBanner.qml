import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Kirigami.InlineMessage {
    id: root
    
    Layout.fillWidth: true
    Layout.margins: Kirigami.Units.smallSpacing
    
    type: Kirigami.MessageType.Information
    showCloseButton: true
    visible: text !== ""

    actions: [
        Kirigami.Action {
            icon.name: "view-analyze"
            text: i18n("Details")
            onTriggered: {
                root.detailsRequested();
            }
        }
    ]

    signal detailsRequested()
}
