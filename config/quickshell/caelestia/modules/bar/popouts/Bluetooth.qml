pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.utils

// 11-12 Fable "tinta y filo" (popout de Bluetooth). Original: Bluetooth.qml.antes-fable
// Cabecera + interruptor, CONECTADOS / GUARDADOS, filo rojo en lo conectado, batería en Anton.
ColumnLayout {
    id: root

    required property PopoutState popouts

    readonly property color hueso: "#efe6d8"
    readonly property color huesoAlto: "#fff1f3"
    readonly property color tenue: "#a0a8b8"
    readonly property color apagado: "#6b7180"
    readonly property color rojo: "#ff2448"
    readonly property var adaptador: Bluetooth.defaultAdapter // qmllint disable unresolved-type
    readonly property var todos: [...Bluetooth.devices.values].sort((a, b) => a.name.localeCompare(b.name)) // qmllint disable unresolved-type
    readonly property var conectados: todos.filter(d => d.connected)
    readonly property var guardados: todos.filter(d => !d.connected && d.paired).slice(0, 5)

    width: 300
    spacing: 6

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 14
        Layout.leftMargin: 4
        Layout.rightMargin: 4

        Text {
            text: "BLUETOOTH"
            color: root.tenue
            font.family: "Anton"
            font.pixelSize: 15
            font.letterSpacing: 3
        }
        Item { Layout.fillWidth: true }
        Interruptor {
            encendido: root.adaptador?.enabled ?? false
            onCambiar: { if (root.adaptador) root.adaptador.enabled = !root.adaptador.enabled; }
        }
    }

    Rotulo { texto: "CONECTADOS"; visible: root.conectados.length > 0 }
    Repeater {
        model: root.conectados
        Fila { required property var modelData; dispositivo: modelData }
    }

    Rotulo { texto: "GUARDADOS"; visible: root.guardados.length > 0 }
    Repeater {
        model: root.guardados
        Fila { required property var modelData; dispositivo: modelData }
    }

    Text {
        visible: !(root.adaptador?.enabled ?? false)
        Layout.leftMargin: 4
        text: "Apagado"
        color: root.apagado
        font.pixelSize: 13
    }

    Text {
        Layout.topMargin: 6
        Layout.bottomMargin: 12
        Layout.leftMargin: 4
        text: "Ajustes de Bluetooth  ›"
        color: aj.containsMouse ? root.hueso : root.apagado
        font.pixelSize: 12
        MouseArea {
            id: aj
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.popouts.detachRequested("bluetooth")
        }
    }

    component Rotulo: Text {
        property string texto
        Layout.topMargin: 8
        Layout.leftMargin: 4
        text: texto
        color: root.apagado
        font.family: "Anton"
        font.pixelSize: 12
        font.letterSpacing: 3
    }

    component Interruptor: Rectangle {
        id: it
        property bool encendido
        signal cambiar
        implicitWidth: 40
        implicitHeight: 22
        radius: 11
        color: Qt.rgba(0.94, 0.90, 0.85, encendido ? 0.18 : 0.08)
        Rectangle {
            width: 16; height: 16; radius: 8
            anchors.verticalCenter: parent.verticalCenter
            x: it.encendido ? parent.width - width - 3 : 3
            color: it.encendido ? root.huesoAlto : "transparent"
            border.width: it.encendido ? 0 : 1.5
            border.color: root.tenue
            Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: it.cambiar() }
    }

    component Fila: Rectangle {
        id: f
        property var dispositivo
        readonly property bool activa: dispositivo?.connected ?? false
        readonly property bool cargando: dispositivo?.state === BluetoothDeviceState.Connecting || dispositivo?.state === BluetoothDeviceState.Disconnecting // qmllint disable unresolved-type

        Layout.fillWidth: true
        implicitHeight: 42
        radius: 12
        color: activa ? "#1d2129" : (m.containsMouse ? Qt.rgba(0.94, 0.90, 0.85, 0.05) : "transparent")
        opacity: cargando ? 0.55 : 1

        Rectangle {
            visible: f.activa
            x: 0; anchors.verticalCenter: parent.verticalCenter
            width: 3; height: parent.height - 14; radius: 1.5
            color: root.rojo
        }
        MaterialIcon {
            anchors.left: parent.left; anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: Icons.getBluetoothIcon(f.dispositivo?.icon ?? "")
            color: f.activa ? root.huesoAlto : root.tenue
        }
        Text {
            anchors.left: parent.left; anchors.leftMargin: 46
            anchors.right: bat.left; anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: f.cargando ? (f.activa ? "Desconectando…" : "Conectando…") : (f.dispositivo?.name ?? "")
            elide: Text.ElideRight
            color: f.activa ? root.huesoAlto : root.hueso
            font.pixelSize: 14
            font.weight: f.activa ? Font.DemiBold : Font.Normal
        }
        Text {
            id: bat
            anchors.right: parent.right; anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            visible: f.activa && (f.dispositivo?.batteryAvailable ?? false)
            text: Math.round((f.dispositivo?.battery ?? 0) * 100)
            color: (f.dispositivo?.battery ?? 1) < 0.2 ? root.rojo : root.tenue
            font.family: "Anton"
            font.pixelSize: 15
        }
        MouseArea {
            id: m
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: { if (f.dispositivo && !f.cargando) f.dispositivo.connected = !f.dispositivo.connected; }
        }
    }
}
