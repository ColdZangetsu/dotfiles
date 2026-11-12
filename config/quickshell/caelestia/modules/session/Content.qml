pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.services
import qs.utils

Column {
    id: root

    required property ScreenState screenState

    padding: Tokens.padding.large
    rightPadding: CUtils.clamp(padding - Config.border.thickness, 0, padding)
    spacing: Tokens.spacing.large

    SessionButton {
        id: logout

        icon: Config.session.icons.logout
        command: Config.session.commands.logout

        KeyNavigation.down: shutdown

        Component.onCompleted: forceActiveFocus()

        Connections {
            function onLauncherChanged(): void {
                if (!root.screenState.launcher)
                    logout.forceActiveFocus();
            }

            target: root.screenState
        }
    }

    SessionButton {
        id: shutdown

        icon: Config.session.icons.shutdown
        command: Config.session.commands.shutdown

        KeyNavigation.up: logout
        KeyNavigation.down: hibernate
    }

    SessionButton {
        id: hibernate

        icon: Config.session.icons.hibernate
        command: Config.session.commands.hibernate

        KeyNavigation.up: shutdown
        KeyNavigation.down: reboot
    }

    SessionButton {
        id: reboot

        icon: Config.session.icons.reboot
        command: Config.session.commands.reboot

        KeyNavigation.up: hibernate
    }

    // 11-12 Fable: cada botón es una luna. Con foco = luna negra con corona roja. Hay que MANTENER
    // (clic o Enter, 480 ms; un anillo recorre la corona) y al cerrarse: eclipse total + tajo, y se ejecuta.
    // Soltar antes cancela. Original: Content.qml.antes-fable
    component SessionButton: Item {
        id: button

        required property list<string> command
        property string icon
        property real avance: 0      // 0..1 mientras mantienes
        property real eclipse: 0     // 0..1 al confirmar
        readonly property bool foco: activeFocus || zona.containsMouse

        function exec(): void {
            if (!SessionManager.exec(command))
                Quickshell.execDetached(command);
        }
        function empezar(): void {
            if (confirma.running || eclipse > 0)
                return;
            suelta.stop();
            mantener.from = avance;
            mantener.duration = 480 * (1 - avance);
            mantener.start();
        }
        function soltar(): void {
            if (avance >= 1 || eclipse > 0)
                return;
            mantener.stop();
            suelta.from = avance;
            suelta.start();
        }

        implicitWidth: Tokens.sizes.session.button
        implicitHeight: Tokens.sizes.session.button
        activeFocusOnTab: true

        NumberAnimation {
            id: mantener
            target: button; property: "avance"; to: 1
            onFinished: if (button.avance >= 1) confirma.start()
        }
        NumberAnimation { id: suelta; target: button; property: "avance"; to: 0; duration: 160 }
        SequentialAnimation {
            id: confirma
            NumberAnimation { target: button; property: "eclipse"; from: 0; to: 1; duration: 260; easing.type: Easing.OutCubic }
            ScriptAction { script: { button.exec(); button.eclipse = 0; button.avance = 0; } }
        }

        onAvanceChanged: luna.requestPaint()
        onEclipseChanged: luna.requestPaint()
        onFocoChanged: luna.requestPaint()

        Canvas {
            id: luna

            anchors.centerIn: parent
            width: parent.width + 40
            height: parent.height + 40
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const cx = width / 2, cy = height / 2, R = button.width / 2 - 2;
                const e = button.eclipse;
                // corona (con foco), se abre al confirmar
                if (button.foco || e > 0) {
                    const g = ctx.createRadialGradient(cx, cy, R * 0.9, cx, cy, R + 10 + 14 * e);
                    g.addColorStop(0, Qt.rgba(1, 0.14, 0.28, 0.55 + 0.4 * e));
                    g.addColorStop(1, Qt.rgba(1, 0.14, 0.28, 0));
                    ctx.fillStyle = g;
                    ctx.beginPath(); ctx.arc(cx, cy, R + 10 + 14 * e, 0, 2 * Math.PI); ctx.fill();
                }
                // disco
                ctx.fillStyle = button.foco || e > 0 ? "#05060a" : "#1a1d24";
                ctx.beginPath(); ctx.arc(cx, cy, R, 0, 2 * Math.PI); ctx.fill();
                ctx.lineWidth = 2;
                ctx.strokeStyle = button.foco || e > 0 ? "#ff2448" : Qt.rgba(0.94, 0.90, 0.85, 0.10);
                ctx.beginPath(); ctx.arc(cx, cy, R, 0, 2 * Math.PI); ctx.stroke();
                // anillo de "mantener" (hueso, desde arriba)
                if (button.avance > 0) {
                    ctx.lineWidth = 3; ctx.lineCap = "round";
                    ctx.strokeStyle = "#fff1f3";
                    ctx.beginPath(); ctx.arc(cx, cy, R + 5, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * button.avance); ctx.stroke();
                }
                // anillo de diamante + tajo al confirmar
                if (e > 0) {
                    ctx.fillStyle = Qt.rgba(1, 0.95, 0.96, 1 - e);
                    ctx.beginPath(); ctx.arc(cx + R * 0.72, cy - R * 0.72, 3 + 4 * (1 - e), 0, 2 * Math.PI); ctx.fill();
                    const L = (R + 18) * e;
                    ctx.lineWidth = 2.5; ctx.lineCap = "round";
                    ctx.strokeStyle = Qt.rgba(1, 0.30, 0.40, 0.95);
                    ctx.beginPath(); ctx.moveTo(cx - L * 0.8, cy + L * 0.8); ctx.lineTo(cx + L * 0.8, cy - L * 0.8); ctx.stroke();
                }
            }
        }

        MaterialIcon {
            anchors.centerIn: parent
            text: button.icon
            color: button.foco ? "#fff1f3" : "#a0a8b8"
            fontStyle: Tokens.font.icon.builders.large.scale(1.15).build()
        }

        MouseArea {
            id: zona

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: button.forceActiveFocus()
            onPressed: button.empezar()
            onReleased: button.soltar()
            onCanceled: button.soltar()
        }

        Keys.onPressed: event => {
            if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) && !event.isAutoRepeat) {
                button.empezar();
                event.accepted = true;
            } else if (event.key === Qt.Key_Escape) {
                root.screenState.session = false;
            } else if (event.key === Qt.Key_Tab && KeyNavigation.down) {
                KeyNavigation.down.focus = true;
                event.accepted = true;
            } else if (event.key === Qt.Key_Backtab && KeyNavigation.up) {
                KeyNavigation.up.focus = true;
                event.accepted = true;
            }
        }
        Keys.onReleased: event => {
            if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) && !event.isAutoRepeat) {
                button.soltar();
                event.accepted = true;
            }
        }
    }
}
