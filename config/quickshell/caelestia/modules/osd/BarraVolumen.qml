// 1) VOLUMEN — "Reiatsu"
// Llama espiritual que sube por la funda; la perilla es la media luna de Zangetsu (斬月).
//   · 0 %     = luna nueva (hueca), sin llama.
//   · 40 %    = nivel seguro: marca fija + imán al arrastrar + doble clic vuelve aquí.
//   · > 40 %  = la llama se agita y se calienta.
//   · tope    = Bankai: la llama se vuelve Getsuga Tenshō (negra con filo rojo) y la luna, Tensa Zangetsu.
// Uso:  BarraVolumen { value: Audio.volume; onMovida: v => Audio.setVolume(v) }
import QtQuick

Item {
    id: bar
    property real value: 0.4
    property real seguro: 0.4
    property bool reducirMovimiento: false
    property bool despierto: false          // ponlo en true mientras el OSD esté a la vista si quieres la llama viva
    property bool etiqueta: true
    property Paleta paleta: Paleta {}
    property string fuenteKanji: "Noto Serif CJK JP"
    property alias nucleo: n
    property real energiaFija: -1           // solo para capturas
    property real tiempoFijo: 1.7
    signal movida(real v)

    width: 72; height: 320
    implicitWidth: 72; implicitHeight: 320

    property real corte: 0                  // 1 → 0: el tajo del Getsuga al tocar el 100 %

    function sua(a, b, x) { var u = Math.max(0, Math.min(1, (x - a) / (b - a))); return u * u * (3 - 2 * u) }
    function pildora(ctx, x, y, w, h) {
        var r = w / 2
        ctx.beginPath()
        ctx.arc(x + r, y + r, r, Math.PI, 2 * Math.PI, false)
        ctx.lineTo(x + w, y + h - r)
        ctx.arc(x + r, y + h - r, r, 0, Math.PI, false)
        ctx.closePath()
    }
    // media luna: círculo R menos círculo r2 desplazado d a la derecha (contorno exacto, se puede trazar)
    function luna(ctx, R, d, r2) {
        var xi = (R * R - r2 * r2 + d * d) / (2 * d), yi = Math.sqrt(Math.max(0, R * R - xi * xi))
        var a1 = Math.atan2(yi, xi), a2 = Math.atan2(yi, xi - d)
        ctx.beginPath()
        ctx.arc(0, 0, R, a1, 2 * Math.PI - a1, false)
        ctx.arc(d, 0, r2, 2 * Math.PI - a2, a2, true)
        ctx.closePath()
    }

    Item {
        id: cuerpo
        width: bar.width; height: bar.height
        y: n.empuje

        Rectangle {
            anchors.fill: parent; radius: width / 2
            gradient: Gradient {
                GradientStop { position: 0; color: bar.paleta.capsulaAlta }
                GradientStop { position: 1; color: bar.paleta.capsula }
            }
        }

        Canvas {
            id: llama
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d"), P = bar.paleta, w = width, h = height, cx = w / 2
                ctx.reset()
                var v = Math.max(0, Math.min(1, n.pos)), e = n.energia, t = n.t
                var yk = n.yPerilla
                var nace = Math.min(1, v / 0.07)
                var ys = yk + (1 - nace) * (n.margen + 16)            // la llama se hunde al llegar a 0
                var calor = bar.sua(bar.seguro, 0.92, v), b = bar.sua(0.86, 1.0, v)

                ctx.save()
                bar.pildora(ctx, 1, 1, w - 2, h - 2); ctx.clip()

                // escala fina cada 10 %
                ctx.fillStyle = P.alfa(P.hueso, 0.09)
                for (var m = 1; m < 10; m++) {
                    var ym = Math.round(n.yDe(m / 10)) - 0.5
                    ctx.fillRect(w - 9, ym, 3, 1); ctx.fillRect(6, ym, 3, 1)
                }

                // kanji grabado, casi invisible sin llama
                ctx.font = '200 22px "' + bar.fuenteKanji + '"'
                ctx.textAlign = "center"; ctx.textBaseline = "middle"
                ctx.fillStyle = P.alfa(P.hueso, 0.075)
                ctx.fillText("斬", cx, h - 92); ctx.fillText("月", cx, h - 64)

                if (v > 0.001) {
                    var A = (8 + 10 * v + 8 * calor) * (0.45 + 0.55 * e) * nace
                    A *= 1 + Math.max(0, -n.estira) * 1.5 - Math.max(0, n.estira) * 0.45   // al bajar deja lenguas largas
                    var rap = 1 + 0.9 * calor

                    // resplandor sobre la superficie
                    var res = ctx.createRadialGradient(cx, ys, 4, cx, ys, 70)
                    res.addColorStop(0, P.alfa(P.rojo, (0.10 + 0.16 * v) * (0.45 + 0.55 * e) * nace))
                    res.addColorStop(1, P.alfa(P.rojo, 0))
                    ctx.fillStyle = res; ctx.fillRect(0, ys - 70, w, 140)

                    function capa(k, off, amp, fa, sa, fb, sb, ph) {
                        ctx.beginPath(); ctx.moveTo(-2, h + 2)
                        for (var x = -2; x <= w + 2; x += 1.5) {
                            var env = 0.62 + 0.38 * Math.sin(Math.PI * Math.max(0, Math.min(1, x / w)))
                            var f = 0.74 * (1 - Math.abs(Math.sin(x * fa + t * sa * rap + ph)))
                                  + 0.26 * (1 - Math.abs(Math.sin(x * fb - t * sb * rap + ph * 2.3)))
                            f = Math.pow(f, 1.35) + 0.08 * Math.sin(x * 0.45 + t * 6 + k)
                            ctx.lineTo(x, ys + off - amp * env * f)
                        }
                        ctx.lineTo(w + 2, h + 2); ctx.closePath()
                    }
                    // halo: lenguas translúcidas (en Bankai es el filo rojo que asoma detrás del negro)
                    var g0 = ctx.createLinearGradient(0, ys - A * 1.6, 0, ys + 30)
                    g0.addColorStop(0, P.alfa(P.mezcla(P.brasa, P.rojo, 0.3 + 0.7 * b), 0.55 + 0.45 * b))
                    g0.addColorStop(1, P.alfa(P.mezcla(P.brasa, P.rojo, 0.6 + 0.4 * b), 0.95))
                    capa(0, -5 - 4 * b, A * 1.55, 0.097, 2.1, 0.171, 3.4, 0.0); ctx.fillStyle = g0; ctx.fill()
                    // cuerpo: cabeza roja que se apaga hacia abajo; en el tope, negro Getsuga sobre carmesí profundo
                    var g1 = ctx.createLinearGradient(0, ys - A, 0, ys + 130)
                    g1.addColorStop(0, P.mezcla(P.mezcla(P.rojo, P.caliente, 0.18 + 0.2 * calor), P.getsuga, b))
                    g1.addColorStop(0.20, P.mezcla(P.rojo, P.getsuga, b))
                    g1.addColorStop(0.58, P.mezcla(P.mezcla(P.rojo, P.brasa, 0.72), P.mezcla(P.brasa, P.getsuga, 0.72), b))
                    g1.addColorStop(1, P.mezcla(P.mezcla(P.brasa, P.ceniza, 0.62), P.mezcla(P.brasa, P.getsuga, 0.5), b))
                    capa(1, 1, A, 0.118, -2.9, 0.203, 4.3, 1.7); ctx.fillStyle = g1; ctx.fill()
                    ctx.strokeStyle = P.alfa(P.mezcla(P.caliente, P.rojo, b), 0.30 + 0.65 * b); ctx.lineWidth = 1 + 0.7 * b; ctx.stroke()
                    // núcleo caliente (se apaga a negro en el tope)
                    var g2 = ctx.createLinearGradient(0, ys - A * 0.3, 0, ys + 64)
                    var nuc = P.mezcla(P.mezcla(P.caliente, P.hueso, 0.6 * calor), P.getsuga, b)
                    g2.addColorStop(0, P.alfa(nuc, 0.95))
                    g2.addColorStop(0.4, P.alfa(P.mezcla(P.mezcla(P.caliente, P.rojo, 0.6), P.getsuga, b), 0.5))
                    g2.addColorStop(1, P.alfa(P.mezcla(P.rojo, P.getsuga, b), 0))
                    capa(2, 9, A * 0.62, 0.141, 3.7, 0.233, -5.2, 3.1); ctx.fillStyle = g2; ctx.fill()
                    if (b > 0.01) {
                        ctx.strokeStyle = P.alfa(P.hueso, 0.5 * b); ctx.lineWidth = 0.8; ctx.stroke()
                        // Bankai: la funda entera se enciende por dentro
                        bar.pildora(ctx, 1, 1, w - 2, h - 2)
                        ctx.strokeStyle = P.alfa(P.rojo, 0.13 * b); ctx.lineWidth = 16; ctx.stroke()
                        ctx.strokeStyle = P.alfa(P.rojo, 0.55 * b); ctx.lineWidth = 4; ctx.stroke()
                    }

                    // kanji a contraluz dentro de la llama
                    ctx.save()
                    ctx.beginPath(); ctx.rect(0, ys + 8, w, h); ctx.clip()
                    ctx.fillStyle = P.mezcla(P.alfa(P.vacio, 0.42), P.alfa(P.rojo, 0.55), b)
                    ctx.fillText("斬", cx, h - 92); ctx.fillText("月", cx, h - 64)
                    ctx.restore()

                    // pavesas: solo despierto
                    if (e > 0.02 && !bar.reducirMovimiento) {
                        var np = Math.round((5 + 13 * v) * e)
                        for (var i = 0; i < np; i++) {
                            var vida = (t * (0.33 + (i % 5) * 0.09) + i * 0.377) % 1
                            var sx = 9 + ((i * 53 + 17) % 97) / 97 * (w - 18) + Math.sin(t * 2.3 + i * 1.9) * 4 * vida
                            var sy = ys - 2 - vida * (34 + 70 * v)
                            if (sy < 4) continue
                            var tam = (i % 3 === 0) ? 2 : 1.4
                            ctx.fillStyle = P.alfa(P.mezcla(P.caliente, P.hueso, (i % 4) / 4 + 0.5 * b), Math.pow(1 - vida, 1.4) * 0.9 * e)
                            ctx.fillRect(sx, sy, tam, tam)
                        }
                    }
                }

                // marca del nivel seguro
                var yseg = n.yDe(bar.seguro), pu = n.pulsoIman
                var pasado = v > bar.seguro + 0.004
                ctx.strokeStyle = P.mezcla(pasado ? P.alfa(P.mezcla(P.hueso, P.rojo, 0.55), 0.95) : P.alfa(P.hueso, 0.62), Qt.rgba(1, 1, 1, 1), pu)
                ctx.lineWidth = 1.6 + 0.6 * pu; ctx.lineCap = "round"
                var len = 8 + 6 * pu
                ctx.beginPath()
                ctx.moveTo(5, yseg); ctx.lineTo(5 + len, yseg)
                ctx.moveTo(w - 5, yseg); ctx.lineTo(w - 5 - len, yseg)
                ctx.stroke()
                ctx.restore()
            }
        }

        Vidrio { paleta: bar.paleta; realce: Math.max(n.encima ? 1 : 0, n.aprieta); foco: n.focoTeclado }

        // perilla: lienzo chico que solo se desplaza (el aura puede salirse de la píldora)
        Canvas {
            id: perilla
            readonly property int lado: 150
            width: lado; height: lado
            x: bar.width / 2 - lado / 2
            y: n.yPerilla - lado / 2
            onPaint: {
                var ctx = getContext("2d"), P = bar.paleta, c = lado / 2
                ctx.reset()
                var v = Math.max(0, Math.min(1, n.pos)), e = n.energia
                var nace = Math.min(1, v / 0.05), b = bar.sua(0.86, 1.0, v), s = n.estira, ap = n.aprieta

                // aura de reiatsu
                var a0 = (0.18 + 0.34 * v) * (0.5 + 0.5 * e) * nace + 0.16 * ap * nace
                var Ra = 24 + 12 * v + 6 * e + 5 * ap
                var au = ctx.createRadialGradient(c, c, 5, c, c, Ra)
                au.addColorStop(0, P.alfa(P.rojo, a0)); au.addColorStop(0.55, P.alfa(P.rojo, a0 * 0.38)); au.addColorStop(1, P.alfa(P.rojo, 0))
                ctx.fillStyle = au; ctx.beginPath(); ctx.arc(c, c, Ra, 0, 2 * Math.PI); ctx.fill()

                // tajo del Getsuga al llegar al tope
                if (bar.corte > 0.02) {
                    var q = 1 - bar.corte, al = Math.pow(bar.corte, 0.7)
                    ctx.save()
                    ctx.translate(c, c + 24 - q * 40); ctx.rotate(Math.PI / 2)
                    bar.luna(ctx, 28 + 16 * q, 9 - 4 * q, 28 + 15.5 * q)
                    ctx.strokeStyle = P.alfa(P.rojo, 0.30 * al); ctx.lineWidth = 6; ctx.lineJoin = "round"; ctx.stroke()
                    ctx.fillStyle = P.alfa(P.getsuga, al); ctx.fill()
                    ctx.strokeStyle = P.alfa(P.rojo, al); ctx.lineWidth = 1.8; ctx.stroke()
                    ctx.strokeStyle = P.alfa(P.hueso, 0.7 * al); ctx.lineWidth = 0.6; ctx.stroke()
                    ctx.restore()
                }

                // anillo al encajar en el 40 %
                if (n.pulsoIman > 0.02) {
                    ctx.strokeStyle = P.alfa(P.hueso, 0.55 * n.pulsoIman); ctx.lineWidth = 1.2
                    ctx.beginPath(); ctx.arc(c, c, 19 + 12 * (1 - n.pulsoIman), 0, 2 * Math.PI); ctx.stroke()
                }

                // sombra bajo la luna
                var so = ctx.createRadialGradient(c, c + 2, 6, c, c + 2, 22)
                so.addColorStop(0, Qt.rgba(0, 0, 0, 0.50)); so.addColorStop(1, Qt.rgba(0, 0, 0, 0))
                ctx.fillStyle = so; ctx.beginPath(); ctx.arc(c, c + 2, 22, 0, 2 * Math.PI); ctx.fill()

                // media luna: se estira con la velocidad, se inclina, se encoge al presionar
                ctx.save()
                ctx.translate(c, c)
                var as = Math.abs(s), esc = 1 - 0.07 * ap + 0.03 * e
                ctx.scale(esc * (1 - 0.10 * as), esc * (1 + 0.24 * as))
                ctx.rotate(-0.44 + s * 0.55)
                bar.luna(ctx, 15, 6.6, 12.3)
                var lg = ctx.createLinearGradient(-15, -15, 6, 15)
                lg.addColorStop(0, P.mezcla(P.hueso, Qt.rgba(1, 1, 1, 1), 0.35))
                lg.addColorStop(1, P.mezcla(P.hueso, P.brasa, 0.22))
                ctx.globalAlpha = 0.10 + 0.90 * nace
                ctx.fillStyle = b > 0.5 ? P.getsuga : lg
                if (b > 0.01 && b <= 0.5) { ctx.fill(); ctx.globalAlpha = b * 2; ctx.fillStyle = P.getsuga }
                ctx.fill()
                ctx.globalAlpha = 1
                // filo: hueso tenue en mudo, rojo en Bankai
                var filo = P.mezcla(P.alfa(P.hueso, 0.65 * (1 - nace)), P.rojo, b)
                if (nace < 1 || b > 0.01) { ctx.strokeStyle = filo; ctx.lineWidth = 1.2 + 0.5 * b; ctx.lineJoin = "round"; ctx.stroke() }
                // destello en el lomo
                ctx.strokeStyle = Qt.rgba(1, 1, 1, (0.55 - 0.3 * b) * nace); ctx.lineWidth = 1.1; ctx.lineCap = "round"
                ctx.beginPath(); ctx.arc(0, 0, 12.6, Math.PI * 0.86, Math.PI * 1.22, false); ctx.stroke()
                ctx.restore()
            }
        }
    }

    Etiqueta { nucleo: n; paleta: bar.paleta; visible: bar.etiqueta && n.tocando > 0.01; texto: Math.round(n.pos * 100) }

    Nucleo {
        id: n
        value: bar.value
        imanes: [bar.seguro]
        preferido: bar.seguro
        margen: 26; radioPerilla: 20
        reducirMovimiento: bar.reducirMovimiento
        despiertoExterno: bar.despierto
        energiaFija: bar.energiaFija; tiempoFijo: bar.tiempoFijo
        ocupado: bar.corte > 0
        onMovida: v => bar.movida(v)
        onTope: lado => { if (lado > 0 && !bar.reducirMovimiento) bar.corte = 1 }
        onTick: dt => {
            if (bar.corte > 0) { bar.corte -= dt * 1.9; if (bar.corte < 0.02) bar.corte = 0 }
            llama.requestPaint(); perilla.requestPaint()
        }
    }
}
