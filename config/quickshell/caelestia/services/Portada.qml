pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// 11-15 Tsuka + Saya: `portada` (COMUN.md §2.1) = color dominante de la carátula del reproductor activo,
// calculado UNA vez por canción (ColorQuantizer en su hilo) y normalizado con la regla del color.
// Sin canción cargada no existe (hay = false).
Singleton {
    id: root

    readonly property MprisPlayer jugador: Players.active
    readonly property string arte: Players.getArtUrl(jugador)
    readonly property bool hay: !!jugador && !!(jugador.trackTitle || "")
    readonly property bool suena: hay && jugador.isPlaying
    readonly property string titulo: jugador?.trackTitle ?? ""
    readonly property string artista: jugador?.trackArtist ?? ""
    // cambia una vez por canción
    readonly property string clave: jugador ? `${jugador.trackTitle}|${jugador.trackArtist}|${jugador.trackAlbum}` : ""

    property color color: Espada.hueso

    function elegir(lista: var): void {
        let mejor = null, puntos = -1;
        for (const c of lista) {
            if (c.hslLightness < 0.12)
                continue;
            const p = c.hslSaturation * (1 - Math.abs(c.hslLightness - 0.55));
            if (p > puntos) {
                puntos = p;
                mejor = c;
            }
        }
        if (mejor)
            color = Espada.prestado(mejor);
    }

    ColorQuantizer {
        id: cuantizador
        source: root.arte
        depth: 3
        rescaleSize: 48
        onColorsChanged: root.elegir(colors)
    }
}
