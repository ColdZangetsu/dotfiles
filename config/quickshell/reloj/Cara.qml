// Cara del reloj (solo QtQuick, sin Quickshell): así se puede dibujar fuera de pantalla para capturas (prueba.qml).
// Tema Eclipse de nerozangetsu.com: luna negra con corona roja, hora en Anton, kanji finos en vertical.
import QtQuick
import QtQuick.Layouts

Item {
    id: cara

    // ---- datos (los pone shell.qml) ----
    property date fecha: new Date()
    property var notifs: []
    property bool sonando: false
    property string pistaTitulo: ""
    property string pistaArtista: ""
    property string pistaArte: ""
    property real pistaProgreso: 0
    property var icono: function (nombre) { return ""; }   // nombre de ícono -> ruta

    // ---- aspecto ----
    property var col: ({ fg: "#fff1f3", tenue: "#94ffe1e6", rojo: "#ff2448", rojo2: "#ff7a8e", vidrio: "#9e140408", borde: "#38ff7a8e", luna: "#050203" })
    property real velo: 0.38        // qué tanto se oscurece el fondo animado (0 = nada, 1 = negro)
    property real luna: 0.9         // opacidad de la luna detrás de la hora
    property bool animar: true      // false = sin transiciones (equivalente a "reducir movimiento")
    readonly property int ancho: 360   // columnas laterales

    readonly property string minuto: Qt.formatTime(fecha, "h:mm")
    readonly property real ahoraMin: Math.floor(fecha.getTime() / 60000)   // cambia 1 vez por minuto (para los "hace 5 min")
    function hace(iso) {
        const s = Math.max(0, ahoraMin * 60 + 59 - new Date(iso).getTime() / 1000);
        if (s < 60) return "ahora";
        if (s < 3600) return Math.floor(s / 60) + " min";
        if (s < 86400) return Math.floor(s / 3600) + " h";
        return Math.floor(s / 86400) + " d";
    }

    FontLoader { id: anton; source: Qt.resolvedUrl("fuentes/Anton-Regular.ttf") }
    FontLoader { source: Qt.resolvedUrl("fuentes/Inter-Regular.ttf") }
    FontLoader { source: Qt.resolvedUrl("fuentes/Inter-Medium.ttf") }
    FontLoader { id: inter; source: Qt.resolvedUrl("fuentes/Inter-SemiBold.ttf") }
    readonly property string fTitulo: anton.status === FontLoader.Ready ? anton.name : "Rubik"
    readonly property string fTexto: inter.status === FontLoader.Ready ? "Inter" : "Rubik"
    readonly property string fKanji: "Noto Serif CJK JP"

    // velo: negro en las orillas, un poco más abierto al centro (el fondo animado sigue viéndose)
    Rectangle {
        anchors.fill: parent
        visible: cara.velo > 0
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.rgba(0, 0, 0, Math.min(1, cara.velo + 0.22)) }
            GradientStop { position: 0.3; color: Qt.rgba(0, 0, 0, cara.velo) }
            GradientStop { position: 0.7; color: Qt.rgba(0, 0, 0, cara.velo) }
            GradientStop { position: 1; color: Qt.rgba(0, 0, 0, Math.min(1, cara.velo + 0.22)) }
        }
    }

    // ---- el eclipse (estático: una textura, cero costo por cuadro) ----
    Item {
        id: eclipse
        visible: false   // 2026-11-11: al usuario no le gustó el anillo del eclipse en el XENEON
        anchors.centerIn: parent
        width: 720; height: 720
        Rectangle { anchors.centerIn: parent; width: 600; height: 600; radius: 300; color: cara.col.luna; opacity: cara.luna }
        Image {
            anchors.fill: parent
            source: Qt.resolvedUrl("eclipse.svg")
            sourceSize: Qt.size(1152, 1152)
            asynchronous: true
        }
    }

    // kanji finos en vertical, por fuera del anillo
    component Vertical: Column {
        property string texto: ""
        property color tinta: cara.col.tenue
        spacing: 10
        Repeater {
            model: parent.texto.split("")
            Text {
                required property string modelData
                text: modelData
                font { family: cara.fKanji; pixelSize: 17; weight: Font.ExtraLight }
                color: parent.tinta
            }
        }
    }
    Vertical { texto: "斬月"; anchors { verticalCenter: parent.verticalCenter; right: eclipse.horizontalCenter; rightMargin: 322 } }
    Vertical {
        texto: ["日", "月", "火", "水", "木", "金", "土"][cara.fecha.getDay()] + "曜日"
        anchors { verticalCenter: parent.verticalCenter; left: eclipse.horizontalCenter; leftMargin: 322 }
    }

    // ---- centro: marca, hora, fecha ----
    Text {
        id: marca
        anchors { horizontalCenter: parent.horizontalCenter; bottom: hora.top; bottomMargin: -6 }
        text: "ZANGETSU"
        font { family: cara.fTitulo; pixelSize: 22; letterSpacing: 13 }
        leftPadding: 13   // compensa el espaciado de la última letra
        color: cara.col.rojo2
    }
    Text {
        id: hora
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -6
        textFormat: Text.StyledText
        text: cara.minuto.replace(":", '<font color="' + cara.col.rojo + '">:</font>')
        font { family: cara.fTitulo; pixelSize: 196 }
        color: cara.col.fg
        style: Text.Raised; styleColor: "#a0000000"
    }
    Column {   // segundos + a. m.: ancho fijo para que no baile la hora
        anchors { left: hora.right; leftMargin: 14; bottom: hora.baseline; bottomMargin: -2 }
        width: 64
        spacing: 2
        Text {
            text: Qt.formatTime(cara.fecha, "ss")
            font { family: cara.fTitulo; pixelSize: 44 }
            color: cara.col.rojo
        }
        Text {
            text: cara.fecha.getHours() < 12 ? "A. M." : "P. M."
            font { family: cara.fTexto; pixelSize: 15; weight: Font.DemiBold; letterSpacing: 2 }
            color: cara.col.tenue
        }
    }
    Text {
        anchors { horizontalCenter: parent.horizontalCenter; top: hora.bottom; topMargin: -10 }
        text: cara.fecha.toLocaleDateString(Qt.locale("es_MX"), "dddd d 'de' MMMM").toUpperCase()
        font { family: cara.fTexto; pixelSize: 22; weight: Font.DemiBold; letterSpacing: 6 }
        leftPadding: 6
        color: cara.col.fg
        style: Text.Raised; styleColor: "#a0000000"
    }

    // ---- tarjeta de vidrio (sin blur: es barato y vive 24/7) ----
    component Vidrio: Rectangle {
        radius: 16
        color: cara.col.vidrio
        border { width: 1; color: cara.col.borde }
    }
    component Rotulo: Text {
        font { family: cara.fTexto; pixelSize: 11; weight: Font.DemiBold; letterSpacing: 3.3 }
        color: cara.col.tenue
    }

    // ---- izquierda: lo que está sonando ----
    Item {
        anchors { left: parent.left; leftMargin: 28; verticalCenter: parent.verticalCenter }
        width: cara.ancho; height: 122
        opacity: cara.sonando ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { enabled: cara.animar; NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

        Rotulo { text: "音  SONANDO"; x: 4 }
        Vidrio {
            y: 24; width: parent.width; height: 98
            RowLayout {
                anchors.fill: parent
                anchors.margins: 11
                spacing: 13
                Rectangle {
                    Layout.preferredWidth: 76; Layout.preferredHeight: 76
                    radius: 10; color: "#22000000"; clip: true
                    Image {
                        anchors.fill: parent
                        sourceSize { width: 152; height: 152 }
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        source: cara.pistaArte
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    Text {
                        Layout.fillWidth: true
                        text: cara.pistaTitulo
                        elide: Text.ElideRight
                        font { family: cara.fTexto; pixelSize: 17; weight: Font.DemiBold }
                        color: cara.col.fg
                    }
                    Text {
                        Layout.fillWidth: true
                        text: cara.pistaArtista
                        elide: Text.ElideRight
                        font { family: cara.fTexto; pixelSize: 13; weight: Font.Medium }
                        color: cara.col.rojo2
                    }
                    Rectangle {   // progreso: hilo rojo con su perla
                        Layout.fillWidth: true
                        Layout.topMargin: 8
                        Layout.preferredHeight: 2
                        radius: 1
                        color: Qt.alpha(cara.col.fg, 0.16)
                        Rectangle {
                            id: avance
                            height: parent.height; radius: 1
                            color: cara.col.rojo
                            width: parent.width * Math.max(0, Math.min(1, cara.pistaProgreso))
                        }
                        Rectangle { x: avance.width - 3; y: -2; width: 6; height: 6; radius: 3; color: cara.col.fg }
                    }
                }
            }
        }
    }

    // ---- derecha: notificaciones (decorativas) ----
    Column {
        anchors { right: parent.right; rightMargin: 28; verticalCenter: parent.verticalCenter }
        width: cara.ancho
        spacing: 8

        Rotulo { text: cara.notifs.length ? "報  AVISOS" : ""; x: 4; visible: cara.notifs.length > 0; bottomPadding: 2 }

        Column {   // vacío: silencio
            visible: cara.notifs.length === 0
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "静"
                font { family: cara.fKanji; pixelSize: 44; weight: Font.ExtraLight }
                color: cara.col.tenue; opacity: 0.6
            }
            Rotulo { anchors.horizontalCenter: parent.horizontalCenter; text: "SIN NOTIFICACIONES"; leftPadding: 3 }
        }

        Repeater {
            model: cara.notifs
            Vidrio {
                id: tarjeta
                required property var modelData
                required property int index
                width: cara.ancho; height: 60

                // la urgente lleva filo rojo
                Rectangle {
                    visible: tarjeta.modelData.urgency === 2
                    x: 0; y: 14; width: 2; height: parent.height - 28; radius: 1; color: cara.col.rojo
                }
                RowLayout {
                    anchors.fill: parent
                    anchors { leftMargin: 12; rightMargin: 13; topMargin: 9; bottomMargin: 9 }
                    spacing: 11
                    Image {
                        Layout.preferredWidth: 34; Layout.preferredHeight: 34
                        sourceSize { width: 68; height: 68 }
                        fillMode: Image.PreserveAspectCrop
                        source: tarjeta.modelData.image ? (tarjeta.modelData.image.startsWith("/") ? "file://" + tarjeta.modelData.image : tarjeta.modelData.image)
                              : (tarjeta.modelData.appIcon ? cara.icono(tarjeta.modelData.appIcon) : "")
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                Layout.fillWidth: true
                                text: tarjeta.modelData.summary || tarjeta.modelData.appName || ""
                                elide: Text.ElideRight
                                font { family: cara.fTexto; pixelSize: 15; weight: Font.DemiBold }
                                color: cara.col.fg
                            }
                            Text {
                                Layout.maximumWidth: 150
                                elide: Text.ElideRight
                                text: ((tarjeta.modelData.appName && tarjeta.modelData.appName !== tarjeta.modelData.summary ? tarjeta.modelData.appName + " · " : "") + cara.hace(tarjeta.modelData.time)).toUpperCase()
                                font { family: cara.fTexto; pixelSize: 10; weight: Font.DemiBold; letterSpacing: 1.2 }
                                color: cara.col.rojo2
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: (tarjeta.modelData.body || "").replace(/<[^>]*>/g, "").replace(/\s+/g, " ")
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            font { family: cara.fTexto; pixelSize: 13 }
                            color: cara.col.tenue
                        }
                    }
                }
            }
        }
    }
}
