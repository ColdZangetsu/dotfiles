import QtQuick
import qs.components
import qs.services

Item {
    id: root

    required property ScreenState screenState
    required property Item sidebarPanel
    property alias osdPanel: content.osdPanel
    property alias sessionPanel: content.sessionPanel
    property alias utilitiesPanel: content.utilitiesPanel

    visible: height > 0
    // 11-15 Saya: el carril de y = 0 a 68 junto a la vaina es de Nero: los avisos bajan a y = 76 (58 en el XENEON)
    // y se separan 16 px del borde derecho
    anchors.topMargin: TsukaConf.saya ? ((parent?.height ?? 1000) < 600 ? 52 : 70) : -5
    anchors.rightMargin: TsukaConf.saya ? 10 : 0
    implicitWidth: Math.max(sidebarPanel.width, content.implicitWidth)
    implicitHeight: content.implicitHeight

    Content {
        id: content

        anchors.topMargin: 5
        screenState: root.screenState
    }
}
