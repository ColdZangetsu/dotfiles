import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import Quickshell

// 11-12 Fable: bloqueo sobrio. Solo el centro (ZANGETSU, reloj, fecha, contraseña). Se van clima, fetch,
// recursos, media y avisos (lo más genérico, y el clima hacía peticiones a internet en cada bloqueo).
// Original: Content.qml.antes-fable
Item {
    id: root

    required property var lock

    Center {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        lock: root.lock
    }
}
