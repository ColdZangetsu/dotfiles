//@ pragma UseQApplication
// Pantalla de inicio (greetd) con el fondo de Makima.
// El ASUS (por modelo, no por puerto) muestra reloj y contraseña; los demás monitores quedan en negro.
// Prueba sin greetd: GREETER_TEST=1 qs -p shell.qml  (se cierra sola a los 10 s)
import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Greetd

ShellRoot {
    id: root

    readonly property string user: "ovi"
    readonly property list<string> session: ["uwsm", "start", "-e", "-D", "Hyprland", "hyprland.desktop"]
    readonly property string principal: "XG27ACDMS"
    readonly property bool test: Quickshell.env("GREETER_TEST") === "1"
    readonly property string dir: Quickshell.shellDir

    property string error: ""
    property bool busy: false
    property string pending: ""

    function start() {
        if (Greetd.available && Greetd.state === GreetdState.Inactive)
            Greetd.createSession(root.user);
    }

    function submit(password) {
        if (root.busy)
            return;
        root.error = "";
        if (!Greetd.available) {
            root.error = "Modo de prueba: greetd no está disponible";
            return;
        }
        root.busy = true;
        root.pending = password;
        if (Greetd.state === GreetdState.Inactive)
            Greetd.createSession(root.user);
        else
            root.flush();
    }

    function flush() {
        if (root.pending === "")
            return;
        const p = root.pending;
        root.pending = "";
        Greetd.respond(p);
    }

    Connections {
        target: Greetd

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired) {
                if (root.busy)
                    root.flush();
            } else {
                Greetd.respond("");
            }
        }

        function onAuthFailure(message) {
            root.busy = false;
            root.pending = "";
            root.error = "Contraseña incorrecta";
            Greetd.cancelSession();
            root.start();
        }

        function onError(error) {
            root.busy = false;
            root.pending = "";
            root.error = error;
        }

        function onReadyToLaunch() {
            Greetd.launch(root.session, [], true);
        }
    }

    Component.onCompleted: root.start()

    Timer {
        running: root.test
        interval: 10000
        onTriggered: Qt.quit()
    }

    Variants {
        model: root.test ? Quickshell.screens.filter(s => s.model === root.principal) : Quickshell.screens

        PanelWindow {
            id: win

            required property ShellScreen modelData
            readonly property bool main: modelData.model === root.principal

            screen: modelData
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            color: "black"
            WlrLayershell.layer: root.test ? WlrLayer.Top : WlrLayer.Overlay
            WlrLayershell.namespace: "greeter-makima"
            WlrLayershell.keyboardFocus: main && !root.test ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            Loader {
                anchors.fill: parent
                active: win.main
                sourceComponent: Greeter {}
            }
        }
    }

    component Greeter: Item {
        id: greeter

        readonly property real s: height / 1440

        Image {
            anchors.fill: parent
            source: "file://" + root.dir + "/fondo.jpg"
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }

        // Fondo animado (Makima: Halo Descent grabado en loop); la imagen de arriba queda de respaldo
        Video {
            anchors.fill: parent
            source: "file://" + root.dir + "/fondo.mp4"
            fillMode: VideoOutput.PreserveAspectCrop
            loops: MediaPlayer.Infinite
            muted: true
            autoPlay: true
        }

        // Reloj y fecha
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.14
            spacing: 6 * greeter.s

            Text {
                id: clock

                anchors.horizontalCenter: parent.horizontalCenter
                color: "#f5f5f5"
                font.family: "Rubik"
                font.weight: Font.Light
                font.pixelSize: 150 * greeter.s
                text: Qt.formatTime(now.date, "HH:mm")
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#e8e8e8"
                font.family: "Rubik"
                font.pixelSize: 30 * greeter.s
                text: {
                    const d = now.date.toLocaleDateString(Qt.locale("es_MX"), "dddd, d 'de' MMMM yyyy");
                    return d.charAt(0).toUpperCase() + d.slice(1);
                }
            }
        }

        SystemClock {
            id: now

            precision: SystemClock.Minutes
        }

        // Contraseña
        Rectangle {
            id: field

            property real shake: 0

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: shake
            y: parent.height * 0.47
            width: 500 * greeter.s
            height: 72 * greeter.s
            radius: 18 * greeter.s
            color: Qt.rgba(1, 1, 1, input.activeFocus ? 0.08 : 0.04)
            border.width: 2
            border.color: root.error !== "" ? "#ff8a80" : Qt.rgba(1, 1, 1, 0.85)

            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }

            TextInput {
                id: input

                anchors.fill: parent
                anchors.leftMargin: 24 * greeter.s
                anchors.rightMargin: 24 * greeter.s
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                echoMode: TextInput.Password
                passwordCharacter: "●"
                color: "white"
                font.family: "Rubik"
                font.pixelSize: 26 * greeter.s
                font.letterSpacing: 6 * greeter.s
                cursorVisible: activeFocus
                focus: true
                enabled: !root.busy
                onTextChanged: root.error = ""
                onAccepted: {
                    if (text.length > 0)
                        root.submit(text);
                }
                Component.onCompleted: forceActiveFocus()
            }

            SequentialAnimation {
                id: shakeAnim

                loops: 2
                NumberAnimation { target: field; property: "shake"; to: -12; duration: 50 }
                NumberAnimation { target: field; property: "shake"; to: 12; duration: 70 }
                NumberAnimation { target: field; property: "shake"; to: 0; duration: 50 }
            }

            Connections {
                target: root

                function onErrorChanged() {
                    if (root.error !== "") {
                        input.text = "";
                        shakeAnim.restart();
                        input.forceActiveFocus();
                    }
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: field.bottom
            anchors.topMargin: 26 * greeter.s
            color: root.error !== "" ? "#ffb4ab" : Qt.rgba(1, 1, 1, 0.8)
            font.family: "Rubik"
            font.pixelSize: 22 * greeter.s
            text: root.error !== "" ? root.error : (root.busy ? "Entrando…" : "us")
        }

        // Apagar / reiniciar
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: parent.height * 0.1
            spacing: 56 * greeter.s

            Repeater {
                model: [
                    { label: "Apagar", cmd: ["systemctl", "poweroff"] },
                    { label: "Reiniciar", cmd: ["systemctl", "reboot"] }
                ]

                Text {
                    required property var modelData

                    color: area.containsMouse ? "white" : Qt.rgba(1, 1, 1, 0.7)
                    font.family: "Rubik"
                    font.pixelSize: 22 * greeter.s
                    text: modelData.label

                    MouseArea {
                        id: area

                        anchors.fill: parent
                        anchors.margins: -10
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (!root.test) Quickshell.execDetached(parent.modelData.cmd)
                    }
                }
            }
        }
    }
}
