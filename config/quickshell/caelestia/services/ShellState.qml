pragma Singleton

import QtQuick
import Quickshell
import Caelestia
import qs.components
import qs.services

Singleton {
    property ShellRoot shellRoot

    // 11-13: confirmación del menú de sesión compartida por las 3 pantallas.
    // accionSesion = icono del botón confirmado; todas las pantallas abren el menú y hacen el eclipse a la vez.
    property string accionSesion: ""
    property real accionSesionT: 0
    // 11-14: la orden se manda UNA vez, la primera pantalla que termina el eclipse (antes dependía de
    // `origen` por botón, que se perdía al re-crearse el menú → animación completa y no reiniciaba).
    property bool accionHecha: false
    // 11-16: eclipses corriendo ahora (una por pantalla); se apaga/reinicia cuando llega a 0 (las que abrieron tarde también terminan)
    property int eclipsesVivos: 0

    property real sesionAbiertaT: 0

    // 11-14: el menú se abre/cierra en LAS 3 pantallas a la vez desde que se abre en una (antes las otras
    // entraban hasta completar el anillo → llegaban tarde). Las espejo no toman el focus grab (Hyprland
    // solo deja uno; si no, se cerrarían entre ellas).
    function espejarSesion(s: ScreenState): void {
        if (s.sesionEspejo) {
            if (!s.session)
                s.sesionEspejo = false;
            return;
        }
        if (s.session) {
            sesionAbiertaT = Date.now();
            for (const o of states.instances)
                if (o !== s && !o.session) {
                    o.sesionEspejo = true;
                    o.session = true;
                }
        } else {
            for (const o of states.instances)
                if (o !== s && o.sesionEspejo)
                    o.session = false;
        }
    }

    function confirmarSesion(icono: string): void {
        for (const s of states.instances)
            if (!s.session) {
                s.sesionEspejo = true;
                s.session = true;
            }
        accionSesionT = Date.now();
        accionHecha = false;
        eclipsesVivos = 0;
        accionSesion = icono;
    }

    // limpia el menú 2.5 s después de mandar la orden (vive aquí y no en el botón, que puede re-crearse)
    Timer { id: limpiarSesion; interval: 2500; onTriggered: terminarSesion() }
    function marcarHecha(): void {
        accionHecha = true;
        limpiarSesion.restart();
    }

    function terminarSesion(): void {
        accionSesion = "";
        for (const s of states.instances)
            s.session = false;
    }

    function anySidebarOpen(): bool {
        return states.instances.some(s => s.sidebar);
    }

    function forScreen(screen: ShellScreen): ScreenState {
        for (const s of states.instances)
            if (s.modelData === screen)
                return s;
        return null;
    }

    function forActive(): ScreenState {
        const mon = Hypr.focusedMonitor;
        for (const s of states.instances)
            if (Hypr.monitorFor(s.modelData) === mon)
                return s;
        return null;
    }

    function componentsFor(screen: ShellScreen): Components {
        for (const c of components.instances)
            if (c.modelData === screen)
                return c;
        return null;
    }

    function componentsForActive(): Components {
        const mon = Hypr.focusedMonitor;
        for (const c of components.instances)
            if (Hypr.monitorFor(c.modelData) === mon)
                return c;
        return null;
    }

    Variants {
        id: states

        model: Screens.screens

        ScreenState {
            id: estado
            onSessionChanged: ShellState.espejarSesion(estado)
        }
    }

    Variants {
        id: components

        model: Screens.screens

        Components {}
    }

    component Components: QtObject {
        required property ShellScreen modelData

        property var background
        property var rootWindow
        property var interactionWrapper
        property var bar
        property var panels

        function find(name: string, rootItem: Item): var {
            return CUtils.findChild(rootItem ?? rootWindow?.contentItem, name);
        }

        function findAll(name: string, rootItem: Item): var {
            return CUtils.findChildren(rootItem ?? rootWindow?.contentItem, name);
        }

        function findMatching(pattern: string, rootItem: Item): var {
            return CUtils.findChildrenMatching(rootItem ?? rootWindow?.contentItem, pattern);
        }
    }

    component ComponentRef: QtObject {
        required property ShellScreen screen
        required property string slot
        required property var component

        readonly property QtObject target: ShellState.componentsFor(screen)

        onTargetChanged: {
            if (target)
                target[slot] = component;
        }
        Component.onDestruction: {
            if (target && target[slot] === component)
                target[slot] = null;
        }
    }
}
