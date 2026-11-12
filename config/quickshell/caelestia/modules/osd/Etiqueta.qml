// Burbuja con el valor, a la izquierda de la perilla. Solo aparece al manipular (arrastre/rueda).
import QtQuick

Item {
    id: e
    property var nucleo
    property var paleta
    property string texto: ""
    property string fuente: "Anton"
    visible: nucleo.tocando > 0.01
    opacity: nucleo.tocando
    width: caja.width; height: caja.height
    x: -width - 12 + (1 - nucleo.tocando) * 6
    y: Math.round(nucleo.yPerilla + nucleo.empuje - height / 2)
    Rectangle {
        id: caja
        width: Math.max(38, lbl.implicitWidth + 18); height: 24; radius: 12
        color: e.paleta.alfa(e.paleta.capsula, 0.92)
        border.width: 1; border.color: e.paleta.alfa(e.paleta.hueso, 0.14)
        Text {
            id: lbl
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 0.5
            text: e.texto; color: e.paleta.hueso
            font { family: e.fuente; pixelSize: 13; letterSpacing: 1 }
        }
    }
}
