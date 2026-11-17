pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.modules.bar as Bar

Region {
    id: root

    required property Bar.BarWrapper bar
    required property Panels panels
    required property var win
    property var saya: null
    // 11-15 Saya: la vaina sustituye el tramo derecho del marco (8 px en vez de 6)
    readonly property real derecha: saya?.activa ? 8 : clampedThickness

    readonly property real borderThickness: win.contentItem.Config.border.thickness
    readonly property real clampedThickness: win.contentItem.Config.border.clampedThickness

    x: bar.clampedWidth + win.dragMaskPadding
    y: clampedThickness + win.dragMaskPadding
    width: win.width - bar.clampedWidth - derecha - win.dragMaskPadding * 2
    height: win.height - clampedThickness * 2 - win.dragMaskPadding * 2
    intersection: Intersection.Xor

    R {
        panel: root.panels.dashboard
        y: 0
        height: panel.height * (1 - root.panels.dashboard.offsetScale) + root.borderThickness
    }

    R {
        panel: root.panels.launcher
        height: root.panels.launcher.visible ? panel.height : 0
    }

    R {
        id: sessionRegion

        panel: root.panels.sessionWrapper
        x: root.win.width - width
        width: panel.width * (1 - root.panels.session.offsetScale) + root.borderThickness + sidebarRegion.width
    }

    R {
        id: sidebarRegion

        panel: root.panels.sidebar
        x: root.win.width - width
        width: panel.width * (1 - root.panels.sidebar.offsetScale) + root.borderThickness
    }

    R {
        panel: root.panels.osdWrapper
        x: root.win.width - width
        width: panel.width * (1 - root.panels.osd.offsetScale) + root.borderThickness + sessionRegion.width
    }

    R {
        panel: root.panels.notifications
        y: 0
        height: panel.height + root.borderThickness
    }

    R {
        panel: root.panels.utilities
        y: root.win.height - height
        height: panel.height * (1 - root.panels.utilities.offsetScale) + root.borderThickness
    }

    // 11-15 Tsuka: la placa abierta (encima de las ventanas) recibe el mouse; en reposo no agrega nada
    Region {
        x: root.bar.implicitWidth
        y: root.bar.alcanceY
        width: Math.max(0, root.bar.alcance - root.bar.implicitWidth)
        height: root.bar.alcanceAlto
        intersection: Intersection.Subtract
    }

    // 11-15 Saya: lo que sale de la vaina (bloque, lengua, detalle, OSD) recibe el mouse
    Region {
        readonly property var r: root.saya?.zonaBloque ?? [0, 0, 0, 0]
        x: root.win.width - r[2] - r[0]
        y: r[1]
        width: r[2]
        height: r[3]
        intersection: Intersection.Subtract
    }
    Region {
        readonly property var r: root.saya?.zonaLengua ?? [0, 0, 0, 0]
        x: root.win.width - r[2] - r[0]
        y: r[1]
        width: r[2]
        height: r[3]
        intersection: Intersection.Subtract
    }
    Region {
        readonly property var r: root.saya?.zonaDetalle ?? [0, 0, 0, 0]
        x: root.win.width - r[2] - r[0]
        y: r[1]
        width: r[2]
        height: r[3]
        intersection: Intersection.Subtract
    }

    R {
        panel: root.panels.popoutsWrapper
        width: panel.width * (1 - root.panels.popoutsWrapper.offsetScale)
    }

    component R: Region {
        required property Item panel

        x: panel.x + root.bar.implicitWidth
        y: panel.y + root.borderThickness
        width: panel.width
        height: panel.height
        intersection: Intersection.Subtract
    }
}
