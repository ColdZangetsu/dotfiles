pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Clima desde wttr.in, en español y °C. Se actualiza cada 15 minutos.
Singleton {
    id: root

    // Vacío = detectar por IP. Para fijar la ciudad: "Mazatlan", "Hermosillo", etc.
    readonly property string location: "Phoenix, Arizona"

    property bool ok: false
    property int temp: 0
    property int feels: 0
    property string desc: ""
    property string place: ""
    property int humidity: 0
    property int rainChance: 0
    property int wind: 0
    property int visibility: 0
    property string sunrise: ""
    property string sunset: ""
    property int code: 113

    readonly property string icon: iconFor(code)

    function iconFor(c) {
        if (c === 113) return "clear_day";
        if (c === 116) return "partly_cloudy_day";
        if (c === 119 || c === 122) return "cloud";
        if ([143, 248, 260].includes(c)) return "foggy";
        if ([200, 386, 389, 392, 395].includes(c)) return "thunderstorm";
        if ([179, 227, 230, 323, 326, 329, 332, 335, 338, 368, 371].includes(c)) return "weather_snowy";
        return "rainy";
    }

    // "06:22 AM" -> "6:22 a.m."
    function fmtTime(t) {
        const m = t.match(/(\d+):(\d+)\s*(AM|PM)/);
        return m ? `${parseInt(m[1])}:${m[2]} ${m[3] === "AM" ? "a.m." : "p.m."}` : t;
    }

    Timer {
        interval: 15 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }

    Process {
        id: proc

        command: ["curl", "-s", "-m", "20", `https://wttr.in/${encodeURIComponent(root.location)}?format=j1&lang=es`]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    const c = d.current_condition[0];
                    const today = d.weather[0];
                    const area = d.nearest_area[0];
                    root.temp = parseInt(c.temp_C);
                    root.feels = parseInt(c.FeelsLikeC);
                    root.desc = (c.lang_es?.[0]?.value ?? c.weatherDesc[0].value).trim();
                    root.place = area.areaName[0].value;
                    root.humidity = parseInt(c.humidity);
                    root.wind = parseInt(c.windspeedKmph);
                    root.visibility = parseInt(c.visibility);
                    root.code = parseInt(c.weatherCode);
                    const hour = new Date().getHours();
                    const slot = today.hourly.reduce((best, h) => Math.abs(parseInt(h.time) / 100 - hour) < Math.abs(parseInt(best.time) / 100 - hour) ? h : best);
                    root.rainChance = parseInt(slot.chanceofrain);
                    root.sunrise = root.fmtTime(today.astronomy[0].sunrise);
                    root.sunset = root.fmtTime(today.astronomy[0].sunset);
                    root.ok = true;
                } catch (e) {}
            }
        }
    }
}
