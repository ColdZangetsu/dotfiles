// Núcleo común de interacción: arrastre, rueda, teclado, muelle, imanes, tope elástico
// y el "latido" (tick) que SOLO corre mientras hay algo que mover. Sin nada visual.
import QtQuick

Item {
    id: n
    anchors.fill: parent

    // ---------- entradas ----------
    property real value: 0                 // valor real (0..1), viene de fuera
    property real paso: 0.02               // rueda / flechas
    property real pasoGrande: 0.10         // RePág / AvPág
    property var imanes: []                // valores donde la perilla "encaja" al arrastrar
    property real radioIman: 0.016
    property real preferido: -1            // doble clic salta aquí (-1 = nada)
    property bool reducirMovimiento: false
    property real margen: 26               // recorrido útil: de margen a height - margen
    property real radioPerilla: 20
    property bool despiertoExterno: false  // el OSD puede forzar "despierto" mientras se muestra
    property real energiaFija: -1          // >= 0: congela energía/tiempo (capturas)
    property real tiempoFijo: 1.7

    // ---------- salidas ----------
    property real pos: value               // valor mostrado (con muelle)
    property real vel: 0                   // unidades/s
    property real estira: 0                // -1..1, suavizado de la velocidad (+ = subiendo)
    property real energia: 0               // 0 reposo .. 1 despierto
    property real t: 0                     // reloj de animación (solo avanza despierto)
    property real empuje: 0                // px de rebote elástico en los topes
    property real pulsoIman: 0             // 1 → 0 al encajar en un imán
    property real aprieta: 0               // 0..1 presión suavizada
    property real tocando: 0               // 0..1 manipulación directa (para la etiqueta)
    readonly property bool presionado: ma.pressed
    readonly property bool encima: ma.containsMouse
    readonly property real yPerilla: yDe(pos)
    readonly property bool focoTeclado: activeFocus && (focusReason === Qt.TabFocusReason || focusReason === Qt.BacktabFocusReason)
    property bool quieto: true
    property bool ocupado: false           // la barra puede pedir más latidos (efectos propios)

    signal movida(real v)                  // el usuario pidió este valor
    signal tick(real dt)                   // repinta aquí
    signal tope(int lado)                  // +1 llegó a 100 %, -1 a 0 %
    signal encaja(real v)                  // encajó en un imán

    function yDe(v) { return height - margen - v * (height - 2 * margen) }
    function despierta() { siesta.restart(); quieto = false }

    // ---------- estado interno ----------
    property real _arrastre: 0
    property real _desfase: 0
    property real _velPos: 0
    property real _velEmp: 0
    property real _goma: 0
    property real _imanActual: -1
    property bool _rebote: false
    property real _pend: -1
    property real _rueda: 0
    property int _ultimoTope: 0
    property bool _ruedaViva: false

    activeFocusOnTab: true
    onValueChanged: { if (energiaFija >= 0) pos = value; else despierta() }
    onVisibleChanged: if (!visible) { pos = value; _velPos = 0; vel = 0; estira = 0; energia = 0; empuje = 0; quieto = true }
    Component.onCompleted: { pos = value; if (energiaFija >= 0) { energia = energiaFija; t = tiempoFijo } tick(0) }

    Timer { id: siesta; interval: 1500 }
    Timer { id: pendiente; interval: 300; onTriggered: n._pend = -1 }
    Timer { id: ruedaT; interval: 700; onTriggered: n._ruedaViva = false }

    function _base() { return presionado ? _arrastre : (_pend >= 0 ? _pend : value) }
    function _pide(v) {
        v = Math.max(0, Math.min(1, v))
        var lado = v >= 1 ? 1 : (v <= 0 ? -1 : 0)
        if (lado !== 0 && lado !== _ultimoTope) tope(lado)
        _ultimoTope = lado
        _pend = v; pendiente.restart(); despierta()
        if (v !== value) movida(v)
    }
    function _paso(dir, tam) {
        var b = _base(), v = Math.round((b + dir * tam) / paso) * paso
        v = Math.max(0, Math.min(1, v))
        if (Math.abs(v - b) < 1e-6) { _velEmp += -dir * 150; despierta(); return }   // golpecito contra el tope
        _pide(v)
    }
    function _mueve(y) {
        var largo = height - 2 * margen
        var crudo = 1 - (y - _desfase - margen) / largo
        var fuera = crudo > 1 ? (crudo - 1) : (crudo < 0 ? crudo : 0)
        // tope elástico: cuanto más jalas, menos cede
        _goma = fuera === 0 ? 0 : -Math.sign(fuera) * 12 * (1 - 1 / (Math.abs(fuera) * largo / 50 + 1))
        var v = Math.max(0, Math.min(1, crudo)), enc = -1
        for (var i = 0; i < imanes.length; i++) if (Math.abs(v - imanes[i]) < radioIman) { v = imanes[i]; enc = v }
        if (enc >= 0 && enc !== _imanActual) { pulsoIman = 1; encaja(enc) }
        _imanActual = enc
        _arrastre = v
        _pide(v)
    }

    Keys.onPressed: ev => {
        var k = ev.key
        if (k === Qt.Key_Up || k === Qt.Key_Right) _paso(1, paso)
        else if (k === Qt.Key_Down || k === Qt.Key_Left) _paso(-1, paso)
        else if (k === Qt.Key_PageUp) _paso(1, pasoGrande)
        else if (k === Qt.Key_PageDown) _paso(-1, pasoGrande)
        else if (k === Qt.Key_Home) _pide(0)
        else if (k === Qt.Key_End) _pide(1)
        else if ((k === Qt.Key_Space || k === Qt.Key_Return) && preferido >= 0) { _rebote = true; _pide(preferido) }
        else return
        ev.accepted = true
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        onPressed: m => {
            n.forceActiveFocus(Qt.MouseFocusReason)
            var yk = n.yDe(n._pend >= 0 ? n._pend : n.value)
            n._desfase = Math.abs(m.y - yk) <= n.radioPerilla + 3 ? (m.y - yk) : 0   // agarrar la perilla no la hace saltar
            n._arrastre = n.pos; n._imanActual = -1
            n._mueve(m.y)
        }
        onPositionChanged: m => { if (pressed) n._mueve(m.y); else n.despierta() }
        onReleased: { n._goma = 0; n._rebote = true; n.despierta() }
        onCanceled: { n._goma = 0; n.despierta() }
        onDoubleClicked: if (n.preferido >= 0) { n._rebote = true; n._pide(n.preferido) }
        onWheel: w => {
            n._rueda += w.angleDelta.y
            n._ruedaViva = true; ruedaT.restart()
            while (Math.abs(n._rueda) >= 120) { var d = n._rueda > 0 ? 1 : -1; n._rueda -= d * 120; n._paso(d, n.paso) }
            n.despierta()
        }
    }

    FrameAnimation {
        running: n.visible && !n.quieto && n.energiaFija < 0
        onTriggered: n._avanza(Math.min(0.05, frameTime))
    }

    function _avanza(dt) {
        var objetivo = presionado ? _arrastre : value
        var antes = pos
        if (reducirMovimiento) { pos = objetivo; _velPos = 0; empuje = presionado ? _goma : 0; _velEmp = 0 }
        else {
            // muelle: rígido y sin rebote al arrastrar o con teclas; un rebote leve solo al soltar / doble clic
            var w = presionado ? 120 : (_rebote ? 30 : 55), z = (!presionado && _rebote) ? 0.55 : 1.0
            var pasos = Math.ceil(dt / 0.003), h = dt / pasos, p = pos, vp = _velPos, em = empuje, ve = _velEmp
            var objE = presionado ? _goma : 0
            for (var i = 0; i < pasos; i++) {
                vp += (w * w * (objetivo - p) - 2 * z * w * vp) * h; p += vp * h
                ve += (1600 * (objE - em) - 2 * 0.5 * 40 * ve) * h; em += ve * h
            }
            if (Math.abs(objetivo - p) < 0.0003 && Math.abs(vp) < 0.003) { p = objetivo; vp = 0; if (!presionado) _rebote = false }
            if (Math.abs(objE - em) < 0.02 && Math.abs(ve) < 0.5) { em = objE; ve = 0 }
            pos = p; _velPos = vp; empuje = em; _velEmp = ve
        }
        vel = dt > 0 ? (pos - antes) / dt : 0
        var k = 1 - Math.exp(-dt * 16)
        estira += ((reducirMovimiento ? 0 : Math.max(-1, Math.min(1, vel / 2.6))) - estira) * k
        if (Math.abs(estira) < 0.002) estira = 0
        var objEn = (presionado || siesta.running || despiertoExterno) ? 1 : 0
        energia += (objEn - energia) * (1 - Math.exp(-dt * (objEn > energia ? 12 : 2.6)))
        if (objEn === 0 && energia < 0.004) energia = 0
        aprieta += ((presionado ? 1 : 0) - aprieta) * (1 - Math.exp(-dt * 26))
        if (!presionado && aprieta < 0.004) aprieta = 0
        var objT = (presionado || _ruedaViva) ? 1 : 0
        tocando += (objT - tocando) * (1 - Math.exp(-dt * (objT ? 22 : 9)))
        if (objT === 0 && tocando < 0.004) tocando = 0
        pulsoIman *= Math.exp(-dt * 6); if (pulsoIman < 0.004) pulsoIman = 0
        if (!reducirMovimiento) t += dt * (0.25 + 0.75 * energia)
        tick(dt)
        if (objEn === 0 && energia === 0 && pos === objetivo && _velPos === 0 && empuje === 0 && _velEmp === 0
            && !ocupado && estira === 0 && aprieta === 0 && tocando === 0 && pulsoIman === 0) quieto = true
    }
}
