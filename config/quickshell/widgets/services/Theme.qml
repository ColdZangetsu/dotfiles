pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Dos temas, mismo diseño. Se elige en el archivo "tema" de la carpeta (cambia en vivo):
//   eclipse   -> vidrio negro, texto hueso, rojo #ff2448 mínimo (familia nerozangetsu)
//   caelestia -> colores del esquema de Caelestia (siguen al fondo), como los widgets de antes
Singleton {
    id: root

    property var colours: ({})
    property string tema: "eclipse"
    readonly property bool eclipse: tema !== "caelestia"

    readonly property real scale: 1.3
    readonly property string font: inter.status === FontLoader.Ready ? "Inter" : "Rubik"
    readonly property string titleFont: anton.status === FontLoader.Ready ? anton.name : "Rubik"
    readonly property string kanjiFont: "Noto Serif CJK JP"
    readonly property string iconFont: "Material Symbols Rounded"
    readonly property real radius: (eclipse ? 14 : 22) * scale

    readonly property color card: eclipse ? "#a808080a" : withAlpha(get("primaryContainer", "76453b"), 0.9)
    readonly property color border: eclipse ? "#1cffffff" : "transparent"
    readonly property color cardText: eclipse ? "#f4f1ec" : "#" + get("onPrimaryContainer", "ffdbd4")
    readonly property color cardTextDim: eclipse ? "#a6f4f1ec" : withAlpha(get("onPrimaryContainer", "ffdbd4"), 0.7)
    readonly property color line: eclipse ? "#1fffffff" : withAlpha(get("onPrimaryContainer", "ffdbd4"), 0.16)
    readonly property color inner: eclipse ? "#12ffffff" : withAlpha(get("onPrimaryContainer", "ffdbd4"), 0.1)
    readonly property color accent: eclipse ? "#ff2448" : "#" + get("primary", "f9b7a8")
    // Día de hoy en el calendario
    readonly property color today: eclipse ? "#ff2448" : "#" + get("primaryFixed", "fcb9ab")
    readonly property color todayText: eclipse ? "#ffffff" : "#" + get("onPrimaryFixed", "4b221a")
    // Círculo del icono del clima
    readonly property color chip: eclipse ? "#16ffffff" : "#" + get("primaryFixed", "fcb9ab")
    readonly property color chipText: eclipse ? "#f4f1ec" : "#" + get("onPrimaryFixed", "4b221a")
    readonly property color highlight: eclipse ? "#b8140507" : withAlpha(get("tertiaryContainer", "fdd494"), 0.92)
    readonly property color highlightText: eclipse ? "#f4f1ec" : "#" + get("onTertiaryContainer", "644815")

    function get(key, fallback) {
        return colours[key] ?? fallback;
    }

    function withAlpha(hex, alpha) {
        const a = Math.round(alpha * 255).toString(16).padStart(2, "0");
        return "#" + a + hex;
    }

    FontLoader { id: anton; source: Qt.resolvedUrl("../fuentes/Anton-Regular.ttf") }
    FontLoader { source: Qt.resolvedUrl("../fuentes/Inter-Regular.ttf") }
    FontLoader { source: Qt.resolvedUrl("../fuentes/Inter-Medium.ttf") }
    FontLoader { id: inter; source: Qt.resolvedUrl("../fuentes/Inter-SemiBold.ttf") }

    FileView {
        path: Qt.resolvedUrl("../tema")
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.tema = text().trim() === "caelestia" ? "caelestia" : "eclipse"
    }

    FileView {
        path: Quickshell.env("HOME") + "/.local/state/caelestia/scheme.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.colours = JSON.parse(text()).colours ?? {};
            } catch (e) {}
        }
    }
}
