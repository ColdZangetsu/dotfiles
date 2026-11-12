// B) "Fases de luna"
// Cada escritorio es una luna y su fase dice el estado: llena = activo, creciente fina = ocupado,
// nueva (solo el contorno) = vacío. Nada se desliza: la luz se pasa de una luna a otra, el terminador
// barre el disco y el kanji se invierte (hueso → tinta) exactamente por donde va pasando la luz.
// La luna llena lleva el aro rojo fino de corona del tema Eclipse (mismo rojo que la variante A).
// El kanji SIEMPRE se lee: donde la creciente lo pisa, se repinta en tinta encima de la luz.
import QtQuick

Base {
    id: b
    property real radio: 14.5
    property real creciente: 0.10       // fracción iluminada de un escritorio ocupado (≈ 2.9 px en su punto más ancho)
    property real corona: 1             // 0 = sin aro rojo en la luna llena, 1 = aro completo
    tamKanji: 19; tamIcono: 18
    property real inclina: -0.44        // misma inclinación que la media luna de la barra de volumen

    // parte iluminada (a la izquierda) con fracción p: 0 = nada, 0.5 = cuarto, 1 = llena
    function fase(ctx, R, p) {
        var k = 2 * p - 1
        ctx.beginPath()
        ctx.arc(0, 0, R, -Math.PI / 2, Math.PI / 2, true)
        for (var j = 1; j <= 16; j++) { var t = Math.PI / 2 - j * Math.PI / 16; ctx.lineTo(k * R * Math.cos(t), R * Math.sin(t)) }
        ctx.closePath()
    }

    pintor: function (ctx) {
        var P = paleta, n = modelo.length, T = 2 * Math.PI, R = radio
        for (var i = 0; i < n; i++) {
            var fr = foco[i], f = sua(0, 1, fr), o = ocup[i], aj = modelo[i].ajeno ? 0.4 : 1
            var p = (creciente * o + (1 - creciente * o) * f)
            var y = cy(i), esc = 1 + 0.07 * Math.sin(Math.PI * fr)       // se hincha un instante al cambiar de fase

            // halo frío de la luna llena
            if (f > 0.02) {
                var h = ctx.createRadialGradient(cx, y, R - 1, cx, y, R + 6.5)
                h.addColorStop(0, P.alfa(P.hielo, 0.30 * f * f)); h.addColorStop(1, P.alfa(P.hielo, 0))
                ctx.fillStyle = h; ctx.beginPath(); ctx.arc(cx, y, R + 6.5, 0, T); ctx.fill()
            }
            // corona roja de la luna llena: aro fino, un pelo más grueso abajo a la izquierda (como el eclipse de A)
            if (f > 0.02 && corona > 0) {
                ctx.fillStyle = P.alfa(P.rojo, f * corona)
                ctx.beginPath(); ctx.arc(cx - 0.4, y + 0.4, R + 0.8, 0, T); ctx.fill()
                ctx.strokeStyle = P.alfa(P.rojoVivo, 0.9 * f * corona); ctx.lineWidth = 0.9
                ctx.beginPath(); ctx.arc(cx, y, R + 0.45, 0, T); ctx.stroke()
            }
            // disco sin luz: luna nueva = apenas el contorno
            ctx.fillStyle = P.alfa(P.vacio, 0.55 + 0.45 * Math.max(o, f))
            ctx.beginPath(); ctx.arc(cx, y, R, 0, T); ctx.fill()
            ctx.strokeStyle = P.alfa(P.hueso, (0.13 + 0.09 * o) * aj); ctx.lineWidth = 1
            ctx.beginPath(); ctx.arc(cx, y, R - 0.5, 0, T); ctx.stroke()

            // kanji sobre la sombra
            etiqueta(ctx, i, tono(i, 0, o))
            ventanas(ctx, i, tonoVentanas(i, f))

            if (p < 0.004) continue
            // luz + kanji en tinta, recortado a la parte iluminada
            ctx.save()
            ctx.translate(cx, y); ctx.rotate(inclina); ctx.scale(esc, esc)
            fase(ctx, R, p)
            var lg = ctx.createLinearGradient(-R, -R, R * 0.6, R)
            lg.addColorStop(0, P.alfa(P.huesoAlto, aj)); lg.addColorStop(1, P.alfa(P.hueso, aj))
            ctx.fillStyle = lg; ctx.fill()
            // siempre, también en reposo: el trozo de kanji que cae sobre la luz va en tinta (si no, la creciente lo tapa)
            ctx.clip()
            ctx.scale(1 / esc, 1 / esc); ctx.rotate(-inclina); ctx.translate(-cx, -y)
            etiqueta(ctx, i, P.alfa(P.vacio, aj))
            ctx.restore()
        }
    }
}
