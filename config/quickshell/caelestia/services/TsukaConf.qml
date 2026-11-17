pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// 11-15 Tsuka + Saya (diseño final de Fable, COMUN.md §6 y §11). Ver TSUKA-SAYA.md en la raíz de esta copia.
// - Interruptor: ~/.config/caelestia/tsuka.json (se vigila: cambia en vivo, sin reiniciar)
//   {"activa", "saya", "lenguasNero", "movimiento", "gemasArriba", "gemasAbajo"}; ausente o roto = todo como antes.
// - Nero: ~/.local/state/nero/estado + mensajes.jsonl (los escribe ~/.local/bin/nero-estado). Sin sondeo.
// - Gemas: ~/.local/state/nero/gemas/<nombre> ("0|1|2\ntexto"; ~/.local/bin/nero-gema). Sin sondeo.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string rutaInterruptor: home + "/.config/caelestia/tsuka.json"
    readonly property string dirNero: home + "/.local/state/nero"
    readonly property string comando: home + "/.local/bin/nero-estado"

    // ── interruptor ──
    readonly property var conf: {
        try {
            const d = JSON.parse(interruptor.text() || "{}");
            return d && typeof d === "object" ? d : {};
        } catch (e) {
            return {};
        }
    }
    readonly property bool activa: conf.activa === true
    readonly property bool saya: conf.saya === true
    readonly property bool lenguas: conf.lenguasNero !== false
    readonly property bool movimiento: conf.movimiento !== false
    // 11-16: la gema «trabajo» ahora es «casa» (encendida en modo casa); un tsuka.json viejo con "trabajo" sigue valiendo
    readonly property var gemasArriba: (Array.isArray(conf.gemasArriba) ? conf.gemasArriba : ["casa", "musica", "cine", "juego"]).map(g => g === "trabajo" ? "casa" : g)
    readonly property var gemasAbajo: Array.isArray(conf.gemasAbajo) ? conf.gemasAbajo : ["zangetsu", "stream", "apagado", "respaldo", "temp"]
    // 11-15 hilo rojo y hoja con elemento (tsuka-transicion-elementos). Todo encendido por omisión:
    //   "hiloRojo": false  -> el filo rojo de antes (marco que se desliza)
    //   "hojaElemento": false -> la hoja SVG de antes (sin elemento, sin ventanita)
    //   "hojaViva": false  -> la hoja con elemento, pero quieta en reposo (solo se mueve al tocarla)
    //   "hojaFps": 12      -> cuadros por segundo de la hoja viva en reposo (30 = más fluida, ~2.5x el costo)
    //   "elemento": {"DP-1": "fuego", ...} -> agua | fuego | viento | ninguno por monitor (si falta: por el tono de la tela)
    //   "respiroMinuto": true -> el temple respira una vez al cambiar el minuto (monitor con foco)
    readonly property bool hiloRojo: conf.hiloRojo !== false
    readonly property bool hojaElemento: conf.hojaElemento !== false
    readonly property bool hojaViva: conf.hojaViva !== false
    readonly property int hojaFps: typeof conf.hojaFps === "number" ? Math.max(1, Math.min(120, conf.hojaFps)) : 12
    readonly property var elementos: conf.elemento && typeof conf.elemento === "object" ? conf.elemento : ({ "DP-1": "fuego" })
    readonly property bool respiroMinuto: conf.respiroMinuto === true
    // la hoja viva se congela en modo trabajo (pantallas apagadas / STREAM al iPad) y tras 3 min sin actividad
    // (lo mismo que tarda en bloquearse; también cubre el apagado de pantallas a los 5 min)
    readonly property bool enTrabajo: (gemas.casa?.v ?? 1) === 0
    readonly property bool inactivo: vigiaInactivo.isIdle
    IdleMonitor {
        id: vigiaInactivo
        timeout: 180
        respectInhibitors: true
    }

    function guardarConf(cambios: var): void {
        const d = Object.assign({}, conf, cambios);
        interruptor.setText(JSON.stringify(d, null, 1) + "\n");
    }
    function alternarLenguas(): void {
        guardarConf({ lenguasNero: !lenguas });
    }

    // ── Nero ──
    // duerme | vigila | escucha | trabaja | escribio
    property string estado: "vigila"
    property string texto: ""
    property real hora: 0
    property int avance: -1
    property var mensajes: []           // todos (máx 20), el más nuevo al final
    readonly property int noLeidos: mensajes.filter(m => !m.leido).length
    readonly property var ultimos: mensajes.slice(-3).reverse()
    readonly property string ultimoTexto: mensajes.length ? mensajes[mensajes.length - 1].texto : ""
    property real masNuevo: -1          // hora del mensaje más nuevo ya visto (-1 = aún no se lee)
    property int pideLengua: 0          // sube cada vez que alguien pide "¿qué dijiste?" (clic en el ojo)
    property int parpadeo: 0            // sube al leer: el ojo parpadea
    property var arrancadas: []         // pantallas que ya hicieron la secuencia de arranque (no se repite al volver de pantalla completa)

    signal nuevoMensaje(string texto)

    readonly property string dice: {
        switch (estado) {
        case "duerme":
            return texto || "Sin enlace con Zangetsu.";
        case "escucha":
            return texto || "Habla; te está oyendo.";
        case "trabaja":
            return (texto || "Trabajando…") + (avance >= 0 ? ` · ${avance} %` : "");
        case "escribio":
            return "Su mensaje está en la vaina.";
        default:
            return noLeidos ? "Su mensaje está en la vaina." : (texto || "Todo en orden.");
        }
    }

    readonly property int caducaTrabaja: 3 * 60 * 60

    // Leer (vaina, clic en la lengua, o WhatsApp vía el bot): todo leído y, si estaba en escribio, vuelve a vigila
    function leido(): void {
        if (!noLeidos && estado !== "escribio")
            return;
        mensajes = mensajes.map(m => Object.assign({}, m, { leido: true }));
        if (estado === "escribio") {
            estado = "vigila";
            texto = "";
        }
        parpadeo++;
        escritor.command = [comando, "leido"];
        escritor.running = false;
        escritor.running = true;
    }

    function repite(): void {
        pideLengua++;
    }

    function leerEstado(t: string): void {
        let d = null;
        try {
            d = JSON.parse(t);
        } catch (e) {
            d = null;
        }
        const e = d && ["duerme", "vigila", "escucha", "trabaja", "escribio"].includes(d.estado) ? d.estado : "vigila";
        hora = d && d.hora ? Number(d.hora) : 0;
        texto = d && typeof d.texto === "string" ? d.texto : "";
        avance = d && typeof d.avance === "number" ? Math.max(0, Math.min(100, Math.round(d.avance))) : -1;
        estado = e;
        programarCaducidad();
    }

    function leerMensajes(t: string): void {
        const lista = [];
        for (const linea of (t || "").split("\n")) {
            if (!linea.trim())
                continue;
            try {
                const m = JSON.parse(linea);
                if (m && typeof m.texto === "string")
                    lista.push({ hora: Number(m.hora) || 0, texto: m.texto, leido: !!m.leido });
            } catch (e) {}
        }
        const max = lista.reduce((a, m) => Math.max(a, m.hora), 0);
        const antes = masNuevo;
        mensajes = lista;
        masNuevo = max;
        // solo un mensaje nuevo SIN LEER que llegó con el shell ya corriendo saca la lengua
        if (antes >= 0 && max > antes) {
            const ult = lista[lista.length - 1];
            if (ult && !ult.leido)
                nuevoMensaje(ult.texto);
        }
    }

    function programarCaducidad(): void {
        caducar.stop();
        if (estado !== "trabaja")
            return;
        const falta = (hora + caducaTrabaja) * 1000 - Date.now();
        if (falta <= 0) {
            ponerVigila();
            return;
        }
        caducar.interval = Math.min(falta + 500, 2147483000);
        caducar.start();
    }

    function ponerVigila(): void {
        estado = "vigila";
        texto = "";
        avance = -1;
        escritor.command = [comando, "vigila"];
        escritor.running = false;
        escritor.running = true;
    }

    Timer {
        id: caducar
        repeat: false
        onTriggered: root.ponerVigila()
    }

    Process {
        id: escritor
        command: [root.comando, "vigila"]
    }

    FileView {
        id: interruptor
        path: root.rutaInterruptor
        blockLoading: true // así la primera barra que se crea ya sabe cuál es (sin parpadeo de la de antes)
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
    }

    FileView {
        path: root.dirNero + "/estado"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.leerEstado(text())
        onLoadFailed: root.leerEstado("")
    }

    FileView {
        path: root.dirNero + "/mensajes.jsonl"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.leerMensajes(text())
        onLoadFailed: root.leerMensajes("")
    }

    // ── gemas: {nombre: {v: 0|1|2, t: "texto"}} ──
    property var gemas: ({})
    function ponGema(nombre: string, t: string): void {
        const lineas = (t || "").split("\n");
        const v = Math.max(0, Math.min(2, parseInt(lineas[0]) || 0));
        const g = Object.assign({}, gemas);
        g[nombre] = { v: v, t: (lineas[1] || "").trim() };
        gemas = g;
    }

    component ArchivoGema: FileView {
        required property string nombre
        path: root.dirNero + "/gemas/" + nombre
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.ponGema(nombre, text())
        onLoadFailed: root.ponGema(nombre, nombre === "casa" ? "1" : "0")   // sin archivo: en casa
    }
    ArchivoGema { nombre: "casa" }
    ArchivoGema { nombre: "musica" }
    ArchivoGema { nombre: "cine" }
    ArchivoGema { nombre: "juego" }
    ArchivoGema { nombre: "zangetsu" }
    ArchivoGema { nombre: "stream" }
    ArchivoGema { nombre: "apagado" }
    ArchivoGema { nombre: "respaldo" }
    ArchivoGema { nombre: "temp" }

    // ── IPC: las barras del monitor con foco atienden estas señales ──
    signal empunar(string zona)
    signal soltar
    signal probarTajo
    signal desenvainar(bool abrir)
    signal sayaNero
    signal sayaOsd(string que)

    IpcHandler {
        target: "tsuka"

        function estado(): string {
            return `${root.activa ? "activa" : "apagada"} · saya=${root.saya ? "sí" : "no"} · nero=${root.estado} ${root.texto}${root.avance >= 0 ? " " + root.avance + "%" : ""} · sin leer=${root.noLeidos} · lenguas=${root.lenguas ? "sí" : "no"}`;
        }
        function empunar(zona: string): void {
            root.empunar(zona || "guarda");
        }
        function soltar(): void {
            root.soltar();
        }
        // solo el tajo con su estela, sin abrir las lunas (para verlo / probarlo), en el monitor con foco
        function tajo(): void {
            root.probarTajo();
        }
    }

    IpcHandler {
        target: "saya"

        function desenvainar(): void {
            root.desenvainar(true);
        }
        function envainar(): void {
            root.desenvainar(false);
        }
        function nero(): void {
            root.sayaNero();
        }
        function osd(que: string): void {
            root.sayaOsd(que || "volumen");
        }
    }
}
