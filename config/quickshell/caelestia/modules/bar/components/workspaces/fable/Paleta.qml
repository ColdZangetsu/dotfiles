// Paleta única del indicador de escritorios (tema Eclipse). Ningún color vive fuera de aquí.
// Para recolorear con Caelestia: crea UNA instancia y enlaza (p. ej. rojo: Colours.palette.m3primary).
import QtQuick

QtObject {
    property color fondo: "#0c0e12"        // negro del escritorio
    property color capsula: "#10121a"      // píldora de la barra
    property color borde: "#2a2d38"
    property color rojo: "#e0303a"         // rojo Bankai
    property color rojoVivo: "#ff2448"     // filo / corona caliente
    property color hueso: "#efe6d8"
    property color huesoAlto: "#fffaf0"    // hueso encendido (kanji activo, luna llena)
    property color hielo: "#a9d4ff"
    property color tenue: "#8a8f9c"
    property color vacio: "#05060a"        // negro de luna / tinta

    function alfa(c, a) { return Qt.rgba(c.r, c.g, c.b, c.a * a) }
    function mezcla(c1, c2, t) {
        t = Math.max(0, Math.min(1, t))
        return Qt.rgba(c1.r + (c2.r - c1.r) * t, c1.g + (c2.g - c1.g) * t, c1.b + (c2.b - c1.b) * t, c1.a + (c2.a - c1.a) * t)
    }
}
