import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services

// Calendario del mes, empieza en lunes. Las flechas cambian de mes; clic en el título vuelve a hoy.
Card {
    id: root

    property int offset: 0
    readonly property date today: clock.date
    readonly property date shown: new Date(today.getFullYear(), today.getMonth() + offset, 1)
    readonly property var locale: Qt.locale("es_MX")

    readonly property var days: {
        const y = shown.getFullYear(), m = shown.getMonth();
        const first = (new Date(y, m, 1).getDay() + 6) % 7;
        const out = [];
        for (let i = 0; i < 42; i++) {
            const d = new Date(y, m, 1 - first + i);
            out.push({
                day: d.getDate(),
                current: d.getMonth() === m,
                today: d.toDateString() === today.toDateString()
            });
        }
        return out;
    }

    implicitWidth: 280 * Theme.scale
    implicitHeight: col.implicitHeight + 32 * Theme.scale

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    ColumnLayout {
        id: col

        anchors.fill: parent
        anchors.margins: 16 * Theme.scale
        spacing: 8 * Theme.scale

        RowLayout {
            Layout.fillWidth: true

            Txt {
                Layout.fillWidth: true
                size: 15
                font.weight: Font.Medium
                text: {
                    const s = root.locale.standaloneMonthName(root.shown.getMonth());
                    return s.charAt(0).toUpperCase() + s.slice(1) + " " + root.shown.getFullYear();
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.offset = 0
                }
            }

            Repeater {
                model: ["chevron_left", "chevron_right"]

                Rectangle {
                    required property string modelData
                    required property int index

                    implicitWidth: 24 * Theme.scale
                    implicitHeight: implicitWidth
                    radius: width / 2
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.cardTextDim

                    Icon {
                        anchors.centerIn: parent
                        size: 16
                        text: parent.modelData
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.offset += parent.index === 0 ? -1 : 1
                    }
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 7
            rowSpacing: 2 * Theme.scale
            columnSpacing: 0

            Repeater {
                model: ["Lu", "Ma", "Mi", "Ju", "Vi", "Sá", "Do"]

                Txt {
                    required property string modelData

                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    size: 11
                    color: Theme.cardTextDim
                    text: modelData
                }
            }

            Repeater {
                model: root.days

                Item {
                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: 28 * Theme.scale

                    Rectangle {
                        anchors.centerIn: parent
                        width: 26 * Theme.scale
                        height: width
                        radius: width / 2
                        color: Theme.chip
                        visible: parent.modelData.today
                    }

                    Txt {
                        anchors.centerIn: parent
                        size: 12
                        text: parent.modelData.day
                        font.weight: parent.modelData.today ? Font.Bold : Font.Normal
                        color: parent.modelData.today ? Theme.chipText : Theme.cardText
                        opacity: parent.modelData.current ? 1 : 0.35
                    }
                }
            }
        }
    }
}
