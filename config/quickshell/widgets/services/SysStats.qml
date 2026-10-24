pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Uso de CPU, RAM, GPU (NVIDIA) y disco en porcentaje.
Singleton {
    id: root

    property int cpu: 0
    property int ram: 0
    property int gpu: 0
    property int disk: 0
    property real diskUsed: 0 // bytes
    property real diskSize: 0

    property real lastTotal: 0
    property real lastIdle: 0

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
        }
    }

    FileView {
        id: stat

        path: "/proc/stat"
        onLoaded: {
            const f = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = f[3] + f[4];
            const total = f.reduce((a, b) => a + b, 0);
            const dt = total - root.lastTotal;
            if (root.lastTotal > 0 && dt > 0)
                root.cpu = Math.round(100 * (1 - (idle - root.lastIdle) / dt));
            root.lastTotal = total;
            root.lastIdle = idle;
        }
    }

    FileView {
        id: meminfo

        path: "/proc/meminfo"
        onLoaded: {
            const t = text();
            const total = Number(t.match(/MemTotal:\s+(\d+)/)?.[1] ?? 0);
            const avail = Number(t.match(/MemAvailable:\s+(\d+)/)?.[1] ?? 0);
            if (total > 0)
                root.ram = Math.round(100 * (1 - avail / total));
        }
    }

    // nvidia-smi se queda corriendo y manda una línea cada 2 s
    Process {
        id: nvidia

        running: true
        command: ["nvidia-smi", "--query-gpu=utilization.gpu", "--format=csv,noheader,nounits", "-l", "2"]
        stdout: SplitParser {
            onRead: data => {
                const v = parseInt(data);
                if (!isNaN(v))
                    root.gpu = v;
            }
        }
        onExited: restartGpu.start()
    }

    Timer {
        id: restartGpu

        interval: 10000
        onTriggered: nvidia.running = true
    }

    // Disco donde está Linux (/), cambia lento: cada 30 s
    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: df.running = true
    }

    Process {
        id: df

        command: ["df", "-B1", "--output=used,size", "/"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split("\n").pop().trim().split(/\s+/).map(Number);
                if (f.length === 2 && f[1] > 0) {
                    root.diskUsed = f[0];
                    root.diskSize = f[1];
                    root.disk = Math.round(100 * f[0] / f[1]);
                }
            }
        }
    }
}
