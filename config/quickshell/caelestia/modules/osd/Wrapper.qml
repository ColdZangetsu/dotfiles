pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property bool sidebarOrSessionVisible

    property bool hovered
    readonly property Brightness.Monitor monitor: Brightness.getMonitorForScreen(root.screen)
    readonly property bool shouldBeActive: screenState.osd && Config.osd.enabled && !(screenState.utilities && Config.utilities.enabled)
    property real offsetScale: shouldBeActive ? 0 : 1
    property real sidebarOffset: sidebarOrSessionVisible ? 12 : 0

    property real volume
    property bool muted
    property real sourceVolume
    property bool sourceMuted
    property real brightness

    // 11-12: el OSD solo enseña la barra que tocaste (volumen / brillo / luces)
    property bool verVolumen
    property bool verBrillo
    property bool verLuces
    property bool controlActivo   // abierto con xeneon-control: se queda ~25 s para tocar con calma
    function reiniciaTemporizador(): void {
        timer.restart();
    }

    function show(que: string): void {
        if (que === "luces")
            verLuces = true;
        else if (que === "brillo")
            verBrillo = true;
        else
            verVolumen = true;
        screenState.osd = true;
        timer.restart();
    }

    // Al acercar el mouse al borde derecho el OSD se abre solo (sin tocar nada): enseña las tres barras
    function verTodas(): void {
        LucesAmbiente.refrescar();
        verVolumen = true;
        verBrillo = true;
        verLuces = true;
    }

    onHoveredChanged: {
        if (hovered)
            verTodas();
    }

    Connections {
        function onOsdChanged(): void {
            if (root.screenState.osd && !root.verVolumen && !root.verBrillo && !root.verLuces)
                root.verTodas();
        }

        target: root.screenState
    }

    Connections {
        function onControlPantalla(pantalla: string): void {
            if (root.screen.name !== pantalla)
                return;
            root.controlActivo = true;
            root.verTodas();
            root.screenState.osd = true;
            timer.restart();
        }

        target: LucesAmbiente
    }

    onVisibleChanged: {
        if (!visible) {
            controlActivo = false;
            verVolumen = false;
            verBrillo = false;
            verLuces = false;
        }
    }

    Component.onCompleted: {
        volume = Audio.volume;
        muted = Audio.muted;
        sourceVolume = Audio.sourceVolume;
        sourceMuted = Audio.sourceMuted;
        brightness = root.monitor?.brightness ?? 0;
    }

    visible: offsetScale < 1
    anchors.rightMargin: (-implicitWidth - 5 - sidebarOffset) * offsetScale
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight
    opacity: 1 - offsetScale

    Behavior on offsetScale {
        Anim {}
    }

    Connections {
        function onMutedChanged(): void {
            root.show("volumen");
            root.muted = Audio.muted;
        }

        function onVolumeChanged(): void {
            root.show("volumen");
            root.volume = Audio.volume;
        }

        function onSourceMutedChanged(): void {
            root.show("volumen");
            root.sourceMuted = Audio.sourceMuted;
        }

        function onSourceVolumeChanged(): void {
            root.show("volumen");
            root.sourceVolume = Audio.sourceVolume;
        }

        target: Audio
    }

    Connections {
        function onBrightnessChanged(): void {
            root.show("brillo");
            root.brightness = root.monitor?.brightness ?? 0;
        }

        target: root.monitor
    }

    Connections {
        function onMostrar(): void {
            root.show("luces");
        }

        target: LucesAmbiente
    }

    Timer {
        id: timer

        interval: root.controlActivo ? 25000 : root.Config.osd.hideDelay
        onTriggered: {
            if (!root.hovered)
                root.screenState.osd = false;
        }
    }

    Loader {
        id: content

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left

        asynchronous: true
        // 11-12: ya no se destruye al ocultarse (crear las 3 barras en cada apertura hacía lag)
        active: true

        sourceComponent: Content {
            monitor: root.monitor
            screenState: root.screenState
            volume: root.volume
            muted: root.muted
            sourceVolume: root.sourceVolume
            sourceMuted: root.sourceMuted
            brightness: root.brightness
            verVolumen: root.verVolumen
            verBrillo: root.verBrillo
            verLuces: root.verLuces
            onActividad: root.reiniciaTemporizador()
        }
    }
}
