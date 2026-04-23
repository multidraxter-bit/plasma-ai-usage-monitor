with open('plugin/appinfo.h', 'r') as f:
    header = f.read()

header = header.replace(
    'Q_INVOKABLE bool exportConfig(const QString &jsonConfig, const QString &suggestedFileName) const;',
    'Q_INVOKABLE bool exportConfig(const QString &jsonConfig, const QString &filePath) const;'
)
header = header.replace(
    'Q_INVOKABLE QString importConfig() const;',
    'Q_INVOKABLE QString importConfig(const QString &filePath) const;'
)

with open('plugin/appinfo.h', 'w') as f:
    f.write(header)

with open('plugin/appinfo.cpp', 'r') as f:
    impl = f.read()

import re
impl = re.sub(r'bool AppInfo::exportConfig\(.*?\).*?\}', r'''bool AppInfo::exportConfig(const QString &jsonConfig, const QString &filePath) const
{
    QString localPath = filePath;
    if (localPath.startsWith("file://")) {
        localPath = QUrl(filePath).toLocalFile();
    }
    QFile file(localPath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) return false;
    
    QTextStream out(&file);
    out << jsonConfig;
    return true;
}''', impl, flags=re.DOTALL)

impl = re.sub(r'QString AppInfo::importConfig\(\).*?\}', r'''QString AppInfo::importConfig(const QString &filePath) const
{
    QString localPath = filePath;
    if (localPath.startsWith("file://")) {
        localPath = QUrl(filePath).toLocalFile();
    }
    QFile file(localPath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return QString();
    
    return QString(file.readAll());
}''', impl, flags=re.DOTALL)

impl = impl.replace('#include <QFileDialog>', '#include <QUrl>')

with open('plugin/appinfo.cpp', 'w') as f:
    f.write(impl)
