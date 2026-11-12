pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.utils
import qs.modules.bar.popouts as BarPopouts

Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property BarPopouts.Wrapper popouts
    required property bool fullscreen

    readonly property bool disabled: Strings.testRegexList(Config.bar.excludedScreens, screen.name)

    readonly property int clampedWidth: Math.max(Config.border.minThickness, implicitWidth)
    readonly property int padding: Math.max(Tokens.padding.small, Config.border.thickness)
    readonly property int contentWidth: Tokens.sizes.bar.innerWidth + padding * 2
    readonly property int exclusiveZone: !disabled && (Config.bar.persistent || screenState.bar) ? contentWidth : Config.border.thickness
    readonly property bool shouldBeVisible: !fullscreen && !disabled && (Config.bar.persistent || screenState.bar || isHovered)
    property bool isHovered

    function closeTray(): void {
        (content.item as Bar)?.closeTray();
    }

    function checkPopout(y: real): void {
        (content.item as Bar)?.checkPopout(y);
    }

    function salir(): void {
        (content.item as Bar)?.salir();
    }

    function handleWheel(y: real, angleDelta: point): void {
        (content.item as Bar)?.handleWheel(y, angleDelta);
    }

    clip: true
    visible: width > Config.border.thickness
    implicitWidth: fullscreen ? 0 : Config.border.thickness

    states: State {
        name: "visible"
        when: root.shouldBeVisible

        PropertyChanges {
            root.implicitWidth: root.contentWidth
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            Anim {
                target: root
                property: "implicitWidth"
            }
        },
        Transition {
            from: "visible"
            to: ""

            Anim {
                target: root
                property: "implicitWidth"
                type: Anim.Emphasized
            }
        }
    ]

    // 11-12 Fable: UNA píldora de cristal que se desliza de ícono en ícono bajo el cursor
    Rectangle {
        id: pildora

        readonly property real objetivo: (content.item as Bar)?.sobreY ?? -1

        z: -1
        width: 36
        height: 36
        radius: 12
        x: content.x + (content.width - width) / 2
        y: content.y + (objetivo >= 0 ? objetivo : (y - content.y + height / 2)) - height / 2
        opacity: objetivo >= 0 ? 1 : 0
        color: Qt.rgba(0.94, 0.90, 0.85, 0.07)
        border.width: 1
        border.color: Qt.rgba(0.94, 0.90, 0.85, 0.10)

        Behavior on y {
            enabled: pildora.opacity > 0.01
            NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 0.8 }
        }
        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }
    }

    Loader {
        id: content

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right

        active: root.shouldBeVisible

        sourceComponent: Bar {
            width: root.contentWidth
            screen: root.screen
            screenState: root.screenState
            popouts: root.popouts // qmllint disable incompatible-type
            fullscreen: root.fullscreen
        }
    }
}
