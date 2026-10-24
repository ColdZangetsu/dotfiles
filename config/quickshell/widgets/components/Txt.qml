import QtQuick
import qs.services

Text {
    property real size: 14

    color: Theme.cardText
    font.family: Theme.font
    font.pixelSize: size * Theme.scale
    renderType: Text.NativeRendering
}
