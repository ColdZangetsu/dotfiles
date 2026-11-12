pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import Quickshell

// 11-12 Fable "tinta y filo" (popout de audio). Original: AudioPopout.qml.antes-fable
// Cabecera VOLUMEN + número en Anton, riel con marca fija del 40 %, y filas de salida/entrada
// donde un filo rojo marca la que está en uso.
Item {
    id: root

    required property PopoutState popouts

    readonly property color hueso: "#efe6d8"
    readonly property color huesoAlto: "#fff1f3"
    readonly property color tenue: "#a0a8b8"
    readonly property color apagado: "#6b7180"
    readonly property color rojo: "#ff2448"
    readonly property color fila: "#1d2129"

    implicitWidth: 300
    implicitHeight: col.implicitHeight + 28

    ColumnLayout {
        id: col

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        spacing: 6

        // ---- cabecera ----
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: Audio.muted ? "SILENCIO" : "VOLUMEN"
                color: root.tenue
                font.family: "Anton"
                font.pixelSize: 15
                font.letterSpacing: 3
                Layout.alignment: Qt.AlignBottom
                bottomPadding: 6
            }
            Item { Layout.fillWidth: true }
            Text {
                text: Math.round(Audio.volume * 100)
                color: root.huesoAlto
                font.family: "Anton"
                font.pixelSize: 34
            }
            Text {
                text: "%"
                color: root.apagado
                font.family: "Anton"
                font.pixelSize: 14
                Layout.alignment: Qt.AlignBottom
                bottomPadding: 5
            }
        }

        // ---- riel ----
        Item {
            id: riel

            readonly property real v: Math.max(0, Math.min(1, Audio.volume))
            Layout.fillWidth: true
            implicitHeight: 26

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width; height: 4; radius: 2
                color: Qt.rgba(0.94, 0.90, 0.85, 0.12)
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * riel.v; height: 4; radius: 2
                color: zona.pressed ? root.rojo : root.hueso
            }
            Rectangle {   // marca fija del 40 % (nivel seguro)
                x: parent.width * 0.4 - 1
                anchors.verticalCenter: parent.verticalCenter
                width: 2; height: 12; radius: 1
                color: Qt.rgba(0.94, 0.90, 0.85, 0.35)
            }
            Rectangle {   // perilla: aparece al acercar el cursor, roja solo al arrastrar
                x: parent.width * riel.v - width / 2
                anchors.verticalCenter: parent.verticalCenter
                width: 14; height: 14; radius: 7
                color: zona.pressed ? root.rojo : root.huesoAlto
                opacity: zona.containsMouse || zona.pressed ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 120 } }
            }
            MouseArea {
                id: zona
                anchors.fill: parent
                hoverEnabled: true
                function poner(x) { Audio.setVolume(Math.max(0, Math.min(1, x / width))); }
                onPressed: e => poner(e.x)
                onPositionChanged: e => { if (pressed) poner(e.x); }
                onWheel: e => { if (e.angleDelta.y > 0) Audio.incrementVolume(); else if (e.angleDelta.y < 0) Audio.decrementVolume(); }
            }
        }

        Rectangle { Layout.fillWidth: true; Layout.topMargin: 4; implicitHeight: 1; color: Qt.rgba(0.94, 0.90, 0.85, 0.08) }

        Rotulo { texto: "SALIDA" }
        Repeater {
            model: Audio.sinks
            Fila {
                required property PwNode modelData
                nodo: modelData
                activa: Audio.sink?.id === modelData.id
                icono: (modelData.description ?? "").match(/BTD|Sennheiser|aud[ií]fono|headset|headphone/i) ? "headphones"
                     : (modelData.description ?? "").match(/HDMI|LG|monitor|ULTRAGEAR/i) ? "desktop_windows" : "speaker"
                onElegida: Audio.setAudioSink(modelData)
            }
        }

        Rotulo { texto: "ENTRADA" }
        Repeater {
            model: Audio.sources
            Fila {
                required property PwNode modelData
                nodo: modelData
                activa: Audio.source?.id === modelData.id
                icono: "mic"
                onElegida: Audio.setAudioSource(modelData)
            }
        }

        // ---- ajustes (discreto) ----
        Text {
            Layout.topMargin: 6
            text: "Ajustes de audio  ›"
            color: ajustes.containsMouse ? root.hueso : root.apagado
            font.pixelSize: 12
            MouseArea {
                id: ajustes
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.popouts.detachRequested("audio")
            }
        }
    }

    component Rotulo: Text {
        property string texto
        Layout.topMargin: 8
        text: texto
        color: root.apagado
        font.family: "Anton"
        font.pixelSize: 12
        font.letterSpacing: 3
    }

    component Fila: Rectangle {
        id: f
        property PwNode nodo
        property bool activa
        property string icono
        signal elegida

        Layout.fillWidth: true
        implicitHeight: 40
        radius: 12
        color: activa ? root.fila : (m.containsMouse ? Qt.rgba(0.94, 0.90, 0.85, 0.05) : "transparent")

        Rectangle {   // filo
            visible: f.activa
            x: 0; anchors.verticalCenter: parent.verticalCenter
            width: 3; height: parent.height - 14; radius: 1.5
            color: root.rojo
        }
        MaterialIcon {
            anchors.left: parent.left; anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: f.icono
            color: f.activa ? root.huesoAlto : root.tenue
        }
        Text {
            anchors.left: parent.left; anchors.leftMargin: 46
            anchors.right: parent.right; anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: f.nodo?.description ?? ""
            elide: Text.ElideRight
            color: f.activa ? root.huesoAlto : root.hueso
            font.pixelSize: 14
            font.weight: f.activa ? Font.DemiBold : Font.Normal
        }
        MouseArea {
            id: m
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: f.elegida()
        }
    }
}
