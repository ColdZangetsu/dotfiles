import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import Quickshell

RowLayout {
    id: root

    required property var lock
    // Modo trabajo: sin clima/fetch/música/recursos/notificaciones (redibujarlos dejaba la GPU
    // en P1 con los monitores apagados); quedan el reloj y la contraseña
    property bool sinWidgets: false

    spacing: Tokens.spacing.largeIncreased * 2

    ColumnLayout {
        visible: !root.sinWidgets
        Layout.fillWidth: true
        spacing: Tokens.spacing.medium

        WeatherInfo {
            Layout.fillWidth: true
            rootHeight: root.height
        }

        Fetch {
            Layout.fillWidth: true
            rootHeight: root.height
        }

        Media {
            Layout.fillWidth: true
            Layout.fillHeight: true
            lock: root.lock
        }
    }

    Center {
        lock: root.lock
    }

    ColumnLayout {
        visible: !root.sinWidgets
        Layout.fillWidth: true
        spacing: Tokens.spacing.medium

        Resources {
            Layout.fillWidth: true
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true

            bottomRightRadius: Tokens.rounding.extraLarge
            radius: Tokens.rounding.medium
            color: Colours.of(QsWindow.window ?? this).tPalette.m3surfaceContainer

            NotifDock {
                lock: root.lock
            }
        }
    }
}
