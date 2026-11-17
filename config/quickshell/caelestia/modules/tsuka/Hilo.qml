pragma ComponentBehavior: Bound

import QtQuick
import "hilo.js" as H

// 11-15 El hilo rojo del cordón (diseño Fable aprobado: tsuka-transicion-elementos, DISENO.md §1).
// Dos muelles (las puntas a y b) y todo lo demás derivado. En reposo no corre nada: los lienzos se quedan como
// quedaron (el activo eclipsado, con su filo y su corona). Solo durante un cambio (~1.3 s) corre un FrameAnimation,
// con tope de 120 repintados por segundo.
// Origen de este Item = g.cord0 (arriba del cordón); la fila k del cordón ocupa [48k, 48k + 48].
// Capas: `bajo` (luz aditiva) y `medio` (normal) van debajo de los kanji; `sobre` (luz aditiva) encima: ver Tsuka.qml.
Item {
    id: hilo

    property int nf: 1                 // filas con función (零, escritorios, especial)
    property int act: -1               // fila activa (-1: ninguna)
    property color eco: "#a9c7ff"
    property bool foco: true
    property bool movimiento: true
    readonly property real sombraReposo: 0.8   // el activo en reposo: eclipsado (lo aprobado)

    // lo que leen los kanji (sube en cada cuadro pintado)
    property int cuadro: 0
    function luz(k: int): real {
        return est.e ? (est.e.luz[k] ?? 0) : 0;
    }
    function cubre(k: int): real {
        return est.e && est.e.sombra > 0.004 ? H.cubre(est.e, k) * Math.min(1, est.e.sombra / 0.5) : 0;
    }
    readonly property real golpe: est.golpe
    readonly property int dir: est.dir

    // los kanji (los pone Tsuka.qml) van entre la luna negra y la luz de encima
    default property alias kanjis: ranura.data

    QtObject {
        id: est
        property var e: null
        property real t: 0
        property real ultimo: -1e9
        property bool corre: false
        property real golpe: 0
        property int dir: 1
        property bool bajoSucio: false
        property bool sinAct: true
    }

    function reinicia(): void {
        est.e = H.nuevo(Math.max(0, act), Math.max(1, nf), act >= 0 ? sombraReposo : 0);
        est.sinAct = act < 0;
        est.corre = false;
        pintaTodo();
    }
    function irA(n: int): void {
        if (!est.e || est.e.NF !== nf || est.sinAct) {
            reinicia();
            return;
        }
        if (n < 0)
            return;
        if (!movimiento) {
            H.salta(est.e, n);
            est.e.quieto = true;
            pintaTodo();
            return;
        }
        H.irA(est.e, n, est.t, foco);
        est.corre = true;
    }
    function tope(d: int): void {
        if (!est.e || !movimiento)
            return;
        H.tope(est.e, d);
        est.corre = true;
    }
    onActChanged: irA(act)
    onNfChanged: reinicia()
    onFocoChanged: pintaTodo()
    onEcoChanged: pintaTodo()
    Component.onCompleted: reinicia()

    function pintaTodo(): void {
        if (!est.e)
            return;
        est.golpe = est.e.golpe;
        est.dir = est.e.dir;
        cuadro++;
        medio.requestPaint();
        sobre.requestPaint();
        if (est.bajoSucio || H.hayBajo(est.e, est.t))
            bajo.requestPaint();
    }

    FrameAnimation {
        running: est.corre && hilo.visible
        onTriggered: {
            const e = est.e;
            let dt = Math.min(50, frameTime * 1000);
            while (dt > 1e-6) {
                const h = Math.min(2, dt);
                dt -= h;
                est.t += h;
                H.paso(e, h / 1000, est.t, hilo.sombraReposo);
            }
            if (e.quieto && !H.hayBajo(e, est.t))
                est.corre = false;
            // repintados: hasta 120/s mientras el hilo corre (≈ 300 ms; la ASUS va a 280 Hz), 60/s mientras llega y
            // se asienta, 24/s en la cola (halo y corona que se apagan). Entre repintados no cambia nada en la escena,
            // así la ventana tampoco se vuelve a dibujar. El último cuadro siempre se pinta.
            const edad = est.t - e.tCambio;
            const minimo = edad < 300 ? 8.2 : edad < 650 ? 16.4 : 41;
            if (!est.corre || est.t - est.ultimo >= minimo) {
                est.ultimo = est.t;
                hilo.pintaTodo();
            }
        }
    }

    readonly property var q: ({ L: height, eco: [eco.r * 255, eco.g * 255, eco.b * 255], foco: foco })

    component Lienzo: Canvas {
        width: hilo.width
        height: hilo.height
        renderTarget: Canvas.Image
        renderStrategy: Canvas.Cooperative
    }
    component Aditivo: ShaderEffect {
        fragmentShader: Qt.resolvedUrl("aditivo.frag.qsb")
    }

    Lienzo {
        id: bajo
        // en reposo queda vacío: ni se compone
        visible: est.corre || est.bajoSucio
        layer.enabled: true
        layer.effect: Aditivo {}
        onPaint: {
            const c = getContext("2d");
            c.reset();
            if (!est.e)
                return;
            c.globalCompositeOperation = "lighter";
            H.pintaBajo(c, est.e, est.t, hilo.q);
            est.bajoSucio = H.hayBajo(est.e, est.t);
        }
    }
    Lienzo {
        id: medio
        onPaint: {
            const c = getContext("2d");
            c.reset();
            if (est.e)
                H.pintaMedio(c, est.e, est.t, hilo.q);
        }
    }
    Item {
        id: ranura
        width: hilo.width
        height: hilo.height
    }
    Lienzo {
        id: sobre
        visible: est.corre
        layer.enabled: true
        layer.effect: Aditivo {}
        onPaint: {
            const c = getContext("2d");
            c.reset();
            if (!est.e)
                return;
            c.globalCompositeOperation = "lighter";
            H.pintaSobre(c, est.e, est.t, hilo.q);
        }
    }
}
