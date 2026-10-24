import QtQuick
import QtQuick.Layouts
import qs.services

// Tarjeta chica: porcentaje grande, nombre abajo, icono arriba a la derecha.
Card {
    id: root

    property string icon
    property url image
    property string value
    property string label
    property string note
    property bool highlighted: false

    readonly property color fg: highlighted ? Theme.highlightText : Theme.cardText

    color: highlighted ? Theme.highlight : Theme.card
    implicitWidth: 130 * Theme.scale
    implicitHeight: 110 * Theme.scale

    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 10 * Theme.scale
        width: 34 * Theme.scale
        height: width
        radius: width / 2
        color: root.image.toString() ? "transparent" : (root.highlighted ? Qt.rgba(0, 0, 0, 0.1) : Theme.inner)

        Icon {
            anchors.centerIn: parent
            size: 18
            color: root.fg
            text: root.icon
            visible: !root.image.toString()
        }

        Image {
            anchors.fill: parent
            source: root.image
            sourceSize: Qt.size(width * 2, height * 2)
            visible: root.image.toString() !== ""
        }
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 14 * Theme.scale
        spacing: 0

        Txt {
            size: 24
            font.weight: Font.Bold
            color: root.fg
            text: root.value
        }

        Txt {
            size: 12
            color: root.fg
            text: root.label
        }

        Txt {
            Layout.fillWidth: true
            size: 9
            color: root.fg
            opacity: 0.75
            elide: Text.ElideRight
            text: root.note
            visible: root.note !== ""
        }
    }
}
