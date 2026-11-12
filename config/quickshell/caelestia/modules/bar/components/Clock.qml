pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import Quickshell

// 11-12 Fable (paso 5, reloj): horas y minutos en Anton, y entre ellos dos cuadritos rojos
// (los dos puntos del reloj del XENEON, acostados). Original: Clock.qml.antes-fable
StyledRect {
    id: root

    readonly property color hueso: "#fff1f3"
    readonly property color rojo: "#ff2448"
    readonly property color apagado: "#8a8f9c"

    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: col.implicitHeight + Tokens.padding.extraSmall * 2
    color: "transparent"
    radius: Tokens.rounding.full

    Column {
        id: col

        anchors.centerIn: parent
        spacing: 0

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Time.hourStr
            color: root.hueso
            font.family: "Anton"
            font.pixelSize: 21
            height: 23
            verticalAlignment: Text.AlignVCenter
        }

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 13
            height: 9

            Rectangle { x: 0; y: 3; width: 4; height: 4; radius: 1; color: root.rojo }
            Rectangle { x: 9; y: 3; width: 4; height: 4; radius: 1; color: root.rojo }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Time.minuteStr
            color: root.hueso
            font.family: "Anton"
            font.pixelSize: 21
            height: 23
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: Units.twelveHourClock && (QsWindow.window?.screen?.name ?? "") !== "DP-3"
            topPadding: 3
            text: Time.amPmStr.toLowerCase()
            color: root.apagado
            font.family: "Anton"
            font.pixelSize: 9
            font.letterSpacing: 2
        }
    }
}
