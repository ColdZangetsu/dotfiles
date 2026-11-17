import QtQuick
import QtQuick.Shapes
import qs.services
import "metal.js" as Metal

// El ojo de Nero (TSUKA-DISENO §4.1): caja de 56 x 44, toda su forma sale de cuatro números
// a (apertura 0-1), x / y (mirada), p (pupila). Port de dibujaOjo() del prototipo.
// Solo se re-tesela mientras cambian esos números (transición de estado, seguir al cursor, parpadeo).
Item {
    id: root

    property string estado: "vigila"
    property color eco: "#adc9ea"
    property bool dormido: false       // arranque y retirada: cerrado sin importar el estado
    property bool sobrePomo: false     // cursor en la kashira: párpado en hueso
    // mirada que sigue al cursor (null = no sigue)
    property var mira: null

    readonly property var meta: {
        const t = {
            duerme: [0, 0, 0, 1],
            vigila: [0.42, 0, 0, 1],
            escucha: [1, 0, 0, 1.6],
            trabaja: [1, 0, 2, 1],
            escribio: [1, 7, 0, 1]
        };
        const o = (t[dormido ? "duerme" : estado] ?? t.vigila).slice();
        if (mira && !dormido && estado !== "duerme") {
            o[0] = Math.max(o[0], 0.86);
            if (estado !== "escribio") {
                o[1] = mira[0];
                o[2] = mira[1];
            }
        }
        return o;
    }

    // los cuatro números: se interpolan 200 ms con salida cúbica; mientras sigue al cursor van directo
    property bool directo: false
    property int dur: Espada.dOjo
    property real a: meta[0]
    property real mx: meta[1]
    property real my: meta[2]
    property real p: meta[3]
    property real cierre: 1            // parpadeo: 1 abierto -> 0 -> 1
    readonly property real ap: a * cierre

    Behavior on a { enabled: !root.directo; NumberAnimation { duration: root.dur; easing.type: Easing.OutCubic } }
    Behavior on mx { enabled: !root.directo; NumberAnimation { duration: root.dur; easing.type: Easing.OutCubic } }
    Behavior on my { enabled: !root.directo; NumberAnimation { duration: root.dur; easing.type: Easing.OutCubic } }
    Behavior on p { enabled: !root.directo; NumberAnimation { duration: root.dur; easing.type: Easing.OutCubic } }

    onMiraChanged: {
        if (mira && !directo && !entrar.running) {
            dur = Espada.mov ? 160 : 0;
            entrar.restart();
        } else if (!mira) {
            entrar.stop();
            directo = false;
            dur = Espada.dOjo;
        }
    }
    Timer {
        id: entrar
        interval: 170
        onTriggered: root.directo = true
    }

    function parpadea(): void {
        if (!Espada.mov)
            return;
        parpadeo.restart();
    }
    SequentialAnimation {
        id: parpadeo
        NumberAnimation { target: root; property: "cierre"; to: 0; duration: 80; easing.type: Easing.InQuad }
        PauseAnimation { duration: 10 }
        NumberAnimation { target: root; property: "cierre"; to: 1; duration: 140; easing.type: Easing.OutCubic }
    }

    readonly property real u: 30 - 32 * ap
    readonly property real l: 30 + 16 * ap
    // v3 (mejora 2): párpado de metal del color del marco; despierto o con el cursor encima se aclara hacia hueso
    property color marco: "#b6c1ce"
    readonly property int parpado: estado === "duerme" || dormido ? -1 : (estado === "vigila" && !sobrePomo ? 0 : 1)

    width: 56
    height: 44

    // ── v3 mejora 2: el ojo vivo (port de ojo(c, ahora) del prototipo v3) ──
    // Canvas que se repinta SOLO cuando cambian los números del ojo (transición, seguir al cursor, parpadeo);
    // en reposo no corre nada. Su resplandor sobre el pomo va aparte, aditivo, pintado una vez por color.
    Canvas {
        id: luz
        y: -6
        width: 56
        height: 56
        opacity: Math.min(1, root.ap * 3)
        visible: opacity > 0.01
        renderTarget: Canvas.Image
        renderStrategy: Canvas.Cooperative
        layer.enabled: true
        layer.effect: ShaderEffect {
            fragmentShader: Qt.resolvedUrl("aditivo.frag.qsb")
        }
        readonly property color c: root.eco
        onCChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.translate(0, 6);
            Metal.ojoLuz(ctx, Metal.deColor(root.eco));
        }
    }
    Canvas {
        id: lienzo
        y: -2
        width: 56
        height: 48
        renderTarget: Canvas.Image
        renderStrategy: Canvas.Cooperative
        readonly property var numeros: [root.ap, root.mx, root.my, root.p, root.parpado, root.eco, root.marco]
        onNumerosChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.translate(0, 2);
            Metal.ojo(ctx, { a: root.ap, x: root.mx, y: root.my, p: root.p, eco: Metal.deColor(root.eco), marco: Metal.deColor(root.marco), parpado: root.parpado });
        }
    }

    // párpados, pestañas (dormida) y ondas (escucha)
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: Qt.alpha(Espada.apagado, Math.max(0, 1 - root.ap * 5))
            strokeWidth: 1
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathSvg { path: "M17 28.4l-1.4 3 M28 30.2v3.2 M39 28.4l1.4 3" }
        }
        ShapePath {
            strokeColor: Qt.alpha(Espada.hueso, root.estado === "escucha" && !root.dormido ? 0.7 : 0)
            strokeWidth: 1
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathSvg { path: "M3.5 17a8 8 0 0 0 0 10 M52.5 17a8 8 0 0 1 0 10" }
        }
    }

}
