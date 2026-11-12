// BORRADOR fable (sin probar dentro de Caelestia): reemplaza a modules/bar/components/workspaces/Workspaces.qml
// y necesita la carpeta fable/ junto a él. Ver LEEME.md de barras-osd/fable-workspaces.
// Cada monitor lleva su variante: la tabla está justo abajo, en `variantePorMonitor`.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Caelestia
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.services
import qs.utils
import "fable"

StyledClippingRect {
    id: root

    // ╔═══════════════════ fable: QUÉ VARIANTE VA EN CADA MONITOR ═══════════════════╗
    //   "A" = Eclipse deslizante · "B" = Fases de luna · "C" = Tajo
    //   El nombre es el de Hyprland (`hyprctl monitors`), el mismo que da `screen.name`.
    readonly property var variantePorMonitor: ({
            "DP-1": "B", // LG
            "DP-2": "B", // ASUS
            "DP-3": "A"  // XENEON
        })
    readonly property string variantePorDefecto: "B" // cualquier monitor que no esté en la tabla
    // ╚═══════════════════════════════════════════════════════════════════════════════╝

    required property ShellScreen screen
    required property bool fullscreen

    readonly property HyprlandMonitor monitor: Hypr.monitorFor(screen)
    readonly property bool onSpecial: monitor?.lastIpcObject.specialWorkspace?.name !== ""
    readonly property int activeWsId: monitor.activeWorkspace?.id ?? 1
    readonly property int activeWsIdx: workspaceIndex(activeWsId)
    readonly property int shown: Math.max(1, Config.bar.workspaces.shown)

    readonly property var wsIds: {
        if (Config.bar.workspaces.showUnoccupied) {
            // Escritorios con nombre de este monitor (ej. "gaming") arriba del primero numerado
            const named = Hypr.workspaces.values.filter(w => w.id < 0 && w.monitor === root.monitor && !w.name.startsWith("special:")).map(w => w.id);
            return named.concat(Array.from({
                length: shown
            }, (_, i) => groupOffset + i + 1));
        }

        const allMonitors = !Config.bar.workspaces.perMonitor;
        const ignoredTags = GlobalConfig.bar.workspaces.ignoredTags;
        const workspaces = Hypr.workspaces.values.filter(w => w.id > 0 && (allMonitors || w.monitor === root.monitor) && (w.id === activeWsId || w.toplevels.values.some(t => !Hypr.isToplevelIgnored(t, ignoredTags))));
        const currentIdx = workspaces.findIndex(w => w.id === activeWsId);
        if (currentIdx < 0)
            return [];

        const end = CUtils.clamp(currentIdx + 1, Math.min(shown, workspaces.length), workspaces.length);
        const start = Math.max(0, end - shown);

        return workspaces.slice(start, end).map(w => w.id);
    }

    // fable: lo que pinta el indicador, una entrada por escritorio mostrado
    readonly property var modeloFable: {
        const cfg = Config.bar.workspaces;
        const ignoredTags = GlobalConfig.bar.workspaces.ignoredTags;
        const kanji = ["〇", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十"];
        return wsIds.map(id => {
            const ws = Hypr.workspaces.values.find(w => w.id === id);
            const nombre = !ws || ws.name == id ? id : Hypr.trimWsName(ws.name);
            let etiqueta;
            if (ws?.name === "gaming")
                etiqueta = "零"; // el escritorio "gaming" va como cero
            else if (Number.isInteger(Number(nombre)) && nombre >= 0 && nombre <= 10)
                etiqueta = kanji[nombre];
            else
                etiqueta = String(nombre)[0] ?? "";
            const ventanas = Hypr.toplevelsForWs(id, ignoredTags);
            return {
                id: id,
                etiqueta: etiqueta,
                icono: ws ? Icons.matchIconRuleList(Hypr.trimWsName(ws.name), GlobalConfig.bar.workspaces.workspaceIcons) : "",
                ocupado: ventanas.length > 0,
                ventanas: cfg.showWindows && cfg.maxWindowIcons > 0 ? ventanas.slice(0, cfg.maxWindowIcons).map(t => Icons.getAppCategoryIcon(t.lastIpcObject.class, "terminal")) : [],
                ajeno: !cfg.perMonitor && !!ws?.monitor && ws.monitor !== root.monitor
            };
        });
    }

    // Only relevant for when showUnoccupied is true
    readonly property int groupOffset: {
        if (!Config.bar.workspaces.showUnoccupied)
            return 0;
        // En un escritorio con nombre (id negativo) se usa el grupo de los numerados de este monitor
        const ids = Hypr.workspaces.values.filter(w => w.id > 0 && w.monitor === root.monitor).map(w => w.id);
        const id = activeWsId > 0 ? activeWsId : (ids.length ? Math.min(...ids) : 1);
        return Math.floor((id - 1) / shown) * shown;
    }

    property real blur: onSpecial ? 1 : 0

    function workspaceIndex(id: int): int {
        return wsIds.indexOf(id);
    }

    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: fable.implicitHeight

    color: Colours.of(QsWindow.window ?? this).tPalette.m3surfaceContainer
    radius: Tokens.rounding.full

    Item {
        anchors.fill: parent
        scale: root.onSpecial ? 0.8 : 1
        opacity: root.onSpecial ? 0.5 : 1
        visible: !root.fullscreen

        layer.enabled: root.blur > 0
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: root.blur
            blurMax: 32
        }

        // ── fable: el indicador completo (etiquetas, ventanas, activo) lo pinta un solo componente ──
        // La variante la elige EscritoriosPorMonitor con la tabla de arriba; A, B y C comparten Base.qml.
        EscritoriosPorMonitor {
            id: fable

            pantalla: root.screen?.name ?? ""
            mapa: root.variantePorMonitor
            porDefecto: root.variantePorDefecto

            anchors.horizontalCenter: parent.horizontalCenter
            fondo: false // la píldora ya la pone esta barra

            modelo: root.modeloFable
            activo: root.activeWsIdx

            ancho: Tokens.sizes.bar.innerWidth
            celda: Tokens.sizes.bar.innerWidth - Tokens.padding.small
            separacion: Tokens.spacing.extraSmall
            margen: Tokens.padding.extraSmall
            fuenteKanji: Tokens.font.workspaces
            mostrarVentanas: Config.bar.workspaces.showWindows && Config.bar.workspaces.maxWindowIcons > 0
            reducirMovimiento: false

            // Opcional: seguir los colores del tema en vez de la paleta Eclipse fija
            // paleta: Paleta {
            //     rojo: Colours.of(QsWindow.window ?? this).palette.m3primary
            //     hueso: Colours.of(QsWindow.window ?? this).palette.m3onSurface
            //     tenue: Colours.of(QsWindow.window ?? this).palette.m3outline
            // }

            onElegido: i => {
                const ws = root.wsIds[i];
                if (!ws)
                    return;
                if (Hypr.activeWsId !== ws)
                    Hypr.focusWorkspace(ws < 0 ? `name:${Hypr.workspaces.values.find(w => w.id === ws)?.name ?? ""}` : ws);
                else
                    Hypr.toggleSpecial("special");
            }
        }

        Behavior on scale {
            Anim {}
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Loader {
        id: specialWs

        anchors.fill: parent

        asynchronous: true
        active: opacity > 0
        opacity: root.onSpecial ? 1 : 0

        sourceComponent: Item {
            StyledRect {
                anchors.fill: parent
                radius: Tokens.rounding.full
                color: Qt.alpha(Colours.of(QsWindow.window ?? this).palette.m3scrim, Colours.light ? 0 : 0.2)
            }

            SpecialWorkspaces {
                anchors.fill: parent
                anchors.margins: Tokens.padding.extraSmall
                monitor: root.monitor

                scale: 0.5
                Component.onCompleted: scale = Qt.binding(() => root.onSpecial ? 1 : 0.5)

                Behavior on scale {
                    Anim {}
                }
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Behavior on blur {
        Anim {
            type: Anim.StandardSmall
        }
    }

    Behavior on implicitHeight {
        Anim {}
    }
}
