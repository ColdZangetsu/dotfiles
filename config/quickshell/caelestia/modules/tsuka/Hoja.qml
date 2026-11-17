pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "elementos.js" as El

// 11-15 La hoja viva con su elemento (diseño Fable aprobado: tsuka-transicion-elementos, DISENO.md §2).
// Acero + elemento = UN material: hoja.frag (ShaderEffect) con el campo de distancias de la forma (elementos.js).
// Va en su propia ventanita (capa Bottom, debajo del resto de Tsuka) para que cada cuadro de la hoja viva repinte
// solo 56 × ~134 px y no la ventana de pantalla completa de los cajones.
// Origen de este Item = arriba de la hoja visible (hab0 + 18 de la barra), como hojaG en Tsuka.qml.
Item {
    id: hoja

    // ── lo que da Tsuka ──
    property string el: "agua"          // agua | fuego | viento
    property real largo: 134            // alto visible de la hoja (H - hab0 - 18)
    property color eco: "#a9c7ff"
    property string telaHex: "#29415b"
    property bool sobre: false          // cursor encima (empuñar)
    property bool tirando: false
    property real dy: 0                 // jalón 0..18
    property bool viva: true            // la luz se mueve en reposo (tsuka.json "hojaViva")
    property bool pausa: false          // modo trabajo, inactivo, retirada…: congelada
    property int fps: 30                // cuadros por segundo de la hoja viva EN REPOSO (al tocarla va a los del monitor)
    property bool movimiento: true

    // ── lo que lee Tsuka ──
    readonly property real baja: est.baja      // cuánto baja la hoja (px)
    readonly property real carga: est.c        // 0..1 (nivel de luz al jalar)
    readonly property bool lista: sdfImg.status === Image.Ready

    readonly property var gh: El.geoHoja(largo)
    // la ruta se fija 250 ms después de que se asiente la geometría (al arrancar el alto llega en pasos)
    readonly property string rutaPedida: largo > 60 && largo < 400 && el ? Quickshell.env("HOME") + "/.cache/caelestia/tsuka-sdf-v" + El.VERSION + "-" + el + "-" + Math.round(largo) + ".bmp64" : ""
    property string rutaSdf: ""
    onRutaPedidaChanged: asienta.restart()
    Component.onCompleted: asienta.restart()
    Timer {
        id: asienta
        interval: 250
        onTriggered: hoja.rutaSdf = hoja.rutaPedida
    }

    function pulso(dur: int, intensidad: real): void {
        if (!movimiento)
            return;
        est.pulso = { t0: est.t, dur: dur, I: intensidad };
        despierta();
    }
    function despierta(): void {
        est.activo = true;
    }

    // estado (port de E2/paso2 del prototipo)
    QtObject {
        id: est
        property real t: 0
        property real baja: 0
        property real vb: 0
        property real c: 0
        property bool rapido: false
        property var pulso: null
        property real fase: 0
        property bool activo: false
        property real nivel: 0
        property real py: 0
        property real pi: 0
    }
    onSobreChanged: {
        if (sobre && !tirando)
            pulso(700, 0.95);
        despierta();
    }
    onTirandoChanged: {
        if (!tirando)
            est.rapido = dy >= 12 || dy < 2; // soltó con tajo: la carga se descarga rápido (τ 110 ms)
        despierta();
    }
    onDyChanged: despierta()

    function paso(dtS: real): void {
        let dt = Math.min(0.05, Math.max(0, dtS)) * 1000;
        const obj = tirando ? 3 + dy : (sobre ? 3 : 0);
        const co = tirando ? Math.max(0, Math.min(1, dy / 18)) : 0;
        if (tirando)
            est.rapido = false;
        let T = est.t, b = est.baja, vb = est.vb, c = est.c, fase = est.fase;
        while (dt > 1e-6) {
            const h = Math.min(2, dt);
            dt -= h;
            T += h;
            const s = h / 1000;
            if (tirando || !movimiento) {
                b = obj;
                vb = 0;
            } else {
                vb += (-30 * 30 * (b - obj) - 2 * 0.55 * 30 * vb) * s;
                b += vb * s;
            }
            c += (co - c) * (1 - Math.exp(-s / (co > c ? 0.07 : est.rapido ? 0.11 : 0.3)));
            fase += s * (0.3 + 1.5 * c + (est.pulso ? 0.5 : 0));
        }
        if (est.pulso && T - est.pulso.t0 > est.pulso.dur)
            est.pulso = null;
        let py = 0, pi = 0;
        if (est.pulso) {
            const uu = (T - est.pulso.t0) / est.pulso.dur;
            py = (El.Y0 - 26) + (gh.H2 + 30 - (El.Y0 - 26)) * uu * uu * (3 - 2 * uu);
            pi = est.pulso.I * Math.sin(Math.PI * Math.min(1, uu * 1.02));
        }
        const quieto = !tirando && !est.pulso && Math.abs(b - obj) < 0.03 && Math.abs(vb) < 0.5 && c < 0.004;
        if (quieto) {
            b = obj;
            vb = 0;
            c = 0;
        }
        est.t = T;
        est.baja = b;
        est.vb = vb;
        est.c = c;
        est.fase = fase;
        est.py = py;
        est.pi = pi;
        est.nivel = Math.max(0, Math.min(1, c * 1.1));
        if (el === "fuego" && (c > 0.004 || pavesas.pintadas))
            pavesas.requestPaint();
        if (quieto)
            est.activo = false;
    }

    // tocándola: a los cuadros del monitor; en reposo: a `fps` (la luz de adentro es lenta) o quieta
    FrameAnimation {
        running: est.activo && hoja.lista && hoja.visible
        onTriggered: hoja.paso(frameTime)
    }
    Timer {
        interval: Math.round(1000 / Math.max(1, hoja.fps))
        repeat: true
        running: !est.activo && hoja.viva && !hoja.pausa && hoja.movimiento && hoja.lista && hoja.visible
        onTriggered: hoja.paso(interval / 1000)
    }

    // ── el material ──
    ShaderEffect {
        id: mat
        y: hoja.gh.YT - El.Y0 // -30
        width: 56
        height: hoja.gh.YF - hoja.gh.YT
        visible: hoja.lista
        blending: true
        vertexShader: Qt.resolvedUrl("hoja.vert.qsb")
        fragmentShader: Qt.resolvedUrl("hoja.frag.qsb")
        property var uSdf: sdfImg
        property real uSB: El.SB
        property real uYT: hoja.gh.YT
        property real uY0: El.Y0
        property real uH2: hoja.gh.H2
        property real uFase: est.fase
        property real uNivel: est.nivel
        property real uPY: est.py
        property real uPI: est.pi
        property real uTime: est.t / 1000
        property real uEl: El.codigo(hoja.el)
        property vector2d uRes: Qt.vector2d(hoja.gh.w, hoja.gh.h)
        property vector3d uEco: Qt.vector3d(hoja.eco.r * 255, hoja.eco.g * 255, hoja.eco.b * 255)
        property vector3d uTemple: Qt.vector3d(255 + (hoja.eco.r * 255 - 255) * 0.62, 250 + (hoja.eco.g * 255 - 250) * 0.62, 240 + (hoja.eco.b * 255 - 240) * 0.62)
        readonly property color telaC: hoja.telaHex
        property vector3d uBase: Qt.vector3d(telaC.r * 255, telaC.g * 255, telaC.b * 255)
        property vector3d uTinte: Qt.vector3d(198 + (hoja.eco.r * 255 - 198) * 0.1, 207 + (hoja.eco.g * 255 - 207) * 0.1, 224 + (hoja.eco.b * 255 - 224) * 0.1)
    }

    // ── campo de distancias: del disco si ya existe (BMP en base64, ~1 MB de texto); si no, se calcula una vez ──
    // (≈ 0.2 s) y se guarda. La forma no depende del color: uno por elemento y por largo de hoja.
    property bool sinCampo: false
    FileView {
        id: archivoSdf
        path: hoja.rutaSdf
        blockLoading: false
        printErrors: false
        onLoaded: {
            hoja.sinCampo = false;
            sdfImg.source = "data:image/bmp;base64," + text();
        }
        onLoadFailed: {
            hoja.sinCampo = true;
            generador.requestPaint();
        }
    }
    Image {
        id: sdfImg
        visible: false
        cache: false
        smooth: false
        mipmap: false
    }
    Canvas {
        id: generador
        width: hoja.gh.w
        height: hoja.gh.h
        visible: hoja.sinCampo
        opacity: 0
        renderTarget: Canvas.Image
        renderStrategy: Canvas.Immediate
        onPaint: {
            if (!hoja.sinCampo)
                return;
            const t0 = Date.now();
            const g = hoja.gh;
            const ctx = getContext("2d");
            ctx.reset();
            ctx.fillStyle = "#ffffff";
            ctx.save();
            ctx.scale(g.SB, g.SB);
            ctx.translate(0, -g.YT);
            El.pintaForma(ctx, hoja.el, g.H2);
            ctx.restore();
            const img = ctx.getImageData(0, 0, g.w, g.h);
            const sal = new Uint8Array(g.w * g.h * 4);
            El.campo(img.data, g.w, g.h, sal);
            const b64 = El.bmp64(sal, g.w, g.h);
            ctx.reset();
            hoja.sinCampo = false;
            sdfImg.source = "data:image/bmp;base64," + b64;
            archivoSdf.setText(b64);
            console.info(`tsuka: campo de distancias ${hoja.el} (${g.w}x${g.h}, lienzo ${img.width}x${img.height}) ${Date.now() - t0} ms`);
        }
    }

    // ── fuego al jalar: el filo al rojo y cinco pavesas (vivo2 del prototipo). Solo pinta mientras hay carga ──
    Canvas {
        id: pavesas
        property bool pintadas: false
        visible: hoja.el === "fuego"
        y: hoja.gh.YT - El.Y0
        width: 56
        height: hoja.gh.YF - hoja.gh.YT
        renderTarget: Canvas.Image
        renderStrategy: Canvas.Cooperative
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const k = est.c;
            pintadas = k > 0.004;
            if (!pintadas)
                return;
            ctx.translate(0, -hoja.gh.YT);
            El.vivoFuego(ctx, k, est.t, hoja.gh);
        }
    }
}
