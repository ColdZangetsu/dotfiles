// Base común de las tres variantes: modelo, geometría de la columna, muelle del activo,
// clic / rueda y el "latido" que SOLO corre mientras algo se está asentando. No dibuja nada propio:
// cada variante le pasa un `pintor(ctx)` que pinta la columna completa en un Canvas.
//
//   modelo: [{ etiqueta: "七", icono: "", ocupado: true, ventanas: ["terminal", "web"], ajeno: false }, ...]
//     · etiqueta = texto (kanji);  icono = nombre de Material Symbols (si viene, reemplaza al kanji)
//     · ventanas = iconos de las ventanas, se listan debajo;  ajeno = el escritorio vive en otro monitor
//   activo: índice dentro de modelo (-1 = ninguno)
//   señales: elegido(i) al hacer clic, rueda(dir) con la rueda (+1 = siguiente)
import QtQuick

Item {
    id: b

    // ---------- entradas ----------
    property var modelo: []
    property int activo: 0
    property Paleta paleta: Paleta {}
    property bool reducirMovimiento: false
    property bool fondo: true               // píldora propia (en Caelestia la pone la barra: false)
    property bool mostrarVentanas: true
    property real escala: 1                 // todo es vectorial: 2 o 3 para verlo grande
    property real ancho: 40                 // Tokens.sizes.bar.innerWidth
    property real celda: 32                 // alto de la etiqueta (innerWidth - padding.small)
    property real separacion: 4
    property real margen: 4
    property real altoVentana: 19
    property real tamKanji: 22
    property real tamIcono: 20
    property real tamVentana: 15
    property string fuenteKanji: "Yuji Boku"
    property string fuenteIconos: "Material Symbols Rounded"
    property bool usarRueda: false          // true: emite rueda(); false: deja pasar la rueda a quien lo aloja
    property bool resaltar: false           // true: aclara la celda bajo el cursor (activa hover)
    property var pintor: null               // function(ctx): lo pone cada variante
    property real sangre: 8                 // aire alrededor para halos (px lógicos)
    property real rigidez: 27               // muelle del activo (rad/s)
    property real amortigua: 0.74           // < 1 = un rebote leve al llegar
    property real durFoco: 0.24             // s: lo que tarda una celda en encenderse / apagarse
    property real durEfecto: 0.38           // s: ventana de los efectos de un solo uso (tajo, destello)
    property int capDesde: -1               // capturas: venir de este índice…
    property real capTiempo: -1             // …y congelar a los N segundos del cambio

    signal elegido(int i)
    signal rueda(int dir)

    // ---------- salidas (para los pintores) ----------
    readonly property var geo: _mide(modelo, mostrarVentanas, celda, separacion, margen, altoVentana)
    readonly property real cx: ancho / 2
    property real pos: 0                    // y del indicador (con muelle)
    property real vel: 0                    // px/s
    property real estira: 0                 // -1..1 velocidad suavizada (+ = hacia abajo)
    property real u: 1e3                    // s desde el último cambio de escritorio
    property int desde: -1                  // índice anterior
    property real posDesde: 0               // y de donde salió
    property var foco: []                   // 0..1 por celda (1 = activa)
    property var ocup: []                   // 0..1 por celda (1 = con ventanas)
    property int sobre: -1                  // celda bajo el cursor
    property bool quieto: true

    implicitWidth: ancho * escala
    implicitHeight: geo.total * escala
    width: implicitWidth; height: implicitHeight

    function sua(a, b2, x) { var t = Math.max(0, Math.min(1, (x - a) / (b2 - a))); return t * t * (3 - 2 * t) }
    function campana(a, m, z, x) { return x <= a || x >= z ? 0 : (x < m ? sua(a, m, x) : 1 - sua(m, z, x)) }
    function cy(i) { return i >= 0 && i < geo.cy.length ? geo.cy[i] : 0 }
    // media luna: círculo R menos círculo r2 desplazado d a la derecha (mismo trazo que la perilla de volumen)
    function luna(ctx, R, d, r2) {
        var xi = (R * R - r2 * r2 + d * d) / (2 * d), yi = Math.sqrt(Math.max(0, R * R - xi * xi))
        var a1 = Math.atan2(yi, xi), a2 = Math.atan2(yi, xi - d)
        ctx.beginPath()
        ctx.arc(0, 0, R, a1, 2 * Math.PI - a1, false)
        ctx.arc(d, 0, r2, 2 * Math.PI - a2, a2, true)
        ctx.closePath()
    }
    function pildora(ctx, x, y, w, h) {
        var r = Math.min(w, h) / 2
        ctx.beginPath()
        ctx.arc(x + r, y + r, r, Math.PI, 1.5 * Math.PI, false); ctx.arc(x + w - r, y + r, r, 1.5 * Math.PI, 2 * Math.PI, false)
        ctx.arc(x + w - r, y + h - r, r, 0, 0.5 * Math.PI, false); ctx.arc(x + r, y + h - r, r, 0.5 * Math.PI, Math.PI, false)
        ctx.closePath()
    }
    // etiqueta de la celda i (kanji o ícono) centrada en su sitio (+dx, +dy)
    function etiqueta(ctx, i, color, dx, dy) {
        var e = modelo[i]; if (!e) return
        var ic = e.icono ? true : false
        ctx.font = ic ? (tamIcono + "px '" + fuenteIconos + "'") : (tamKanji + "px '" + fuenteKanji + "'")
        ctx.textAlign = "center"; ctx.textBaseline = "middle"
        ctx.fillStyle = color
        ctx.fillText(ic ? e.icono : (e.etiqueta || ""), cx + (dx || 0), geo.cy[i] + (ic ? 1 : 0.5) + (dy || 0))
    }
    // iconos de ventanas bajo la celda i
    function ventanas(ctx, i, color) {
        var e = modelo[i]; if (!e || !mostrarVentanas || !e.ventanas || !e.ventanas.length) return
        ctx.font = tamVentana + "px '" + fuenteIconos + "'"
        ctx.textAlign = "center"; ctx.textBaseline = "middle"; ctx.fillStyle = color
        for (var k = 0; k < e.ventanas.length; k++)
            ctx.fillText(e.ventanas[k], cx, geo.top[i] + celda + altoVentana * (k + 0.5) - 1)
    }
    // color base de una etiqueta según su estado (f = foco 0..1, o = ocupación 0..1)
    function tono(i, f, o) {
        var P = paleta, e = modelo[i]
        var c = P.mezcla(P.alfa(P.tenue, 0.42), P.alfa(P.hueso, 0.88), o)
        if (e && e.ajeno) c = P.alfa(P.tenue, 0.30)
        if (i === sobre) c = P.mezcla(c, P.hueso, 0.45)
        return P.mezcla(c, P.huesoAlto, f)
    }
    function tonoVentanas(i, f) { return paleta.alfa(paleta.mezcla(paleta.tenue, paleta.hueso, 0.55 * f), (modelo[i] && modelo[i].ajeno) ? 0.35 : 0.72) }

    // ---------- interno ----------
    property int _previo: -1
    property real _vp: 0
    property bool _listo: false

    function _mide(m, ven, celda, sep, mar, av) {
        var top = [], cys = [], alto = [], y = mar
        for (var i = 0; i < m.length; i++) {
            var n = ven && m[i].ventanas ? m[i].ventanas.length : 0
            var h = celda + (n > 0 ? n * av + 2 : 0)
            top.push(y); cys.push(y + celda / 2); alto.push(h)
            y += h + sep
        }
        return { top: top, cy: cys, alto: alto, total: Math.max(celda + 2 * mar, y - sep + mar) }
    }
    function _ajusta() {
        var n = modelo.length
        while (foco.length < n) { foco.push(0); ocup.push(modelo[ocup.length].ocupado ? (_listo ? 0 : 1) : 0) }
        foco.length = n; ocup.length = n
    }
    function _fija() {       // todo a su destino, sin animar
        _ajusta()
        for (var i = 0; i < modelo.length; i++) { foco[i] = i === activo ? 1 : 0; ocup[i] = modelo[i].ocupado ? 1 : 0 }
        pos = cy(activo); _vp = 0; vel = 0; estira = 0; u = 1e3; quieto = true
        lienzo.requestPaint()
    }
    function _despierta() { if (!_listo) return; _ajusta(); if (reducirMovimiento || capTiempo >= 0) _fija(); else quieto = false }

    onActivoChanged: {
        if (!_listo) return
        desde = _previo; posDesde = pos; _previo = activo; u = 0
        if (desde < 0 || activo < 0) { _fija(); return }
        _despierta()
    }
    onModeloChanged: _despierta()
    onGeoChanged: _despierta()
    onSobreChanged: lienzo.requestPaint()
    onReducirMovimientoChanged: if (_listo) _fija()
    onVisibleChanged: if (_listo && !visible) _fija()
    onPintorChanged: lienzo.requestPaint()
    Component.onCompleted: { _listo = true; fija() }

    // Deja todo en su destino sin animar. La usa quien enlaza las entradas DESPUÉS de crear el componente
    // (EscritoriosPorMonitor), para que el primer cuadro no arranque animando desde el escritorio 0.
    function fija() { _previo = activo; desde = -1; _fija(); _congela() }
    function _congela() {    // capturas: cuadro congelado a media transición
        if (!(capTiempo >= 0 && capDesde >= 0 && capDesde !== activo && capDesde < foco.length)) return
        for (var i = 0; i < foco.length; i++) foco[i] = i === capDesde ? 1 : 0
        pos = cy(capDesde); posDesde = pos; desde = capDesde; u = 0
        for (var t = 0; t < capTiempo; t += 0.004) _avanza(0.004)
        lienzo.requestPaint()
    }

    FrameAnimation {
        running: b.visible && !b.quieto && b.capTiempo < 0
        onTriggered: b._avanza(Math.min(0.05, frameTime))
    }

    function _avanza(dt) {
        var obj = cy(activo), antes = pos, w = rigidez, z = amortigua
        var pasos = Math.ceil(dt / 0.003), h = dt / pasos, p = pos, vp = _vp
        for (var s = 0; s < pasos; s++) { vp += (w * w * (obj - p) - 2 * z * w * vp) * h; p += vp * h }
        if (Math.abs(obj - p) < 0.05 && Math.abs(vp) < 1.5) { p = obj; vp = 0 }
        pos = p; _vp = vp
        vel = dt > 0 ? (pos - antes) / dt : 0
        estira += (Math.max(-1, Math.min(1, vel / 520)) - estira) * (1 - Math.exp(-dt * 26))
        if (vp === 0 && Math.abs(estira) < 0.004) estira = 0
        var vivo = false
        for (var i = 0; i < foco.length; i++) {
            var of = i === activo ? 1 : 0, oo = modelo[i].ocupado ? 1 : 0
            if (foco[i] !== of) { foco[i] = of > foco[i] ? Math.min(1, foco[i] + dt / durFoco) : Math.max(0, foco[i] - dt / durFoco); vivo = true }
            if (ocup[i] !== oo) { ocup[i] = oo > ocup[i] ? Math.min(1, ocup[i] + dt / 0.22) : Math.max(0, ocup[i] - dt / 0.22); vivo = true }
        }
        u += dt
        lienzo.requestPaint()
        if (!vivo && vp === 0 && estira === 0 && u >= durEfecto) quieto = true
    }

    Canvas {
        id: lienzo
        x: -b.sangre * b.escala; y: -b.sangre * b.escala
        width: (b.ancho + 2 * b.sangre) * b.escala
        height: (b.geo.total + 2 * b.sangre) * b.escala
        onPaint: {
            var ctx = getContext("2d"), P = b.paleta
            ctx.reset()
            ctx.scale(b.escala, b.escala); ctx.translate(b.sangre, b.sangre)
            if (b.foco.length !== b.modelo.length) b._ajusta()
            if (b.fondo) {
                b.pildora(ctx, 0, 0, b.ancho, b.geo.total)
                ctx.fillStyle = P.capsula; ctx.fill()
                b.pildora(ctx, 0.5, 0.5, b.ancho - 1, b.geo.total - 1)
                ctx.strokeStyle = P.alfa(P.borde, 0.7); ctx.lineWidth = 1; ctx.stroke()
            }
            if (b.pintor) b.pintor(ctx)
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: b.resaltar
        function celdaEn(y) {
            y /= b.escala
            for (var i = 0; i < b.modelo.length; i++)
                if (y >= b.geo.top[i] - b.separacion / 2 && y < b.geo.top[i] + b.geo.alto[i] + b.separacion / 2) return i
            return -1
        }
        onPositionChanged: m => { if (b.resaltar) b.sobre = celdaEn(m.y) }
        onExited: b.sobre = -1
        onClicked: m => { var i = celdaEn(m.y); if (i >= 0) b.elegido(i) }
        onWheel: w => { if (b.usarRueda) b.rueda(w.angleDelta.y < 0 ? 1 : -1); else w.accepted = false }
    }
}
