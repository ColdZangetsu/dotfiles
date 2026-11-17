import QtQuick
import QtQuick.Shapes
import qs.services

// Ícono de la familia propia del par (COMUN.md §3.1): rejilla 16 x 16, trazo 1.4, remates rectos, sin relleno.
// "tacha" = estado apagado: tajo de (2, 14) a (14, 2).
Item {
    id: root

    property string nombre: "ventana"
    property color color: Espada.hueso
    property real tam: 14
    property real grosor: tam <= 10 ? 1.6 : 1.4
    property bool relleno: false
    property bool tacha: false
    property bool animarColor: true

    implicitWidth: tam
    implicitHeight: tam

    Behavior on color {
        enabled: root.animarColor
        ColorAnimation { duration: Espada.dColor }
    }

    Shape {
        width: 16
        height: 16
        scale: root.tam / 16
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.color
            strokeWidth: root.relleno ? 1 : root.grosor
            fillColor: root.relleno ? root.color : "transparent"
            capStyle: ShapePath.SquareCap
            joinStyle: ShapePath.MiterJoin
            PathSvg { path: Espada.ico[root.nombre] ?? Espada.ico.ventana }
        }
        ShapePath {
            strokeColor: root.tacha ? root.color : "transparent"
            strokeWidth: root.grosor
            fillColor: "transparent"
            capStyle: ShapePath.SquareCap
            startX: 2; startY: 14
            PathLine { x: 14; y: 2 }
        }
    }
}
