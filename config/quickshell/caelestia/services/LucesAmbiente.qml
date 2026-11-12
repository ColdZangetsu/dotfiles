pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// 11-12: estado de la barra de luces del OSD (día ↔ noche de luz1/luz2). Backend: ~/.local/bin/luces-ambiente
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.local/state/luces-ambiente"
    readonly property string script: Quickshell.env("HOME") + "/.local/bin/luces-ambiente"

    property real value: 1.0
    property real pendiente: -1
    property real ultimo: -1
    signal mostrar

    // Mientras arrastras: como mucho una orden cada 140 ms (+ la última al soltar)
    function set(v: real): void {
        value = v;
        pendiente = v;
        if (!espera.running)
            espera.start();
    }

    Timer {
        id: espera
        interval: 140
        repeat: false
        onTriggered: {
            if (root.pendiente < 0)
                return;
            if (proc.running) {
                espera.start();
                return;
            }
            root.ultimo = root.pendiente;
            proc.command = [root.script, "set", root.pendiente.toFixed(4)];
            root.pendiente = -1;
            proc.running = true;
        }
    }

    Process {
        id: proc
        onRunningChanged: {
            if (!running && root.pendiente >= 0)
                espera.start();
        }
    }

    // valor guardado (para empezar en el sitio donde quedó)
    FileView {
        path: root.dir + "/valor"
        watchChanges: true
        onLoaded: {
            const v = parseFloat(text());
            if (!isNaN(v) && root.pendiente < 0 && !proc.running && Math.abs(v - root.ultimo) > 0.0005)
                root.value = Math.max(0, Math.min(1, v));
        }
        onFileChanged: reload()
    }

    // Super+L → `luces-ambiente mostrar` escribe este archivo y el OSD enseña la barra
    FileView {
        path: root.dir + "/mostrar"
        watchChanges: true
        onFileChanged: {
            reload();
            root.mostrar();
        }
    }
}
