import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services

// Hora local grande + fecha + otras ciudades (con horario de verano correcto, vía `date`).
Card {
    id: root

    property string place: "Los Mochis"
    // [nombre, zona horaria]
    property var cities: [["Monterrey", "America/Monterrey"], ["Nueva York", "America/New_York"], ["Tokyo", "Asia/Tokyo"], ["Colombia", "America/Bogota"]]
    property var cityTimes: []

    readonly property var locale: Qt.locale("es_MX")

    implicitWidth: 300 * Theme.scale
    implicitHeight: col.implicitHeight + 32 * Theme.scale

    SystemClock {
        id: clock

        precision: SystemClock.Seconds
        onDateChanged: if (date.getSeconds() === 0 || root.cityTimes.length === 0) cityProc.running = true
    }

    Process {
        id: cityProc

        command: ["sh", "-c", root.cities.map(c => `LC_ALL=C TZ='${c[1]}' date '+%-I:%M|%P|%H|%:::z'`).join(";")]
        stdout: StdioCollector {
            onStreamFinished: root.cityTimes = text.trim().split("\n").map(l => l.split("|"))
        }
    }

    ColumnLayout {
        id: col

        anchors.fill: parent
        anchors.margins: 16 * Theme.scale
        spacing: 4 * Theme.scale

        RowLayout {
            spacing: 4 * Theme.scale

            Icon {
                size: 16
                text: "location_on"
                fill: false
            }

            Txt {
                size: 13
                text: root.place
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 6 * Theme.scale

            Txt {
                size: 40
                font.weight: Font.Bold
                text: clock.date.toLocaleTimeString(root.locale, "h:mm")
            }

            Txt {
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 8 * Theme.scale
                size: 14
                color: Theme.cardTextDim
                text: clock.date.getHours() < 12 ? "a.m." : "p.m."
            }
        }

        Txt {
            Layout.alignment: Qt.AlignRight
            size: 12
            color: Theme.cardTextDim
            text: {
                const s = clock.date.toLocaleDateString(root.locale, "dddd, d 'de' MMMM yyyy");
                return s.charAt(0).toUpperCase() + s.slice(1);
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.topMargin: 8 * Theme.scale
            columns: 2
            rowSpacing: 8 * Theme.scale
            columnSpacing: 8 * Theme.scale

            Repeater {
                model: root.cities

                Rectangle {
                    id: city

                    required property var modelData
                    required property int index
                    readonly property var t: root.cityTimes[index] ?? ["--:--", "", "12", ""]
                    readonly property int hour: parseInt(t[2])

                    Layout.fillWidth: true
                    implicitHeight: 52 * Theme.scale
                    radius: 14 * Theme.scale
                    color: Theme.inner

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8 * Theme.scale
                        spacing: 0

                        RowLayout {
                            Layout.fillWidth: true

                            Txt {
                                Layout.fillWidth: true
                                size: 10
                                elide: Text.ElideRight
                                text: city.modelData[0]
                            }

                            Txt {
                                size: 9
                                color: Theme.cardTextDim
                                text: "UTC" + city.t[3]
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            Txt {
                                Layout.fillWidth: true
                                size: 15
                                font.weight: Font.Bold
                                text: city.t[0] + " " + (city.t[1] === "am" ? "a.m." : city.t[1] === "pm" ? "p.m." : "")
                            }

                            Icon {
                                size: 13
                                color: Theme.cardTextDim
                                text: city.hour >= 7 && city.hour < 19 ? "light_mode" : "dark_mode"
                            }
                        }
                    }
                }
            }
        }
    }
}
