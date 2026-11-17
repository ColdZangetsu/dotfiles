pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications
import Caelestia.Config
import qs.components
import qs.services
import qs.utils
import qs.modules.tsuka
import qs.modules.osd as Osd
import "../tsuka/material.js" as Mat
import "laca.js" as Laca

// 11-15 Saya 鞘, la vaina: barra derecha (diseño Fable, SAYA-DISENO.md + COMUN.md + tsuka-saya-final.html).
// 8 px en reposo (laca, boca = Nero, pasador y cordón = música, incrustación = luz, rayas = avisos, contera).
// Cursor 140 ms en el borde (o clic) = se desenvaina el bloque de 148 px con las cuatro secciones.
// Sección Barras: Amanecer · Reiatsu · Eclipse de modules/osd (las mismas, SIN redibujar) a escala s.bs, en fila,
// quietas en reposo; con la vaina guardada el OSD saca solo la barra tocada en una lengüeta de 64 px (misma instancia).
// Material pintado una vez (material.js); lo vivo solo cambia con eventos. Ver TSUKA-SAYA.md.
Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property bool fullscreen

    readonly property bool activa: TsukaConf.saya
    readonly property HyprlandMonitor monitor: Hypr.monitorFor(screen)
    readonly property bool esLG: (monitor?.lastIpcObject?.description ?? "").indexOf("LG") >= 0
    readonly property bool compacta: height > 0 && height < 600
    readonly property color eco: {
        const p = Colours.of(QsWindow.window ?? root).palette;
        // paleta de wallmux de ESTE monitor (cambia en vivo con el fondo); el material se repinta solo entonces
        return Espada.ecoSeguro(esLG ? p.m3tertiaryFixed : p.m3primary);
    }
    readonly property string ecoHex: Espada.hex(eco)
    // v3 (mejoras 8 y 9): la laca y el nashiji toman la tela oscura y el marco clarito del fondo, como el mango (Mat.mango)
    readonly property var colMango: {
        const p = Colours.of(QsWindow.window ?? root).palette;
        return Mat.mango(Espada.hex(esLG ? p.m3tertiaryFixedDim : p.m3primaryFixedDim), Espada.hex(esLG ? p.m3onTertiaryFixedVariant : p.m3onPrimaryFixedVariant));
    }
    readonly property color cBase: Qt.rgba(colMango.base[0] / 255, colMango.base[1] / 255, colMango.base[2] / 255, 1)
    readonly property string hilosVuelta: Laca.hilos(10, 2.6)
    readonly property color marco: colMango.marcoHex
    readonly property real dpr: (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1
    readonly property var g: Mat.geo(Math.max(height, 300), compacta, 0)
    readonly property var s: g.s
    readonly property bool listo: activa && height > 200
    readonly property real borde: width     // borde derecho del monitor

    // "solo habla una": lenguas solo en el monitor con foco (o el primero visible si ese está en pantalla completa)
    readonly property bool habla: {
        const _f = Hyprland.focusedMonitor;
        const _w = Hypr.workspaces.values.length;
        return Espada.monitorQueHabla() === screen.name;
    }
    readonly property bool conFoco: Hyprland.focusedMonitor === monitor

    readonly property int anchoBloque: 148
    readonly property int anchoOsd: 64
    readonly property real bs: s.bs ?? 0.5

    width: anchoBloque + 340 + 16
    visible: activa

    // ── estado ──
    property bool sobreVaina: false
    property bool sobreBloque: false
    property bool sobreLengua: false
    property bool sobreDetalle: false
    property bool fija: false            // clic o IPC: queda desenvainada hasta salir
    property bool hoverAbierta: false
    readonly property bool abierta: (hoverAbierta || fija) && !fullscreen && retiro === 0
    property string seccionSobre: ""
    property bool detalle: false
    property string osd: ""             // "" | "luz": la sección Barras sale sola como OSD
    property string osdQue: ""          // volumen | luces | brillo: la barra tocada
    property real mano: 0               // última vez que se movió una barra con la mano (no atenúa a las otras)

    // lo que Regions.qml suma a la máscara de entrada: [margen derecho, y, ancho, alto]
    readonly property var zonaBloque: {
        if (!listo)
            return [0, 0, 0, 0];
        if (abierta)
            return [0, 0, anchoBloque, s.fin];
        if (osd)
            return [0, s.luz[0], anchoOsd, s.luz[1]];
        return [0, 0, 0, 0];
    }
    // de dónde sale la lengua: del bloque, de la lengüeta del OSD (si es de su sección) o de la vaina
    readonly property real bordeLengua: abierta ? anchoBloque : (osd && lengua.sec === "luz" ? anchoOsd : 8)
    readonly property var zonaLengua: lengua.fuera ? [bordeLengua, asomo.y, asomo.width, 38] : [0, 0, 0, 0]
    readonly property var zonaDetalle: detalle && abierta ? [anchoBloque, 0, cajaDetalle.width, cajaDetalle.height] : [0, 0, 0, 0]

    // un solo detector para todo lo que sale de la vaina (borde, bloque, secciones, lengua, detalle):
    // la máscara de entrada solo deja pasar el cursor por esas piezas
    HoverHandler {
        id: sobreSaya
        onHoveredChanged: {
            root.sobreBloque = hovered;
            if (hovered)
                tCerrar.stop();
            else
                root.alSalir();
        }
    }
    function alSalir(): void {
        tAbrir.stop();
        if (!sobreVaina && !sobreBloque && !sobreLengua && !sobreDetalle)
            tCerrar.restart();
    }
    Timer {
        id: tAbrir
        interval: Espada.esperaAbrir
        onTriggered: if (root.sobreVaina) root.hoverAbierta = true
    }
    Timer {
        id: tCerrar
        interval: Espada.esperaCerrar
        onTriggered: {
            if (root.sobreVaina || root.sobreBloque || root.sobreLengua || root.sobreDetalle)
                return;
            root.hoverAbierta = false;
            root.fija = false;
            root.detalle = false;
            tLeer.stop();
        }
    }
    Timer {
        id: tLeer
        interval: 700
        onTriggered: TsukaConf.leido()
    }

    // ── lenguas ──
    function sacarLengua(sec: string, rot: string, txt: string, ms: int, filoColor: color): void {
        if (!listo || fullscreen || !habla)
            return;
        if (sec === "nero" && !TsukaConf.lenguas)
            return;
        lengua.sec = sec;
        lengua.rot = rot;
        lengua.txt = txt;
        lengua.filo = filoColor;
        lengua.fuera = false;
        lengua.fuera = true;
        if (Espada.mov)
            lenguaBrillo.restart();
        if (sec === "nero" && Espada.mov)
            destelloBoca.restart();
        tLengua.interval = ms;
        tLengua.restart();
    }
    function guardarLengua(): void {
        tLengua.stop();
        lengua.fuera = false;
    }
    Timer {
        id: tLengua
        onTriggered: {
            if (root.sobreLengua)
                restart();
            else
                lengua.fuera = false;
        }
    }

    Connections {
        target: TsukaConf
        function onNuevoMensaje(texto: string): void {
            root.sacarLengua("nero", "NERO", texto, 6000, Espada.hueso);
        }
        function onPideLenguaChanged(): void {
            if (TsukaConf.ultimoTexto)
                root.sacarLengua("nero", "NERO", TsukaConf.ultimoTexto, 6000, Espada.hueso);
        }
        function onDesenvainar(abrir: bool): void {
            if (!root.conFoco)
                return;
            root.fija = abrir;
            root.hoverAbierta = abrir;
            if (!abrir)
                root.detalle = false;
        }
        function onSayaNero(): void {
            if (!root.conFoco || root.fullscreen)
                return;
            root.fija = true;
            root.hoverAbierta = true;
            root.detalle = true;
            root.guardarLengua();
            tLeer.restart();
        }
        function onSayaOsd(que: string): void {
            if (root.conFoco)
                root.mostrarOsd(que === "luz" ? "luces" : que);
        }
    }

    // ── música (Portada) ──
    readonly property bool hayMusica: Portada.hay
    readonly property bool suena: Portada.suena
    readonly property color portada: Portada.hay ? Portada.color : Espada.apagado
    property real avance: 0
    function medirAvance(): void {
        const p = Portada.jugador;
        if (!p || !p.length || p.length <= 0) {
            avance = 0;
            tAvance.stop();
            return;
        }
        const pos = p.position;
        avance = Math.max(0, Math.min(1, pos / p.length));
        tAvance.stop();
        if (!p.isPlaying)
            return;
        // siguiente umbral: cada 20 % (cordón) o cada 1/23 (onda, solo desenvainada)
        const paso = abierta ? 1 / 23 : 0.2;
        const sig = (Math.floor(avance / paso) + 1) * paso;
        if (sig >= 1)
            return;
        const seg = (sig * p.length - pos) / Math.max(0.1, p.rate || 1);
        tAvance.interval = Math.max(250, Math.min(2147483000, seg * 1000 + 120));
        tAvance.start();
    }
    Timer {
        id: tAvance
        onTriggered: root.medirAvance()
    }
    onAbiertaChanged: medirAvance()
    Connections {
        target: Portada.jugador
        ignoreUnknownSignals: true
        function onIsPlayingChanged(): void {
            root.medirAvance();
        }
        function onLengthChanged(): void {
            root.medirAvance();
        }
        function onPositionChanged(): void {
            root.medirAvance();
        }
    }
    property bool primeraCancion: true
    Connections {
        target: Portada
        function onClaveChanged(): void {
            root.medirAvance();
            if (!Portada.hay)
                return;
            if (root.primeraCancion) {
                root.primeraCancion = false;
                return;
            }
            if (Espada.mov)
                cascada.restart();
            root.sacarLengua("suena", "SUENA", Portada.titulo + (Portada.artista ? " · " + Portada.artista : ""), 3000, Portada.color);
        }
    }
    readonly property int vueltas: !hayMusica ? 0 : Math.max(1, Math.ceil(avance * 5))
    // onda: 23 barras con alturas fijas por canción (semilla del título)
    readonly property var onda: {
        let sem = 41;
        const t = Portada.titulo || "";
        for (let i = 0; i < t.length; i++)
            sem = (sem * 31 + t.charCodeAt(i)) % 2147483647;
        if (sem <= 0)
            sem = 41;
        const r = Mat.azar(sem), a = [];
        for (let i = 0; i < 23; i++)
            a.push(Math.round(3 + r() * 11));
        return a;
    }

    // ── luz ──
    property bool candado: false
    property var lamparas: [{ on: true, c: "#4b3cff", b: 100 }, { on: true, c: "#0000ff", b: 100 }, { on: false, c: "#ff7a30", b: 100 }]
    property bool lucesEncendidas: lamparas[0].on || lamparas[1].on
    FileView {
        path: TsukaConf.home + "/.config/nero/luces-bloqueadas"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.ponCandado(true)
        onLoadFailed: root.ponCandado(false)
    }
    property bool candadoLeido: false
    function ponCandado(v: bool): void {
        const antes = candado;
        candado = v;
        if (candadoLeido && antes !== v)
            sacarLengua("luz", "CANDADO", v ? "puesto" : "quitado", 3000, Espada.hueso);
        candadoLeido = true;
    }
    // estado real de las tres lámparas: se lee al desenvainar o al abrir Amanecer (un evento, no un sondeo)
    Process {
        id: lectorLuces
        command: [TsukaConf.home + "/.local/bin/govee"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = root.lamparas.slice();
                for (const linea of text.split("\n")) {
                    const m = linea.match(/^luz(\d)[^:]*:\s*(prendida|apagada),\s*(\d+)%,\s*(#[0-9a-fA-F]{6})/);
                    if (!m)
                        continue;
                    const i = parseInt(m[1]) - 1;
                    if (i >= 0 && i < 3)
                        l[i] = { on: m[2] === "prendida", c: m[4], b: parseInt(m[3]) };
                }
                root.lamparas = l;
            }
        }
    }
    function leerLuces(): void {
        if (!lectorLuces.running)
            lectorLuces.running = true;
    }
    function colorLampara(i: int): color {
        const l = lamparas[i];
        return l?.on ? Espada.prestado(l.c) : Espada.apagado;
    }
    function alternarCloset(): void {
        const on = !lamparas[2].on;
        Quickshell.execDetached(["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=3", "zangetsu", `~/.local/bin/closet ${on ? "on" : "off"}`]);
        const l = lamparas.slice();
        l[2] = Object.assign({}, l[2], { on: on });
        lamparas = l;
    }
    function alternarCandado(): void {
        Quickshell.execDetached(["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=3", "zangetsu", `~/.local/bin/luces-bloqueo ${candado ? "off" : "on"}`]);
    }
    readonly property var brilloMon: Brightness.getMonitorForScreen(screen)

    // ── avisos ──
    readonly property int nAvisos: Notifs.notClosed.length
    readonly property bool critico: Notifs.notClosed.some(n => n.urgency === NotificationUrgency.Critical)

    // ── OSD: una sola sección, se guarda a 1.6 s del último cambio ──
    property bool calma: true            // ignora los cambios del arranque
    Timer {
        interval: 2500
        running: true
        onTriggered: root.calma = false
    }
    function mostrarOsd(que: string): void {
        if (!listo || calma)
            return;
        // desenvainada y movida con la mano: la barra ya se mueve en su lugar, sin atenuar a las otras
        if (abierta && Date.now() - mano < 600)
            return;
        if (que === "luces")
            leerLuces();
        osdQue = que;
        osd = "luz";
        tOsd.restart();
    }
    function movidaMano(): void {
        mano = Date.now();
        if (osd && !abierta)
            tOsd.restart();
    }
    Timer {
        id: tOsd
        interval: 1600
        onTriggered: {
            if (root.sobreBloque && root.osd && !root.abierta)
                restart();
            else
                root.osd = "";
        }
    }
    // xeneon-control (Super+F4): la vaina de esa pantalla se desenvaina entera ~25 s, con las tres barras tocables
    Timer {
        id: tControl
        interval: 25000
        onTriggered: {
            if (root.sobreBloque || root.sobreVaina) {
                restart();
                return;
            }
            root.fija = false;
            root.hoverAbierta = false;
        }
    }
    Connections {
        target: Audio
        function onVolumeChanged(): void {
            if (root.conFoco)
                root.mostrarOsd("volumen");
        }
        function onMutedChanged(): void {
            if (root.conFoco)
                root.mostrarOsd("volumen");
        }
    }
    Connections {
        target: root.brilloMon
        ignoreUnknownSignals: true
        function onBrightnessChanged(): void {
            root.mostrarOsd("brillo");
        }
    }
    Connections {
        target: LucesAmbiente
        function onMostrar(): void {
            if (root.habla || root.conFoco)
                root.mostrarOsd("luces");
        }
        function onControlPantalla(pantalla: string): void {
            if (root.screen.name !== pantalla)
                return;
            root.calma = false;
            if (root.fullscreen) {
                root.mostrarOsd("luces");
                return;
            }
            root.leerLuces();
            root.fija = true;
            root.hoverAbierta = true;
            tControl.restart();
        }
    }

    // ── retirada en pantalla completa y arranque ──
    property real retiro: 0
    onFullscreenChanged: {
        if (fullscreen) {
            hoverAbierta = false;
            fija = false;
            detalle = false;
            guardarLengua();
            if (Espada.mov)
                retirar.restart();
            else
                retiro = 1;
        } else {
            retirar.stop();
            if (Espada.mov)
                regresar.restart();
            else
                retiro = 0;
        }
    }
    SequentialAnimation {
        id: retirar
        PauseAnimation { duration: 280 }
        NumberAnimation { target: root; property: "retiro"; to: 1; duration: Espada.dRetira; easing.type: Easing.BezierSpline; easing.bezierCurve: Espada.cEntra }
    }
    NumberAnimation { id: regresar; target: root; property: "retiro"; to: 0; duration: Espada.dRetira; easing.type: Easing.BezierSpline; easing.bezierCurve: Espada.cEntra }

    property real lacaX: 0
    property real marcasOp: 1
    Component.onCompleted: {
        if (fullscreen) {
            retiro = 1;
            return;
        }
        if (Espada.mov && !TsukaConf.arrancadas.includes("saya:" + screen.name)) {
            TsukaConf.arrancadas = TsukaConf.arrancadas.concat(["saya:" + screen.name]);
            arranque.start();
        }
    }
    ParallelAnimation {
        id: arranque
        NumberAnimation { target: root; property: "lacaX"; from: 10; to: 0; duration: 220; easing.type: Easing.BezierSpline; easing.bezierCurve: Espada.cEntra }
        SequentialAnimation {
            PropertyAction { target: brilloLaca; property: "opacity"; value: 0 }
            PauseAnimation { duration: 200 }
            PropertyAction { target: brilloLaca; property: "opacity"; value: 1 }
            NumberAnimation { target: brilloLaca; property: "y"; from: -90; to: root.s.largo; duration: 620; easing.type: Easing.BezierSpline; easing.bezierCurve: Espada.cBrillo }
            PropertyAction { target: brilloLaca; property: "opacity"; value: 0 }
        }
        SequentialAnimation {
            PropertyAction { target: root; property: "marcasOp"; value: 0 }
            PauseAnimation { duration: 532 }
            NumberAnimation { target: root; property: "marcasOp"; to: 1; duration: 228 }
        }
    }

    // ════════════════════ la vaina (8 px) ════════════════════
    Item {
        id: vaina
        x: root.borde - 8 + 16 * root.retiro + root.lacaX
        width: 8
        height: root.s.largo
        visible: root.listo && root.retiro < 1

        // v3 mejora 8: laca honda (reflejo largo del eco a tramos, polvo de hueso), boca de cuerno, contera,
        // pasador de metal y el hueco de la incrustación; lienzo de 16 px (sobresalen el pasador y la sombra del hueco)
        Material {
            x: -8
            width: 16
            height: root.s.largo
            visible: root.listo
            fragmentShader: Qt.resolvedUrl("vaina.frag.qsb")
            property real t0: root.g.ojoC - 8
            property real largo: root.s.largo
            property real punta: root.s.punta
            property real pc: root.s.suena[0] + root.s.suena[1] / 2
            property real lc: root.s.luz[0] + root.s.luz[1] / 2
            property color eco: root.eco
        }
        Rectangle {
            id: brilloLaca
            width: 8
            height: 90
            y: -90
            opacity: 0
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.5; color: Qt.alpha(Espada.huesoAlto, 0.5) }
                GradientStop { position: 1; color: "transparent" }
            }
        }

        // ── marcas en reposo (pegadas al borde derecho) ──
        Item {
            anchors.fill: parent
            opacity: root.marcasOp

            // boca (Nero): 8 x 16; sin leer = asoma 6 px y pasa a hueso alto
            Item {
                id: boca
                readonly property bool llama: TsukaConf.noLeidos > 0
                property real destello: 1
                anchors.right: parent.right
                y: root.g.ojoC - 8
                width: llama ? 14 : 8
                height: 16
                Behavior on width { NumberAnimation { duration: Espada.dFilo; easing.type: Easing.BezierSpline; easing.bezierCurve: Espada.cEntra } }
                // v3: en calma la boca es el cuerno pintado en la laca (vaina.frag); al llamar asoma 6 px en hueso alto
                Item {
                    anchors.fill: parent
                    opacity: boca.llama ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: Espada.dFilo } }
                    Rectangle {
                        anchors.fill: parent
                        topLeftRadius: 1
                        bottomLeftRadius: 1
                        gradient: Gradient {
                            GradientStop { position: 0; color: Espada.huesoAlto }
                            GradientStop { position: 0.6; color: Espada.hueso }
                            GradientStop { position: 1; color: "#cfc6b8" }
                        }
                    }
                    Rectangle { width: parent.width; height: 1; color: Qt.alpha(Espada.huesoAlto, 0.35) }
                    Rectangle { y: 15; width: parent.width; height: 1; color: Qt.rgba(0, 0, 0, 0.5) }
                }
                // trabaja: línea de 2 px en eco
                Rectangle {
                    y: 7
                    width: parent.width
                    height: 2
                    color: root.eco
                    opacity: TsukaConf.estado === "trabaja" ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Espada.dColor } }
                }
                // duerme: brillo al 45 %
                Rectangle {
                    anchors.fill: parent
                    color: "black"
                    opacity: TsukaConf.estado === "duerme" ? 0.55 : 0
                    Behavior on opacity { NumberAnimation { duration: Espada.dColor } }
                }
                // destello al salir la lengua de Nero
                Rectangle {
                    anchors.fill: parent
                    color: Espada.huesoAlto
                    opacity: (boca.destello - 1) / 1.2 * 0.8
                }
                NumberAnimation { id: destelloBoca; target: boca; property: "destello"; from: 2.2; to: 1; duration: 260 }
            }

            // pasador (metal, en vaina.frag) + cordón tejido (Suena): cada vuelta con volumen e hilos
            Column {
                id: cordonVaina
                anchors.right: parent.right
                y: root.s.suena[0] + root.s.suena[1] / 2 - 9
                width: 10
                spacing: Audio.muted ? 2 : 1.4
                Repeater {
                    model: 5
                    Item {
                        id: vuelta
                        required property int index
                        readonly property bool encendida: root.suena && index < root.vueltas
                        property real dx: 0
                        width: 10
                        height: Audio.muted ? 3 : 2.6
                        transform: Translate { x: vuelta.dx }
                        Rectangle { y: 0.8; width: parent.width; height: parent.height; color: Qt.rgba(0, 0, 0, 0.6); visible: !Audio.muted }
                        Item {
                            width: parent.width
                            height: parent.height
                            opacity: Audio.muted ? 1 : (vuelta.encendida ? 1 : (root.hayMusica ? 0.55 : 0.7))
                            Rectangle {
                                anchors.fill: parent
                                color: Audio.muted ? "transparent" : (vuelta.encendida ? root.portada : (root.hayMusica ? Espada.tenue : Espada.apagado))
                                border.width: Audio.muted ? 1 : 0
                                border.color: Espada.apagado
                                Behavior on color { ColorAnimation { duration: Espada.dColor } }
                            }
                            // volumen: claro arriba, el color al centro, hondo abajo (mez(col, ALTO, .35) -> col -> col * .35)
                            Rectangle {
                                anchors.fill: parent
                                visible: !Audio.muted
                                gradient: Gradient {
                                    GradientStop { position: 0; color: Qt.alpha(Espada.huesoAlto, 0.35) }
                                    GradientStop { position: 0.5; color: "transparent" }
                                    GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.65) }
                                }
                            }
                            Image {
                                anchors.fill: parent
                                visible: !Audio.muted
                                source: root.hilosVuelta
                                sourceSize: Qt.size(Math.ceil(10 * root.dpr * 2), Math.ceil(2.6 * root.dpr * 2))
                                smooth: true
                            }
                        }
                        SequentialAnimation {
                            id: entraVuelta
                            PropertyAction { target: vuelta; property: "dx"; value: -5 }
                            PauseAnimation { duration: vuelta.index * 30 }
                            NumberAnimation { target: vuelta; property: "dx"; to: 0; duration: 200; easing.type: Easing.BezierSpline; easing.bezierCurve: Espada.cFilo }
                        }
                        Connections {
                            target: cascada
                            function onStarted(): void {
                                entraVuelta.restart();
                            }
                        }
                    }
                }
            }

            // incrustación (Luz): mitad luz1, mitad luz2, hundida en su hueco (vaina.frag) y con su resplandor; candado = cuadrito de hueso
            Shape {
                id: resplandor
                readonly property color luz: root.colorLampara(0)
                visible: !root.candado && root.lamparas[0].on
                x: -8
                y: root.s.luz[0] + root.s.luz[1] / 2 - 10
                width: 16
                height: 20
                ShapePath {
                    strokeWidth: -1
                    fillGradient: RadialGradient {
                        centerX: 10; centerY: 10; centerRadius: 9
                        focalX: 10; focalY: 10
                        GradientStop { position: 0; color: Qt.alpha(resplandor.luz, 0.35) }
                        GradientStop { position: 1; color: Qt.alpha(resplandor.luz, 0) }
                    }
                    PathRectangle { x: 0; y: 0; width: 16; height: 20 }
                }
            }
            Item {
                anchors.right: parent.right
                anchors.rightMargin: root.candado ? 1 : 0
                y: root.s.luz[0] + root.s.luz[1] / 2 - 3
                width: root.candado ? 6 : 8
                height: 6
                Rectangle {
                    visible: !root.candado
                    width: parent.width
                    height: 3
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: Espada.mezcla(root.colorLampara(0), Espada.huesoAlto, 0.5) }
                        GradientStop { position: 1; color: Qt.darker(root.colorLampara(0), 1 / 0.7) }
                    }
                }
                Rectangle {
                    visible: !root.candado
                    y: 3
                    width: parent.width
                    height: 3
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: Espada.mezcla(root.colorLampara(1), Espada.huesoAlto, 0.5) }
                        GradientStop { position: 1; color: Qt.darker(root.colorLampara(1), 1 / 0.7) }
                    }
                }
                Rectangle {
                    visible: root.candado
                    anchors.fill: parent
                    color: Espada.hueso
                    Rectangle { anchors.fill: parent; anchors.margins: 2; color: "transparent"; border.width: 1; border.color: Espada.tinta }
                }
            }

            // rayas (Avisos)
            Column {
                anchors.right: parent.right
                y: root.s.avisos[0] + root.s.avisos[1] / 2 - 5
                width: root.critico ? 14 : 8
                spacing: 2
                Behavior on width { NumberAnimation { duration: Espada.dFilo; easing.type: Easing.BezierSpline; easing.bezierCurve: Espada.cEntra } }
                Repeater {
                    model: 3
                    Rectangle {
                        required property int index
                        width: parent.width
                        height: 2
                        opacity: index < Math.max(1, Math.min(3, root.nAvisos)) ? 1 : 0
                        color: root.critico ? Espada.rojo : (root.nAvisos ? Espada.tenue : Espada.apagado)
                        Behavior on color { ColorAnimation { duration: Espada.dColor } }
                    }
                }
            }
        }

        // el borde de 8 px: cursor 140 ms = desenvainar; clic = sin esperar; rueda = volumen
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor
            onContainsMouseChanged: {
                root.sobreVaina = containsMouse;
                if (containsMouse) {
                    tCerrar.stop();
                    if (!root.abierta)
                        tAbrir.restart();
                } else {
                    root.alSalir();
                }
            }
            onClicked: ev => {
                if (ev.button === Qt.MiddleButton) {
                    Portada.jugador?.togglePlaying();
                    return;
                }
                root.fija = true;
                root.hoverAbierta = true;
            }
            onWheel: ev => root.ruedaVolumen(ev.angleDelta.y)
        }
    }
    SequentialAnimation {
        id: cascada
        PauseAnimation { duration: 1 }
    }

    function ruedaVolumen(d: real): void {
        if (!d)
            return;
        const v = Math.max(0, Math.min(1, Audio.volume + (d > 0 ? 0.05 : -0.05)));
        Audio.setVolume(v);
        mostrarOsd("volumen");
    }
    function ruedaLuces(d: real): void {
        if (!d)
            return;
        LucesAmbiente.set(Math.max(0, Math.min(1, LucesAmbiente.value + (d > 0 ? 0.05 : -0.05))));
        mostrarOsd("luces");
    }
    function ruedaBrillo(d: real): void {
        if (!d || !brilloMon)
            return;
        brilloMon.setBrightness(Math.max(0, Math.min(1, brilloMon.brightness + (d > 0 ? 0.05 : -0.05))));
        mostrarOsd("brillo");
    }

    // ════════════════════ el bloque desenvainado ════════════════════
    Item {
        id: bloque
        readonly property real ancho: root.abierta ? root.anchoBloque : 8
        x: root.borde - width
        width: ancho
        height: root.s.fin
        clip: true
        visible: root.listo && width > 8.5
        Behavior on width {
            NumberAnimation {
                duration: root.abierta ? Espada.dAbre : Espada.dCierra
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.abierta ? Espada.cEntra : Espada.cSale
            }
        }
        // v3 mejora 9: nashiji de verdad (laca honda apenas teñida, escamas de hueso y metal dorado a tres
        // profundidades, dos reflejos diagonales, canto de luz) y las divisiones talladas entre secciones
        Material {
            width: root.anchoBloque
            height: root.s.fin
            fragmentShader: Qt.resolvedUrl("nashiji.frag.qsb")
            property real corte: 16
            property real y0: 0
            property vector4d divs: {
                const d = Laca.divisiones(root.s);
                // en el monitor alto la fila CANDADO · CLÓSET baja hasta ~370: el surco Luz/Avisos va debajo de ella
                return Qt.vector4d(d[0], d[1], root.compacta ? d[2] : root.s.avisos[0] + 7, d[3]);
            }
        }
        Text {
            visible: !root.compacta
            width: root.anchoBloque
            y: root.s.fin - 44
            height: 28
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: "鞘"
            font.family: "Yuji Boku"
            font.pixelSize: 20
            // v3: el sello toma el tono del marco (marco * .5 al 80 %)
            color: Qt.rgba(root.marco.r * 0.5, root.marco.g * 0.5, root.marco.b * 0.5, 0.8)
            opacity: root.abierta ? 1 : 0
            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.abierta && Espada.mov ? 100 : 0 } NumberAnimation { duration: Espada.dColor } } }
        }
    }

    // ── las cuatro secciones ──
    Seccion {
        id: secNero
        nombre: "nero"
        orden: 0
        filoColor: TsukaConf.noLeidos ? Espada.huesoAlto : (TsukaConf.estado === "trabaja" ? root.eco : (TsukaConf.estado === "duerme" ? Espada.apagado : Espada.tenue))
        onEntro: {
            root.detalle = true;
            root.guardarLengua();
            tLeer.restart();
        }
        onClic: {
            root.fija = true;
            root.detalle = true;
            TsukaConf.leido();
        }
        onClicDerecho: TsukaConf.alternarLenguas()
        onRueda: d => root.ruedaVolumen(d)

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: 46
            Row {
                Text {
                    text: TsukaConf.noLeidos ? String(TsukaConf.noLeidos) : (TsukaConf.estado === "trabaja" && TsukaConf.avance >= 0 ? String(TsukaConf.avance) : "0")
                    font.family: "Anton"
                    font.pixelSize: 24
                    font.features: ({ "tnum": 1 })
                    color: TsukaConf.noLeidos || (TsukaConf.estado === "trabaja" && TsukaConf.avance >= 0) ? Espada.huesoAlto : Espada.apagado
                }
                Text {
                    visible: !TsukaConf.noLeidos && TsukaConf.estado === "trabaja" && TsukaConf.avance >= 0
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 3
                    leftPadding: 2
                    text: "%"
                    font.family: "Anton"
                    font.pixelSize: 11
                    color: Espada.tenue
                }
            }
            Rectangle {
                visible: TsukaConf.estado === "trabaja" && TsukaConf.avance >= 0
                width: 46
                height: 2
                color: Espada.trazo
                Rectangle { width: parent.width * TsukaConf.avance / 100; height: 2; color: root.eco }
            }
            Etiqueta { topPadding: 6; text: !TsukaConf.noLeidos && TsukaConf.estado === "trabaja" ? "ENCARGO" : "NERO" }
        }
    }

    Seccion {
        id: secSuena
        nombre: "suena"
        orden: 1
        filoColor: root.hayMusica && !Audio.muted ? root.portada : Espada.apagado
        onClic: Portada.jugador?.togglePlaying()
        onClicDerecho: Portada.jugador?.next()
        onClicMedio: Portada.jugador?.previous()
        onRueda: d => root.ruedaVolumen(d)

        // una fila: carátula, y a su derecha título, artista y la onda (SAYA-DISENO.md §4.2)
        Row {
            anchors.verticalCenter: parent.verticalCenter
            width: 118
            spacing: 9
            Item {
                id: caratula
                readonly property int lado: root.compacta ? 38 : 46
                anchors.verticalCenter: parent.verticalCenter
                width: lado
                height: lado
                opacity: root.suena ? 1 : 0.3
                Rectangle {
                    anchors.fill: parent
                    radius: 4
                    color: Espada.capa
                    border.color: Espada.trazo
                }
                Image {
                    id: arte
                    anchors.fill: parent
                    anchors.margins: 1
                    source: Portada.arte
                    sourceSize: Qt.size(caratula.lado * root.dpr, caratula.lado * root.dpr)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
                Ico {
                    x: 4
                    y: parent.height - 14
                    tam: 10
                    nombre: root.suena ? "pausa" : "sigue"
                    relleno: !root.suena
                    color: Espada.huesoAlto
                }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: 118 - caratula.width - 9
                spacing: 4
                Text {
                    width: parent.width
                    text: root.suena ? Portada.titulo.toUpperCase() : "EN PAUSA"
                    elide: Text.ElideRight
                    font.family: "Anton"
                    font.pixelSize: 14
                    font.letterSpacing: 1.2
                    color: Espada.hueso
                }
                Text {
                    visible: !root.compacta || text.length > 0
                    width: parent.width
                    text: Portada.artista
                    elide: Text.ElideRight
                    font.family: "Inter"
                    font.pixelSize: 10
                    color: Espada.tenue
                }
                Row {
                    height: 14
                    spacing: 1
                    opacity: root.suena ? 1 : 0.3
                    Repeater {
                        model: root.onda
                        Rectangle {
                            required property var modelData
                            required property int index
                            anchors.verticalCenter: parent.verticalCenter
                            width: 1
                            height: modelData
                            color: root.hayMusica && index < root.avance * 23 ? root.portada : Espada.trazo
                        }
                    }
                }
            }
        }
    }

    // Barras: el cuerpo (las tres barras, lecturas y conmutadores) va en la capa `barras`, encima de la sección,
    // para que reciban el mouse y puedan dibujar fuera del bloque (aura, burbuja, tajo)
    Seccion {
        id: secLuz
        nombre: "luz"
        orden: 2
        filoColor: root.candado ? Espada.hueso : root.colorLampara(0)
        filoColor2: root.candado ? Espada.hueso : root.colorLampara(1)
        osdActiva: root.osd === "luz"
        onAbrio: root.leerLuces()
        onClicDerecho: root.alternarCandado()
        // rueda fuera de las barras: la de esa columna (o la tocada, como OSD)
        onRueda: (d, px) => {
            const que = !root.abierta ? root.osdQue : (px < 55 ? "luces" : (px < 95 ? "volumen" : "brillo"));
            if (que === "luces")
                root.ruedaLuces(d);
            else if (que === "brillo")
                root.ruedaBrillo(d);
            else
                root.ruedaVolumen(d);
        }
    }

    Seccion {
        id: secAvisos
        nombre: "avisos"
        orden: 3
        filoColor: root.critico ? Espada.rojo : (root.nAvisos ? Espada.tenue : Espada.apagado)
        onClic: root.screenState.sidebar = true
        onClicDerecho: {
            for (const n of Notifs.list.slice())
                n.close();
        }
        onRueda: d => root.ruedaVolumen(d)

        // en fila (cantidad + etiqueta), como el prototipo: con el bloque de 148 cabe y deja aire bajo los conmutadores
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 9
            Text {
                id: numAvisos
                text: String(root.nAvisos)
                font.family: "Anton"
                font.pixelSize: 24
                font.features: ({ "tnum": 1 })
                color: root.nAvisos ? Espada.huesoAlto : Espada.apagado
            }
            Row {
                visible: !root.compacta
                anchors.bottom: numAvisos.bottom
                anchors.bottomMargin: 6
                spacing: 3
                Ico { anchors.verticalCenter: parent.verticalCenter; tam: 10; nombre: "aviso"; color: Espada.apagado }
                Etiqueta { text: "AVISOS"; font.letterSpacing: 0.8 }
            }
        }
    }

    // ════════════════════ Barras: Amanecer · Reiatsu · Eclipse ════════════════════
    // Las mismas de modules/osd (sin redibujar), una sola instancia: viven en el bloque y salen solas como OSD.
    // Quietas en reposo: su Nucleo solo late mientras el valor se mueve o el cursor las toca.
    Item {
        id: barras
        readonly property bool ver: root.abierta || root.osd !== ""
        readonly property bool soloOsd: root.osd !== "" && !root.abierta
        readonly property real w: 72 * root.bs
        readonly property real h: 320 * root.bs
        readonly property real hueco: (116 - 3 * w) / 2
        readonly property int gL: root.compacta ? 3 : 5
        x: secLuz.x
        y: secLuz.y + (root.compacta ? 6 : 8)
        width: root.anchoBloque
        height: secLuz.height
        opacity: ver ? secLuz.opacity : 0
        visible: root.listo && opacity > 0 && (root.retiro < 1 || root.osd !== "")
        Behavior on opacity {
            SequentialAnimation {
                PauseAnimation { duration: barras.ver && root.abierta && Espada.mov ? 60 : 0 }
                NumberAnimation { duration: barras.ver ? Espada.dColor : Espada.dToque }
            }
        }
        // al volver a la vista: un repintado (si el valor cambió mientras estaban ocultas, su muelle lo alcanza solo)
        onVisibleChanged: {
            if (!visible)
                return;
            amanecer.nucleo.tick(0);
            reiatsu.nucleo.tick(0);
            eclipse.nucleo.tick(0);
        }

        Mini {
            indice: 0
            clave: "luces"
            rotulo: "LUZ"
            barra: amanecer
            lectura: LucesAmbiente.value > 0.66 ? "día" : (LucesAmbiente.value > 0.33 ? "tarde" : "noche")
            onClicDerecho: root.alternarCloset()   // 11-15 usuario: clic derecho en Amanecer = clóset
            Osd.BarraLuces {
                id: amanecer
                anchors.centerIn: parent
                scale: root.bs
                despierto: parent.parent.tocada
                value: LucesAmbiente.value
                onMovida: v => {
                    root.movidaMano();
                    LucesAmbiente.set(v);
                }
            }
        }
        Mini {
            indice: 1
            clave: "volumen"
            rotulo: "SON"
            barra: reiatsu
            lectura: Math.round(reiatsu.value * 100) + " %"
            onClicDerecho: if (Audio.sink?.audio) Audio.sink.audio.muted = !Audio.muted
            onClicMedio: Portada.jugador?.togglePlaying()
            Osd.BarraVolumen {
                id: reiatsu
                anchors.centerIn: parent
                scale: root.bs
                despierto: parent.parent.tocada
                value: Math.min(1, Audio.volume / Math.max(0.01, GlobalConfig.services.maxVolume))
                onMovida: v => {
                    root.movidaMano();
                    Audio.setVolume(v * GlobalConfig.services.maxVolume);
                }
            }
        }
        Mini {
            indice: 2
            clave: "brillo"
            rotulo: "BRI"
            barra: eclipse
            lectura: Math.round(eclipse.value * 100) + " %"
            onClicDerecho: root.alternarCandado()  // 11-15 usuario: clic derecho en Eclipse = candado de luces
            Osd.BarraBrillo {
                id: eclipse
                anchors.centerIn: parent
                scale: root.bs
                value: root.brilloMon?.brightness ?? 0
                onMovida: v => {
                    root.movidaMano();
                    root.brilloMon?.setBrightness(v);
                }
            }
        }

        // conmutadores: candado y clóset (solo desenvainada)
        Row {
            x: 16 + (118 - width) / 2
            y: barras.h + barras.gL + 11 + barras.gL + 8 + (root.compacta ? 5 : 9)
            spacing: 16
            visible: root.abierta
            Conmutador {
                nombre: "candado"
                rotulo: "CANDADO"
                tono: root.candado ? Espada.hueso : Espada.apagado
                onClic: root.alternarCandado()
            }
            Conmutador {
                nombre: "puerta"
                rotulo: "CLÓSET"
                tono: root.lamparas[2].on ? "#ff9a5c" : Espada.apagado
                onClic: root.alternarCloset()
            }
        }
    }

    // ════════════════════ la lengua ════════════════════
    Item {
        id: asomo
        readonly property real ancho: Math.max(180, Math.min(340, (QsWindow.window?.width ?? 1600) - 56 - 8 - 16))
        x: root.borde - root.bordeLengua - width
        y: lengua.sec === "nero" ? root.g.ojoC - 19 : (root.s[lengua.sec]?.[0] ?? 0) + (root.s[lengua.sec]?.[1] ?? 0) / 2 - 19
        width: ancho
        height: 38
        clip: true
        visible: root.listo && (lengua.fuera || lengua.x < width)
        Behavior on x { NumberAnimation { duration: Espada.dAbre; easing.type: Easing.BezierSpline; easing.bezierCurve: Espada.cEntra } }

        Item {
            id: lengua
            property string sec: "nero"
            property string rot: ""
            property string txt: ""
            property color filo: Espada.hueso
            property bool fuera: false
            width: asomo.width
            height: 38
            x: fuera ? 0 : asomo.width + 2
            Behavior on x {
                NumberAnimation {
                    duration: lengua.fuera ? Espada.dAbre : Espada.dCierra
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: lengua.fuera ? Espada.cEntra : Espada.cSale
                }
            }

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeWidth: -1
                    fillGradient: LinearGradient {
                        x1: 0; y1: 0; x2: lengua.width; y2: 0
                        GradientStop { position: 0; color: "#161a21" }
                        GradientStop { position: 0.6; color: Espada.tinta }
                    }
                    startX: 16; startY: 0
                    PathLine { x: lengua.width; y: 0 }
                    PathLine { x: lengua.width; y: 38 }
                    PathLine { x: 0; y: 38 }
                    PathLine { x: 0; y: 16 }
                    PathLine { x: 16; y: 0 }
                }
                ShapePath {
                    strokeWidth: -1
                    fillGradient: LinearGradient {
                        x1: 0; y1: 0; x2: 0; y2: 15
                        GradientStop { position: 0; color: Qt.alpha(Espada.hueso, 0.09) }
                        GradientStop { position: 1; color: Qt.alpha(Espada.hueso, 0) }
                    }
                    startX: 16; startY: 0
                    PathLine { x: lengua.width; y: 0 }
                    PathLine { x: lengua.width; y: 15 }
                    PathLine { x: 0; y: 15 }
                    PathLine { x: 0; y: 16 }
                    PathLine { x: 16; y: 0 }
                }
            }
            // hamon en los 8 px inferiores
            Image {
                y: 30
                width: lengua.width
                height: 8
                opacity: 0.55
                source: Mat.hamon(Math.round(asomo.ancho))
                sourceSize: Qt.size(asomo.ancho * root.dpr, 8 * root.dpr)
            }
            // brillo que la recorre una vez
            Rectangle {
                id: barrido
                x: -90
                width: 70
                height: 38
                opacity: 0
                rotation: 10
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 0.5; color: Qt.alpha(Espada.huesoAlto, 0.26) }
                    GradientStop { position: 1; color: "transparent" }
                }
            }
            SequentialAnimation {
                id: lenguaBrillo
                PropertyAction { target: barrido; property: "x"; value: -90 }
                PropertyAction { target: barrido; property: "opacity"; value: 1 }
                PauseAnimation { duration: 100 }
                NumberAnimation { target: barrido; property: "x"; to: lengua.width * 1.1; duration: 460; easing.type: Easing.BezierSpline; easing.bezierCurve: Espada.cEntra }
                PropertyAction { target: barrido; property: "opacity"; value: 0 }
            }
            Rectangle { anchors.right: parent.right; width: 2; height: 38; color: lengua.filo }
            Row {
                x: 28
                height: 38
                spacing: 10
                opacity: lengua.fuera ? 1 : 0
                Behavior on opacity {
                    SequentialAnimation {
                        PauseAnimation { duration: lengua.fuera && Espada.mov ? 80 : 0 }
                        NumberAnimation { duration: lengua.fuera ? Espada.dColor : Espada.dToque }
                    }
                }
                Text {
                    id: rotL
                    anchors.verticalCenter: parent.verticalCenter
                    text: lengua.rot
                    font.family: "Anton"
                    font.pixelSize: 12
                    font.letterSpacing: 2
                    color: Espada.huesoAlto
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: lengua.width - 28 - 12 - rotL.width - 10
                    text: lengua.txt
                    elide: Text.ElideRight
                    font.family: "Inter"
                    font.pixelSize: 12
                    color: Espada.hueso
                }
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onContainsMouseChanged: {
                    root.sobreLengua = containsMouse;
                    if (!containsMouse)
                        root.alSalir();
                }
                onClicked: {
                    const deNero = lengua.sec === "nero";
                    root.guardarLengua();
                    if (deNero)
                        TsukaConf.leido();
                }
            }
        }
    }

    // ════════════════════ detalle de Nero (sus tres últimos mensajes) ════════════════════
    Item {
        id: cajaDetalle
        readonly property real ancho: Math.max(170, Math.min(288, (QsWindow.window?.width ?? 1600) - 56 - root.anchoBloque - 8))
        x: root.borde - root.anchoBloque - width
        y: 0
        width: ancho
        height: detCol.implicitHeight + 12 + 18
        clip: true
        visible: root.listo && (root.detalle && root.abierta || det.x < width)

        Item {
            id: det
            width: parent.width
            height: parent.height
            x: root.detalle && root.abierta ? 0 : parent.width + 2
            Behavior on x {
                NumberAnimation {
                    duration: root.detalle ? Espada.dAbre : Espada.dCierra
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root.detalle ? Espada.cEntra : Espada.cSale
                }
            }
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeWidth: -1
                    fillColor: Espada.tinta
                    startX: 0; startY: 0
                    PathLine { x: det.width; y: 0 }
                    PathLine { x: det.width; y: det.height }
                    PathLine { x: 16; y: det.height }
                    PathLine { x: 0; y: det.height - 16 }
                    PathLine { x: 0; y: 0 }
                }
            }
            Rectangle {
                width: parent.width
                height: 60
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.alpha(Espada.hueso, 0.07) }
                    GradientStop { position: 1; color: "transparent" }
                }
            }
            Rectangle { anchors.right: parent.right; width: 2; height: parent.height; color: Espada.hueso }
            Column {
                id: detCol
                x: 22
                y: 12
                width: parent.width - 22 - 14
                spacing: 9
                Row {
                    spacing: 9
                    Item {
                        width: 26
                        height: 26
                        Image {
                            anchors.fill: parent
                            source: SysInfo.osLogo
                            sourceSize: Qt.size(26 * root.dpr, 26 * root.dpr)
                            smooth: false
                        }
                        Rectangle { anchors.fill: parent; radius: 5; color: "transparent"; border.color: Espada.trazo }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "NERO"
                        font.family: "Anton"
                        font.pixelSize: 10
                        font.letterSpacing: 2
                        color: Espada.hueso
                    }
                }
                Text {
                    visible: !TsukaConf.mensajes.length
                    text: "Sin mensajes."
                    font.family: "Inter"
                    font.pixelSize: 12
                    color: Espada.tenue
                }
                Repeater {
                    model: TsukaConf.ultimos
                    Row {
                        id: msj
                        required property var modelData
                        spacing: 8
                        Text {
                            width: 34
                            text: root.horaMensaje(msj.modelData.hora)
                            font.family: "Anton"
                            font.pixelSize: 10
                            font.letterSpacing: 1
                            lineHeight: 16
                            lineHeightMode: Text.FixedHeight
                            color: Espada.apagado
                        }
                        Text {
                            width: detCol.width - 34 - 8
                            text: msj.modelData.texto
                            wrapMode: Text.Wrap
                            maximumLineCount: 4
                            elide: Text.ElideRight
                            font.family: "Inter"
                            font.pixelSize: 12
                            lineHeight: 16
                            lineHeightMode: Text.FixedHeight
                            color: msj.modelData.leido ? Espada.tenue : Espada.hueso
                        }
                    }
                }
            }
        }
    }
    function horaMensaje(h: real): string {
        const d = new Date(h * 1000), hoy = new Date();
        if (d.toDateString() === hoy.toDateString())
            return Qt.formatTime(d, "h:mm");
        const ayer = new Date(hoy.getTime() - 86400000);
        if (d.toDateString() === ayer.toDateString())
            return "ayer";
        return Qt.formatDate(d, "d/M");
    }

    // ════════════════════ piezas ════════════════════
    // v3 (mejoras 8 y 9): material calculado pixel por pixel en la GPU (vaina.frag / nashiji.frag). layer.enabled:
    // corre UNA vez y queda como textura; solo se vuelve a pintar si cambia un uniforme (fondo o geometría).
    // En reposo no corre nada.
    component Material: ShaderEffect {
        property vector2d tam: Qt.vector2d(width, height)
        property real dpr: root.dpr
        property color base: root.cBase
        property color marco: root.marco
        blending: true
        layer.enabled: true
        layer.smooth: true
    }

    component Etiqueta: Text {
        property real px: 9
        font.family: "Inter"
        font.pointSize: px * 0.75
        font.letterSpacing: 1.6
        color: Espada.apagado
    }


    // una sección: 8 px envainada, 148 desenvainada; la de Barras sale de 64 como OSD. Filo de 2 px que crece de 2 a 22
    component Seccion: Item {
        id: sec
        property string nombre
        property int orden: 0
        property color filoColor: Espada.tenue
        property color filoColor2: filoColor
        property bool osdActiva: false
        readonly property bool comoOsd: osdActiva && !root.abierta
        readonly property bool fuera: root.abierta || osdActiva
        default property alias contenido: cuerpoNormal.data
        signal clic
        signal clicDerecho
        signal clicMedio
        signal entro
        signal abrio
        signal rueda(real d, real px)

        x: root.borde - width
        y: root.s[nombre][0]
        height: root.s[nombre][1]
        width: root.abierta ? root.anchoBloque : (osdActiva ? root.anchoOsd : 8)
        visible: root.listo && (root.retiro < 1 || osdActiva)
        opacity: root.abierta && root.seccionSobre && root.seccionSobre !== nombre ? 0.4 : 1
        onFueraChanged: if (fuera) abrio()
        Behavior on opacity { NumberAnimation { duration: Espada.dToque } }
        Behavior on width {
            NumberAnimation {
                duration: sec.fuera ? Espada.dAbre : Espada.dCierra
                easing.type: Easing.BezierSpline
                easing.bezierCurve: sec.fuera ? Espada.cEntra : Espada.cSale
            }
        }

        // fondo, borde y corte del bloque cuando sale sola como OSD (lengüeta de 64 px); al desenvainar la tapa el bloque
        Item {
            anchors.fill: parent
            clip: true
            visible: sec.osdActiva && bloque.width < root.anchoOsd + 0.5
            // v3: el mismo nashiji que el bloque (la misma franja de y)
            Material {
                width: root.anchoOsd
                height: sec.height
                fragmentShader: Qt.resolvedUrl("nashiji.frag.qsb")
                property real corte: 16
                property real y0: root.s[sec.nombre][0]
                property vector4d divs: Qt.vector4d(-1, -1, -1, -1)
            }
        }

        Item {
            id: cuerpo
            anchors.fill: parent
            clip: true
            scale: area.pressed ? 0.97 : 1
            Behavior on scale { NumberAnimation { duration: Espada.dToque } }

            // filo de la sección
            Rectangle {
                y: (sec.height - height) / 2
                width: 2
                height: sec.fuera ? 22 : 2
                opacity: sec.fuera ? 1 : 0
                gradient: Gradient {
                    GradientStop { position: 0; color: sec.filoColor }
                    GradientStop { position: 1; color: sec.filoColor2 }
                }
                Behavior on height { NumberAnimation { duration: Espada.dFilo; easing.type: Easing.BezierSpline; easing.bezierCurve: Espada.cEntra } }
                Behavior on opacity { NumberAnimation { duration: Espada.dColor } }
            }
            Item {
                id: cuerpoNormal
                x: 16
                width: root.anchoBloque - 30
                height: parent.height
                readonly property bool ver: root.abierta
                opacity: ver ? 1 : 0
                visible: opacity > 0
                transform: Translate {
                    x: cuerpoNormal.ver ? 0 : 8
                    Behavior on x { NumberAnimation { duration: Espada.dFilo; easing.type: Easing.BezierSpline; easing.bezierCurve: Espada.cEntra } }
                }
                Behavior on opacity {
                    SequentialAnimation {
                        PauseAnimation { duration: cuerpoNormal.ver && Espada.mov ? 30 * sec.orden : 0 }
                        NumberAnimation { duration: cuerpoNormal.ver ? Espada.dColor : Espada.dToque }
                    }
                }
            }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            enabled: sec.fuera
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor
            onContainsMouseChanged: {
                if (containsMouse) {
                    root.seccionSobre = sec.nombre;
                    if (sec.nombre !== "nero" && !root.fija) {
                        root.detalle = false;
                        tLeer.stop();
                    }
                    if (root.abierta)
                        sec.entro();
                } else if (root.seccionSobre === sec.nombre) {
                    root.seccionSobre = "";
                }
            }
            onClicked: ev => {
                if (ev.button === Qt.RightButton)
                    sec.clicDerecho();
                else if (ev.button === Qt.MiddleButton)
                    sec.clicMedio();
                else
                    sec.clic();
            }
            onWheel: ev => sec.rueda(ev.angleDelta.y, ev.x)
        }
    }

    // una de las tres barras en la vaina: la barra de modules/osd (escala bs) + lectura + rótulo
    component Mini: Item {
        id: mini
        required property int indice
        required property string clave      // luces | volumen | brillo
        property string lectura
        property string rotulo
        property Item barra: null
        readonly property bool tocada: root.osd !== "" && root.osdQue === clave
        default property alias contenido: ranura.data
        signal clicDerecho
        signal clicMedio

        width: barras.w
        height: barras.h + barras.gL + 11 + barras.gL + 8
        x: barras.soloOsd ? 14 : 17 + indice * (barras.w + barras.hueco)
        visible: !barras.soloOsd || tocada
        opacity: root.abierta && root.osd !== "" && !tocada ? 0.35 : 1
        z: (barra?.nucleo?.tocando ?? 0) > 0.01 ? 2 : 0
        Behavior on x { NumberAnimation { duration: Espada.dAbre; easing.type: Easing.BezierSpline; easing.bezierCurve: Espada.cEntra } }
        Behavior on opacity { NumberAnimation { duration: Espada.dColor } }

        Item {
            id: ranura
            width: barras.w
            height: barras.h
        }
        // clic derecho / medio (el izquierdo, la rueda y el cursor pasan a la barra)
        MouseArea {
            anchors.fill: ranura
            acceptedButtons: Qt.RightButton | Qt.MiddleButton
            onClicked: ev => ev.button === Qt.RightButton ? mini.clicDerecho() : mini.clicMedio()
        }
        Text {
            y: barras.h + barras.gL
            width: parent.width
            height: 11
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: mini.lectura
            font.family: "Anton"
            font.pixelSize: 11
            font.letterSpacing: 0.5
            font.features: ({ "tnum": 1 })
            color: Espada.huesoAlto
        }
        Text {
            y: barras.h + barras.gL + 11 + barras.gL
            width: parent.width
            height: 8
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: mini.rotulo
            font.family: "Anton"
            font.pixelSize: 8
            font.letterSpacing: 1.4
            color: Espada.apagado
        }
    }

    // conmutador bajo las barras: ícono + rótulo en Anton 8
    component Conmutador: Item {
        id: cm
        property string nombre
        property string rotulo
        property color tono: Espada.apagado
        signal clic
        implicitWidth: filaCm.implicitWidth
        implicitHeight: 11
        scale: areaCm.pressed ? 0.92 : 1
        Behavior on scale { NumberAnimation { duration: Espada.dToque } }
        Row {
            id: filaCm
            spacing: 4
            Ico {
                anchors.verticalCenter: parent.verticalCenter
                tam: 11
                nombre: cm.nombre
                color: cm.tono
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: cm.rotulo
                font.family: "Anton"
                font.pixelSize: 8
                font.letterSpacing: 1.2
                color: cm.tono
                Behavior on color { ColorAnimation { duration: Espada.dColor } }
            }
        }
        MouseArea {
            id: areaCm
            anchors.fill: parent
            anchors.margins: -3
            cursorShape: Qt.PointingHandCursor
            onClicked: cm.clic()
        }
    }
}
