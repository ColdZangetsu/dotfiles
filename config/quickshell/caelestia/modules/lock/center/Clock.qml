pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.services

// 11-12 Fable: el mismo reloj del XENEON — Anton enorme, horas y minutos en hueso, dos cuadritos rojos.
// Original: center/Clock.qml.antes-fable
Row {
    id: root

    required property real centerScale
    readonly property int tam: Math.round(220 * centerScale)

    spacing: Math.round(18 * centerScale)

    Text {
        text: Time.hourStr
        color: "#fff1f3"
        font.family: "Anton"
        font.pixelSize: root.tam
        anchors.verticalCenter: parent.verticalCenter
    }

    Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: Math.round(root.tam * 0.16)

        Rectangle { width: Math.round(root.tam * 0.11); height: width; radius: 3; color: "#ff2448" }
        Rectangle { width: Math.round(root.tam * 0.11); height: width; radius: 3; color: "#ff2448" }
    }

    Text {
        text: Time.minuteStr
        color: "#fff1f3"
        font.family: "Anton"
        font.pixelSize: root.tam
        anchors.verticalCenter: parent.verticalCenter
    }
}
