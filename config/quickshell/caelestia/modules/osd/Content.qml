pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils

// 11-12: OSD con las barras de Fable (Reiatsu / Eclipse / Amanecer pixel). Original en modules/osd.bak-barras.
// Solo se ve la barra que tocaste: volumen, brillo o luces (Super+L).
Item {
    id: root

    required property Brightness.Monitor monitor
    required property ScreenState screenState

    required property real volume
    required property bool muted
    required property real sourceVolume
    required property bool sourceMuted
    required property real brightness

    property bool verVolumen
    property bool verBrillo
    property bool verLuces
    signal actividad   // mover una barra (mouse o toque) mantiene el OSD abierto

    readonly property real escala: 0.6   // tamaño: 0.6 = ~43x192 px (parecido a las barras viejas)
    readonly property real margen: 12    // aire para el aura, la burbuja y el tajo que se salen de la barra
    readonly property real maxVol: Math.max(0.01, GlobalConfig.services.maxVolume)

    implicitWidth: fila.implicitWidth + Tokens.padding.large
    implicitHeight: fila.implicitHeight + Tokens.padding.large

    ColumnLayout {
        id: fila

        anchors.centerIn: parent
        spacing: 0

        // Luces del cuarto — Amanecer pixel (Super+L)
        Ranura {
            activo: root.verLuces

            BarraLuces {
                anchors.centerIn: parent
                scale: root.escala
                despierto: root.screenState.osd
                value: LucesAmbiente.value
                onMovida: v => { LucesAmbiente.set(v); root.actividad(); }
            }
        }

        // Volumen — Reiatsu
        Ranura {
            activo: root.verVolumen

            BarraVolumen {
                anchors.centerIn: parent
                scale: root.escala
                despierto: root.screenState.osd
                value: Math.min(1, root.volume / root.maxVol)
                onMovida: v => { Audio.setVolume(v * root.maxVol); root.actividad(); }
            }
        }

        // Micrófono (la barra de siempre, solo si lo activaste en la config)
        Ranura {
            activo: root.verVolumen && Config.osd.enableMicrophone

            CustomMouseArea {
                function onWheel(event: WheelEvent) {
                    if (event.angleDelta.y > 0)
                        Audio.incrementSourceVolume();
                    else if (event.angleDelta.y < 0)
                        Audio.decrementSourceVolume();
                }

                anchors.centerIn: parent
                implicitWidth: Tokens.sizes.osd.sliderWidth
                implicitHeight: Tokens.sizes.osd.sliderHeight

                FilledSlider {
                    anchors.fill: parent

                    icon: Icons.getMicVolumeIcon(value, root.sourceMuted)
                    value: root.sourceVolume
                    to: GlobalConfig.services.maxVolume
                    onMoved: Audio.setSourceVolume(value)
                }
            }
        }

        // Brillo — Eclipse
        Ranura {
            activo: root.verBrillo && Config.osd.enableBrightness

            BarraBrillo {
                anchors.centerIn: parent
                scale: root.escala
                despierto: root.screenState.osd
                value: root.brightness
                onMovida: v => { root.monitor?.setBrightness(v); root.actividad(); }
            }
        }
    }

    component Ranura: Item {
        property bool activo

        Layout.preferredWidth: 72 * root.escala + root.margen * 2
        Layout.preferredHeight: activo ? 320 * root.escala + root.margen : 0
        opacity: activo ? 1 : 0
        visible: opacity > 0

        Behavior on Layout.preferredHeight {
            Anim {
                type: Anim.Emphasized
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
