// Paleta única de las tres barras. Para recolorear con Caelestia, crea UNA instancia
// y enlaza estos colores a los del tema (p. ej. rojo: Colours.palette.m3primary).
import QtQuick

QtObject {
    // ---- base del tema ----
    property color fondo: "#0c0e12"        // negro del escritorio
    property color capsula: "#0f1117"      // interior de la píldora
    property color capsulaAlta: "#171a23"  // parte alta del interior (degradado)
    property color borde: "#2a2d38"
    property color rojo: "#e0303a"         // rojo Bankai
    property color hueso: "#efe6d8"
    property color hielo: "#a9d4ff"
    property color tenue: "#8a8f9c"
    property color vacio: "#05060a"        // negro de luna / tinta

    // ---- 1) Reiatsu (volumen) ----
    property color brasa: "#7a1119"        // llama del fondo
    property color ceniza: "#1b0508"       // base de la llama
    property color caliente: "#ff8a6a"     // núcleo caliente
    property color getsuga: "#07030a"      // negro del Getsuga Tenshō (tope)

    // ---- 2) Eclipse (brillo) ----
    property color sol: "#fff4da"
    property color cieloAlto: "#1a2540"    // tinte del cielo con brillo alto
    property color corona: rojo

    // ---- 3) Amanecer pixel (luces) ----  de arriba hacia abajo
    property var luzDia: ["#4b3cff", "#2f20ff", "#0000ff", "#0626ff", "#1247ff", "#2a6cff"]
    // de oscuro a "blanco cálido tenue" (el resplandor de la lámpara)
    property var luzNoche: ["#0d0b0a", "#17120f", "#261e18", "#3d3229", "#685a49", "#a8967c", "#ecdcbe"]
    property color estrella: "#ffe9c4"
    property color estrellaTenue: "#7d6a52"
    property color lunaPixel: "#f2e2c0"
    property color lunaPixelSombra: "#b9a582"
    property color solPixel: "#fff7cf"
    property color solPixelBorde: "#ffe27a"
    property color nube: "#86a8ff"
    property color nubeLuz: "#dbe6ff"
    property color tierraDia: "#06107a"
    property color tierraDiaLuz: "#1a35d0"
    property color tierraNoche: "#080706"
    property color tierraNocheLuz: "#3d3229"
    property color ventana: "#ffdca6"      // la ventanita encendida de noche

    function alfa(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    function mezcla(c1, c2, t) {
        t = Math.max(0, Math.min(1, t))
        return Qt.rgba(c1.r + (c2.r - c1.r) * t, c1.g + (c2.g - c1.g) * t, c1.b + (c2.b - c1.b) * t, c1.a + (c2.a - c1.a) * t)
    }
}
