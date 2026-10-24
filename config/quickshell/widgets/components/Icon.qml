import QtQuick
import qs.services

Text {
    property real size: 18
    property bool fill: true

    color: Theme.cardText
    font.family: Theme.iconFont
    font.pixelSize: size * Theme.scale
    font.variableAxes: ({ "FILL": fill ? 1 : 0 })
}
