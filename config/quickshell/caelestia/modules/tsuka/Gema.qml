import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.services
import "metal.js" as Metal

// Gema del mango (TSUKA-DISENO §4.2b): piedra tallada en rombo engastada en una ventana del tejido.
// 0 apagada (piedra en bruto) · 1 encendida (toma gc) · 2 te llama (hueso alto, aro grueso). Nunca rojo.
// "mantener" (casa y cine): el aro se recorre en 480 ms; soltar antes cancela.
Item {
    id: root

    property color apagadoM: Espada.apagado

    property color tenueM: Espada.tenue

    property string nombre: ""
    property int valor: 0
    property color colorGema: "#adc9ea"
    // v3: colores del mango de este monitor (Mat.mango: base = tela, marco)
    property var mango: null
    property bool mantener: false
    property bool sobre: area.containsMouse
    property real progreso: 0
    signal accion

    readonly property color tono: valor === 2 ? Espada.huesoAlto : colorGema

    width: 56
    height: 48

    onValorChanged: if (Espada.mov) entra.restart()
    NumberAnimation { id: entra; target: cuerpo; property: "scale"; from: 0.86; to: 1; duration: 220; easing.type: Easing.BezierSpline; easing.bezierCurve: Espada.cFilo }

    // ── v3 mejora 4: gema tallada (port de gema(c, y, on, glifo, ahora) del prototipo v3, sin el destello en cruz) ──
    // Dos Canvas que se repintan SOLO al cambiar de estado o de colores: la luz propia sobre la piel (aditiva)
    // y la piedra (engaste de metal oscuro con sombra, corona de 8 facetas y mesa). En reposo no corre nada.
    readonly property bool encendida: valor > 0
    Canvas {
        anchors.fill: parent
        opacity: root.encendida ? 1 : 0
        visible: opacity > 0.01
        renderTarget: Canvas.Image
        renderStrategy: Canvas.Cooperative
        layer.enabled: true
        layer.effect: ShaderEffect {
            fragmentShader: Qt.resolvedUrl("aditivo.frag.qsb")
        }
        Behavior on opacity { NumberAnimation { duration: Espada.dColor } }
        readonly property color c: root.tono
        onCChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            Metal.gemaLuz(ctx, Metal.deColor(root.tono));
        }
    }

    Item {
        id: cuerpo
        anchors.fill: parent
        scale: area.pressed ? 0.92 : 1
        Behavior on scale { NumberAnimation { duration: Espada.dToque } }

        Canvas {
            anchors.fill: parent
            renderTarget: Canvas.Image
            renderStrategy: Canvas.Cooperative
            readonly property var firma: [root.encendida, root.tono, root.mango ? root.mango.telaHex + root.mango.marcoHex : ""]
            onFirmaChanged: requestPaint()
            onPaint: {
                if (!root.mango)
                    return;
                const ctx = getContext("2d");
                ctx.reset();
                Metal.gema(ctx, root.encendida, Metal.deColor(root.tono), root.mango);
            }
        }

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            // canto de la piedra: hueso con el cursor encima; hueso alto y grueso cuando te llama
            ShapePath {
                strokeColor: root.valor === 2 ? Espada.huesoAlto : root.sobre ? Qt.alpha(Espada.hueso, 0.85) : "transparent"
                strokeWidth: root.valor === 2 ? 1.6 : 1
                fillColor: "transparent"
                joinStyle: ShapePath.MiterJoin
                PathSvg { path: "M28 12L42 24L28 36L14 24Z" }
            }
            // mantener: el aro se recorre desde el vértice superior
            ShapePath {
                strokeColor: root.progreso > 0 ? Espada.huesoAlto : "transparent"
                strokeWidth: 1.6
                fillColor: "transparent"
                joinStyle: ShapePath.MiterJoin
                PathSvg {
                    path: {
                        const pts = [[28, 12], [42, 24], [28, 36], [14, 24], [28, 12]];
                        const total = root.progreso * 4;
                        let d = "M28 12";
                        for (let i = 0; i < 4 && i < total; i++) {
                            const f = Math.min(1, total - i), a = pts[i], b = pts[i + 1];
                            d += `L${(a[0] + (b[0] - a[0]) * f).toFixed(2)} ${(a[1] + (b[1] - a[1]) * f).toFixed(2)}`;
                        }
                        return d;
                    }
                }
            }
        }

        // 11-17 «A · Brasa» (diseno-fable/gemas-legibles): símbolo de 11 px y trazo 1.9 en los dos estados.
        // Encendida: claro (col→ALTO .78) con resplandor del color (Canvas: blur 3, .9) sobre la piedra honda.
        // Apagada: mez(base×1.9, marco, .5) al .96; con el cursor encima, hueso.
        Item {
            // margen de 4 px para que el resplandor no se recorte en la capa
            x: 28 - 5.5 - 4
            y: 24 - 5.5 - 4
            width: 19
            height: 19
            layer.enabled: root.encendida
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(root.tono.r, root.tono.g, root.tono.b, 0.9)
                shadowBlur: 0.5
                blurMax: 6
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 0
            }

            Ico {
                x: 4
                y: 4
                tam: 11
                grosor: 1.9
                nombre: Espada.ico[root.nombre] ? root.nombre : (({ zangetsu: "servidor", stream: "pantalla", apagado: "arena" })[root.nombre] ?? "ventana")
                color: {
                    const c = root.tono, A = [255, 250, 240];
                    if (root.valor)
                        return Qt.rgba((c.r * 255 * 0.22 + A[0] * 0.78) / 255, (c.g * 255 * 0.22 + A[1] * 0.78) / 255, (c.b * 255 * 0.22 + A[2] * 0.78) / 255, 1);
                    if (root.sobre)
                        return Espada.hueso;
                    if (!root.mango)
                        return root.apagadoM;
                    const b = root.mango.base, m = root.mango.marco, f = (i) => Math.min(1, (Math.min(255, b[i] * 1.9) * 0.5 + m[i] * 0.5) / 255);
                    return Qt.rgba(f(0), f(1), f(2), 0.96);
                }
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: if (root.mantener) llenar.restart()
        onReleased: {
            if (root.mantener) {
                if (llenar.running) {
                    llenar.stop();
                    vaciar.restart();
                }
            }
        }
        onCanceled: if (root.mantener) { llenar.stop(); vaciar.restart(); }
        onClicked: if (!root.mantener) root.accion()
    }
    NumberAnimation {
        id: llenar
        target: root; property: "progreso"; from: 0; to: 1; duration: 480
        onFinished: { root.accion(); vaciar.restart(); }
    }
    NumberAnimation { id: vaciar; target: root; property: "progreso"; to: 0; duration: 160 }
}
