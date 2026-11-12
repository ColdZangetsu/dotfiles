// C) "Tajo"
// El lenguaje aquí es el filo. A la izquierda corre un riel (la funda): el activo es una hoja roja curva
// que se desliza por él con muelle y se alarga con la velocidad. Al cambiar deja una cicatriz fina en el riel
// y, al llegar, un Getsuga negro de filo rojo cruza la celda y "corta" el kanji: las dos mitades se
// desfasan un par de pixeles y vuelven a unirse. Ocupado = una muesca en el riel. Vacío = nada.
import QtQuick

Base {
    id: b
    property real riel: 7               // x del riel
    property real hoja: 22              // largo de la hoja en reposo
    property real corre: 2.5            // las etiquetas se recorren para dejarle sitio al riel
    property real angulo: -0.74         // dirección del tajo (rad)

    pintor: function (ctx) {
        var P = paleta, n = modelo.length, i
        var s = estira, as = Math.abs(s), x = riel
        var hay = activo >= 0 && activo < n
        var corte = hay ? campana(0.06, 0.15, durEfecto, u) : 0

        if (hay) {
            // la celda activa apenas se tiñe desde el filo
            var ya = cy(activo), fa = sua(0, 1, foco[activo])
            var w = ctx.createLinearGradient(0, 0, ancho * 0.62, 0)
            w.addColorStop(0, P.alfa(P.rojo, 0.22 * fa)); w.addColorStop(1, P.alfa(P.rojo, 0))
            ctx.fillStyle = w
            pildora(ctx, 3, ya - celda / 2 + 1, ancho - 6, celda - 2); ctx.fill()
            // cicatriz en el riel, de donde salió a donde va
            var ci = 1 - sua(0.08, durEfecto, u)
            if (ci > 0.01 && desde >= 0) {
                ctx.strokeStyle = P.alfa(P.rojoVivo, 0.6 * ci); ctx.lineWidth = 1; ctx.lineCap = "round"
                ctx.beginPath(); ctx.moveTo(x - 1.4, posDesde); ctx.lineTo(x - 1.4, pos); ctx.stroke()
            }
        }

        for (i = 0; i < n; i++) {
            var f = sua(0, 1, foco[i]), o = ocup[i], col = tono(i, f, o)
            // muesca de "ocupado"
            var a = o * (1 - f) * (modelo[i].ajeno ? 0.4 : 1)
            if (a > 0.01) {
                ctx.strokeStyle = P.alfa(P.hueso, 0.8 * a); ctx.lineWidth = 1.5; ctx.lineCap = "round"
                ctx.beginPath(); ctx.moveTo(x - 2.6, cy(i) + 3.2); ctx.lineTo(x + 0.2, cy(i) - 3.2); ctx.stroke()
            }
            ventanas(ctx, i, tonoVentanas(i, f))
            if (i === activo && corte > 0.01) {
                // Getsuga: lente negra de filo rojo que cruza la celda
                var L = 11 + 8 * sua(0.05, 0.2, u), dxy = 2.0 * corte
                var ca = Math.cos(angulo), sa = Math.sin(angulo)
                ctx.save()
                ctx.translate(cx + corre, cy(i)); ctx.rotate(angulo)
                ctx.beginPath(); ctx.moveTo(-L, 0); ctx.quadraticCurveTo(0, -5.5, L, 0); ctx.quadraticCurveTo(0, -1.2, -L, 0); ctx.closePath()
                ctx.fillStyle = P.alfa(P.vacio, corte); ctx.fill()
                ctx.strokeStyle = P.alfa(P.rojoVivo, corte); ctx.lineWidth = 1; ctx.lineJoin = "round"; ctx.stroke()
                ctx.restore()
                // el kanji, partido en dos por el tajo
                for (var m = 0; m < 2; m++) {
                    var sg = m === 0 ? 1 : -1
                    ctx.save()
                    ctx.translate(cx + corre, cy(i)); ctx.rotate(angulo)
                    ctx.beginPath(); ctx.rect(-60, m === 0 ? -60 : 0, 120, 60); ctx.clip()
                    ctx.rotate(-angulo); ctx.translate(-cx - corre, -cy(i))
                    etiqueta(ctx, i, col, corre + sg * dxy * ca, sg * dxy * sa)
                    ctx.restore()
                }
            } else etiqueta(ctx, i, col, corre, 0)
        }

        if (hay) {
            // la hoja: curva como una katana, se alarga con la velocidad
            var H = hoja * (1 + 0.6 * as) / 2, y = pos - s * 3
            ctx.beginPath()
            ctx.moveTo(x, y - H); ctx.quadraticCurveTo(x - 6.4, y + 2, x, y + H); ctx.quadraticCurveTo(x - 1.2, y + 1, x, y - H)
            ctx.closePath()
            var g = ctx.createLinearGradient(0, y - H, 0, y + H)
            g.addColorStop(0, P.rojo); g.addColorStop(0.5, P.rojoVivo); g.addColorStop(1, P.rojo)
            ctx.fillStyle = g; ctx.fill()
            // contrafilo: un hilo de hueso
            ctx.strokeStyle = P.alfa(P.huesoAlto, 0.38); ctx.lineWidth = 0.6
            ctx.beginPath(); ctx.moveTo(x, y - H + 2); ctx.quadraticCurveTo(x - 1.0, y, x, y + H - 2); ctx.stroke()
        }
    }
}
