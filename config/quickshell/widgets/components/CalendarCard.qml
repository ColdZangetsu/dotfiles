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
            spacing: 6 * Theme.scale

            Txt {
                size: 19
                font.family: Theme.titleFont
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1 * Theme.scale
                text: root.locale.standaloneMonthName(root.shown.getMonth())

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.offset = 0
                }
            }

            Txt {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignBaseline
                size: 12
                color: Theme.cardTextDim
                text: root.shown.getFullYear()
            }

            // Kanji del día de la semana (日月火水木金土), solo en el mes actual
            Txt {
                Layout.rightMargin: 4 * Theme.scale
                size: 14
                font.family: Theme.kanjiFont
                color: Theme.accent
                text: "日月火水木金土"[root.today.getDay()]
                visible: root.offset === 0
            }

            Repeater {
                model: ["chevron_left", "chevron_right"]

                Item {
                    id: arrow

                    required property string modelData
                    required property int index

                    implicitWidth: 24 * Theme.scale
                    implicitHeight: implicitWidth

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Theme.inner
                        visible: hover.containsMouse
                    }

                    Icon {
                        anchors.centerIn: parent
                        size: 18
                        color: Theme.cardTextDim
                        text: arrow.modelData
                    }

                    MouseArea {
                        id: hover

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.offset += arrow.index === 0 ? -1 : 1
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

                Label {
                    required property string modelData

                    Layout.fillWidth: true
                    Layout.bottomMargin: 2 * Theme.scale
                    horizontalAlignment: Text.AlignHCenter
                    font.letterSpacing: 0.6 * Theme.scale
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
                        color: Theme.today
                        visible: parent.modelData.today
                    }

                    Txt {
                        anchors.centerIn: parent
                        size: 12
                        text: parent.modelData.day
                        font.weight: parent.modelData.today ? Font.DemiBold : Font.Normal
                        color: parent.modelData.today ? Theme.todayText : Theme.cardText
                        opacity: parent.modelData.current ? 1 : 0.3
                    }
                }
            }
        }
    }
}
