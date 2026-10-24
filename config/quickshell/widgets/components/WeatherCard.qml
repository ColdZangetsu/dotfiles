import QtQuick
import QtQuick.Layouts
import qs.services

Card {
    id: root

    implicitWidth: 360 * Theme.scale
    implicitHeight: 110 * Theme.scale

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14 * Theme.scale
        spacing: 12 * Theme.scale

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2 * Theme.scale

            RowLayout {
                Layout.fillWidth: true
                spacing: 10 * Theme.scale

                Txt {
                    size: 30
                    font.weight: Font.Bold
                    text: Weather.ok ? Weather.temp + "°C" : "--°C"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Txt {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        size: 13
                        text: Weather.desc ? Weather.desc.charAt(0).toUpperCase() + Weather.desc.slice(1) : "Cargando…"
                    }

                    Txt {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        size: 11
                        color: Theme.cardTextDim
                        text: Weather.place + (Weather.ok ? " · se siente " + Weather.feels + "°" : "")
                    }
                }
            }

            RowLayout {
                Layout.topMargin: 6 * Theme.scale
                spacing: 12 * Theme.scale

                Repeater {
                    model: [["humidity_percentage", Weather.humidity + "%"], ["umbrella", Weather.rainChance + "%"], ["air", Weather.wind + " km/h"], ["visibility", Weather.visibility + " km"]]

                    RowLayout {
                        required property var modelData

                        spacing: 3 * Theme.scale

                        Icon {
                            size: 12
                            color: Theme.cardTextDim
                            text: parent.modelData[0]
                        }

                        Txt {
                            size: 10
                            color: Theme.cardTextDim
                            text: parent.modelData[1]
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignTop | Qt.AlignRight
            spacing: 4 * Theme.scale

            Rectangle {
                Layout.alignment: Qt.AlignRight
                width: 40 * Theme.scale
                height: width
                radius: width / 2
                color: Theme.chip

                Icon {
                    anchors.centerIn: parent
                    size: 22
                    color: Theme.chipText
                    text: Weather.icon
                }
            }

            Repeater {
                model: [["wb_twilight", Weather.sunrise], ["bedtime", Weather.sunset]]

                RowLayout {
                    required property var modelData

                    Layout.alignment: Qt.AlignRight
                    spacing: 3 * Theme.scale

                    Icon {
                        size: 11
                        color: Theme.cardTextDim
                        text: parent.modelData[0]
                    }

                    Txt {
                        size: 9
                        color: Theme.cardTextDim
                        text: parent.modelData[1]
                    }
                }
            }
        }
    }
}
