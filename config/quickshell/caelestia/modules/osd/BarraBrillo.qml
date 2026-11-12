// 2) BRILLO — "Eclipse"
// Astronomía limpia: una órbita fina y un sol. Al bajar el brillo la luna negra entra en diagonal y lo tapa;
// en totalidad queda la corona roja (la luna de nerozangetsu.com) y aparece 蝕. Justo antes: el anillo de diamante.
// Barata a propósito: no tiene animación propia, solo repinta cuando el valor se mueve.
// Uso:  BarraBrillo { value: Brightness.value; onMovida: v => Brightness.set(v) }
import QtQuick

Item {
    id: bar
    property real value: 0.7
    property real preferido: 0.7
    property bool reducirMovimiento: false
    property bool despierto: false
    property bool etiqueta: true
    property Paleta paleta: Paleta {}
    property string fuenteKanji: "Noto Serif CJK JP"
    property alias nucleo: n
    property real energiaFija: -1
    property real tiempoFijo: 1.7
    signal movida(real v)

    width: 72; height: 320
    implicitWidth: 72; implicitHeight: 320

    function sua(a, b, x) { var u = Math.max(0, Math.min(1, (x - a) / (b - a))); return u * u * (3 - 2 * u) }
    // estrellas fijas [x, y, tamaño]
    readonly property var estrellas: [[14, 22, 1], [52, 30, 1.5], [30, 48, 1], [60, 66, 1], [11, 80, 1.5], [44, 96, 1], [22, 118, 1], [58, 132, 1.5],
                                      [13, 150, 1], [49, 168, 1], [27, 186, 1.5], [61, 204, 1], [16, 224, 1], [53, 246, 1], [24, 270, 1], [45, 290, 1.5]]

    Item {
        id: cuerpo
        width: bar.width; height: bar.height
        y: n.empuje

        Rectangle { anchors.fill: parent; radius: width / 2; color: bar.paleta.vacio }
        Rectangle {      // el cielo se aclara con el brillo (solo opacidad: gratis)
            anchors.fill: parent; radius: width / 2
            opacity: 0.25 + 0.75 * Math.max(0, Math.min(1, n.pos))
            gradient: Gradient {
                GradientStop { position: 0; color: bar.paleta.cieloAlto }
                GradientStop { position: 1; color: bar.paleta.capsula }
            }
        }

        Canvas {
            id: cielo
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d"), P = bar.paleta, w = width, h = height, cx = w / 2
                ctx.reset()
                var v = Math.max(0, Math.min(1, n.pos)), yk = n.yPerilla
                // estrellas: salen cuando oscurece
                var ae = Math.pow(1 - v, 1.3)
                for (var i = 0; i < bar.estrellas.length; i++) {
                    var s = bar.estrellas[i]
                    ctx.fillStyle = P.alfa(i % 5 === 0 ? P.hielo : P.hueso, ae * (0.35 + 0.5 * ((i * 7) % 4) / 3))
                    ctx.fillRect(s[0], s[1], s[2], s[2])
                }
                // órbita: hilo central con una cuenta cada 10 %; lo recorrido queda encendido
                var y1 = n.yDe(1), y0 = n.yDe(0)
                ctx.fillStyle = P.alfa(P.hueso, 0.10); ctx.fillRect(cx - 0.5, y1, 1, y0 - y1)
                var lz = ctx.createLinearGradient(0, yk, 0, y0)
                lz.addColorStop(0, P.alfa(P.sol, 0.15 + 0.55 * v)); lz.addColorStop(1, P.alfa(P.sol, 0.10 + 0.15 * v))
                ctx.fillStyle = lz; ctx.fillRect(cx - 0.5, yk, 1, Math.max(0, y0 - yk))
                for (var m = 0; m <= 10; m++) {
                    var ym = n.yDe(m / 10), enc = m / 10 <= v + 0.001
                    ctx.fillStyle = enc ? P.alfa(P.sol, 0.45 + 0.4 * v) : P.alfa(P.hueso, 0.20)
                    var r = (m % 5 === 0) ? 1.8 : 1.1
                    ctx.beginPath(); ctx.arc(cx, ym, r, 0, 2 * Math.PI); ctx.fill()
                }
            }
        }

        Vidrio { paleta: bar.paleta; realce: Math.max(n.encima ? 1 : 0, n.aprieta); foco: n.focoTeclado; brillo: 0.7 }

        Canvas {
            id: astro
            readonly property int lado: 132
            width: lado; height: lado
            x: bar.width / 2 - lado / 2
            y: n.yPerilla - lado / 2
            onPaint: {
                var ctx = getContext("2d"), P = bar.paleta, c = lado / 2
                ctx.reset()
                var v = Math.max(0, Math.min(1, n.pos)), R = 13
                var ap = n.aprieta, s = Math.abs(n.estira)
                var ang = -0.52                                   // la luna entra desde arriba a la derecha
                var d = 2.25 * R * Math.pow(v, 0.85)              // separación sol–luna
                var tapa = 1 - bar.sua(0.0, 0.5, v)               // cuánto pesa el eclipse
                var total = 1 - bar.sua(0.0, 0.05, v)
                var mx = Math.cos(ang) * d, my = Math.sin(ang) * d

                ctx.translate(c, c)
                var esc = 1 - 0.06 * ap
                ctx.scale(esc * (1 - 0.06 * s), esc * (1 + 0.12 * s))

                // halo del sol
                var hr = R * (1.7 + 1.5 * v)
                var ha = ctx.createRadialGradient(0, 0, R * 0.8, 0, 0, hr)
                ha.addColorStop(0, P.alfa(P.sol, 0.34 * v)); ha.addColorStop(1, P.alfa(P.sol, 0))
                ctx.fillStyle = ha; ctx.beginPath(); ctx.arc(0, 0, hr, 0, 2 * Math.PI); ctx.fill()

                // corona roja: dos pinceladas largas + resplandor
                if (tapa > 0.01) {
                    function pincel(a, largo, ancho, alfa) {
                        ctx.save(); ctx.rotate(a); ctx.scale(1, ancho)
                        var g = ctx.createRadialGradient(0, 0, R * 0.6, 0, 0, largo)
                        g.addColorStop(0, P.alfa(P.corona, alfa)); g.addColorStop(1, P.alfa(P.corona, 0))
                        ctx.fillStyle = g; ctx.beginPath(); ctx.arc(0, 0, largo, 0, 2 * Math.PI); ctx.fill()
                        ctx.restore()
                    }
                    pincel(-0.30, R * (2.3 + 1.1 * tapa), 0.20, 0.42 * tapa)
                    pincel(1.20, R * (1.9 + 0.7 * tapa), 0.18, 0.28 * tapa)
                    var co = ctx.createRadialGradient(0, 0, R * 0.9, 0, 0, R * 2.5)
                    co.addColorStop(0, P.alfa(P.corona, 0.80 * tapa)); co.addColorStop(0.35, P.alfa(P.corona, 0.30 * tapa)); co.addColorStop(1, P.alfa(P.corona, 0))
                    ctx.fillStyle = co; ctx.beginPath(); ctx.arc(0, 0, R * 2.5, 0, 2 * Math.PI); ctx.fill()
                }

                // rayos finos: giran con el valor (se sienten como una corona de reloj)
                if (v > 0.12) {
                    ctx.save(); ctx.rotate(v * Math.PI * 0.75)
                    ctx.strokeStyle = P.alfa(P.sol, 0.75 * bar.sua(0.12, 0.6, v)); ctx.lineWidth = 1; ctx.lineCap = "round"
                    ctx.beginPath()
                    for (var k = 0; k < 12; k++) {
                        var a = k * Math.PI / 6, r0 = R + 4, r1 = R + 5.5 + (k % 2 === 0 ? 5.5 : 2.5) * v
                        ctx.moveTo(Math.cos(a) * r0, Math.sin(a) * r0); ctx.lineTo(Math.cos(a) * r1, Math.sin(a) * r1)
                    }
                    ctx.stroke(); ctx.restore()
                }

                // sol
                var sg = ctx.createRadialGradient(-3, -3, 1, 0, 0, R)
                sg.addColorStop(0, Qt.rgba(1, 1, 1, 1)); sg.addColorStop(1, P.mezcla(P.mezcla(P.sol, P.corona, 0.35), P.sol, v))
                ctx.fillStyle = sg; ctx.beginPath(); ctx.arc(0, 0, R, 0, 2 * Math.PI); ctx.fill()

                // luna negra (se desvanece al salir del todo)
                var al = 1 - bar.sua(0.80, 0.98, v)
                if (al > 0.01) {
                    ctx.globalAlpha = al
                    ctx.fillStyle = P.vacio; ctx.beginPath(); ctx.arc(mx, my, R + 0.7, 0, 2 * Math.PI); ctx.fill()
                    ctx.strokeStyle = P.mezcla(P.alfa(P.hueso, 0.16), P.alfa(P.corona, 0.85), tapa); ctx.lineWidth = 1
                    ctx.beginPath(); ctx.arc(mx, my, R + 0.7, 0, 2 * Math.PI); ctx.stroke()
                    ctx.globalAlpha = 1
                }

                // anillo de diamante: el último destello antes de la totalidad
                var dia = bar.sua(0.0, 0.05, v) * (1 - bar.sua(0.08, 0.2, v))
                if (dia > 0.01) {
                    var px = -Math.cos(ang) * (R + 0.5), py = -Math.sin(ang) * (R + 0.5)
                    var dg = ctx.createRadialGradient(px, py, 0, px, py, 9)
                    dg.addColorStop(0, Qt.rgba(1, 1, 1, dia)); dg.addColorStop(0.3, P.alfa(P.sol, 0.6 * dia)); dg.addColorStop(1, P.alfa(P.sol, 0))
                    ctx.fillStyle = dg; ctx.beginPath(); ctx.arc(px, py, 9, 0, 2 * Math.PI); ctx.fill()
                    ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.8 * dia); ctx.lineWidth = 0.8
                    ctx.beginPath(); ctx.moveTo(px - 11, py); ctx.lineTo(px + 11, py); ctx.moveTo(px, py - 11); ctx.lineTo(px, py + 11); ctx.stroke()
                }

                // 蝕 en totalidad
                if (total > 0.01) {
                    ctx.font = '200 15px "' + bar.fuenteKanji + '"'
                    ctx.textAlign = "center"; ctx.textBaseline = "middle"
                    ctx.fillStyle = P.alfa(P.mezcla(P.hueso, P.corona, 0.35), 0.85 * total)
                    ctx.fillText("蝕", 0, -R * 3.6)
                }
            }
        }
    }

    Etiqueta { nucleo: n; paleta: bar.paleta; visible: bar.etiqueta && n.tocando > 0.01; texto: Math.round(n.pos * 100) }

    Nucleo {
        id: n
        value: bar.value
        preferido: bar.preferido
        margen: 26; radioPerilla: 20
        reducirMovimiento: bar.reducirMovimiento
        despiertoExterno: false              // esta barra no necesita latir en reposo
        energiaFija: bar.energiaFija; tiempoFijo: bar.tiempoFijo
        onMovida: v => bar.movida(v)
        property real _pintado: -1
        property real _extra: -1
        onTick: dt => {
            var firma = aprieta + Math.abs(estira) * 3
            if (pos !== _pintado || firma !== _extra) { _pintado = pos; _extra = firma; cielo.requestPaint(); astro.requestPaint() }
        }
    }
}
