import re

with open('package/contents/ui/configProviders.qml', 'r') as f:
    content = f.read()

# Add advanced mode toggle at the top
if 'id: providersPage' in content and 'property bool advancedMode' not in content:
    content = content.replace(
        'id: providersPage\n',
        'id: providersPage\n\n    property bool advancedMode: false\n'
    )
    
    # After Component.onDestruction
    top_controls = """
    Kirigami.FormLayout {
        anchors.fill: parent
        
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Settings Mode")
        }
        
        QQC2.Switch {
            id: advancedModeSwitch
            Kirigami.FormData.label: i18n("Advanced Mode:")
            checked: providersPage.advancedMode
            onCheckedChanged: providersPage.advancedMode = checked
            QQC2.ToolTip.text: i18n("Show advanced configuration options like custom base URLs and specific tiers.")
            QQC2.ToolTip.visible: hovered
        }
        
"""
    content = content.replace('Kirigami.FormLayout {\n        anchors.fill: parent\n', top_controls)

# Hide advanced fields
advanced_fields = [
    r'(QQC2\.TextField {\n\s+id: \w+BaseUrlField.*?\n\s+Kirigami\.FormData\.label: i18n\(".*?"\)\n\s+enabled:.*?)(\n\s+text:)',
    r'(QQC2\.TextField {\n\s+id: \w+ProjectField.*?\n\s+Kirigami\.FormData\.label: i18n\(".*?"\)\n\s+enabled:.*?)(\n\s+text:)',
    r'(QQC2\.TextField {\n\s+id: \w+RegionField.*?\n\s+Kirigami\.FormData\.label: i18n\(".*?"\)\n\s+enabled:.*?)(\n\s+text:)',
    r'(QQC2\.TextField {\n\s+id: \w+DeploymentField.*?\n\s+Kirigami\.FormData\.label: i18n\(".*?"\)\n\s+enabled:.*?)(\n\s+text:)',
    r'(QQC2\.ComboBox {\n\s+id: \w+TierField.*?\n\s+Kirigami\.FormData\.label: i18n\(".*?"\)\n\s+enabled:.*?)(\n\s+model:)'
]

for pattern in advanced_fields:
    content = re.sub(pattern, r'\1\n            visible: providersPage.advancedMode\2', content, flags=re.DOTALL)

with open('package/contents/ui/configProviders.qml', 'w') as f:
    f.write(content)
