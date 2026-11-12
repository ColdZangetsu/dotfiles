// Captura fuera de pantalla (no abre ninguna ventana). Lo usa probar.sh captura.
import QtQuick
import QtQuick.Window

Window {
    id: w
    width: 1530; height: 430; visible: true; color: "black"
    // uso: qml6 prueba.qml -- <salida.png> [fondo.png] [vacio]
    readonly property var arg: Qt.application.arguments.slice(Qt.application.arguments.indexOf("--") + 1)
    property string salida: arg[0] || "reloj-fable.png"
    property string fondo: arg[1] ? "file://" + arg[1] : ""
    property bool vacio: arg[2] === "vacio"
    Image { anchors.fill: parent; source: w.fondo; fillMode: Image.PreserveAspectCrop }
    Cara {
        id: cara
        anchors.fill: parent
        fecha: new Date(2026, 10, 10, 22, 47, 36)
        sonando: !w.vacio
        pistaTitulo: "Number One"; pistaArtista: "Shiro Sagisu · Bleach OST"; pistaProgreso: 0.42
        notifs: w.vacio ? [] : [
            { time: "2026-11-11T05:45:00Z", summary: "Nero", body: "Ya quedó el respaldo de anoche, todo bien.", appName: "WhatsApp", image: "", appIcon: "", urgency: 1 },
            { time: "2026-11-11T05:12:00Z", summary: "Archivo apartado", body: "El.CamRj3rFk.rar: no es video (RAR archive data, v5)", appName: "Vigilante", image: "", appIcon: "", urgency: 2 },
            { time: "2026-11-11T01:56:00Z", summary: "Gestor de paquetes", body: "Updates Available", appName: "Gestor de paquetes", image: "", appIcon: "", urgency: 1 }
        ]
    }
    Timer { interval: 900; running: true; onTriggered: w.contentItem.grabToImage(r => { r.saveToFile(w.salida); Qt.quit(); }) }
}
