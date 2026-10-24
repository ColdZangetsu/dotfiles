//@ pragma UseQApplication
import QtQuick
import Quickshell
import qs.components
import qs.services

// Widgets de escritorio sobre Caelestia. Se inicia con: qs -c widgets
ShellRoot {
    id: root

    readonly property var mon: Quickshell.screens.find(s => s.model.includes("XG27ACDMS")) ?? Quickshell.screens[0]
    readonly property real s: Theme.scale
    readonly property real gap: 16 * s
    // Caelestia usa ~90 px desde la orilla de arriba para gestos de arrastre en escritorios vacíos;
    // los widgets van debajo para que los clics del calendario lleguen.
    readonly property real top: 100
    readonly property real left: 80 * s


    // Posición inicial de cada widget (en fila). Al arrastrarlos se guarda la nueva posición.
    readonly property real calX: left
    readonly property real clockX: calX + calWin.implicitWidth + gap
    readonly property real tileX: clockX + clockWin.implicitWidth + gap
    readonly property real tileStep: cpuWin.implicitWidth + gap
    readonly property real weatherX: tileX + tileStep * 4

    function gb(bytes) {
        return Math.round(bytes / 1e9);
    }

    DesktopWindow {
        id: calWin

        key: "calendario"
        screen: root.mon
        defaultX: root.calX
        defaultY: root.top

        CalendarCard {}
    }

    DesktopWindow {
        id: clockWin

        key: "reloj"
        screen: root.mon
        defaultX: root.clockX
        defaultY: root.top

        ClockCard {}
    }

    DesktopWindow {
        id: cpuWin

        key: "cpu"
        screen: root.mon
        defaultX: root.tileX
        defaultY: root.top

        StatTile {
            icon: "memory"
            value: SysStats.cpu + "%"
            label: "CPU"
        }
    }

    DesktopWindow {
        key: "ram"
        screen: root.mon
        defaultX: root.tileX + root.tileStep
        defaultY: root.top

        StatTile {
            icon: "memory_alt"
            value: SysStats.ram + "%"
            label: "RAM"
        }
    }

    DesktopWindow {
        key: "gpu"
        screen: root.mon
        defaultX: root.tileX + root.tileStep * 2
        defaultY: root.top

        StatTile {
            icon: "developer_board"
            value: SysStats.gpu + "%"
            label: "GPU"
        }
    }

    DesktopWindow {
        key: "disco"
        screen: root.mon
        defaultX: root.tileX + root.tileStep * 3
        defaultY: root.top

        StatTile {
            icon: "hard_drive"
            value: SysStats.disk + "%"
            label: "Disco"
            note: SysStats.diskSize > 0 ? root.gb(SysStats.diskUsed) + " de " + root.gb(SysStats.diskSize) + " GB" : ""
        }
    }


    DesktopWindow {
        key: "clima"
        screen: root.mon
        defaultX: root.weatherX
        defaultY: root.top

        WeatherCard {}
    }
}
