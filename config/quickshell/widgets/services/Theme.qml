pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Colores tomados del esquema actual de Caelestia; se actualizan solos al cambiar de fondo.
Singleton {
    id: root

    property var colours: ({})

    readonly property real scale: 1.3
    readonly property string font: "Rubik"
    readonly property string iconFont: "Material Symbols Rounded"
    readonly property real radius: 22 * scale

    readonly property color card: withAlpha(get("primaryContainer", "76453b"), 0.9)
    readonly property color cardText: "#" + get("onPrimaryContainer", "ffdbd4")
    readonly property color cardTextDim: withAlpha(get("onPrimaryContainer", "ffdbd4"), 0.7)
    readonly property color inner: withAlpha(get("onPrimaryContainer", "ffdbd4"), 0.1)
    readonly property color chip: "#" + get("primaryFixed", "fcb9ab")
    readonly property color chipText: "#" + get("onPrimaryFixed", "4b221a")
    readonly property color accent: "#" + get("primary", "f9b7a8")
    readonly property color accentText: "#" + get("onPrimary", "61342a")
    readonly property color highlight: withAlpha(get("tertiaryContainer", "fdd494"), 0.92)
    readonly property color highlightText: "#" + get("onTertiaryContainer", "644815")

    function get(key, fallback) {
        return colours[key] ?? fallback;
    }

    function withAlpha(hex, alpha) {
        const a = Math.round(alpha * 255).toString(16).padStart(2, "0");
        return "#" + a + hex;
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
