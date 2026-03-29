set(aiusagemonitor_SRCS
    aiusageplugin.cpp
    appinfo.cpp
    secretsmanager.cpp
    providerbackend.cpp
    openaicompatibleprovider.cpp
    openaiprovider.cpp
    azureopenaiprovider.cpp
    anthropicprovider.cpp
    googleprovider.cpp
    mistralprovider.cpp
    deepseekprovider.cpp
    groqprovider.cpp
    xaiprovider.cpp
    openrouterprovider.cpp
    togetherprovider.cpp
    cohereprovider.cpp
    googleveoprovider.cpp
    usagedatabase.cpp
    updatechecker.cpp
    subscriptiontoolbackend.cpp
    claudecodemonitor.cpp
    codexclimonitor.cpp
    copilotmonitor.cpp
    cursormonitor.cpp
    windsurfmonitor.cpp
    browsercookieextractor.cpp
    loofiserverprovider.cpp
    ollamaprovider.cpp
    intelligencebackend.cpp
    awssigv4signer.cpp
    bedrockprovider.cpp
    forecastengine.cpp
)

set(aiusagemonitor_HDRS
    aiusageplugin.h
    appinfo.h
    secretsmanager.h
    providerbackend.h
    openaicompatibleprovider.h
    openaiprovider.h
    azureopenaiprovider.h
    anthropicprovider.h
    googleprovider.h
    mistralprovider.h
    deepseekprovider.h
    groqprovider.h
    xaiprovider.h
    openrouterprovider.h
    togetherprovider.h
    cohereprovider.h
    googleveoprovider.h
    usagedatabase.h
    clipboardhelper.h
    updatechecker.h
    subscriptiontoolbackend.h
    claudecodemonitor.h
    codexclimonitor.h
    copilotmonitor.h
    cursormonitor.h
    windsurfmonitor.h
    browsercookieextractor.h
    loofiserverprovider.h
    ollamaprovider.h
    intelligencebackend.h
    awssigv4signer.h
    bedrockprovider.h
    forecastengine.h
)

add_library(aiusagemonitorplugin SHARED ${aiusagemonitor_SRCS} ${aiusagemonitor_HDRS})

target_compile_definitions(aiusagemonitorplugin
    PRIVATE AIUSAGE_MONITOR_VERSION="${PROJECT_VERSION}"
)

target_link_libraries(aiusagemonitorplugin
    Qt6::Core
    Qt6::Qml
    Qt6::Quick
    Qt6::Network
    Qt6::Sql
    KF6::Wallet
    KF6::Notifications
    KF6::I18n
)

install(TARGETS aiusagemonitorplugin DESTINATION ${KDE_INSTALL_QMLDIR}/com/github/loofi/aiusagemonitor)
install(FILES qmldir DESTINATION ${KDE_INSTALL_QMLDIR}/com/github/loofi/aiusagemonitor)

if(BUILD_TESTING)
    add_subdirectory(tests)
endif()
