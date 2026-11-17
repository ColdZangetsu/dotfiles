pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.utils
import qs.modules.bar.popouts as BarPopouts
import qs.services
import qs.modules.tsuka as TsukaMod

Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property BarPopouts.Wrapper popouts
    required property bool fullscreen

    // 11-15: con Tsuka, el STREAM (modo trabajo) también lleva barra (COMUN.md §7); la de siempre lo sigue excluyendo
    readonly property bool disabled: !tsuka && Strings.testRegexList(Config.bar.excludedScreens, screen.name)

    readonly property int clampedWidth: Math.max(Config.border.minThickness, implicitWidth)
    readonly property int padding: Math.max(Tokens.padding.small, Config.border.thickness)
    readonly property int contentWidth: Tokens.sizes.bar.innerWidth + padding * 2
    readonly property int exclusiveZone: !disabled && (Config.bar.persistent || screenState.bar) ? contentWidth : Config.border.thickness
    readonly property bool shouldBeVisible: !fullscreen && !disabled && (Config.bar.persistent || screenState.bar || isHovered)
    property bool isHovered

    // 11-14 Tsuka (Fable): con ~/.config/caelestia/tsuka.json {"activa": true} se carga modules/tsuka en vez de Bar.
    // La barra de siempre queda intacta (componente barraDeSiempre). Ver TSUKA-SAYA.md.
    readonly property bool tsuka: TsukaConf.activa
    // 11-15 placa de Tsuka abierta (encima de las ventanas): Regions.qml suma ese rectángulo a la máscara de entrada
    readonly property int alcance: tsuka && content.item ? (content.item.alcance ?? 0) : 0
    readonly property real alcanceY: tsuka && content.item ? (content.item.alcanceY ?? 0) : 0
    readonly property real alcanceAlto: tsuka && content.item ? (content.item.alcanceAlto ?? 0) : 0
    // pantalla completa: Tsuka se queda cargada ~0.5 s para cerrar el ojo y retirarse; luego se descarga (cero costo)
    property bool tsukaFuera: fullscreen
    onFullscreenChanged: {
        if (fullscreen)
            descargar.restart();
        else {
            descargar.stop();
            tsukaFuera = false;
        }
    }
    Timer {
        id: descargar
        interval: 560
        onTriggered: root.tsukaFuera = true
    }

    // Bar y Tsuka tienen las mismas cuatro funciones
    function closeTray(): void {
        content.item?.closeTray();
    }

    function checkPopout(y: real): void {
        content.item?.checkPopout(y);
    }

    function salir(): void {
        content.item?.salir();
    }

    function handleWheel(y: real, angleDelta: point): void {
        content.item?.handleWheel(y, angleDelta);
    }

    clip: !tsuka // Tsuka se sale a propósito: guarda, placas y tajo
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

        readonly property real objetivo: root.tsuka ? -1 : ((content.item as Bar)?.sobreY ?? -1)

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
        anchors.right: root.tsuka ? undefined : parent.right
        anchors.left: root.tsuka ? parent.left : undefined

        active: root.tsuka ? (!root.disabled && !root.tsukaFuera) : root.shouldBeVisible

        sourceComponent: root.tsuka ? tsukaComp : barraDeSiempre
    }

    Component {
        id: barraDeSiempre

        Bar {
            width: root.contentWidth
            screen: root.screen
            screenState: root.screenState
            popouts: root.popouts // qmllint disable incompatible-type
            fullscreen: root.fullscreen
        }
    }

    Component {
        id: tsukaComp

        TsukaMod.Tsuka {
            width: root.contentWidth
            screen: root.screen
            screenState: root.screenState
            fullscreen: root.fullscreen
            popouts: root.popouts
        }
    }
}
