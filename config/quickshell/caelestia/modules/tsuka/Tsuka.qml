pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.services
import qs.utils
import "material.js" as Mat
import "elementos.js" as El

// 11-15 Tsuka 柄, la empuñadura: barra izquierda FINAL (diseño Fable)
// /mnt/Compartido/Nero/diseno-fable/tsuka-saya-final/ (TSUKA-DISENO.md, COMUN.md, tsuka-saya-final.html).
// Dos capas: MATERIAL (material.js -> SVG pintado una vez como textura; solo se regenera si cambia el eco o el alto)
// y VIVO (ojo, ventanas, gemas, filo, menuki, hora, marcas): solo cambia con eventos.
// Ocupa los mismos 56 px reservados; las placas por zona van ENCIMA de las ventanas (alcance* -> Regions.qml).
// La carga BarWrapper en vez de Bar cuando TsukaConf.activa. Ver TSUKA-SAYA.md.
Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property bool fullscreen
    property var popouts: null

    // ── monitor ──
    readonly property HyprlandMonitor monitor: Hypr.monitorFor(screen)
    readonly property bool esLG: (monitor?.lastIpcObject?.description ?? "").indexOf("LG") >= 0
    readonly property bool compacta: height > 0 && height < 600
    readonly property color eco: {
        const p = Colours.of(QsWindow.window ?? root).palette;
        // paleta de wallmux de ESTE monitor (cambia en vivo con el fondo); el material se repinta solo entonces
        return Espada.ecoSeguro(esLG ? p.m3tertiaryFixed : p.m3primary);
    }
    readonly property string ecoHex: Espada.hex(eco)
    // 11-15 mango final, ajuste del usuario: varillas = tono CLARO del fondo, tela = tono OSCURO (Mat.mango)
    readonly property var colMango: {
        const p = Colours.of(QsWindow.window ?? root).palette;
        return Mat.mango(Espada.hex(esLG ? p.m3tertiaryFixedDim : p.m3primaryFixedDim), Espada.hex(esLG ? p.m3onTertiaryFixedVariant : p.m3onPrimaryFixedVariant));
    }
    // 11-15 usuario: lo apagado/tenue (iconos, kanji de escritorios vacíos, gemas apagadas) toma la paleta de ESTE monitor
    readonly property color tonoClaro: {
        const p = Colours.of(QsWindow.window ?? root).palette;
        return esLG ? p.m3tertiaryFixedDim : p.m3primaryFixedDim;
    }
    readonly property color apagadoM: Espada.mezcla(Espada.apagado, tonoClaro, 0.45)
    // v3 mejora 5: letras talladas en el metal (NERO en reposo toma el marco al 78 %)
    readonly property color marcoTallado: Qt.rgba(colMango.marco[0] * 0.78 / 255, colMango.marco[1] * 0.78 / 255, colMango.marco[2] * 0.78 / 255, 1)
    readonly property color tenueM: Espada.mezcla(Espada.tenue, tonoClaro, 0.45)
    // las sombras del Canvas de Qt SÍ siguen ctx.scale (probado 11-15: desplazamiento 10 a escala 4 = 40 px) -> 1
    readonly property real sombraR: 1
    readonly property real dpr: (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1
    readonly property int anchoPantalla: QsWindow.window?.width ?? screen.width
    readonly property bool conFoco: Hyprland.focusedMonitor === monitor

    // ── escritorios de ESTE monitor (reglas de hypr-user.lua: ASUS 1-3 + gaming, LG 4-6, XENEON 7-8) ──
    readonly property var wsAqui: {
        const mon = monitor;
        if (!mon)
            return [];
        return Hypr.workspaces.values.filter(w => w.monitor === mon && !w.name.startsWith("special:"));
    }
    readonly property var numerados: wsAqui.filter(w => w.id > 0).sort((a, b) => a.id - b.id)
    readonly property var wsCero: wsAqui.find(w => w.name === "gaming") ?? null
    readonly property string especialVisible: monitor?.lastIpcObject?.specialWorkspace?.name ?? ""
    readonly property string especialNombre: especialVisible || "special:claude"
    readonly property var wsEspecial: Hypr.workspaces.values.find(w => w.name === especialNombre) ?? null

    readonly property var g: Mat.geo(Math.max(height, 300), compacta, numerados.length, TsukaConf.gemasArriba, TsukaConf.gemasAbajo)
    readonly property bool listo: height > 200

    // 11-15 la hoja con elemento (tsuka-transicion-elementos, DISENO.md §2.4): agua | fuego | viento | "" (la de antes)
    readonly property string elemento: TsukaConf.hojaElemento ? El.elementoDe(screen?.name ?? "", colMango.telaHex, TsukaConf.elementos) : ""
    readonly property var hv: elemento && cargaHoja.item ? cargaHoja.item.hoja : null

    function ventanasDe(w: var): var {
        if (!w)
            return [];
        return Hypr.toplevels.values.filter(t => t.workspace === w && !Hypr.isToplevelIgnored(t)).sort((a, b) => (a.lastIpcObject?.focusHistoryID ?? 99) - (b.lastIpcObject?.focusHistoryID ?? 99));
    }
    function kanji(w: var): string {
        if (!w)
            return "";
        if (w.name === "gaming")
            return "零";
        if (w.id >= 1 && w.id <= 9)
            return ["", "一", "二", "三", "四", "五", "六", "七", "八", "九"][w.id];
        return String(w.name)[0] ?? "";
    }

    // filas del cordón con función: 零, escritorios y el especial
    readonly property var filas: {
        const r = [];
        const act = monitor?.activeWorkspace;
        if (!g.compacta)
            r.push({ tipo: "cero", fila: 0, ws: wsCero, kanji: "零", ventanas: ventanasDe(wsCero), existe: !!wsCero, activo: !especialVisible && !!wsCero && act === wsCero });
        numerados.forEach((w, i) => r.push({ tipo: "ws", fila: g.iWs + i, ws: w, kanji: kanji(w), ventanas: ventanasDe(w), existe: true, activo: !especialVisible && act === w }));
        const ve = ventanasDe(wsEspecial);
        r.push({ tipo: "esp", fila: g.iEsp, ws: wsEspecial, kanji: "", ventanas: ve, existe: ve.length > 0, activo: !!especialVisible });
        for (const f of r) {
            f.y = g.cord0 + 48 * f.fila;
            f.urge = f.ventanas.some(t => t.urgent === true);
        }
        return r;
    }
    readonly property var filaActiva: filas.find(f => f.activo) ?? null
    readonly property var ventanasVisibles: filaActiva ? filaActiva.ventanas : []
    readonly property var alFrente: {
        const v = ventanasVisibles;
        if (!v.length)
            return null;
        const act = Hyprland.activeToplevel;
        return v.includes(act) ? act : v[0];
    }

    // ── interfaz que espera BarWrapper (la de Bar) ──
    function closeTray(): void {
    }
    function checkPopout(y: real): void {
    }
    function salir(): void {
    }
    function handleWheel(y: real, angleDelta: point): void {
        if (fullscreen || !angleDelta.y)
            return;
        const dir = angleDelta.y > 0 ? -1 : 1;
        if (especialVisible) {
            Hypr.toggleSpecial(especialVisible.slice(8));
            return;
        }
        const orden = (wsCero ? [wsCero] : []).concat(numerados);
        const i = orden.indexOf(monitor?.activeWorkspace);
        if (i < 0 || i + dir < 0 || i + dir >= orden.length) {
            if (root.hilo) {
                root.hilo.tope(dir);
                return;
            }
            tope.dir = dir;
            tope.restart();
            return;
        }
        Hypr.dispatch(`ws_monitor(${dir})`);
    }

    function irA(f: var): void {
        if (!f)
            return;
        if (f.tipo === "esp") {
            Hypr.toggleSpecial(especialNombre.slice(8));
            return;
        }
        if (!f.ws)
            return;
        Hypr.focusWorkspace(f.ws.id < 0 ? `name:${f.ws.name}` : f.ws.id);
    }
    function mandarA(f: var): void {
        if (!f?.ws || f.tipo === "esp")
            return;
        const dest = f.ws.id < 0 ? `name:${f.ws.name}` : `${f.ws.id}`;
        Hypr.dispatch(`hl.dsp.window.move({ workspace = "${dest}", follow = false })`);
    }
    function enfocar(t: var): void {
        if (t?.address)
            Hypr.dispatch(`hl.dsp.focus({ window = "address:0x${t.address}" })`);
    }
    function cerrar(t: var): void {
        if (t?.address)
            Hypr.dispatch(`hl.dsp.window.close({ window = "address:0x${t.address}" })`);
    }
    function ejecutar(cmd: string): void {
        Hypr.dispatch(`hl.dsp.exec_cmd(${JSON.stringify(cmd)})`);
    }
    readonly property string bin: TsukaConf.home + "/.local/bin/"

    // ── gemas ──
    readonly property var infoGemas: ({
            casa: ["casa", "Modo casa", ["apagado · modo trabajo", "encendido · en casa"]],
            musica: ["musica", "Modo música", ["apagado", "encendido · bocinas por AirPlay"]],
            cine: ["cine", "Modo cine", ["apagado", "encendido · proyector"]],
            juego: ["juego", "Modo juego", ["sin partida", "jugando"]],
            zangetsu: ["servidor", "Zangetsu", ["sin vigilar", "en línea", "no responde"]],
            stream: ["pantalla", "Transmisión", ["nadie", "compartiendo pantalla"]],
            apagado: ["arena", "Apagado automático", ["sin armar", "armado · 1 h sin uso", "se apaga pronto"]],
            respaldo: ["respaldo", "Respaldo", ["al día", "corriendo", "falló"]],
            temp: ["temp", "Temperatura", ["fresca", "tibia", "caliente"]]
        })
    function valorGema(id: string): int {
        const v = TsukaConf.gemas[id]?.v ?? 0;
        if (id === "juego" && GameMode.enabled)
            return Math.max(1, v);
        return v;
    }
    function textoGema(id: string): string {
        const t = TsukaConf.gemas[id]?.t ?? "";
        const i = infoGemas[id];
        return t || (i ? (i[2][valorGema(id)] ?? i[2][0]) : "");
    }
    // 11-17 «D · Solo los modos» (diseno-fable/gemas-colores): los modos tienen piedra propia, igual en los 3 monitores;
    // música = portada; las vigías (zangetsu, stream, apagado, respaldo, temp) siguen con el eco del monitor. Nunca rojo.
    readonly property var piedraModo: ({ casa: "#ffb23e", cine: "#b584ff", juego: "#3fdc8c" })
    function colorGema(id: string): color {
        if (id === "musica" && Portada.hay)
            return Portada.color;
        return piedraModo[id] ?? eco;
    }
    function accionGema(id: string): void {
        const v = valorGema(id);
        if (id === "casa")   // mantener: en casa → modo trabajo; en modo trabajo → modo casa
            ejecutar(v ? bin + "modo-trabajo on" : bin + "modo-casa");
        else if (id === "musica")
            ejecutar(bin + "modo-musica");
        else if (id === "cine")
            ejecutar("ssh -o BatchMode=yes -o ConnectTimeout=3 zangetsu 'f=~/.config/nero/modo-cine-off; [ -e $f ] && ~/.local/bin/modo-cine on || ~/.local/bin/modo-cine off'");
        else if (id === "zangetsu")
            zonaFija = "vigias";
        else if (id === "apagado" && v > 0)
            ejecutar(bin + "apagado-auto cancelar");
    }

    // ── empuñar: placas por zona ──
    property string zonaHover: ""
    property string zonaFija: ""
    property string zonaPendiente: ""
    property bool sobreBarra: false
    property bool sobrePlaca: false
    readonly property string zona: {
        if (fullscreen || retiro > 0)
            return "";
        let z = zonaFija || zonaHover;
        if ((z === "agarre" || z === "modos" || z === "vigias") && !g.men)
            z = "cabeza";
        if (z === "vigias" && g.nAbajo <= 0)
            z = "agarre";
        if (z === "modos" && g.nArriba <= 0)
            z = "agarre";
        return z;
    }
    readonly property bool abierta: zona !== ""
    property string zonaVista: "cabeza"   // la última zona abierta (la placa conserva su lugar al guardarse)
    onZonaChanged: if (zona) zonaVista = zona

    function zonaDe(y: real): string {
        if (y < g.headEnd)
            return "cabeza";
        if (y >= g.fuchi0 - 6)
            return "guarda";
        if (!g.men)
            return y < (g.headEnd + g.fuchi0) / 2 ? "cabeza" : "guarda";
        return y < g.menuki0 ? "modos" : y < g.menuki0 + g.menukiH ? "agarre" : "vigias";
    }

    readonly property real altoAgarre: ventanasVisibles.length ? 128 + 28 * Math.min(8, ventanasVisibles.length) : 76
    function rectZona(z: string): var {
        switch (z) {
        case "cabeza":
            return [0, g.headEnd + 10];
        case "modos":
            return [g.cord0 + 48 * g.gA[0] - 6, 48 * g.nArriba + 12];
        case "vigias":
            return [g.cord0 + 48 * g.gB[0] - 6, 48 * g.nAbajo + 12];
        case "agarre":
            return [Math.round(g.menuki0 + g.menukiH / 2 - altoAgarre / 2), altoAgarre];
        case "guarda":
            return [g.fuchi0 - 6, height - g.fuchi0 + 6];
        }
        return [0, 0];
    }
    readonly property var rPlaca: rectZona(zonaVista)

    // lo que BarWrapper/Regions suman a la máscara de entrada (encima de las ventanas)
    readonly property int alcance: abierta ? 56 + 248 : 56
    readonly property real alcanceY: rPlaca[0]
    readonly property real alcanceAlto: abierta ? rPlaca[1] : 0

    function alMover(px: real, py: real): void {
        mirar(px, py);
        const z = zonaDe(py);
        if (z !== zonaHover) {
            tZona.interval = zonaHover ? Espada.esperaZona : Espada.esperaAbrir;
            zonaPendiente = z;
            tZona.restart();
        } else {
            tZona.stop();
        }
    }
    function alSalir(): void {
        tZona.stop();
        if (!sobreBarra && !sobrePlaca)
            tCerrar.restart();
    }
    Timer {
        id: tZona
        onTriggered: if (root.sobreBarra) root.zonaHover = root.zonaPendiente
    }
    Timer {
        id: tCerrar
        interval: Espada.esperaCerrar
        onTriggered: {
            if (root.sobreBarra || root.sobrePlaca)
                return;
            root.zonaHover = "";
            root.zonaFija = "";
            ojo.mira = null;
        }
    }

    // el ojo sigue al cursor en la zona cabeza (barra o placa)
    function mirar(px: real, py: real): void {
        if (py > g.headEnd + 10 || (zonaHover && zonaHover !== "cabeza") || TsukaConf.estado === "duerme") {
            ojo.mira = null;
            return;
        }
        ojo.mira = [Math.max(-4, Math.min(8, (px - 28) / 26)), Math.max(-3, Math.min(5, (py - g.ojoC) / 30))];
    }

    Connections {
        target: TsukaConf
        function onEmpunar(z: string): void {
            if (root.conFoco && !root.fullscreen)
                root.zonaFija = z;
        }
        function onProbarTajo(): void {
            if (!root.conFoco)
                return;
            if (root.hv)
                tajoEl.empieza();
            else
                tajoAnim.restart();
        }
        function onSoltar(): void {
            root.zonaFija = "";
        }
        function onParpadeoChanged(): void {
            ojo.parpadea();
        }
    }

    // ── retirada en pantalla completa y arranque (COMUN.md §8 y §4.2) ──
    property real retiro: 0            // 0 en su lugar, 1 fuera (-80 px)
    property bool ojoCerrado: true
    onFullscreenChanged: {
        if (fullscreen) {
            zonaHover = "";
            zonaFija = "";
            ojoCerrado = true;
            if (Espada.mov)
                retirar.restart();
            else
                retiro = 1;
        } else {
            regresar();
        }
    }
    SequentialAnimation {
        id: retirar
        PauseAnimation { duration: 280 }
        NumberAnimation { target: root; property: "retiro"; to: 1; duration: Espada.dRetira; easing.type: Easing.BezierSpline; easing.bezierCurve: Espada.cEntra }
    }
    function regresar(): void {
        retirar.stop();
        if (!Espada.mov) {
            retiro = 0;
            ojoCerrado = false;
            return;
        }
        regreso.restart();
    }
    SequentialAnimation {
        id: regreso
        NumberAnimation { target: root; property: "retiro"; from: 1; to: 0; duration: Espada.dRetira; easing.type: Easing.BezierSpline; easing.bezierCurve: Espada.cEntra }
        ScriptAction { script: root.ojoCerrado = false }
    }

    // arranque: una vez por pantalla (no se repite al volver de pantalla completa)
    property real revela: 1
    property real tsubaX: 0
    property real hojaBaja: 0
    property real marcasOp: 1
    Component.onCompleted: {
        const ya = TsukaConf.arrancadas.includes(screen.name);
        if (!ya)
            TsukaConf.arrancadas = TsukaConf.arrancadas.concat([screen.name]);
        if (fullscreen) {
            retiro = 1;
            return;
        }
        if (!Espada.mov) {
            ojoCerrado = false;
            return;
        }
        if (ya) {
            retiro = 1;
            regresar();
        } else {
            arranque.start();
        }
    }
    ParallelAnimation {
        id: arranque
        NumberAnimation { target: root; property: "revela"; from: 0; to: 1; duration: 520; easing.type: Easing.BezierSpline; easing.bezierCurve: Espada.cEntra }
        SequentialAnimation {
            PropertyAction { target: root; property: "tsubaX"; value: -76 }
            PauseAnimation { duration: 336 }
            NumberAnimation { target: root; property: "tsubaX"; to: 0; duration: 224; easing.type: Easing.BezierSpline; easing.bezierCurve: Espada.cFilo }
        }
        SequentialAnimation {
            PropertyAction { target: root; property: "hojaBaja"; value: -(root.height - root.g.hab0) }
            PauseAnimation { duration: 434 }
            NumberAnimation { target: root; property: "hojaBaja"; to: 0; duration: 266; easing.type: Easing.BezierSpline; easing.bezierCurve: Espada.cEntra }
        }
        SequentialAnimation {
            PropertyAction { target: root; property: "marcasOp"; value: 0 }
            PauseAnimation { duration: 684 }
            NumberAnimation { target: root; property: "marcasOp"; to: 1; duration: 76 }
        }
        SequentialAnimation {
            PauseAnimation { duration: 640 }
            ScriptAction { script: { ojo.dur = 260; root.ojoCerrado = false; } }
            PauseAnimation { duration: 280 }
            ScriptAction { script: ojo.dur = Qt.binding(() => Espada.dOjo) }
        }
    }

    // ════════════════════ la barra ════════════════════
    Item {
        id: cuerpo
        x: -80 * root.retiro
        width: 56
        height: root.height
        visible: root.retiro < 1

        HoverHandler {
            onHoveredChanged: {
                root.sobreBarra = hovered;
                if (hovered)
                    tCerrar.stop();
                else
                    root.alSalir();
            }
            onPointChanged: if (hovered) root.alMover(point.position.x, point.position.y)
        }

        // revelado de arriba abajo (solo en el arranque)
        Item {
            id: revelado
            width: 56
            height: root.height * root.revela
            clip: root.revela < 1

            Rectangle {
                width: 56
                height: root.height
                color: Espada.tinta
            }

            // ── material (estático) ──
            // ── herrajes de metal (v3, mejora 1): canto pulido, surco y nanako; más oscuros que la tela, sin líneas claras.
            // Sombreador que corre una vez (Pieza) y de nuevo solo si cambia el fondo o la geometría.
            Pieza {
                readonly property bool c: root.g.compacta
                readonly property real t0: c ? 3 : 5
                readonly property real pb: root.g.pomoH - 6
                visible: root.listo
                width: 56
                height: root.g.pomoH
                dpr: root.dpr
                fragmentShader: Qt.resolvedUrl("herraje.frag.qsb")
                property vector4d caja: Qt.vector4d(0, 0, 56, root.g.pomoH)
                property vector4d forma: Qt.vector4d(28, (t0 + pb) / 2, 24, (pb - t0) / 2)
                // nanako solo en la franja de NERO (la compacta no la lleva)
                property vector4d radios: Qt.vector4d(c ? 15 : 17, 2.5, c ? 1e9 : pb - 27, c ? -1 : pb - 8.5)
                property vector4d base: v4(root.colMango.base, 1)
                property vector4d marco: v4(root.colMango.marco, 1)
                property vector4d extra: Qt.vector4d(pb - 4, 0, 0, 0)
            }
            Text {
                visible: !root.compacta
                x: 29.3 - width / 2 + 1.3
                y: 77 - 10.5 * 0.92
                text: "NERO"
                font.family: "Anton"
                font.pointSize: 7.875 // 10.5 px
                font.letterSpacing: 2.6
                // v3 mejora 5: tallado en el metal; en reposo del tono del marco
                color: TsukaConf.estado === "duerme" ? root.apagadoM : (TsukaConf.estado === "vigila" ? root.marcoTallado : Espada.hueso)
                Behavior on color { ColorAnimation { duration: Espada.dColor } }
                Surco {}
                Canto {}
            }
            // v3 mejora 3: piel de raya de verdad (nódulos nacarados), DEBAJO de la tela, que deja los rombos transparentes
            Pieza {
                visible: root.listo
                y: root.g.cord0
                width: 56
                height: Math.max(1, root.g.gripEnd - root.g.cord0)
                dpr: root.dpr
                fragmentShader: Qt.resolvedUrl("piel.frag.qsb")
                property vector4d caja: Qt.vector4d(0, 0, 56, height)
                property vector4d filas: Qt.vector4d(root.g.N, root.g.iMen, root.g.men, 0)
                property vector4d fondo: v4(Mat.pielFondo(root.colMango), 1)
            }
            // la tela del mango (hineri-maki), hilo por hilo, con los marcos (varillas) encima: TSUKA-DISENO.md §3.3.
            // Canvas pintado UNA vez a 2x (se reduce con filtro = caja 2x2) y solo de nuevo si cambia el fondo
            // (colMango) o la geometría. En reposo no corre nada.
            Canvas {
                id: tela
                readonly property int sup: 2
                readonly property string firma: root.listo ? [root.colMango.marcoHex, root.colMango.telaHex, root.g.N, root.g.cord0, root.g.gripEnd, root.g.menuki0, root.g.men].join("|") : ""
                visible: root.listo && !(congelada && telaFija.status === Image.Ready)
                y: root.g.cord0
                width: 56 * sup
                height: Math.max(1, (root.g.gripEnd - root.g.cord0) * sup)
                scale: 1 / sup
                transformOrigin: Item.TopLeft
                smooth: true
                renderTarget: Canvas.Image
                renderStrategy: Canvas.Cooperative
                property string pintadaCon: ""
                // tras pintar se congela en un Image (PNG en memoria) y el Canvas se oculta: en reposo queda
                // exactamente como el material SVG de siempre (una textura), sin nodo de Canvas vivo
                property bool congelada: false
                // espera a que la geometría se asiente (al arrancar llegan los escritorios uno por uno)
                onFirmaChanged: if (firma && firma !== pintadaCon) {
                    congelada = false;
                    repintar.restart();
                }
                Timer {
                    id: repintar
                    interval: 250
                    onTriggered: tela.requestPaint()
                }
                onPainted: if (pintadaCon && !congelada) {
                    telaFija.source = toDataURL("image/png");
                    congelada = true;
                }
                onPaint: {
                    if (!firma || firma === pintadaCon || repintar.running)
                        return;
                    pintadaCon = firma;
                    const t0 = Date.now();
                    const ctx = getContext("2d");
                    ctx.reset();
                    ctx.scale(sup, sup);
                    Mat.pintaTela(ctx, root.g, root.colMango, root.sombraR, true);
                    console.info(`tsuka: tela ${root.screen?.name} ${Date.now() - t0} ms (marco ${root.colMango.marcoHex}, tela ${root.colMango.telaHex})`);
                }
            }
            Image {
                id: telaFija
                visible: root.listo && tela.congelada && status === Image.Ready
                y: root.g.cord0
                width: 56
                height: root.g.gripEnd - root.g.cord0
                smooth: true
                mipmap: false
                cache: false
            }
            // dōgane: el manguito del título, entre los nudos del menuki (§3.3b)
            // dōgane: todo de nanako, con la cartela lisa hundida para el título
            Pieza {
                readonly property real d0: root.g.menuki0 + 9
                readonly property real dh: root.g.menukiH - 18
                visible: root.listo && root.g.men > 0
                y: root.g.menuki0 + 8
                width: 56
                height: Math.max(1, root.g.menukiH - 16)
                dpr: root.dpr
                fragmentShader: Qt.resolvedUrl("herraje.frag.qsb")
                property vector4d caja: Qt.vector4d(0, y, 56, height)
                property vector4d forma: Qt.vector4d(28, d0 + dh / 2, 26.5, dh / 2)
                property vector4d radios: Qt.vector4d(3, 3, 0, 0)
                property vector4d base: v4(root.colMango.base, 1)
                property vector4d marco: v4(root.colMango.marco, 1)
                property vector4d extra: Qt.vector4d(0, 1, 1, 0)
            }
            // fuchi: el collar de la hora, satinado
            Pieza {
                visible: root.listo
                y: root.g.fuchi0 - 1
                width: 56
                height: 82
                dpr: root.dpr
                fragmentShader: Qt.resolvedUrl("herraje.frag.qsb")
                property vector4d caja: Qt.vector4d(0, y, 56, height)
                property vector4d forma: Qt.vector4d(28, root.g.fuchi0 + 40, 25, 40)
                property vector4d radios: Qt.vector4d(3.5, 3.5, 0, 0)
                property vector4d base: v4(root.colMango.base, 1)
                property vector4d marco: v4(root.colMango.marco, 1)
                property vector4d extra: Qt.vector4d(0, 0, 0, 0)
            }

            // ── hoja (grupo móvil, recortado desde hab0 + 18) ──
            Item {
                id: recorteHoja
                y: root.g.hab0 + 18
                width: 56
                height: Math.max(0, root.height - y)
                clip: true

                Item {
                    id: hojaG
                    y: root.hojaBaja + (root.hv ? root.hv.baja : (jalar.tirando ? 3 + jalar.dy : (jalar.sobre ? 3 : 0)))
                    width: 56
                    height: root.height
                    Behavior on y {
                        enabled: !root.hv && !jalar.tirando && !arranque.running
                        NumberAnimation { duration: Espada.dCierra; easing.type: Easing.BezierSpline; easing.bezierCurve: Espada.cEntra }
                    }

                    Image {
                        visible: root.listo && !root.hv
                        y: -30
                        width: 56
                        height: root.height + 26 - (root.g.hab0 + 18 - 30)
                        source: root.listo && !root.hv ? Mat.hoja(root.g, root.ecoHex) : ""
                        sourceSize: Qt.size(56 * root.dpr, height * root.dpr)
                        smooth: false
                        cache: false
                    }
                    Image {
                        visible: root.listo && !root.hv
                        y: -30
                        width: 56
                        height: root.height + 26 - (root.g.hab0 + 18 - 30)
                        source: root.listo ? Mat.filoHoja(root.g, jalar.dy >= 12 ? 2.4 : 1.2) : ""
                        sourceSize: Qt.size(56 * root.dpr, height * root.dpr)
                        opacity: jalar.sobre || jalar.tirando ? 1 : 0.8
                        Behavior on opacity { NumberAnimation { duration: Espada.dColor } }
                        smooth: false
                        cache: false
                    }
                    // brillo que recorre la hoja una vez (cursor encima)
                    Rectangle {
                        id: brillo
                        x: 5
                        width: 46
                        height: 30
                        y: -30
                        opacity: 0
                        gradient: Gradient {
                            GradientStop { position: 0; color: Qt.alpha(Espada.huesoAlto, 0) }
                            GradientStop { position: 0.5; color: Qt.alpha(Espada.huesoAlto, 0.5) }
                            GradientStop { position: 1; color: Qt.alpha(Espada.huesoAlto, 0) }
                        }
                    }
                    SequentialAnimation {
                        id: brillar
                        PropertyAction { target: brillo; property: "opacity"; value: 1 }
                        NumberAnimation { target: brillo; property: "y"; from: -30; to: root.height - root.g.hab0 + 20 - 30; duration: 460; easing.type: Easing.BezierSpline; easing.bezierCurve: Espada.cBrillo }
                        PropertyAction { target: brillo; property: "opacity"; value: 0 }
                    }

                    // ── marcas grabadas en la hoja (se mueven con ella) ──
                    Item {
                        y: root.g.mar0 - (root.g.hab0 + 18)
                        width: 56
                        height: 72
                        opacity: root.marcasOp

                        Marca {
                            id: mRed
                            fila: 0
                            nombre: "red"
                            apagada: !root.hayRed
                            colorBase: root.vpn ? root.eco : Espada.hueso
                            op: root.hayRed ? 0.8 : 0.4
                            onClic: root.abrirPopout("network", root.g.mar0 + 9)
                        }
                        Marca {
                            id: mBt
                            fila: 1
                            nombre: "bt"
                            apagada: !root.btEncendido
                            op: root.btEncendido ? 0.8 : 0.4
                            onClic: root.abrirPopout("bluetooth", root.g.mar0 + 27)
                            onClicDerecho: root.alternarBt()
                        }
                        Marca {
                            id: mBandeja
                            fila: 2
                            nombre: "bandeja"
                            colorBase: root.bandejaLlama ? Espada.huesoAlto : Espada.hueso
                            op: root.bandejaLlama ? 1 : 0.45
                            onClic: root.zonaFija = "guarda"
                        }
                        Marca {
                            id: mGraba
                            fila: 3
                            nombre: "graba"
                            visible: Recorder.running
                            colorBase: Espada.huesoAlto
                            op: 1
                            onClic: Recorder.stop()
                        }
                    }
                }
            }

            // v3 mejora 6: habaki limado en diagonal (neko-gaki), con sus dos cuerpos; sombreador que corre una vez
            Pieza {
                visible: root.listo
                y: root.g.hab0 - 7
                width: 56
                height: 30
                dpr: root.dpr
                fragmentShader: Qt.resolvedUrl("habaki.frag.qsb")
                property vector4d caja: Qt.vector4d(0, y, 56, 30)
                property vector4d marco: v4(root.colMango.marco, root.g.hab0)
            }

            // ── ventanas del cordón: escritorios (piel de raya, halo, kanji, filo) ──
            Repeater {
                id: ventanas
                model: root.listo ? root.filas : []

                Item {
                    id: ventana

                    required property var modelData
                    readonly property bool con: modelData.ventanas.length > 0
                    readonly property bool encendida: modelData.tipo === "ws" || modelData.existe
                    readonly property bool apretada: hit.pressed
                    readonly property bool sobre: hit.containsMouse

                    y: modelData.y
                    width: 56
                    height: 48
                    opacity: encendida ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: Espada.dColor } }

                    Item {
                        anchors.fill: parent
                        scale: hit.pressed ? 0.94 : 1
                        Behavior on scale { NumberAnimation { duration: Espada.dToque } }

                        // v3 mejora 3: la piel de raya ya está debajo de la tela (nódulos nacarados); aquí solo el velo de
                        // hueso del escritorio con ventanas (6 %) o con el cursor encima (10 %)
                        Shape {
                            anchors.fill: parent
                            opacity: hit.containsMouse ? 1 : (ventana.con ? 0.6 : 0)
                            visible: opacity > 0
                            preferredRendererType: Shape.CurveRenderer
                            Behavior on opacity { NumberAnimation { duration: Espada.dColor } }
                            ShapePath {
                                strokeWidth: -1
                                fillColor: Qt.alpha(Espada.hueso, 0.1)
                                PathSvg { path: "M28 7L48 24L28 41L8 24Z" }
                            }
                        }
                        Image {
                            anchors.fill: parent
                            source: Mat.halo(root.ecoHex)
                            sourceSize: Qt.size(56 * root.dpr, 48 * root.dpr)
                            opacity: ventana.con ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Espada.dColor } }
                        }
                        Text {
                            visible: ventana.modelData.tipo !== "esp" && !TsukaConf.hiloRojo
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 30 - 17 * 1.06
                            text: ventana.modelData.kanji
                            font.family: "Yuji Boku"
                            font.pixelSize: 17
                            color: ventana.modelData.activo || ventana.modelData.urge || hit.containsMouse ? Espada.huesoAlto : (ventana.con ? Espada.hueso : root.apagadoM)
                            Behavior on color { ColorAnimation { duration: Espada.dColor } }
                        }
                        Shape {
                            visible: ventana.modelData.tipo === "esp" && !TsukaConf.hiloRojo
                            anchors.fill: parent
                            preferredRendererType: Shape.CurveRenderer
                            ShapePath {
                                strokeColor: ventana.modelData.activo ? Espada.huesoAlto : root.tenueM
                                strokeWidth: 1.2
                                fillColor: "transparent"
                                joinStyle: ShapePath.MiterJoin
                                PathSvg { path: "M28 17L35 24L28 31L21 24Z" }
                            }
                        }
                    }
                    // pide atención: rombo en hueso
                    Shape {
                        anchors.fill: parent
                        opacity: ventana.modelData.urge && !ventana.modelData.activo ? 1 : 0
                        preferredRendererType: Shape.CurveRenderer
                        Behavior on opacity { NumberAnimation { duration: Espada.dColor } }
                        ShapePath {
                            strokeColor: Espada.hueso
                            strokeWidth: 1
                            fillColor: "transparent"
                            joinStyle: ShapePath.MiterJoin
                            PathSvg { path: "M28 7L48 24L28 41L8 24Z" }
                        }
                    }
                    MouseArea {
                        id: hit
                        anchors.fill: parent
                        enabled: ventana.encendida
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ev => ev.button === Qt.RightButton ? root.mandarA(ventana.modelData) : root.irA(ventana.modelData)
                    }
                }
            }

            // ── gemas ──
            Repeater {
                model: root.listo ? root.g.gemas : []

                Gema {
                    apagadoM: root.apagadoM
                    mango: root.colMango
                    tenueM: root.tenueM
                    required property var modelData
                    y: modelData.y
                    nombre: root.infoGemas[modelData.id]?.[0] ?? modelData.id
                    valor: root.valorGema(modelData.id)
                    colorGema: root.colorGema(modelData.id)
                    mantener: modelData.id === "casa" || modelData.id === "cine"
                    onAccion: root.accionGema(modelData.id)
                }
            }

            // ── el filo rojo con su corona (el de antes): un solo grupo, se desliza a la fila activa ──
            Item {
                id: filo
                property real cabeceo: 0
                visible: root.listo && !!root.filaActiva && !TsukaConf.hiloRojo
                y: (root.filaActiva?.y ?? root.g.cord0) + cabeceo
                width: 56
                height: 48
                Behavior on y {
                    enabled: !tope.running
                    NumberAnimation { duration: Espada.dFilo; easing.type: Easing.BezierSpline; easing.bezierCurve: Espada.cFilo }
                }
                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeColor: Qt.alpha(Espada.rojo, root.conFoco ? 0.16 : 0.06)
                        strokeWidth: 6
                        fillColor: "transparent"
                        joinStyle: ShapePath.RoundJoin
                        PathSvg { path: "M28 7L48 24L28 41L8 24Z" }
                    }
                    ShapePath {
                        strokeColor: Qt.alpha(Espada.rojo, root.conFoco ? 1 : 0.6)
                        strokeWidth: root.conFoco ? 1.6 : 1
                        fillColor: "transparent"
                        joinStyle: ShapePath.MiterJoin
                        PathSvg { path: "M28 7L48 24L28 41L8 24Z" }
                    }
                }
            }
            SequentialAnimation {
                id: tope
                property int dir: 1
                NumberAnimation { target: filo; property: "cabeceo"; to: 5 * tope.dir; duration: 90; easing.type: Easing.OutQuad }
                NumberAnimation { target: filo; property: "cabeceo"; to: 0; duration: 110; easing.type: Easing.BezierSpline; easing.bezierCurve: Espada.cEntra }
            }

            // luz que recorre el cordón al cambiar de escritorio
            Image {
                id: destello
                visible: !TsukaConf.hiloRojo
                width: 56
                height: 80
                opacity: 0
                source: "data:image/svg+xml;utf8," + encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" width="56" height="80"><defs><radialGradient id="r"><stop offset="0" stop-color="#fffaf0" stop-opacity=".2"/><stop offset=".7" stop-color="#fffaf0" stop-opacity="0"/></radialGradient></defs><ellipse cx="28" cy="40" rx="28" ry="40" fill="url(#r)"/></svg>')
            }
            Item {
                id: luzVigia
                property real yAnterior: -1
                readonly property real yActiva: root.filaActiva?.y ?? -1
                onYActivaChanged: {
                    if (yAnterior >= 0 && yActiva >= 0 && yActiva !== yAnterior && Espada.mov && !TsukaConf.hiloRojo) {
                        luz.desde = yAnterior - 16;
                        luz.hasta = yActiva - 16;
                        luz.restart();
                    }
                    yAnterior = yActiva;
                }
            }
            ParallelAnimation {
                id: luz
                property real desde
                property real hasta
                NumberAnimation { target: destello; property: "y"; from: luz.desde; to: luz.hasta; duration: Espada.dLuz; easing.type: Easing.BezierSpline; easing.bezierCurve: Espada.cEntra }
                SequentialAnimation {
                    NumberAnimation { target: destello; property: "opacity"; from: 0; to: 1; duration: Espada.dLuz * 0.35 }
                    NumberAnimation { target: destello; property: "opacity"; to: 0; duration: Espada.dLuz * 0.65 }
                }
            }

            // ── el ojo de Nero ──
            Ojo {
                id: ojo
                y: root.g.ojoC - 22
                estado: TsukaConf.estado
                eco: root.eco
                marco: root.colMango.marcoHex
                dormido: root.ojoCerrado
                sobrePomo: pomo.containsMouse
            }
            MouseArea {
                id: pomo
                width: 56
                height: root.g.pomoH - 14
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: ev => {
                    if (ev.button === Qt.RightButton) {
                        TsukaConf.alternarLenguas();
                    } else {
                        ojo.parpadea();
                        TsukaConf.repite();
                    }
                }
            }

            // ── menuki: apps del escritorio visible y título girado ──
            Item {
                id: menuki
                visible: root.listo && root.g.men > 0
                y: root.g.menuki0
                width: 56
                height: root.g.menukiH

                Column {
                    id: apps
                    y: 16
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8
                    Repeater {
                        model: root.ventanasVisibles.slice(0, 4)
                        Ico {
                            id: icoApp
                            required property var modelData
                            tam: 15
                            nombre: Espada.icoApp(modelData.lastIpcObject?.class ?? "")
                            color: icoArea.containsMouse ? Espada.hueso : (modelData === root.alFrente ? Espada.huesoAlto : root.tenueM)
                            scale: icoArea.pressed ? 0.88 : 1
                            Behavior on scale { NumberAnimation { duration: Espada.dToque } }
                            MouseArea {
                                id: icoArea
                                anchors.fill: parent
                                anchors.margins: -3
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ev => ev.button === Qt.MiddleButton ? root.cerrar(icoApp.modelData) : root.enfocar(icoApp.modelData)
                            }
                        }
                    }
                }
                // título girado (se lee de abajo arriba)
                Item {
                    id: cajaTit
                    y: apps.y + apps.height + 10
                    width: 56
                    height: Math.max(0, menuki.height - y - 14)
                    clip: true
                    Row {
                        id: filaTit
                        readonly property string app: root.alFrente ? Espada.nombreApp(root.alFrente) : ""
                        rotation: -90
                        transformOrigin: Item.TopLeft
                        x: (56 - height) / 2
                        y: cajaTit.height
                        spacing: 8
                        onAppChanged: if (Espada.mov) aparece.restart()
                        NumberAnimation { id: aparece; target: filaTit; property: "opacity"; from: 0; to: 1; duration: Espada.dColor }
                        Text {
                            id: tApp
                            anchors.verticalCenter: parent.verticalCenter
                            text: filaTit.app.toUpperCase()
                            font.family: "Anton"
                            font.pixelSize: 10
                            font.letterSpacing: 1.8
                            color: Espada.hueso
                            Surco {}
                            Canto {}
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.max(0, Math.min(implicitWidth, cajaTit.height - tApp.width - 8))
                            text: root.alFrente?.title ?? ""
                            elide: Text.ElideRight
                            font.family: "Inter"
                            font.pixelSize: 11
                            font.letterSpacing: 0.2
                            color: Espada.mezcla(Espada.hueso, root.tenueM, 0.35)
                            Surco {}
                            Canto {}
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ev => {
                            if (ev.button === Qt.MiddleButton) {
                                root.cerrar(root.alFrente);
                                return;
                            }
                            const v = root.ventanasVisibles;
                            if (v.length > 1)
                                root.enfocar(v[(v.indexOf(root.alFrente) + 1) % v.length]);
                        }
                    }
                }
            }

            // ── la hora (12 h) grabada en el fuchi; cuadritos llenos = p. m., huecos = a. m. ──
            Item {
                visible: root.listo
                y: root.g.clock0
                width: 56
                height: 64
                Digitos { y: 0; text: String(Time.hours % 12 || 12) }
                Row {
                    y: 30
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 4
                    Repeater {
                        model: 2
                        Rectangle {
                            width: 4
                            height: 4
                            Rectangle { y: 4; x: -0.5; width: 4; height: 0.8; color: Qt.rgba(0, 0, 0, 0.5) }
                            color: Time.hours >= 12 ? Espada.hueso : "transparent"
                            border.width: 1
                            border.color: Espada.hueso
                            Behavior on color { ColorAnimation { duration: Espada.dColor } }
                        }
                    }
                }
                Digitos { y: 36; text: String(Time.minutes).padStart(2, "0") }
            }

            // la hoja: cursor encima, clic, jalar
            MouseArea {
                id: jalar
                readonly property bool sobre: containsMouse
                property bool tirando: false
                property real desde: 0
                property real dy: 0
                visible: root.listo
                y: root.g.jala0
                width: 56
                height: Math.max(0, root.height - root.g.jala0)
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: tirando ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                onContainsMouseChanged: if (containsMouse && Espada.mov && !tirando && !root.hv) brillar.restart()
                onPressed: ev => {
                    if (ev.button !== Qt.LeftButton)
                        return;
                    desde = ev.y;
                    dy = 0;
                    tirando = true;
                }
                onPositionChanged: ev => {
                    if (tirando)
                        dy = Math.max(0, Math.min(18, ev.y - desde));
                }
                onReleased: ev => {
                    if (ev.button === Qt.RightButton) {
                        root.bloquear();
                        return;
                    }
                    if (!tirando)
                        return;
                    const abre = dy >= 12 || dy < 2;
                    tirando = false;
                    dy = 0;
                    if (abre)
                        root.tajoYLunas("");
                }
                onCanceled: {
                    tirando = false;
                    dy = 0;
                }
            }
        }
    }

    // v3 mejora 7: el mango proyecta su sombra sobre el escritorio (14 px, suave) en lugar de la raya de 1 px del borde
    // derecho; llega hasta donde empieza la hoja (como en el prototipo). Un degradado fijo: no cuesta en reposo.
    // Va fuera de `cuerpo` (que mide 56) y se retira con él.
    Rectangle {
        x: 56 - 80 * root.retiro
        width: 14
        height: Math.min(root.g.hab0 + 18, root.height * root.revela)
        visible: root.listo && root.retiro < 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0.5) }
            GradientStop { position: 0.4; color: Qt.rgba(0, 0, 0, 0.18) }
            GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0) }
        }
    }

    // ── la tsuba: lo único que se sale 16 px del ancho; encima de la placa; no recibe clics ──
    // v3 mejora 6: guarda de hueso con veta y cordoncillo en relieve, y su sombra sobre el habaki y el escritorio (72 x 20)
    Pieza {
        visible: root.listo && root.retiro < 1
        x: -80 * root.retiro + root.tsubaX
        y: root.g.guard0
        z: 3
        width: 72
        height: 20
        dpr: root.dpr
        fragmentShader: Qt.resolvedUrl("tsuba.frag.qsb")
        property vector4d marco: v4(root.colMango.marco, 1)
    }

    // ════════════════════ 11-15 el hilo rojo: su propia ventanita (capa Top, encima de los cajones, sin entrada) ════════════════════
    // tsuka.json "hiloRojo" (si es false, el filo de antes). Va aparte para que los ~1.3 s de cada cambio de
    // escritorio repinten 56 × ~350 px y no la ventana de pantalla completa de los cajones. Debajo (en la ventana de
    // siempre) quedan la piel, el halo y el mouse de cada rombo; aquí: luna negra, hilo, kanji y la luz.
    readonly property var hilo: cargaHilo.item ? cargaHilo.item.hilo : null
    LazyLoader {
        id: cargaHilo
        active: root.listo && TsukaConf.hiloRojo

        PanelWindow {
            id: ventanaHilo
            property alias hilo: hilo
            screen: root.screen
            anchors.left: true
            anchors.top: true
            margins.top: root.g.cord0
            implicitWidth: 56
            implicitHeight: Math.max(48, Math.min(root.g.gripEnd - root.g.cord0, 48 * (root.g.iEsp + 1) + 112))
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "tsuka-hilo"
            mask: Region {}
            Component.onCompleted: Hypr.extras.batchMessage([`eval hl.layer_rule({ match = { namespace = "tsuka-hilo" }, no_anim = true })`])

            Item {
                x: -80 * root.retiro
                width: 56
                height: Math.max(0, Math.min(ventanaHilo.height, root.height * root.revela - root.g.cord0))
                clip: root.revela < 1
                visible: root.retiro < 1

                Hilo {
                    id: hilo
                    width: 56
                    height: ventanaHilo.height
                    nf: root.g.iEsp + 1
                    act: root.filaActiva ? root.filaActiva.fila : -1
                    eco: root.eco
                    foco: root.conFoco
                    movimiento: Espada.mov

                    // los kanji de cada fila: encima de la luna negra, debajo de la luz
                    Repeater {
                        model: root.listo && TsukaConf.hiloRojo ? root.filas : []

                        Item {
                            id: kj
                            required property var modelData
                            required property int index
                            readonly property Item vent: ventanas.count > index ? ventanas.itemAt(index) : null
                            readonly property bool con: modelData.ventanas.length > 0
                            readonly property bool activo: modelData.activo
                            y: modelData.y - root.g.cord0
                            width: 56
                            height: 48
                            opacity: modelData.tipo === "ws" || modelData.existe ? 1 : 0
                            visible: opacity > 0
                            Behavior on opacity { NumberAnimation { duration: Espada.dColor } }
                            scale: vent && vent.apretada ? 0.94 : 1
                            Behavior on scale { NumberAnimation { duration: Espada.dToque } }
                            // color: el de siempre, encendido a hueso alto por la luz del hilo y por la luna que lo tapa
                            readonly property color base: modelData.urge || (vent && vent.sobre) ? Espada.huesoAlto : (con ? Espada.hueso : root.apagadoM)
                            readonly property real enc: {
                                hilo.cuadro;
                                const f = modelData.fila;
                                return Math.max(hilo.luz(f), hilo.cubre(f) * (activo ? 1 : 0.45));
                            }
                            readonly property color tinta: Espada.mezcla(base, Espada.huesoAlto, Math.max(0, Math.min(1, enc)))
                            // el golpecito del kanji activo al llegar el hilo (escala 1 + g, desplazamiento −14·g·dir)
                            transform: [
                                Scale {
                                    origin.x: 28
                                    origin.y: 24
                                    xScale: kj.activo ? 1 + hilo.golpe : 1
                                    yScale: xScale
                                },
                                Translate { y: kj.activo ? -14 * hilo.golpe * hilo.dir : 0 }
                            ]
                            Text {
                                visible: kj.modelData.tipo !== "esp"
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 30 - 17 * 1.06
                                text: kj.modelData.kanji
                                font.family: "Yuji Boku"
                                font.pixelSize: 17
                                color: kj.tinta
                            }
                            Shape {
                                visible: kj.modelData.tipo === "esp"
                                anchors.fill: parent
                                preferredRendererType: Shape.CurveRenderer
                                ShapePath {
                                    strokeColor: kj.activo ? Espada.huesoAlto : Espada.mezcla(root.tenueM, Espada.huesoAlto, Math.max(0, Math.min(1, kj.enc)))
                                    strokeWidth: 1.2
                                    fillColor: "transparent"
                                    joinStyle: ShapePath.MiterJoin
                                    PathSvg { path: "M28 17L35 24L28 31L21 24Z" }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ════════════════════ la hoja con elemento: su propia ventanita (capa Top, encima de los cajones, sin entrada) ════════════════════
    // Así cada cuadro de la hoja viva repinta 56 × ~129 px y no la ventana de pantalla completa de los cajones.
    // Empieza justo debajo del habaki (hab0 + 23). Pinta hoja, pavesas, filo y la VISTA de las marcas; el mouse
    // (jalar, marcas) sigue en la ventana de siempre, debajo: la máscara vacía deja pasar todo.
    LazyLoader {
        id: cargaHoja
        active: root.listo && root.elemento !== ""

        PanelWindow {
            id: ventanaHoja
            property alias hoja: hojaViva
            screen: root.screen
            anchors.left: true
            anchors.bottom: true
            implicitWidth: 56
            implicitHeight: Math.max(1, root.height - root.g.hab0 - 23)
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "tsuka-hoja"
            mask: Region {}
            Component.onCompleted: Hypr.extras.batchMessage([`eval hl.layer_rule({ match = { namespace = "tsuka-hoja" }, no_anim = true })`])

            Item {
                id: marcoHoja
                x: -80 * root.retiro
                width: 56
                // el revelado de arriba abajo del arranque también tapa la hoja
                height: Math.max(0, Math.min(ventanaHoja.height, root.height * root.revela - (root.g.hab0 + 23)))
                clip: root.revela < 1
                visible: root.retiro < 1

                Item {
                    width: 56
                    height: ventanaHoja.height
                    Rectangle {
                        anchors.fill: parent
                        color: Espada.tinta
                    }
                    Hoja {
                        id: hojaViva
                        y: -5 + root.hojaBaja + baja
                        width: 56
                        height: ventanaHoja.height + 5
                        el: root.elemento
                        largo: root.height - root.g.hab0 - 18
                        eco: root.eco
                        telaHex: root.colMango.telaHex
                        sobre: jalar.sobre
                        tirando: jalar.tirando
                        dy: jalar.dy
                        movimiento: Espada.mov
                        viva: TsukaConf.hojaViva
                        fps: TsukaConf.hojaFps
                        pausa: TsukaConf.enTrabajo || TsukaConf.inactivo || root.retiro > 0.99 || root.fullscreen

                        // encima del material: filo y marcas (vista), se mueven con la hoja
                        Image {
                            y: -30
                            width: 56
                            height: root.height + 26 - (root.g.hab0 + 18 - 30)
                            source: root.listo ? Mat.filoHoja(root.g, jalar.dy >= 12 ? 2.4 : 1.2) : ""
                            sourceSize: Qt.size(56 * root.dpr, height * root.dpr)
                            opacity: jalar.sobre || jalar.tirando || hojaViva.carga > 0.02 ? 1 : 0.8
                            Behavior on opacity { NumberAnimation { duration: Espada.dColor } }
                            smooth: false
                            cache: false
                        }
                        Item {
                            y: root.g.mar0 - (root.g.hab0 + 18)
                            width: 56
                            height: 72
                            opacity: root.marcasOp
                            MarcaVista { x: 1 + 28 - 6.5; y: 0 + 2.5; de: mRed }
                            MarcaVista { x: 1 + 28 - 6.5; y: 18 + 2.5; de: mBt }
                            MarcaVista { x: 1 + 28 - 6.5; y: 36 + 2.5; de: mBandeja }
                            MarcaVista { x: 1 + 28 - 6.5; y: 54 + 2.5; de: mGraba; visible: Recorder.running }
                        }
                    }
                }
            }
        }
    }
    Connections {
        target: Time
        enabled: TsukaConf.respiroMinuto && !!root.hv && root.conFoco
        function onMinutesChanged(): void {
            root.hv.pulso(1600, 0.5);
        }
    }

    // ════════════════════ la placa (empuñada) ════════════════════
    Item {
        id: placaClip
        x: 56
        z: 2
        y: root.rPlaca[0]
        width: 248
        height: root.rPlaca[1]
        clip: true
        visible: root.listo && (root.abierta || placa.x > -248)

        Behavior on y {
            enabled: root.abierta && placa.x > -247
            NumberAnimation { duration: Espada.dFilo; easing.type: Easing.BezierSpline; easing.bezierCurve: Espada.cEntra }
        }
        Behavior on height {
            enabled: root.abierta && placa.x > -247
            NumberAnimation { duration: Espada.dFilo; easing.type: Easing.BezierSpline; easing.bezierCurve: Espada.cEntra }
        }

        HoverHandler {
            enabled: root.abierta
            onHoveredChanged: {
                root.sobrePlaca = hovered;
                if (hovered)
                    tCerrar.stop();
                else
                    root.alSalir();
            }
            onPointChanged: if (hovered) root.mirar(56 + point.position.x, placaClip.y + point.position.y)
        }

        Item {
            id: placa
            width: 248
            height: parent.height
            x: root.abierta ? 0 : -249
            Behavior on x {
                NumberAnimation {
                    duration: root.abierta ? Espada.dAbre : Espada.dCierra
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root.abierta ? Espada.cEntra : Espada.cSale
                }
            }

            // fondo: tinta, corte de hoja de 16 px (abajo en cabeza/agarre/modos/vigías, arriba en guarda)
            Shape {
                id: fondoPlaca
                readonly property bool arriba: root.zonaVista === "guarda"
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeWidth: -1
                    fillColor: Espada.tinta
                    PathSvg {
                        path: {
                            const w = 248, h = placa.height;
                            return fondoPlaca.arriba ? `M0 0H${w - 16}L${w} 16V${h}H0Z` : `M0 0H${w}V${h - 16}L${w - 16} ${h}H0Z`;
                        }
                    }
                }
                ShapePath {
                    strokeColor: Qt.alpha(Espada.hueso, 0.12)
                    strokeWidth: 1
                    fillColor: "transparent"
                    PathSvg {
                        path: {
                            const w = 247.5, h = placa.height;
                            return fondoPlaca.arriba ? `M${w - 15.5} 0L${w} 15.5` : `M${w} ${h - 15.5}L${w - 15.5} ${h}`;
                        }
                    }
                }
            }
            Rectangle {
                width: 14
                height: parent.height
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0.35) }
                    GradientStop { position: 1; color: "transparent" }
                }
            }
            Rectangle {
                x: 247
                y: fondoPlaca.arriba ? 16 : 0
                width: 1
                height: Math.max(0, parent.height - 16)
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.alpha(Espada.hueso, 0.28) }
                    GradientStop { position: 1; color: Qt.alpha(Espada.hueso, 0.05) }
                }
            }

            // el contenido usa coordenadas de pantalla (como el prototipo): se desplaza -top
            Item {
                id: dentro
                y: -placaClip.y
                width: 248
                height: root.height

                // ── cabeza ──
                Zona {
                    activa: root.zona === "cabeza"

                    Item {
                        x: 14
                        y: root.compacta ? 9 : 14
                        width: 248 - 14 - 22
                        height: 60
                        Image {
                            id: retrato
                            width: root.compacta ? 26 : 34
                            height: width
                            source: SysInfo.osLogo
                            sourceSize: Qt.size(width * root.dpr, width * root.dpr)
                            smooth: false
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                maskEnabled: true
                                maskSource: mascaraRetrato
                            }
                        }
                        Rectangle {
                            id: mascaraRetrato
                            visible: false
                            layer.enabled: true
                            width: retrato.width
                            height: retrato.height
                            radius: 6
                        }
                        Rectangle {
                            width: retrato.width
                            height: retrato.height
                            radius: 6
                            color: "transparent"
                            border.color: Espada.trazo
                        }
                        Column {
                            x: retrato.width + 10
                            width: parent.width - x
                            Row {
                                spacing: 8
                                Text {
                                    id: rotNero
                                    text: "NERO"
                                    font.family: "Anton"
                                    font.pixelSize: 11
                                    font.letterSpacing: 2
                                    color: Espada.hueso
                                }
                                Text {
                                    anchors.baseline: rotNero.baseline
                                    text: ({ duerme: "duerme", vigila: "vigila", escucha: "te escucha", trabaja: "trabaja", escribio: "te escribió" })[TsukaConf.estado] + (TsukaConf.lenguas ? "" : " · en silencio")
                                    font.family: "Inter"
                                    font.pixelSize: 11
                                    color: root.tenueM
                                }
                            }
                            Text {
                                topPadding: 5
                                width: parent.width
                                text: TsukaConf.dice
                                wrapMode: Text.Wrap
                                maximumLineCount: root.compacta ? 1 : 2
                                elide: Text.ElideRight
                                font.family: "Inter"
                                font.pixelSize: 12
                                lineHeight: 15
                                lineHeightMode: Text.FixedHeight
                                color: root.tenueM
                            }
                        }
                    }

                    Repeater {
                        model: root.filas.filter(f => f.tipo === "ws" || f.existe)
                        Fila {
                            id: filaWs
                            required property var modelData
                            y: modelData.y
                            height: 48
                            frente: modelData.activo
                            vacia: !modelData.ventanas.length
                            onClic: root.irA(modelData)
                            onClicDerecho: root.mandarA(modelData)
                            Repeater {
                                model: filaWs.modelData.ventanas.slice(0, 3)
                                Ico {
                                    required property var modelData
                                    anchors.verticalCenter: parent?.verticalCenter
                                    nombre: Espada.icoApp(modelData.lastIpcObject?.class ?? "")
                                    color: filaWs.frente ? Espada.hueso : root.tenueM
                                }
                            }
                            FilaTexto {
                                text: {
                                    const f = filaWs.modelData;
                                    if (!f.ventanas.length)
                                        return "vacío";
                                    const n = [];
                                    for (const t of f.ventanas) {
                                        const a = Espada.nombreApp(t);
                                        if (a && !n.includes(a))
                                            n.push(a);
                                    }
                                    return (f.tipo === "esp" ? "flotante · " : "") + n.join(" · ") + (f.urge && !f.activo ? " · te llama" : "");
                                }
                                color: filaWs.colorTexto
                            }
                        }
                    }
                }

                // ── modos y vigías ──
                Repeater {
                    model: ["modos", "vigias"]
                    Zona {
                        id: zGemas
                        required property string modelData
                        activa: root.zona === modelData
                        Text {
                            x: 14
                            width: 248 - 14 - 22
                            y: root.g.cord0 + 48 * (zGemas.modelData === "modos" ? root.g.gA[0] : root.g.gB[0]) + 4
                            horizontalAlignment: Text.AlignRight
                            text: zGemas.modelData === "modos" ? "MODOS" : "NERO VIGILA"
                            font.family: "Anton"
                            font.pixelSize: 10
                            font.letterSpacing: 2
                            color: root.apagadoM
                        }
                        Repeater {
                            model: root.g.gemas.filter(x => x.zona === zGemas.modelData)
                            Fila {
                                id: filaG
                                required property var modelData
                                readonly property int v: root.valorGema(modelData.id)
                                y: modelData.y
                                height: 48
                                llama: v === 2
                                onClic: root.accionGema(modelData.id)
                                Ico {
                                    anchors.verticalCenter: parent?.verticalCenter
                                    nombre: root.infoGemas[filaG.modelData.id]?.[0] ?? "ventana"
                                    color: filaG.v === 2 ? Espada.huesoAlto : (filaG.v ? root.colorGema(filaG.modelData.id) : root.tenueM)
                                }
                                Column {
                                    anchors.verticalCenter: parent?.verticalCenter
                                    width: Math.max(0, (parent?.width ?? 0) - x)
                                    spacing: 1
                                    Text {
                                        width: parent.width
                                        elide: Text.ElideRight
                                        text: root.infoGemas[filaG.modelData.id]?.[1] ?? filaG.modelData.id
                                        font.family: "Inter"
                                        font.pixelSize: 12
                                        font.weight: Font.Medium
                                        color: filaG.v === 2 || filaG.sobre ? Espada.huesoAlto : Espada.hueso
                                    }
                                    Text {
                                        width: parent.width
                                        elide: Text.ElideRight
                                        text: root.textoGema(filaG.modelData.id)
                                        font.family: "Inter"
                                        font.pixelSize: 11
                                        color: filaG.v === 2 ? Espada.huesoAlto : root.tenueM
                                    }
                                }
                            }
                        }
                    }
                }

                // ── agarre: la ventana al frente y las de este escritorio ──
                Zona {
                    id: zAgarre
                    activa: root.zona === "agarre"
                    readonly property real tope: root.rectZona("agarre")[0]

                    Row {
                        visible: !!root.alFrente
                        x: 14
                        y: zAgarre.tope + 14
                        spacing: 8
                        Ico {
                            anchors.verticalCenter: parent.verticalCenter
                            nombre: Espada.icoApp(root.alFrente?.lastIpcObject?.class ?? "")
                            color: Espada.hueso
                        }
                        Text {
                            text: (root.alFrente ? Espada.nombreApp(root.alFrente) : "").toUpperCase()
                            font.family: "Anton"
                            font.pixelSize: 12
                            font.letterSpacing: 2
                            color: Espada.hueso
                        }
                    }
                    Text {
                        visible: !!root.alFrente
                        x: 14
                        y: zAgarre.tope + 38
                        width: 248 - 14 - 22
                        text: root.alFrente?.title ?? ""
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        font.family: "Inter"
                        font.pointSize: 9.375 // 12.5 px
                        lineHeight: 16
                        lineHeightMode: Text.FixedHeight
                        color: Espada.hueso
                    }
                    Text {
                        visible: !!root.alFrente
                        x: 14
                        y: zAgarre.tope + 86
                        text: "EN ESTE ESCRITORIO"
                        font.family: "Anton"
                        font.pixelSize: 10
                        font.letterSpacing: 2
                        color: root.apagadoM
                    }
                    Repeater {
                        model: root.ventanasVisibles.slice(0, 8)
                        Fila {
                            id: filaV
                            required property var modelData
                            required property int index
                            y: zAgarre.tope + 106 + 28 * index
                            height: 28
                            frente: modelData === root.alFrente
                            onClic: root.enfocar(modelData)
                            onClicMedio: root.cerrar(modelData)
                            Ico {
                                anchors.verticalCenter: parent?.verticalCenter
                                nombre: Espada.icoApp(filaV.modelData.lastIpcObject?.class ?? "")
                                color: filaV.frente ? Espada.hueso : root.tenueM
                            }
                            FilaTexto {
                                text: Espada.nombreApp(filaV.modelData) + " — " + (filaV.modelData.title ?? "")
                                color: filaV.colorTexto
                            }
                        }
                    }
                    Column {
                        visible: !root.alFrente
                        x: 14
                        y: zAgarre.tope + 18
                        spacing: 6
                        Text {
                            text: "ESCRITORIO VACÍO"
                            font.family: "Anton"
                            font.pixelSize: 12
                            font.letterSpacing: 2
                            color: root.apagadoM
                        }
                        Text {
                            text: "Sin ventanas aquí."
                            font.family: "Inter"
                            font.pointSize: 9.375 // 12.5 px
                            color: root.apagadoM
                        }
                    }
                }

                // ── guarda: fecha, marcas con su nombre, bandeja y sesión ──
                Zona {
                    activa: root.zona === "guarda"

                    Column {
                        x: 14
                        y: root.g.clock0 + 12
                        Text {
                            text: root.fechaLarga
                            font.family: "Inter"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            lineHeight: 18
                            lineHeightMode: Text.FixedHeight
                            color: Espada.hueso
                        }
                        Text {
                            text: `${Time.hours % 12 || 12}:${String(Time.minutes).padStart(2, "0")} ${Time.hours >= 12 ? "p. m." : "a. m."} · semana ${root.semana}`
                            font.family: "Inter"
                            font.pixelSize: 12
                            lineHeight: 16
                            lineHeightMode: Text.FixedHeight
                            color: root.tenueM
                        }
                    }
                    Fila {
                        id: fRed
                        y: root.g.mar0
                        height: 18
                        chica: true
                        onClic: root.abrirPopout("network", root.g.mar0 + 9)
                        Ico { anchors.verticalCenter: parent?.verticalCenter; nombre: "red"; color: root.tenueM; tacha: !root.hayRed }
                        FilaTexto { chica: true; text: root.textoRed; color: fRed.colorTexto }
                    }
                    Fila {
                        id: fBt
                        y: root.g.mar0 + 18
                        height: 18
                        chica: true
                        onClic: root.abrirPopout("bluetooth", root.g.mar0 + 27)
                        onClicDerecho: root.alternarBt()
                        Ico { anchors.verticalCenter: parent?.verticalCenter; nombre: "bt"; color: root.tenueM; tacha: !root.btEncendido }
                        FilaTexto { chica: true; text: root.textoBt; color: fBt.colorTexto }
                    }
                    Fila {
                        id: fBandeja
                        y: root.g.mar0 + 36
                        height: 18
                        chica: true
                        Ico { anchors.verticalCenter: parent?.verticalCenter; nombre: "bandeja"; color: root.tenueM }
                        Text {
                            anchors.verticalCenter: parent?.verticalCenter
                            text: "Bandeja"
                            font.family: "Inter"
                            font.pointSize: 8.625 // 11.5 px
                            color: fBandeja.colorTexto
                        }
                        Row {
                            anchors.verticalCenter: parent?.verticalCenter
                            spacing: 9
                            leftPadding: 2
                            Repeater {
                                model: root.bandeja
                                MouseArea {
                                    id: icoB
                                    required property SystemTrayItem modelData
                                    width: 14
                                    height: 14
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                    cursorShape: Qt.PointingHandCursor
                                    scale: pressed ? 0.88 : 1
                                    onClicked: ev => {
                                        if (ev.button === Qt.LeftButton) {
                                            modelData.activate();
                                        } else if (ev.button === Qt.MiddleButton) {
                                            modelData.secondaryActivate();
                                        } else if (modelData.hasMenu) {
                                            const p = icoB.mapToItem(null, 0, icoB.height + 4);
                                            modelData.display(QsWindow.window, p.x, p.y);
                                        } else {
                                            modelData.secondaryActivate();
                                        }
                                    }
                                    IconImage {
                                        anchors.fill: parent
                                        implicitSize: 14
                                        source: Icons.getTrayIcon(icoB.modelData.id, icoB.modelData.icon, icoB.modelData.title)
                                        opacity: icoB.containsMouse ? 1 : 0.78
                                        layer.enabled: true
                                        layer.effect: MultiEffect {
                                            colorization: 1
                                            colorizationColor: Espada.hueso
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Fila {
                        id: fGraba
                        visible: Recorder.running
                        y: root.g.mar0 + 54
                        height: 18
                        chica: true
                        onClic: Recorder.stop()
                        Ico { anchors.verticalCenter: parent?.verticalCenter; nombre: "graba"; color: Espada.huesoAlto }
                        FilaTexto { chica: true; text: "Grabando · desde las " + root.grabaDesde; color: fGraba.colorTexto }
                    }
                    // sesión: centrada en el tramo que se jala
                    Row {
                        x: 14
                        y: root.g.jala0 + (root.height - root.g.jala0 - 14) / 2
                        height: 14
                        spacing: 9
                        Sesion { nombre: "candado"; texto: "BLOQUEAR"; onClic: root.bloquear() }
                        Sesion { nombre: "luna"; texto: "SUSPENDER"; onClic: root.tajoYLunas("hibernate") }
                        Sesion { nombre: "apagar"; texto: "APAGAR"; fuerte: true; onClic: root.tajoYLunas("shutdown") }
                    }
                }
            }
        }
    }

    // ════════════════════ el tajo (capa a pantalla completa, sin entrada; solo vive 380 ms) ════════════════════
    Shape {
        id: tajo
        z: 10
        visible: tajoAnim.running
        width: root.anchoPantalla
        height: root.height
        preferredRendererType: Shape.CurveRenderer
        property real p1: 0
        property real p2: 0
        property real o1: 1
        property real o2: 1
        readonly property real x0: 46
        readonly property real y0: root.height - 10
        readonly property real x1: root.anchoPantalla + 20
        readonly property real y1: Math.max(-20, root.height - 10 - root.anchoPantalla * 0.8)
        ShapePath {
            strokeColor: Qt.alpha(Espada.huesoAlto, tajo.o1)
            strokeWidth: 2.2
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"
            startX: tajo.x0; startY: tajo.y0
            PathLine { x: tajo.x0 + (tajo.x1 - tajo.x0) * tajo.p1; y: tajo.y0 + (tajo.y1 - tajo.y0) * tajo.p1 }
        }
        ShapePath {
            strokeColor: Qt.alpha(Espada.huesoAlto, tajo.o2)
            strokeWidth: 0.8
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"
            startX: tajo.x0; startY: tajo.y0 - 9
            PathLine { x: tajo.x0 + (tajo.x1 - tajo.x0) * tajo.p2; y: tajo.y0 - 9 + (tajo.y1 - tajo.y0) * tajo.p2 }
        }
    }
    ParallelAnimation {
        id: tajoAnim
        SequentialAnimation {
            PropertyAction { target: tajo; property: "o1"; value: 1 }
            NumberAnimation { target: tajo; property: "p1"; from: 0; to: 1; duration: 210; easing.type: Easing.BezierSpline; easing.bezierCurve: Espada.cEntra }
            NumberAnimation { target: tajo; property: "o1"; to: 0; duration: 170 }
        }
        SequentialAnimation {
            PropertyAction { target: tajo; property: "o2"; value: 1 }
            PropertyAction { target: tajo; property: "p2"; value: 0 }
            PauseAnimation { duration: 40 }
            NumberAnimation { target: tajo; property: "p2"; from: 0; to: 1; duration: 210; easing.type: Easing.BezierSpline; easing.bezierCurve: Espada.cEntra }
            NumberAnimation { target: tajo; property: "o2"; to: 0; duration: 170 }
        }
    }
    // 11-15 el tajo con la estela del elemento (DISENO.md §2.3): vive 900 ms. Para no pintar la pantalla completa
    // cada cuadro, el lienzo es una franja de 260 px girada a lo largo del corte (el dibujo va en coordenadas de pantalla).
    Item {
        id: tajoEl
        property real tau: -1
        readonly property var o: ({ ox: 43.4, oy: root.height - 10, W: root.anchoPantalla })
        readonly property real largo: El.largoTajo(o)
        readonly property real ang: Math.atan2(-0.8, 1)
        z: 10
        visible: tau >= 0
        x: o.ox
        y: o.oy
        rotation: ang * 180 / Math.PI
        transformOrigin: Item.TopLeft
        function empieza(): void {
            tau = 0;
            lienzoTajo.requestPaint();
        }
        FrameAnimation {
            running: tajoEl.tau >= 0
            property real ultimo: 0
            onTriggered: {
                tajoEl.tau += frameTime * 1000;
                if (tajoEl.tau >= 900) {
                    tajoEl.tau = -1;
                    return;
                }
                // tope de 60 repintados por segundo
                if (tajoEl.tau - ultimo >= 16) {
                    ultimo = tajoEl.tau;
                    lienzoTajo.requestPaint();
                }
            }
        }
        Canvas {
            id: lienzoTajo
            x: -60
            y: -130
            width: tajoEl.largo + 120
            height: 260
            renderTarget: Canvas.Image
            renderStrategy: Canvas.Cooperative
            onPaint: {
                const c = getContext("2d");
                c.reset();
                if (tajoEl.tau < 0)
                    return;
                c.translate(60, 130);
                c.rotate(-tajoEl.ang);
                c.translate(-tajoEl.o.ox, -tajoEl.o.oy);
                const e = root.eco, t = root.colMango.telaHex;
                const eco = [e.r * 255, e.g * 255, e.b * 255];
                const tc = Qt.color(t);
                El.tajo(c, tajoEl.tau, root.elemento, tajoEl.o, {
                    eco: eco,
                    temple: [255 + (eco[0] - 255) * 0.62, 250 + (eco[1] - 250) * 0.62, 240 + (eco[2] - 240) * 0.62],
                    base: [tc.r * 255, tc.g * 255, tc.b * 255]
                });
            }
        }
    }
    Timer {
        id: lunasEn
        interval: 170
        onTriggered: root.screenState.session = true
    }
    function tajoYLunas(foco: string): void {
        zonaHover = "";
        zonaFija = "";
        screenState.sesionFoco = foco;
        if (!Espada.mov) {
            screenState.session = true;
            return;
        }
        if (root.hv)
            tajoEl.empieza();
        else
            tajoAnim.restart();
        lunasEn.restart();
    }
    function bloquear(): void {
        Quickshell.execDetached(["qs", "-c", "caelestia", "ipc", "call", "lock", "lock"]);
    }

    // ── red, bluetooth, bandeja, grabación ──
    readonly property var es: Qt.locale("es_MX")
    readonly property bool hayRed: !!Nmcli.active || Nmcli.isConnected || !!Nmcli.activeEthernet
    readonly property bool vpn: VPN.connected
    readonly property string textoRed: {
        let t;
        if (Nmcli.active)
            t = `Red · ${Nmcli.active.ssid}`;
        else if (Nmcli.activeEthernet)
            t = "Red · cable";
        else if (Nmcli.isConnected)
            t = "Red · conectada";
        else
            t = "Red · sin conexión";
        return t + (vpn ? " · VPN" : "");
    }
    readonly property var adaptador: Bluetooth.defaultAdapter
    readonly property bool btEncendido: !!adaptador?.enabled
    readonly property string textoBt: {
        if (!btEncendido)
            return "Bluetooth · apagado";
        const d = Bluetooth.devices.values.find(x => x.connected);
        return d ? `Bluetooth · ${d.name || d.deviceName}` : "Bluetooth · sin dispositivo";
    }
    function alternarBt(): void {
        if (adaptador)
            adaptador.enabled = !adaptador.enabled;
    }
    readonly property var bandeja: SystemTray.items.values
    readonly property bool bandejaLlama: bandeja.some(i => i.status === Status.NeedsAttention)
    property string grabaDesde: ""
    Connections {
        target: Recorder
        function onRunningChanged(): void {
            if (Recorder.running)
                root.grabaDesde = Qt.formatTime(new Date(Date.now() - Recorder.elapsed * 1000), "h:mm");
        }
    }
    // fecha y semana: dependen de la hora (cambia una vez por hora), no de Time.date (cambia cada segundo)
    readonly property string fechaLarga: {
        const _h = Time.hours;
        return es.toString(new Date(), "dddd d 'de' MMMM");
    }
    readonly property int semana: {
        const _h = Time.hours;
        const hoy = new Date();
        const d = new Date(Date.UTC(hoy.getFullYear(), hoy.getMonth(), hoy.getDate()));
        const dia = d.getUTCDay() || 7;
        d.setUTCDate(d.getUTCDate() + 4 - dia);
        const ini = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
        return Math.ceil(((d - ini) / 86400000 + 1) / 7);
    }
    function abrirPopout(nombre: string, y: real): void {
        if (!popouts)
            return;
        zonaHover = "";
        zonaFija = "";
        popouts.currentName = nombre;
        popouts.currentCenter = y;
        popouts.hasCurrent = true;
    }

    // ════════════════════ piezas ════════════════════
    // v3 mejora 5: letra tallada en el metal = hueco oscuro arriba a la izquierda y canto tenue (marco) abajo a la
    // derecha, debajo del relleno (z −1 = detrás del Text padre). Copias del mismo texto: cuestan lo que un Text.
    component Grabado: Text {
        readonly property Text t: parent as Text
        z: -1
        width: t.width
        height: t.height
        text: t.text
        font: t.font
        elide: t.elide
        horizontalAlignment: t.horizontalAlignment
        verticalAlignment: t.verticalAlignment
        opacity: 1
    }
    component Surco: Grabado {
        x: -0.7
        y: -0.8
        color: Qt.rgba(0, 0, 0, 0.75)
    }
    component Canto: Grabado {
        x: 0.6
        y: 0.7
        color: Qt.alpha(root.colMango.marcoHex, 0.16)
    }
    // dígitos de la hora: los que cambian entran desde 7 px abajo
    component Digitos: Text {
        id: dig
        property bool primera: true
        width: 56
        height: 28
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.family: "Anton"
        font.pixelSize: 26
        font.letterSpacing: 1
        font.features: ({ "tnum": 1 })
        color: Espada.huesoAlto
        Surco {}
        Canto {}
        onTextChanged: {
            if (primera) {
                primera = false;
                return;
            }
            if (Espada.mov)
                entraDig.restart();
        }
        transform: Translate { id: trDig; y: 0 }
        ParallelAnimation {
            id: entraDig
            NumberAnimation { target: trDig; property: "y"; from: 7; to: 0; duration: Espada.dColor; easing.type: Easing.BezierSpline; easing.bezierCurve: Espada.cEntra }
            NumberAnimation { target: dig; property: "opacity"; from: 0; to: 1; duration: Espada.dColor }
        }
    }

    // marca grabada en la hoja (13 px, centrada en x = 29, sombra de 1 px que la hace leer como grabado)
    component Marca: MouseArea {
        id: marca
        property int fila: 0
        property string nombre: "red"
        property bool apagada: false
        property color colorBase: Espada.hueso
        property real op: 0.8
        signal clic
        signal clicDerecho
        x: 1
        y: 18 * fila
        width: 56
        height: 18
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: ev => ev.button === Qt.RightButton ? clicDerecho() : clic()
        // con la hoja nueva la marca se VE en la ventanita de la hoja (MarcaVista allá) y aquí solo recibe el mouse
        MarcaVista {
            visible: !root.hv
            de: marca
        }
    }
    component MarcaVista: Item {
        id: vista
        required property Item de
        x: 28 - 6.5
        y: 2.5
        width: 13
        height: 13
        scale: vista.de.pressed ? 0.88 : 1
        Behavior on scale { NumberAnimation { duration: Espada.dToque } }
        opacity: vista.de.containsMouse ? 1 : vista.de.op
        Behavior on opacity { NumberAnimation { duration: Espada.dColor } }
        Ico { y: 1; tam: 13; nombre: vista.de.nombre; tacha: vista.de.apagada; color: Qt.rgba(0, 0, 0, 0.7); animarColor: false }
        Ico { tam: 13; nombre: vista.de.nombre; tacha: vista.de.apagada; color: vista.de.containsMouse ? Espada.huesoAlto : vista.de.colorBase }
    }

    // contenedor de una zona de la placa: el anterior sale en dToque, el nuevo entra 40 ms después con 8 px
    component Zona: Item {
        id: zonaC
        property bool activa: false
        property Item filaSobre: null      // foco por atenuación: con el cursor sobre una fila, las demás al 45 %
        width: 248
        height: root.height
        opacity: activa ? 1 : 0
        visible: opacity > 0
        enabled: activa
        transform: Translate {
            x: zonaC.activa ? 0 : -8
            Behavior on x { NumberAnimation { duration: Espada.dFilo; easing.type: Easing.BezierSpline; easing.bezierCurve: Espada.cEntra } }
        }
        Behavior on opacity {
            SequentialAnimation {
                PauseAnimation { duration: zonaC.activa && Espada.mov ? 40 : 0 }
                NumberAnimation { duration: zonaC.activa ? Espada.dColor : Espada.dToque }
            }
        }
    }

    // fila de placa: ícono + texto; cursor encima = huesoAlto y las demás de su zona al 45 %; presionada = 2 px a la derecha
    component Fila: MouseArea {
        id: fila
        property bool frente: false
        property bool vacia: false
        property bool llama: false
        property bool chica: false
        readonly property bool sobre: containsMouse
        readonly property color colorTexto: sobre || frente || llama ? Espada.huesoAlto : (vacia ? root.apagadoM : root.tenueM)
        readonly property Item zonaPadre: parent
        default property alias contenido: filaRow.data
        signal clic
        signal clicDerecho
        signal clicMedio
        x: 14
        width: 248 - 14 - 22
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: ev => ev.button === Qt.RightButton ? clicDerecho() : (ev.button === Qt.MiddleButton ? clicMedio() : clic())
        onSobreChanged: {
            if (!zonaPadre || zonaPadre.filaSobre === undefined)
                return;
            if (sobre)
                zonaPadre.filaSobre = fila;
            else if (zonaPadre.filaSobre === fila)
                zonaPadre.filaSobre = null;
        }
        opacity: zonaPadre?.filaSobre && zonaPadre.filaSobre !== fila ? 0.45 : 1
        Behavior on opacity { NumberAnimation { duration: Espada.dToque } }
        Rectangle {
            visible: fila.frente
            anchors.verticalCenter: parent.verticalCenter
            width: 2
            height: 14
            color: Espada.hueso
        }
        Row {
            id: filaRow
            x: (fila.frente ? 10 : 0) + (fila.pressed ? 2 : 0)
            width: fila.width - (fila.frente ? 10 : 0)
            height: parent.height
            spacing: 8
            Behavior on x { NumberAnimation { duration: Espada.dToque } }
        }
    }
    component FilaTexto: Text {
        property bool chica: false
        anchors.verticalCenter: parent?.verticalCenter
        width: Math.max(0, (parent?.width ?? 0) - x)
        elide: Text.ElideRight
        font.family: "Inter"
        font.pointSize: (chica ? 11.5 : 12) * 0.75 // px
        Behavior on color { ColorAnimation { duration: Espada.dColor } }
    }

    component Sesion: MouseArea {
        id: ses
        property string nombre
        property string texto
        property bool fuerte: false
        signal clic
        width: filaS.implicitWidth
        height: 14
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: clic()
        scale: pressed ? 0.95 : 1
        Row {
            id: filaS
            spacing: 5
            height: 14
            Ico {
                anchors.verticalCenter: parent.verticalCenter
                tam: 11
                nombre: ses.nombre
                color: lbl.color
            }
            Text {
                id: lbl
                anchors.verticalCenter: parent.verticalCenter
                text: ses.texto
                font.family: "Inter"
                font.pointSize: 7.125 // 9.5 px
                font.weight: Font.Medium
                font.letterSpacing: 0.3
                color: ses.containsMouse ? Espada.huesoAlto : (ses.fuerte ? Espada.hueso : root.tenueM)
            }
        }
    }
}
