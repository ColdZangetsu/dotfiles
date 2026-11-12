import "center"
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

// 11-12 Fable: ZANGETSU arriba, reloj Anton con los dos cuadritos rojos, fecha espaciada y la contraseña.
// La lógica de la contraseña (PasswordInput / InputField / Pam) no se toca. Original: Center.qml.antes-fable
ColumnLayout {
    id: root

    required property var lock
    readonly property real centerScale: Math.min(1, (lock.screen?.height ?? 1440) / 1440)
    readonly property int centerWidth: Tokens.sizes.lock.centerWidth * centerScale

    width: centerWidth
    spacing: 0

    Item { Layout.fillHeight: true }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: "ZANGETSU"
        color: Qt.rgba(0.94, 0.90, 0.85, 0.6)
        font.family: "Cinzel"
        font.pixelSize: Math.round(18 * root.centerScale)
        font.letterSpacing: 10
        leftPadding: 10
    }

    Item { Layout.preferredHeight: 28 * root.centerScale }

    Clock {
        Layout.alignment: Qt.AlignHCenter
        centerScale: root.centerScale
    }

    Item { Layout.preferredHeight: 18 * root.centerScale }

    Text {
        Layout.alignment: Qt.AlignHCenter
        // se refresca cada minuto con el reloj
        text: (Time.minuteStr, Qt.locale("es_MX").toString(new Date(), "dddd d 'de' MMMM").toUpperCase())
        color: Qt.rgba(0.94, 0.90, 0.85, 0.75)
        font.pixelSize: Math.round(17 * root.centerScale)
        font.weight: Font.Medium
        font.letterSpacing: 5
    }

    Item { Layout.preferredHeight: 48 * root.centerScale }

    PasswordInput {
        Layout.alignment: Qt.AlignHCenter
        centerScale: Math.max(0.8, root.centerScale)
        centerWidth: root.centerWidth
        lock: root.lock
    }

    StateMessage {
        Layout.fillWidth: true
        pam: root.lock.pam
    }

    Item { Layout.fillHeight: true }
}
