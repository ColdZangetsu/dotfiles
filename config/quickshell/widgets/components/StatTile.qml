import QtQuick
import QtQuick.Layouts
import qs.services

// Mosaico: etiqueta + icono arriba, porcentaje grande, barra fina abajo (roja desde 85 %).
Card {
    id: root

    property string icon
    property url image
    property string value
    property string label
    property string note
    property real percent: -1 // 0-100; -1 = sin barra
    property bool highlighted: false

    readonly property color fg: highlighted ? Theme.highlightText : Theme.cardText
    readonly property bool hot: percent >= 85

    color: highlighted ? Theme.highlight : Theme.card
    implicitWidth: 130 * Theme.scale
    implicitHeight: 110 * Theme.scale

    RowLayout {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 14 * Theme.scale
        anchors.topMargin: 12 * Theme.scale

        Label {
            Layout.fillWidth: true
            color: root.fg
            opacity: 0.7
            text: root.label
        }

        Icon {
            size: 15
            fill: false
            color: root.fg
            opacity: 0.6
            text: root.icon
            visible: !root.image.toString()
        }

        Image {
            Layout.preferredWidth: 18 * Theme.scale
            Layout.preferredHeight: 18 * Theme.scale
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
        anchors.bottomMargin: 13 * Theme.scale
        spacing: 3 * Theme.scale

        Txt {
            size: 30
            font.family: Theme.titleFont
            color: root.hot ? Theme.accent : root.fg
            text: root.value
        }

        Txt {
            Layout.fillWidth: true
            size: 9
            color: root.fg
            opacity: 0.65
            elide: Text.ElideRight
            text: root.note
            visible: root.note !== ""
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 2 * Theme.scale
            implicitHeight: Math.max(2, Math.round(2 * Theme.scale))
            radius: height / 2
            color: Theme.inner
            visible: root.percent >= 0

            Rectangle {
                width: parent.width * Math.max(0, Math.min(100, root.percent)) / 100
                height: parent.height
                radius: height / 2
                color: root.hot ? Theme.accent : root.fg
                opacity: root.hot ? 1 : 0.75
            }
        }
    }
}
