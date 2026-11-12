// A) "Eclipse deslizante"
// El activo es un eclipse: disco negro con corona roja fina. Se desliza con muelle de una celda a otra,
// se estira con la velocidad y deja la corona más gruesa por detrás. Al llegar, un "anillo de diamante"
// parpadea en el borde de avance. Ocupado = kanji hueso + mini media luna de Zangetsu (el eclipse se la traga
// al posarse encima). Vacío = kanji apagado.
import QtQuick

Base {
    id: b
    property real radio: 15

    pintor: function (ctx) {
        var P = paleta, n = modelo.length, i, T = 2 * Math.PI
        var s = estira, as = Math.abs(s), R = radio

        if (activo >= 0 && activo < n) {
            var dir = cy(activo) >= posDesde ? 1 : -1
            ctx.save()
            ctx.translate(cx, pos)
            // resplandor: se queda un poco atrás, como estela
            var gy = -s * 8, gr = R + 6.5 + 5 * as
            var g = ctx.createRadialGradient(0, gy, R * 0.7, 0, gy, gr)
            g.addColorStop(0, P.alfa(P.rojo, 0.36)); g.addColorStop(1, P.alfa(P.rojo, 0))
            ctx.fillStyle = g; ctx.beginPath(); ctx.arc(0, gy, gr, 0, T); ctx.fill()
            ctx.scale(1 - 0.10 * as, 1 + 0.22 * as)
            // corona: más gruesa abajo a la izquierda en reposo, y hacia atrás al moverse
            ctx.fillStyle = P.rojo
            ctx.beginPath(); ctx.arc(-0.65 * (1 - as), 0.65 * (1 - as) - s * 2.6, R + 0.85, 0, T); ctx.fill()
            ctx.strokeStyle = P.rojoVivo; ctx.lineWidth = 1.1
            ctx.beginPath(); ctx.arc(0, 0, R + 0.35, 0, T); ctx.stroke()
            // la luna
            ctx.fillStyle = P.vacio
            ctx.beginPath(); ctx.arc(0, 0, R, 0, T); ctx.fill()
            // anillo de diamante al llegar
            var d = campana(0.11, 0.21, durEfecto, u)
            if (d > 0.01) {
                var ax = R * 0.62, ay = dir * R * 0.80
                var gd = ctx.createRadialGradient(ax, ay, 0, ax, ay, 5.5)
                gd.addColorStop(0, P.alfa(P.huesoAlto, 0.95 * d)); gd.addColorStop(0.3, P.alfa(P.rojoVivo, 0.55 * d)); gd.addColorStop(1, P.alfa(P.rojoVivo, 0))
                ctx.fillStyle = gd; ctx.beginPath(); ctx.arc(ax, ay, 5.5, 0, T); ctx.fill()
            }
            ctx.restore()
        }

        for (i = 0; i < n; i++) {
            var f = sua(0, 1, foco[i]), o = ocup[i]
            etiqueta(ctx, i, tono(i, f, o))
            ventanas(ctx, i, tonoVentanas(i, f))
            // mini media luna de Zangetsu: "aquí hay algo"
            var a = o * (1 - f) * (modelo[i].ajeno ? 0.4 : 1)
            if (a > 0.01) {
                ctx.save()
                ctx.translate(cx + 13.4, cy(i) - 10.6); ctx.rotate(-0.44); ctx.scale(0.55 + 0.45 * a, 0.55 + 0.45 * a)
                luna(ctx, 3.9, 1.9, 3.3)
                ctx.fillStyle = P.alfa(P.hueso, 0.9 * a); ctx.fill()
                ctx.restore()
            }
        }
    }
}
