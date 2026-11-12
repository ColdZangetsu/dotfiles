// Cáscara de cristal de la píldora: borde, brillo superior y sombra inferior. Estático (cero costo).
import QtQuick

Item {
    id: g
    property var paleta
    property real realce: 0          // 0..1 hover/actividad
    property bool foco: false
    property real brillo: 1
    anchors.fill: parent
    Rectangle {      // brillo del cristal arriba, sombra abajo
        anchors.fill: parent; anchors.margins: 1; radius: width / 2
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.10 * g.brillo) }
            GradientStop { position: 0.16; color: Qt.rgba(1, 1, 1, 0.0) }
            GradientStop { position: 0.80; color: Qt.rgba(0, 0, 0, 0.0) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.30) }
        }
    }
    Rectangle {      // reflejo largo a la izquierda
        x: 7; y: 30; width: 2; height: 74; radius: 1
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.0) }
            GradientStop { position: 0.3; color: Qt.rgba(1, 1, 1, 0.13 * g.brillo) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
        }
    }
    Rectangle {      // aro exterior oscuro: separa la píldora de cualquier fondo
        anchors.fill: parent; anchors.margins: -1; radius: width / 2
        color: "transparent"; border.width: 1; border.color: Qt.rgba(0, 0, 0, 0.55)
    }
    Rectangle {      // borde
        anchors.fill: parent; radius: width / 2; color: "transparent"; border.width: 1
        border.color: g.foco ? g.paleta.alfa(g.paleta.hueso, 0.75)
                             : g.paleta.mezcla(g.paleta.borde, g.paleta.hueso, 0.22 * g.realce)
    }
}
