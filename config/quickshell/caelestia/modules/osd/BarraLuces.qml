// 3) LUCES — "Amanecer pixel"
// Mundo en pixel art (celdas de 4 px, paleta fija, degradados con dither Bayer): arriba noche cálida con estrellas
// y luna cuadrada; abajo el azul de siempre con sol cuadrado y nubes. La frontera es un amanecer de blanco cálido.
// La perilla es una lente de vidrio de verdad: vuelve a muestrear el mundo pixel por pixel con aumento,
// compresión en el borde y aberración cromática (rojo y azul se separan un poco).
//   value 1 = día (azul) · 0 = noche (blanco cálido tenue)
// Uso:  BarraLuces { value: Govee.mezcla; onMovida: v => Govee.ponMezcla(v) }
import QtQuick

Item {
    id: bar
    property real value: 1.0
    property real preferido: 1.0
    property bool reducirMovimiento: false
    property bool despierto: false
    property bool etiqueta: true
    property Paleta paleta: Paleta {}
    property alias nucleo: n
    property real energiaFija: -1
    property real tiempoFijo: 1.7
    signal movida(real v)

    width: 72; height: 320
    implicitWidth: 72; implicitHeight: 320

    readonly property int cel: 4
    readonly property int cols: Math.ceil(width / cel)
    readonly property int filas: Math.ceil(height / cel)
    readonly property int radioLente: 21
    readonly property var bayer: [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]

    // ---- tabla de colores (índices) armada desde la paleta ----
    property var tabla: []          // [{css, r, g, b}]
    property int iNoche: 0
    property int iExtra: 0
    function armaTabla() {
        var P = paleta, tb = []
        function mete(c) { c = Qt.color(c); tb.push({ css: "" + c, r: Math.round(c.r * 255), g: Math.round(c.g * 255), b: Math.round(c.b * 255) }) }
        for (var i = 0; i < P.luzDia.length; i++) mete(P.luzDia[i])
        iNoche = tb.length
        for (i = 0; i < P.luzNoche.length; i++) mete(P.luzNoche[i])
        iExtra = tb.length
        var ex = [P.estrella, P.estrellaTenue, P.lunaPixel, P.lunaPixelSombra, P.solPixel, P.solPixelBorde, P.nube, P.nubeLuz,
                  P.tierraDia, P.tierraDiaLuz, P.tierraNoche, P.tierraNocheLuz, P.ventana, P.capsula]
        for (i = 0; i < ex.length; i++) mete(ex[i])
        tabla = tb
    }
    // nombres de los extra
    readonly property int cEstrella: iExtra + 0
    readonly property int cEstrellaT: iExtra + 1
    readonly property int cLuna: iExtra + 2
    readonly property int cLunaS: iExtra + 3
    readonly property int cSol: iExtra + 4
    readonly property int cSolB: iExtra + 5
    readonly property int cNube: iExtra + 6
    readonly property int cNubeL: iExtra + 7
    readonly property int cTierraD: iExtra + 8
    readonly property int cTierraDL: iExtra + 9
    readonly property int cTierraN: iExtra + 10
    readonly property int cTierraNL: iExtra + 11
    readonly property int cVentana: iExtra + 12
    readonly property int cFondo: iExtra + 13
    Component.onCompleted: { armaTabla(); repinta() }
    Connections { target: bar.paleta; function onLuzDiaChanged() { bar.armaTabla(); bar.repinta() } function onLuzNocheChanged() { bar.armaTabla(); bar.repinta() } }

    // ---- sprites ----
    readonly property var sprLuna: ["LLLLLL", "LLLSLL", "LSLLLL", "LLLLSL", "LLSLLL", "LLLLLL"]          // luna cuadrada con cráteres
    readonly property var sprSol: [" BBBBBB ", "BSSSSSSB", "BSSSSSSB", "BSSSSSSB", "BSSSSSSB", "BSSSSSSB", "BSSSSSSB", " BBBBBB "]
    readonly property var sprNubeA: ["  HHH   ", " HHHHHH ", "NNNNNNNN"]
    readonly property var sprNubeB: [" HH  ", "NNNNN"]
    readonly property var perfil: [3, 3, 4, 4, 5, 6, 6, 6, 6, 6, 6, 5, 5, 4, 5, 5, 4, 3]                 // altura del cerro por columna
    readonly property var sprCasa: ["  R  ", " RRR ", "RRRRR", " TVT ", " TTT "]                         // T = muro/techo, V = ventana

    property var celdas: []          // índice de color por celda (se recalcula en cada pintada)
    property var chispas: []         // partículas pixel que suelta la lente al moverse rápido

    function sua(a, b, x) { var u = Math.max(0, Math.min(1, (x - a) / (b - a))); return u * u * (3 - 2 * u) }
    function h2(i, j) { var x = Math.sin(i * 127.1 + j * 311.7) * 43758.5453; return x - Math.floor(x) }

    function calcula() {
        var c = cel, nc = cols, nf = filas, by = bayer, cd = celdas
        if (cd.length !== nc * nf) cd = new Array(nc * nf)
        var v = Math.max(0, Math.min(1, n.pos)), e = n.energia, t = n.t
        // frontera = centro de la lente, salvo en los extremos: a 100 % se va por arriba (todo día) y a 0 % por abajo
        var fuga = (bar.radioLente + 26) / c
        var kf = n.yPerilla / c - fuga * sua(0.86, 1.0, v) + fuga * (1 - sua(0.0, 0.14, v))
        var nD = paleta.luzDia.length, nN = paleta.luzNoche.length
        var onda = bar.reducirMovimiento ? 0 : (0.45 * e + 2.6 * Math.abs(n.estira))
        var fuerza = 0.62 + 0.38 * (1 - v)                       // de noche la lámpara cálida pesa más
        var tw = Math.floor(t * 3)
        var esNoche = v < 0.5
        var lampara = (1 - v) * (1 - v) * 4.2                    // de noche el cuarto queda bañado en blanco cálido tenue
        for (var j = 0; j < nf; j++) {
            for (var i = 0; i < nc; i++) {
                var u = (by[(j & 3) * 4 + (i & 3)] + 0.5) / 16                 // umbral 0..1
                var d = j + 0.5 - kf + Math.sin(i * 0.8 + t * 2.4) * onda       // > 0 = debajo de la perilla = día
                var idx
                if (d / 3.5 > u * 2 - 1) {
                    var g = j / nf * (nD - 1) * 1.05
                    idx = Math.max(0, Math.min(nD - 1, Math.floor(g + u)))
                } else {
                    var cerca = Math.max(0, 1 + d / 30)                        // 1 en la frontera → 0 lejos
                    var lv = Math.pow(cerca, 1.9) * (nN - 1) * fuerza + 0.6 * (1 - j / nf) + lampara * Math.pow(j / nf, 2.6)
                    idx = iNoche + Math.max(0, Math.min(nN - 1, Math.floor(lv + u)))
                    if (idx <= iNoche + 1) {                                   // estrellas en lo oscuro
                        var hs = bar.h2(i, j)
                        if (hs < 0.045) idx = (bar.h2(i + tw, j * 3 + tw) > 0.3 || hs < 0.012) ? cEstrella : cEstrellaT
                    }
                }
                cd[j * nc + i] = idx
            }
        }
        function esDia(i, j) { return cd[j * nc + i] < iNoche }
        var x, y, fila, ch, k
        // luna cuadrada (solo sobre noche)
        for (y = 0; y < sprLuna.length; y++) for (x = 0; x < 6; x++) {
            i = 6 + x; j = 9 + y
            if (!esDia(i, j)) cd[j * nc + i] = sprLuna[y][x] === "S" ? cLunaS : cLuna
        }
        // sol cuadrado (solo sobre día)
        for (y = 0; y < sprSol.length; y++) for (x = 0; x < 8; x++) {
            ch = sprSol[y][x]; i = 5 + x; j = nf - 30 + y
            if (ch !== " " && esDia(i, j)) cd[j * nc + i] = ch === "S" ? cSol : cSolB
        }
        // nubes que cruzan el día
        function nube(spr, col0, fil0) {
            for (var yy = 0; yy < spr.length; yy++) for (var xx = 0; xx < spr[yy].length; xx++) {
                var cc = spr[yy][xx]; if (cc === " ") continue
                var ii = ((col0 + xx) % (nc + 10) + (nc + 10)) % (nc + 10) - 5, jj = fil0 + yy
                if (ii >= 0 && ii < nc && jj >= 0 && jj < nf && esDia(ii, jj)) cd[jj * nc + ii] = cc === "H" ? cNubeL : cNube
            }
        }
        var paso = Math.floor(t * 1.6)
        nube(sprNubeA, 3 + paso, 22); nube(sprNubeB, 14 + Math.floor(t * 2.3), 37); nube(sprNubeA, 12 + Math.floor(t * 1.1), 58)
        // cerro + casita con la ventana encendida de noche
        for (i = 0; i < nc; i++) {
            var alto = perfil[i % perfil.length]
            for (k = 0; k < alto; k++) {
                j = nf - 1 - k
                var dd = esDia(i, j)
                cd[j * nc + i] = k === alto - 1 ? (dd ? cTierraDL : cTierraNL) : (dd ? cTierraD : cTierraN)
            }
        }
        for (y = 0; y < sprCasa.length; y++) for (x = 0; x < 5; x++) {
            ch = sprCasa[y][x]; if (ch === " ") continue
            i = 7 + x; j = nf - 6 - sprCasa.length + y
            dd = esDia(i, j)
            cd[j * nc + i] = ch === "V" ? (esNoche ? cVentana : (dd ? cNube : cTierraNL)) : (ch === "R" ? (dd ? cTierraDL : cTierraNL) : (dd ? cTierraD : cTierraN))
        }
        // estrella fugaz de vez en cuando (solo despierto y con cielo de sobra)
        if (e > 0.5 && !bar.reducirMovimiento && kf > 40) {
            var ciclo = t / 4.2, fase = ciclo - Math.floor(ciclo), sem = Math.floor(ciclo)
            if (fase < 0.16) {
                var x0 = 3 + Math.floor(bar.h2(sem, 7) * 8), y0 = 3 + Math.floor(bar.h2(sem, 3) * 6), av = Math.floor(fase / 0.16 * 9)
                for (k = 0; k < 3; k++) {
                    i = x0 + av - k; j = y0 + av - k
                    if (i >= 0 && i < nc && j >= 0 && j < nf && !esDia(i, j)) cd[j * nc + i] = k === 0 ? cEstrella : cEstrellaT
                }
            }
        }
        // chispas pixel
        for (k = 0; k < chispas.length; k++) {
            var q = chispas[k]; i = Math.floor(q.x); j = Math.floor(q.y)
            if (i >= 0 && i < nc && j >= 0 && j < nf) cd[j * nc + i] = esDia(i, j) ? cNubeL : cEstrella
        }
        celdas = cd
    }

    function repinta() { calcula(); mundo.requestPaint() }

    Item {
        id: cuerpo
        width: bar.width; height: bar.height
        y: n.empuje

        Rectangle { anchors.fill: parent; radius: width / 2; color: bar.paleta.capsula }

        Canvas {
            id: mundo
            anchors.fill: parent
            antialiasing: false
            onPaint: {
                var ctx = getContext("2d"), w = width, h = height, r = w / 2
                ctx.reset()
                var cd = bar.celdas, tb = bar.tabla, nc = bar.cols, nf = bar.filas, c = bar.cel
                if (cd.length !== nc * nf || tb.length === 0) return
                ctx.beginPath()
                ctx.arc(r, r, r - 1, Math.PI, 2 * Math.PI, false)
                ctx.lineTo(w - 1, h - r); ctx.arc(r, h - r, r - 1, 0, Math.PI, false); ctx.closePath(); ctx.clip()
                for (var j = 0; j < nf; j++) {
                    var i0 = 0, base = j * nc, act = cd[base]
                    for (var i = 1; i <= nc; i++) {
                        var cur = i < nc ? cd[base + i] : -1
                        if (cur !== act) { ctx.fillStyle = tb[act].css; ctx.fillRect(i0 * c, j * c, (i - i0) * c, c); i0 = i; act = cur }
                    }
                }
            }
        }

        Vidrio { paleta: bar.paleta; realce: Math.max(n.encima ? 1 : 0, n.aprieta); foco: n.focoTeclado; brillo: 0.8 }

        // lente de vidrio
        Canvas {
            id: lente
            readonly property int rl: bar.radioLente
            readonly property int pad: 7
            readonly property int lado: 2 * (rl + pad)
            width: lado; height: lado
            x: bar.width / 2 - lado / 2
            y: Math.round(n.yPerilla) - lado / 2
            antialiasing: true
            Component.onCompleted: requestPaint()
            transform: Scale {
                origin.x: lente.lado / 2; origin.y: lente.lado / 2
                xScale: 1 + 0.05 * n.aprieta - 0.07 * Math.abs(n.estira)
                yScale: 1 + 0.05 * n.aprieta + 0.13 * Math.abs(n.estira)
            }
            onPaint: {
                var ctx = getContext("2d"), P = bar.paleta, R = rl
                var cd = bar.celdas, tb = bar.tabla, nc = bar.cols, nf = bar.filas, cel = bar.cel
                ctx.reset()
                if (cd.length !== nc * nf || tb.length === 0) return
                // 11-12: lente simple (antes remuestreaba el pixel art pixel por pixel en JS y lagueaba el OSD)
                var cc = lado / 2
                var gl = ctx.createRadialGradient(cc - 5, cc - 6, 2, cc, cc, R)
                gl.addColorStop(0, Qt.rgba(1, 1, 1, 0.30)); gl.addColorStop(0.65, Qt.rgba(1, 1, 1, 0.07)); gl.addColorStop(1, Qt.rgba(1, 1, 1, 0.16))
                ctx.fillStyle = gl; ctx.beginPath(); ctx.arc(cc, cc, R, 0, 2 * Math.PI); ctx.fill()

                var c = lado / 2
                // sombra de contacto alrededor
                ctx.lineWidth = 5; ctx.strokeStyle = Qt.rgba(0, 0, 0, 0.16); ctx.beginPath(); ctx.arc(c, c + 1.5, R + 2.5, 0, 2 * Math.PI); ctx.stroke()
                ctx.lineWidth = 2; ctx.strokeStyle = Qt.rgba(0, 0, 0, 0.30); ctx.beginPath(); ctx.arc(c, c + 0.5, R + 0.8, 0, 2 * Math.PI); ctx.stroke()
                // aro: claro arriba-izquierda, se apaga y vuelve abajo-derecha
                var ar = ctx.createLinearGradient(c - R, c - R, c + R, c + R)
                ar.addColorStop(0, Qt.rgba(1, 1, 1, 0.95)); ar.addColorStop(0.45, Qt.rgba(1, 1, 1, 0.28)); ar.addColorStop(0.75, Qt.rgba(1, 1, 1, 0.18)); ar.addColorStop(1, Qt.rgba(1, 1, 1, 0.70))
                ctx.lineWidth = 1.5; ctx.strokeStyle = ar; ctx.beginPath(); ctx.arc(c, c, R - 0.75, 0, 2 * Math.PI); ctx.stroke()
                ctx.lineWidth = 1; ctx.strokeStyle = Qt.rgba(0, 0, 0, 0.22); ctx.beginPath(); ctx.arc(c, c, R - 2.2, 0, 2 * Math.PI); ctx.stroke()
                // reflejos
                ctx.lineCap = "round"
                ctx.lineWidth = 2.4; ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.62); ctx.beginPath(); ctx.arc(c, c, R - 6, Math.PI * 1.10, Math.PI * 1.42); ctx.stroke()
                ctx.lineWidth = 1.4; ctx.strokeStyle = P.alfa(P.hielo, 0.40); ctx.beginPath(); ctx.arc(c, c, R - 5, Math.PI * 0.18, Math.PI * 0.36); ctx.stroke()
            }
        }
    }

    Etiqueta {
        nucleo: n; paleta: bar.paleta; visible: bar.etiqueta && n.tocando > 0.01
        texto: n.pos > 0.66 ? "DÍA" : (n.pos > 0.33 ? "TARDE" : "NOCHE")
    }

    Nucleo {
        id: n
        value: bar.value
        preferido: bar.preferido
        margen: 28; radioPerilla: bar.radioLente
        reducirMovimiento: bar.reducirMovimiento
        despiertoExterno: bar.despierto
        energiaFija: bar.energiaFija; tiempoFijo: bar.tiempoFijo
        onMovida: v => bar.movida(v)
        property real _acum: 1
        property real _pintado: -1
        property real _firma: -1
        onTick: dt => {
            // chispas: nacen al mover rápido, caen/suben un par de celdas y mueren
            var ch = bar.chispas, vivo = ch.length > 0
            if (!bar.reducirMovimiento && Math.abs(vel) > 0.5 && ch.length < 18 && Math.random() < 0.5) {
                var lado = Math.random() < 0.5 ? -1 : 1
                ch.push({ x: bar.cols / 2 + lado * (5.5 + Math.random() * 2), y: yPerilla / bar.cel + (Math.random() - 0.5) * 6,
                          vx: lado * (2 + Math.random() * 5), vy: -vel * 14 + (Math.random() - 0.5) * 6, vida: 0.35 + Math.random() * 0.3 })
            }
            for (var k = ch.length - 1; k >= 0; k--) {
                var q = ch[k]; q.x += q.vx * dt; q.y += q.vy * dt; q.vida -= dt
                if (q.vida <= 0) ch.splice(k, 1)
            }
            ocupado = ch.length > 0
            // el mundo pixel anima a ~12 fps; la lente sigue al cursor en cada cuadro
            _acum += dt
            var firma = aprieta + Math.abs(estira) * 7
            if (pos !== _pintado || firma !== _firma || vivo || (_acum >= 0.2 && energia > 0)) {
                _pintado = pos; _firma = firma; _acum = 0; bar.repinta()
            }
        }
    }
}
