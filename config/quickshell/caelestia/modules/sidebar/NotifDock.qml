pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.effects
import qs.services
import qs.utils

Item {
    id: root

    required property Props props
    required property ScreenState screenState
    readonly property int notifCount: Notifs.list.reduce((acc, n) => n.closed ? acc : acc + 1, 0)

    anchors.fill: parent
    anchors.margins: Tokens.padding.medium

    Component.onCompleted: Notifs.list.forEach(n => n.popup = false)

    Item {
        id: title

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Tokens.padding.extraSmall

        implicitHeight: Math.max(count.implicitHeight, titleText.implicitHeight, limpiar.implicitHeight)

        // 11-12 Fable: la única acción va arriba, a la vista (antes un botón flotante abajo). Original: NotifDock.qml.antes-fable
        Rectangle {
            id: limpiar

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: limpiarFila.implicitWidth + 26
            implicitHeight: 32
            radius: 16
            visible: root.notifCount > 0
            color: zonaLimpiar.containsMouse ? "#efe6d8" : "transparent"
            border.width: 1
            border.color: Qt.rgba(0.94, 0.90, 0.85, 0.25)

            Row {
                id: limpiarFila

                anchors.centerIn: parent
                spacing: 7

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "clear_all"
                    color: zonaLimpiar.containsMouse ? "#0c0e12" : "#efe6d8"
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "LIMPIAR"
                    color: zonaLimpiar.containsMouse ? "#0c0e12" : "#efe6d8"
                    font.family: "Anton"
                    font.pixelSize: 13
                    font.letterSpacing: 2.5
                }
            }

            MouseArea {
                id: zonaLimpiar

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: clearTimer.start()
            }
        }

        StyledText {
            id: count

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: root.notifCount > 0 ? 0 : -width - titleText.anchors.leftMargin
            opacity: root.notifCount > 0 ? 1 : 0

            text: root.notifCount
            color: "#fff1f3"
            font.family: "Anton"
            font.pixelSize: 30

            Behavior on anchors.leftMargin {
                Anim {}
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        StyledText {
            id: titleText

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: count.right
            anchors.right: limpiar.left
            anchors.leftMargin: 10
            anchors.verticalCenterOffset: 4

            text: root.notifCount === 1 ? "AVISO" : "AVISOS"
            color: "#a0a8b8"
            font.family: "Anton"
            font.pixelSize: 15
            font.letterSpacing: 3
            elide: Text.ElideRight
        }
    }

    ClippingRectangle {
        id: clipRect

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: title.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: Tokens.spacing.medium

        radius: Tokens.rounding.medium
        color: "transparent"

        Loader {
            asynchronous: true
            anchors.centerIn: parent
            active: opacity > 0
            opacity: root.notifCount > 0 ? 0 : 1

            sourceComponent: Column {
                spacing: 18

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "無"
                    color: Qt.rgba(0.94, 0.90, 0.85, 0.22)
                    font.family: "Noto Serif CJK JP"
                    font.weight: Font.Light
                    font.pixelSize: 120
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "NADA PENDIENTE"
                    color: "#6b7180"
                    font.family: "Anton"
                    font.pixelSize: 14
                    font.letterSpacing: 3
                }
            }

            Behavior on opacity {
                Anim {
                    type: Anim.StandardExtraLarge
                }
            }
        }

        StyledFlickable {
            id: view

            anchors.fill: parent

            flickableDirection: Flickable.VerticalFlick
            contentWidth: width
            contentHeight: notifList.implicitHeight

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: view
            }

            NotifDockList {
                id: notifList

                props: root.props
                screenState: root.screenState
                container: view
            }
        }
    }

    Timer {
        id: clearTimer

        repeat: true
        triggeredOnStart: true
        interval: Math.max(15, Math.min(80, 69.8 - 12.3 * Math.log(Notifs.notClosed.length)))
        onTriggered: {
            const first = Notifs.notClosed[0];
            if (!first) {
                stop();
                return;
            }

            const appName = first.appName;
            let cleared = 0;
            for (const n of Notifs.notClosed.filter(n => n.appName === appName)) {
                n.close();
                cleared++;
                if (cleared > 30) {
                    interval = 5;
                    return;
                }
            }
        }
    }
}
