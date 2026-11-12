import QtQuick
import Caelestia.Config
import qs.components
import qs.services
import Quickshell

Item {
    id: root

    required property ScreenState screenState

    implicitWidth: icon.implicitHeight + Tokens.padding.small
    implicitHeight: icon.implicitHeight

    StateLayer {
        id: capa
        // Cursed workaround to make the height larger than the parent
        anchors.fill: undefined
        anchors.centerIn: parent
        implicitWidth: implicitHeight
        implicitHeight: icon.implicitHeight + Tokens.padding.small
        radius: Tokens.rounding.full
        onClicked: root.screenState.session = !root.screenState.session
    }

    // 11-12 Fable: tenue en reposo, rojo solo con el cursor encima (original: Power.qml.antes-fable)
    MaterialIcon {
        id: icon

        anchors.centerIn: parent

        text: "power_settings_new"
        color: capa.containsMouse ? "#ff2448" : "#94a0a8b8"

        Behavior on color {
            ColorAnimation { duration: 140 }
        }
        fontStyle: Tokens.font.icon.builders.small.weight(Font.Bold).build()
    }
}
