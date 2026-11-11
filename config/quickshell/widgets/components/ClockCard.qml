import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services

// Hora local grande + fecha + otras ciudades (con horario de verano correcto, vía `date`).
Card {
    id: root

    property string place: "Casa"
    // [nombre, zona horaria]
    property var cities: [["Monterrey", "America/Monterrey"], ["Nueva York", "America/New_York"], ["Tokyo", "Asia/Tokyo"], ["Colombia", "America/Bogota"]]
    property var cityTimes: []

    readonly property var locale: Qt.locale("es_MX")

    implicitWidth: 300 * Theme.scale
    implicitHeight: col.implicitHeight + 32 * Theme.scale

    // Por minuto (antes por segundo): la tarjeta no muestra segundos.
    SystemClock {
        id: clock

        precision: SystemClock.Minutes
        onDateChanged: cityProc.running = true
    }

    Process {
        id: cityProc

        running: true
        command: ["sh", "-c", root.cities.map(c => `LC_ALL=C TZ='${c[1]}' date '+%-I:%M|%P|%H|%:::z'`).join(";")]
        stdout: StdioCollector {
            onStreamFinished: root.cityTimes = text.trim().split("\n").map(l => l.split("|"))
        }
    }

    ColumnLayout {
        id: col

        anchors.fill: parent
        anchors.margins: 16 * Theme.scale
        spacing: 2 * Theme.scale

        RowLayout {
            spacing: 6 * Theme.scale

            Rectangle {
                implicitWidth: 5 * Theme.scale
                implicitHeight: implicitWidth
                radius: width / 2
                color: Theme.accent
            }

            Label {
                text: root.place
            }
        }

        RowLayout {
            spacing: 6 * Theme.scale

            Txt {
                size: 58
                font.family: Theme.titleFont
                text: clock.date.toLocaleTimeString(root.locale, "h:mm")
            }

            Txt {
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 11 * Theme.scale
                size: 14
                color: Theme.cardTextDim
                text: clock.date.getHours() < 12 ? "a.m." : "p.m."
            }
        }

        Txt {
            size: 12
            color: Theme.cardTextDim
            text: {
                const s = clock.date.toLocaleDateString(root.locale, "dddd, d 'de' MMMM yyyy");
                return s.charAt(0).toUpperCase() + s.slice(1);
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 12 * Theme.scale
            implicitHeight: 1
            color: Theme.line
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.topMargin: 10 * Theme.scale
            columns: 2
            rowSpacing: 10 * Theme.scale
            columnSpacing: 18 * Theme.scale

            Repeater {
                model: root.cities

                ColumnLayout {
                    id: city

                    required property var modelData
                    required property int index
                    readonly property var t: root.cityTimes[index] ?? ["--:--", "", "12", ""]
                    readonly property int hour: parseInt(t[2])

                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    spacing: 1 * Theme.scale

                    RowLayout {
                        Layout.fillWidth: true

                        Label {
                            Layout.fillWidth: true
                            size: 9
                            font.letterSpacing: 1 * Theme.scale
                            elide: Text.ElideRight
                            text: city.modelData[0]
                        }

                        Txt {
                            size: 9
                            color: Theme.cardTextDim
                            opacity: 0.7
                            text: "UTC" + city.t[3]
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4 * Theme.scale

                        Txt {
                            size: 16
                            font.weight: Font.DemiBold
                            text: city.t[0]
                        }

                        Txt {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignBaseline
                            size: 10
                            color: Theme.cardTextDim
                            text: city.t[1] === "am" ? "a.m." : city.t[1] === "pm" ? "p.m." : ""
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
