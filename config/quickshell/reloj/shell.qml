// Reloj del XENEON (DP-3) — BORRADOR tema Eclipse (2026-11-10). Mismo comportamiento que ~/.config/quickshell/reloj:
// lo que está sonando a la izquierda, hora + fecha al centro, notificaciones de Caelestia a la derecha.
// Capa "bottom": encima del fondo animado y debajo de las ventanas. No atrapa clics ni toques.
// El dibujo vive en Cara.qml. Ajustes rápidos aquí abajo (velo, luna, tema).
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import QtQuick

ShellRoot {
    id: root
    readonly property string monitor: "DP-3"
    readonly property string home: Quickshell.env("HOME")

    // ---- ajustes ----
    readonly property bool temaEclipse: Quickshell.env("RELOJ_TEMA") !== "caelestia"   // "caelestia" = colores del fondo, como el reloj anterior
    readonly property real velo: 0.0      // oscurecer el fondo animado (0 = nada, 1 = negro puro)
    readonly property real luna: 0.0      // opacidad de la luna detrás de la hora
    readonly property bool animar: Quickshell.env("RELOJ_SIN_ANIM") !== "1"

    readonly property var eclipse: ({ fg: "#fff1f3", tenue: "#94ffe1e6", rojo: "#ff2448", rojo2: "#ff7a8e", vidrio: "#9e140408", borde: "#38ff7a8e", luna: "#050203" })

    // Colores de Caelestia para este monitor (solo se usan con RELOJ_TEMA=caelestia)
    property var cae: null
    FileView {
        path: root.home + "/.local/state/caelestia/schemes/" + root.monitor + ".json"
        watchChanges: root.temaEclipse === false
        onFileChanged: reload()
        onLoaded: {
            if (root.temaEclipse) return;
            try {
                const d = JSON.parse(text());
                const c = d.colours ?? d;
                const h = k => "#" + String(c[k] ?? "").replace("#", "");
                root.cae = { fg: h("onSurface"), tenue: Qt.alpha(h("secondary"), 0.8), rojo: h("primary"), rojo2: h("tertiary"),
                             vidrio: Qt.alpha(h("surface"), 0.72), borde: Qt.alpha(h("primary"), 0.35), luna: h("surface") };
            } catch (e) {}
        }
    }

    // Notificaciones que guarda Caelestia (la más nueva primero); al descartarlas desaparecen
    property var notifs: []
    FileView {
        path: root.home + "/.local/state/caelestia/notifs.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try { root.notifs = JSON.parse(text()).slice(0, 3); } catch (e) {}
        }
    }

    SystemClock { id: reloj; precision: SystemClock.Seconds }

    // Lo que está sonando (MPRIS: Cider, navegador, etc.); solo si alguno está en play
    readonly property var sonando: {
        const ps = Mpris.players.values;
        for (let i = 0; i < ps.length; i++)
            if (ps[i].isPlaying) return ps[i];
        return null;
    }
    Timer {   // la posición de MPRIS no avisa sola; se refresca para la barrita
        running: root.sonando !== null
        interval: 1000; repeat: true
        onTriggered: if (root.sonando) root.sonando.positionChanged()
    }

    Variants {
        model: Quickshell.screens.filter(s => s.name === root.monitor)

        PanelWindow {
            required property var modelData
            screen: modelData
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "reloj-xeneon"
            exclusionMode: ExclusionMode.Normal
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            mask: Region {}

            Cara {
                anchors.fill: parent
                fecha: reloj.date
                notifs: root.notifs
                sonando: root.sonando !== null
                pistaTitulo: root.sonando?.trackTitle ?? ""
                pistaArtista: root.sonando?.trackArtist ?? ""
                pistaArte: root.sonando?.trackArtUrl ?? ""
                pistaProgreso: root.sonando && root.sonando.length > 0 ? root.sonando.position / root.sonando.length : 0
                icono: n => Quickshell.iconPath(n, "dialog-information")
                col: root.temaEclipse || !root.cae ? root.eclipse : root.cae
                velo: root.velo
                luna: root.luna
                animar: root.animar
            }
        }
    }
}
