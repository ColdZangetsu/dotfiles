pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// 11-15 Tsuka + Saya (diseño final de Fable, COMUN.md): lo común del par.
// Paleta (§2), regla del color (§2.1), movimiento (§4), íconos propios (§3.1) y "solo habla una" (§7).
// Un solo archivo para las dos barras (antes modules/tsuka/Tinta.qml).
Singleton {
    id: root

    // ── paleta ──
    readonly property color tinta: "#0c0e12"
    readonly property color capa: "#14171d"
    readonly property color capaAlta: "#1c2028"
    readonly property color trazo: "#2a2d38"
    readonly property color apagado: "#555a66"
    readonly property color tenue: "#8a8f9c"
    readonly property color hueso: "#efe6d8"
    readonly property color huesoAlto: "#fffaf0"
    readonly property color rojo: "#e0303a"
    readonly property color ambar: "#ffcf93"
    readonly property color vacio: "#05060a"

    // ── movimiento (con "movimiento": false en tsuka.json todo dura 0) ──
    readonly property bool mov: TsukaConf.movimiento
    readonly property int dColor: mov ? 160 : 0
    readonly property int dToque: mov ? 110 : 0
    readonly property int dFilo: mov ? 200 : 0
    readonly property int dAbre: mov ? 220 : 0
    readonly property int dCierra: mov ? 160 : 0
    readonly property int dRetira: mov ? 200 : 0
    readonly property int dLuz: mov ? 260 : 0
    readonly property int dOjo: mov ? 200 : 0
    readonly property var cEntra: [0.22, 1, 0.36, 1, 1, 1]
    readonly property var cSale: [0.4, 0, 1, 1, 1, 1]
    readonly property var cFilo: [0.3, 1.25, 0.4, 1, 1, 1]
    readonly property var cBrillo: [0.4, 0, 0.6, 1, 1, 1]
    readonly property int esperaAbrir: 140
    readonly property int esperaZona: 60
    readonly property int esperaCerrar: 240

    // ── color ──
    // p de a sobre b
    function mezcla(a: color, b: color, p: real): color {
        return Qt.rgba(a.r * p + b.r * (1 - p), a.g * p + b.g * (1 - p), a.b * p + b.b * (1 - p), 1);
    }
    // Regla del color: todo color prestado (portada, luces) se normaliza; la franja del rojo se dibuja en hueso
    function prestado(c: color): color {
        if (!c || c.a === 0)
            return ambar;
        const h = c.hslHue * 360;
        if (c.hslSaturation > 0.12 && (h >= 345 || h <= 15))
            return hueso;
        const l = Math.max(0.62, Math.min(0.8, c.hslLightness));
        const s = Math.min(0.7, c.hslSaturation);
        return Qt.hsla(c.hslHue < 0 ? 0 : c.hslHue, s, l, 1);
    }
    // El eco de cada monitor sale de la paleta que genera wallmux para ESE monitor
    // (~/.local/state/caelestia/schemes/<monitor>.json vía Colours.of(ventana), se vigila en vivo).
    // Regla del color: si cae en la franja del rojo (345°-15°), se dibuja en hueso.
    function ecoSeguro(c: color): color {
        if (!c || c.a === 0)
            return hueso;
        const h = c.hslHue * 360;
        if (c.hslSaturation > 0.12 && (h >= 345 || h <= 15))
            return hueso;
        return c;
    }
    function hex(c: color): string {
        const h = n => {
            const s = Math.round(Math.max(0, Math.min(1, n)) * 255).toString(16);
            return s.length < 2 ? "0" + s : s;
        };
        return "#" + h(c.r) + h(c.g) + h(c.b);
    }

    // ── íconos propios (rejilla 16, trazo 1.4, remates rectos): COMUN.md §3.1 ──
    readonly property var ico: ({
            terminal: "M2 3h12v10H2z M5 6.5l2 1.5-2 1.5 M9 10h2.5",
            musica: "M6 11.5V4l7-1.5v7.5 M6 11.5a2 2 0 1 1-4 0a2 2 0 0 1 4 0z M13 10a2 2 0 1 1-4 0a2 2 0 0 1 4 0z",
            chat: "M2 3h12v8H8l-3 3v-3H2z",
            juego: "M3.5 5h9l2 6.5h-3L10 9.5H6l-1.5 2h-3z M5.5 6.5v2 M4.5 7.5h2 M10.6 7.5h.1",
            archivos: "M2 4h4.5L8 6h6v7H2z",
            video: "M2 3h12v10H2z M6.5 6l4 2-4 2z",
            codigo: "M6 4L2 8l4 4 M10 4l4 4-4 4",
            ventana: "M2 3h12v10H2z M2 6h12",
            red: "M2 6.5a9 9 0 0 1 12 0 M4.3 9a6 6 0 0 1 7.4 0 M8 12h.1",
            bt: "M5 5l6 6-3 3V2l3 3-6 6",
            bandeja: "M2 9l2-5h8l2 5v4H2z M2 9h4l1 1.5h2L10 9h4",
            graba: "M8 3a5 5 0 1 0 0 10a5 5 0 0 0 0-10z M8 7.4a.6.6 0 1 0 0 1.2a.6.6 0 0 0 0-1.2z",
            candado: "M4 7h8v6H4z M5.5 7V5a2.5 2.5 0 0 1 5 0v2",
            puerta: "M4 2h8v12H4z M9.8 8h.1",
            luna: "M12 9.5A5 5 0 1 1 6.5 4a4 4 0 0 0 5.5 5.5z",
            apagar: "M8 2v6 M4.6 4.6a5 5 0 1 0 6.8 0",
            aviso: "M4 11V7a4 4 0 0 1 8 0v4l1.5 1.5h-11z M7 14h2",
            escudo: "M8 2l5 2v4c0 3-2 5-5 6c-3-1-5-3-5-6V4z",
            luz: "M8 2v2 M3 8H1 M15 8h-2 M4 4L3 3 M12 4l1-1 M5 8a3 3 0 1 1 6 0c0 1.5-1 2-1 3.5H6C6 10 5 9.5 5 8z M6.5 14h3",
            sigue: "M5 3l8 5-8 5z",
            pausa: "M5 3v10 M11 3v10",
            trabajo: "M2 5h12v8H2z M6 5V3h4v2 M2 9h12",
            casa: "M2 8L8 2.5L14 8 M3.5 6.8V13.5h9V6.8 M6.8 13.5v-3.5h2.4v3.5",
            cine: "M2 5h9v7H2z M11 7.5l3-2v6l-3-2 M4.5 3h4",
            servidor: "M3 3h10v4H3z M3 9h10v4H3z M5.5 5h.1 M5.5 11h.1",
            pantalla: "M2 3h12v8H2z M6 13.5h4 M8 11v2.5",
            arena: "M4 2h8 M4 14h8 M5 2c0 4 6 4 6 12 M11 2c0 4-6 4-6 12",
            respaldo: "M8 2v8 M5 7l3 3 3-3 M3 13.5h10",
            temp: "M8 2v7.5 M8 9.5a2.2 2.2 0 1 0 0 4.4a2.2 2.2 0 0 0 0-4.4z M11 3h2 M11 6h2"
        })

    // App -> ícono, por clase de ventana (una sola tabla). Lo que no esté aquí usa "ventana".
    function icoApp(cls: string): string {
        const c = (cls || "").toLowerCase();
        if (!c)
            return "ventana";
        if (/kitty|alacritty|foot|wezterm|konsole|terminal/.test(c))
            return "terminal";
        if (/cider|spotify|music|tidal|rhythmbox|elisa/.test(c))
            return "musica";
        if (/discord|equibop|vesktop|equicord|telegram|whatsapp|signal|element/.test(c))
            return "chat";
        if (/steam|lutris|heroic|minecraft|battle\.net|gamescope|\.exe$|hookshot|prism/.test(c))
            return "juego";
        if (/nautilus|thunar|dolphin|nemo|files|pcmanfm/.test(c))
            return "archivos";
        if (/jellyfin|mpv|vlc|celluloid|crunchyroll|youtube|stremio/.test(c))
            return "video";
        if (/code|codium|zed|neovide|kate|gedit|sublime|jetbrains/.test(c))
            return "codigo";
        return "ventana";
    }

    // Nombre corto de la app (para placas y menuki)
    function nombreApp(t: var): string {
        const cls = t?.lastIpcObject?.class ?? "";
        if (!cls)
            return "";
        const d = DesktopEntries.heuristicLookup(cls);
        let n = d?.name || cls;
        if (/^code-oss$/i.test(cls))
            n = "VS Code";
        return n;
    }

    // ── "solo habla una" (§7): lenguas y OSD salen solo en el monitor con foco de teclado; si está en
    // pantalla completa, en el primero visible de ASUS, LG, XENEON, STREAM. Para el OSD sí cuenta el foco aunque
    // tenga pantalla completa.
    readonly property var ordenMonitores: ["DP-2", "DP-1", "DP-3", "STREAM"]
    function enPantallaCompleta(mon: var): bool {
        if (!mon)
            return false;
        const esp = mon.lastIpcObject?.specialWorkspace?.name ?? "";
        if (esp.length > 0) {
            const ws = Hyprland.workspaces.values.find(w => w.name === esp);
            return ws?.toplevels.values.some(t => (t.lastIpcObject?.fullscreen ?? 0) > 1) ?? false;
        }
        return mon.activeWorkspace?.toplevels.values.some(t => (t.lastIpcObject?.fullscreen ?? 0) > 1) ?? false;
    }
    function monitorQueHabla(): string {
        const f = Hyprland.focusedMonitor;
        if (f && !enPantallaCompleta(f))
            return f.name;
        for (const n of ordenMonitores) {
            const m = Hyprland.monitors.values.find(x => x.name === n);
            if (m && !enPantallaCompleta(m) && (m.lastIpcObject?.dpmsStatus ?? true))
                return n;
        }
        return "";
    }
}
