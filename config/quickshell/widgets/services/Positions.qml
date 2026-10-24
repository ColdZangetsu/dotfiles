pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Posiciones guardadas de los widgets (los que arrastras con el mouse).
Singleton {
    id: root

    property var saved: ({})

    function get(key) {
        return saved[key];
    }

    function set(key, x, y) {
        const next = Object.assign({}, saved);
        next[key] = [Math.round(x), Math.round(y)];
        saved = next;
    }

    function save() {
        file.setText(JSON.stringify(saved, null, 2) + "\n");
    }

    function reset() {
        saved = {};
        save();
    }

    FileView {
        id: file

        path: Quickshell.env("HOME") + "/.local/state/widgets-escritorio/positions.json"
        printErrors: false
        atomicWrites: true
        onLoaded: {
            try {
                root.saved = JSON.parse(text()) ?? {};
            } catch (e) {}
        }
    }

    IpcHandler {
        target: "widgets"

        // qs -c widgets ipc call widgets resetPositions
        function resetPositions(): void {
            root.reset();
        }
    }
}
