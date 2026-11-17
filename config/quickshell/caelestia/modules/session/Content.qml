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
        kanji: "出"
        nombre: "Salir"
        command: Config.session.commands.logout

        KeyNavigation.down: shutdown

        // 11-15 Tsuka: SUSPENDER / APAGAR de la placa abren las lunas con esa luna enfocada (solo el foco; nada más cambia)
        Component.onCompleted: {
            forceActiveFocus();
            const f = root.screenState.sesionFoco;
            root.screenState.sesionFoco = "";
            if (f === "shutdown")
                Qt.callLater(() => shutdown.forceActiveFocus());
            else if (f === "hibernate")
                Qt.callLater(() => hibernate.forceActiveFocus());
        }

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
        kanji: "滅"
        nombre: "Apagar"
        command: Config.session.commands.shutdown

        KeyNavigation.up: logout
        KeyNavigation.down: hibernate
    }

    SessionButton {
        id: hibernate

        icon: Config.session.icons.hibernate
        kanji: "眠"
        nombre: "Hibernar"
        command: Config.session.commands.hibernate

        KeyNavigation.up: shutdown
        KeyNavigation.down: reboot
    }

    SessionButton {
        id: reboot

        icon: Config.session.icons.reboot
        kanji: "廻"
        nombre: "Reiniciar"
        command: Config.session.commands.reboot

        KeyNavigation.up: hibernate
    }

    // 11-12 Fable: cada botón es una luna. Con foco = luna negra con corona roja. Hay que MANTENER
    // (clic o Enter, 480 ms; un anillo recorre la corona) y al cerrarse: eclipse total + tajo, y se ejecuta.
    // Soltar antes cancela. Original: Content.qml.antes-fable
    component SessionButton: Item {
        id: button

        required property list<string> command
        property string icon         // sigue siendo la llave de ShellState (confirmarSesion/accionSesion)
        property string kanji        // 11-15: lo que se ve (prototipo final de Fable: luna perla con kanji en pincel)
        property string nombre       // 11-15: lo que significa el kanji; aparece a la izquierda al pasar el ratón / con foco
        property real avance: 0      // 0..1 mientras mantienes
        property real eclipse: 0     // 0..1 al confirmar
        readonly property bool foco: activeFocus || zona.containsMouse

        function exec(): void {
            if (!SessionManager.exec(command))
                Quickshell.execDetached(command);
        }
        function empezar(): void {
            if (confirma.running || sincronia.running || eclipse > 0)
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

        // 11-13: al completar el anillo, se abre el menú en LAS 3 pantallas y todas esperan a que
        // termine de entrar (deslizamiento) para hacer el eclipse juntas. Solo la pantalla de origen ejecuta.
        property bool origen: false
        readonly property int esperaEntrada: Tokens.anim.durations.expressiveDefaultSpatial + 60

        NumberAnimation {
            id: mantener
            target: button; property: "avance"; to: 1
            onFinished: if (button.avance >= 1) {
                button.origen = true;
                ShellState.confirmarSesion(button.icon);
            }
        }
        Connections {
            target: ShellState
            function onAccionSesionChanged(): void {
                if (ShellState.accionSesion === button.icon && !confirma.running && button.eclipse === 0) {
                    button.avance = 1;
                    sincronia.restart();
                } else if (ShellState.accionSesion === "") {
                    confirma.stop(); sincronia.stop(); ejecutar.stop();
                    button.eclipse = 0; button.avance = 0; button.origen = false;
                }
            }
        }
        Timer {
            id: sincronia
            // descuenta lo que ya pasó (la pantalla que se cargó tarde arranca igual que las demás)
            // 11-14: como las 3 ya abrieron juntas, se cuenta desde la apertura (casi siempre = 0 → eclipse inmediato)
            interval: Math.max(0, Math.max(ShellState.accionSesionT, ShellState.sesionAbiertaT + button.esperaEntrada) - Date.now())
            onTriggered: confirma.start()
        }
        Component.onCompleted: if (ShellState.accionSesion === button.icon) { button.avance = 1; sincronia.start(); }
        Timer { id: limpiar; interval: 2500; onTriggered: ShellState.terminarSesion() }
        NumberAnimation { id: suelta; target: button; property: "avance"; to: 0; duration: 160 }
        SequentialAnimation {
            id: confirma
            ScriptAction { script: ShellState.eclipsesVivos++ }
            NumberAnimation { target: button; property: "eclipse"; from: 0; to: 1; duration: 260; easing.type: Easing.OutCubic }
            PauseAnimation { duration: 450 }   // que se vea el eclipse completo en las 3 antes de apagar
            // 11-16: ya no ejecuta la primera que acaba: ASUS/LG abren el menú hasta confirmar y empiezan tarde;
            // se espera a que TODAS terminen (contador en ShellState) y luego un respiro corto.
            ScriptAction { script: { ShellState.eclipsesVivos = Math.max(0, ShellState.eclipsesVivos - 1); ejecutar.restart(); } }
        }
        Timer {
            id: ejecutar
            interval: 150
            onTriggered: {
                if (ShellState.accionHecha || ShellState.accionSesion !== button.icon)
                    return;
                if (ShellState.eclipsesVivos > 0 && Date.now() - ShellState.accionSesionT < 2500) {
                    ejecutar.restart();
                    return;   // otra pantalla sigue en su eclipse: ella ejecuta al terminar (tope 2.5 s por si una se atora)
                }
                ShellState.marcarHecha();
                button.exec();
            }
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
                // 11-15 lunas de Fable (tsuka-saya-final, «jalar la hoja»): en reposo luna PERLA
                // (degradado radial desde 38 % / 34 %: #f4ecdf → #b9b1a4 al 70 %), con foco luna NEGRA
                // (#05060a) con aro rojo fino de 1.5 px (#e0303a). La corona solo aparece en el eclipse.
                const oscura = button.foco || e > 0;
                if (e > 0) {
                    const g = ctx.createRadialGradient(cx, cy, R * 0.9, cx, cy, R + 10 + 14 * e);
                    g.addColorStop(0, Qt.rgba(1, 0.14, 0.28, 0.55 + 0.4 * e));
                    g.addColorStop(1, Qt.rgba(1, 0.14, 0.28, 0));
                    ctx.fillStyle = g;
                    ctx.beginPath(); ctx.arc(cx, cy, R + 10 + 14 * e, 0, 2 * Math.PI); ctx.fill();
                }
                // disco (con una sombra suave para que la perla no se pierda sobre fondos claros)
                ctx.save();
                ctx.shadowColor = Qt.rgba(0, 0, 0, oscura ? 0.35 : 0.45);
                ctx.shadowBlur = 10;
                ctx.shadowOffsetY = 2;
                if (oscura) {
                    ctx.fillStyle = "#05060a";
                } else {
                    const D = 2 * R, gx = cx - R + 0.38 * D, gy = cy - R + 0.34 * D;
                    const p = ctx.createRadialGradient(gx, gy, 0, gx, gy, 0.906 * D);
                    p.addColorStop(0, "#f4ecdf");
                    p.addColorStop(0.7, "#b9b1a4");
                    p.addColorStop(1, "#b9b1a4");
                    ctx.fillStyle = p;
                }
                ctx.beginPath(); ctx.arc(cx, cy, R, 0, 2 * Math.PI); ctx.fill();
                ctx.restore();
                if (oscura) {
                    ctx.lineWidth = 1.5;
                    ctx.strokeStyle = "#e0303a";
                    ctx.beginPath(); ctx.arc(cx, cy, R + 0.75, 0, 2 * Math.PI); ctx.stroke();
                }
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

        // kanji en pincel (Yuji Boku, 20 px sobre 52 en el prototipo → 0.385 del diámetro)
        Text {
            anchors.centerIn: parent
            text: button.kanji
            font.family: "Yuji Boku"
            font.pixelSize: Math.round(button.width * 0.385)
            color: button.foco || button.eclipse > 0 ? "#efe6d8" : "#0c0e12"
            renderType: Text.QtRendering
            // presión: el kanji se hunde un poco mientras mantienes
            scale: button.avance > 0 && button.eclipse === 0 ? 0.92 : 1
            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }

        // 11-15: nombre de la luna (el usuario no lee kanji): pastilla de tinta a la izquierda, solo con foco
        Rectangle {
            anchors.right: parent.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            width: etiqueta.implicitWidth + 20
            height: etiqueta.implicitHeight + 10
            radius: height / 2
            color: "#e60c0e12"
            border.width: 1
            border.color: "#40efe6d8"
            opacity: button.foco && button.eclipse === 0 ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

            Text {
                id: etiqueta
                anchors.centerIn: parent
                text: button.nombre.toUpperCase()
                font.family: "Inter"
                font.pixelSize: 11
                font.letterSpacing: 1.6
                font.weight: Font.Medium
                color: "#efe6d8"
            }
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
