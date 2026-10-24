import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Ventana del escritorio: arriba del fondo y debajo de las ventanas normales.
// Se puede arrastrar con el mouse; la posición se guarda por `key`.
PanelWindow {
    id: root

    default property alias content: holder.data
    required property string key
    property real defaultX: 0
    property real defaultY: 0

    readonly property var savedPos: Positions.get(key)
    readonly property real posX: savedPos ? savedPos[0] : defaultX
    readonly property real posY: savedPos ? savedPos[1] : defaultY

    anchors.top: true
    anchors.left: true
    margins.left: posX
    margins.top: posY
    implicitWidth: holder.childrenRect.width
    implicitHeight: holder.childrenRect.height
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "widgets-escritorio"

    // Va antes del contenido: los botones del widget (p. ej. flechas del calendario)
    // reciben su clic primero, y el resto de la tarjeta sirve para arrastrar.
    MouseArea {
        property real pressX
        property real pressY

        anchors.fill: parent
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.ArrowCursor
        onPressed: e => {
            pressX = e.x;
            pressY = e.y;
        }
        onPositionChanged: e => {
            const sw = root.screen?.width ?? 2560;
            const sh = root.screen?.height ?? 1440;
            const x = Math.max(0, Math.min(sw - root.width, root.posX + e.x - pressX));
            const y = Math.max(0, Math.min(sh - root.height, root.posY + e.y - pressY));
            Positions.set(root.key, x, y);
        }
        onReleased: Positions.save()
    }

    Item {
        id: holder

        anchors.fill: parent
    }
}
