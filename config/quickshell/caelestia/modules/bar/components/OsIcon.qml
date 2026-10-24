import QtQuick
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services
import qs.utils

Item {
    id: root

    implicitWidth: Math.round(Tokens.font.body.large.pointSize * 2)
    implicitHeight: Math.round(Tokens.font.body.large.pointSize * 2)

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const screenState = ShellState.forActive();
            screenState.launcher = !screenState.launcher;
        }
    }

    Loader {
        asynchronous: true
        anchors.centerIn: parent
        sourceComponent: SysInfo.isDefaultLogo ? caelestiaLogo : distroIcon
    }

    Component {
        id: caelestiaLogo

        Logo {
            implicitWidth: Math.round(Tokens.font.body.large.pointSize * 1.6)
            implicitHeight: Math.round(Tokens.font.body.large.pointSize * 1.6)
        }
    }

    Component {
        id: distroIcon

        Image {
            source: SysInfo.osLogo
            width: Math.round(Tokens.font.body.large.pointSize * 2)
            height: width
            sourceSize.width: width * 2
            sourceSize.height: height * 2
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
        }
    }
}
