pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.Images
import qs.services
import qs.utils

Singleton {
    id: root

    property bool showPreview
    property string scheme
    property string flavour
    readonly property bool light: showPreview ? previewLight : currentLight
    property bool currentLight
    property bool previewLight
    readonly property M3Palette palette: showPreview ? preview : current
    readonly property M3TPalette tPalette: M3TPalette {}
    readonly property M3Palette current: M3Palette {}
    readonly property M3Palette preview: M3Palette {}
    readonly property Transparency transparency: Transparency {}
    readonly property alias wallLuminance: analyser.luminance

    property bool cooldownPending
    property real lastBaseTransparency

    function getLuminance(c: color): real {
        if (c.r == 0 && c.g == 0 && c.b == 0)
            return 0;
        return Math.sqrt(0.299 * (c.r ** 2) + 0.587 * (c.g ** 2) + 0.114 * (c.b ** 2));
    }

    function alterColour(c: color, a: real, layer: int): color {
        const luminance = getLuminance(c);

        const offset = (!light || layer == 1 ? 1 : -layer / 2) * (light ? 0.2 : 0.3) * (1 - transparency.base) * (1 + wallLuminance * (light ? (layer == 1 ? 3 : 1) : 2.5));
        const scale = (luminance + offset) / luminance;
        const r = Math.max(0, Math.min(1, c.r * scale));
        const g = Math.max(0, Math.min(1, c.g * scale));
        const b = Math.max(0, Math.min(1, c.b * scale));

        return Qt.rgba(r, g, b, a);
    }

    function layer(c: color, layer: var): color {
        if (!transparency.enabled)
            return c;

        return layer === 0 ? Qt.alpha(c, transparency.base) : alterColour(c, transparency.layers, layer ?? 1);
    }

    function on(c: color): color {
        if (c.hslLightness < 0.5)
            return Qt.hsla(c.hslHue, c.hslSaturation, 0.9, 1);
        return Qt.hsla(c.hslHue, c.hslSaturation, 0.1, 1);
    }

    function load(data: string, isPreview: bool): void {
        const colours = isPreview ? preview : current;
        const scheme = JSON.parse(data);

        if (!isPreview) {
            root.scheme = scheme.name;
            flavour = scheme.flavour;
            currentLight = scheme.mode === "light";
        } else {
            previewLight = scheme.mode === "light";
        }

        root.fill(colours, scheme);
    }

    function fill(colours: QtObject, scheme: var): void {
        for (const [name, colour] of Object.entries(scheme.colours)) {
            const propName = name.startsWith("term") ? name : `m3${name}`;
            if (colours.hasOwnProperty(propName))
                colours[propName] = `#${colour}`;
        }
    }

    // --- Colores por monitor (caelestia-permon) ---
    // Mapa nombre de monitor -> ScreenScheme con su paleta propia.
    property var screenSchemes: ({})

    // Devuelve algo con .palette y .tPalette para la ventana dada: la paleta
    // de su monitor si existe, si no la global (root).
    function of(win: var): var {
        if (showPreview)
            return root;
        const name = win?.screen?.name;
        return (name && root.screenSchemes[name]) || root;
    }

    function setScreenScheme(name: string, scheme: var): void {
        const map = Object.assign({}, root.screenSchemes);
        if (scheme)
            map[name] = scheme;
        else
            delete map[name];
        root.screenSchemes = map;
    }

    Variants {
        model: Quickshell.screens

        ScreenScheme {}
    }

    function setMode(mode: string): void {
        Quickshell.execDetached(["caelestia", "scheme", "set", "--notify", "-m", mode]);
    }

    function reloadHyprRules(): void {
        let rule, trEnabled;
        if (Hypr.usingLua) {
            rule = `eval hl.layer_rule({ match = { namespace = "caelestia-drawers" }, %1 = %2 })`;
            trEnabled = transparency.enabled;
        } else {
            rule = "keyword layerrule %1 %2, match:namespace caelestia-drawers";
            trEnabled = transparency.enabled ? 1 : 0;
        }
        Hypr.extras.batchMessage([rule.arg("blur").arg(trEnabled), rule.arg("ignore_alpha").arg(Math.max(0, transparency.base - 0.03))]);
    }

    function requestReloadHyprRules(): void {
        if (cooldownTimer.running) {
            root.cooldownPending = true;
        } else {
            root.reloadHyprRules();
            cooldownTimer.restart();
        }
    }

    Component.onCompleted: root.requestReloadHyprRules()

    Connections {
        function onConfigReloaded(): void {
            root.reloadHyprRules();
        }

        target: Hypr
    }

    FileView {
        path: `${Paths.state}/scheme.json`
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.load(text(), false)
    }

    ImageAnalyser {
        id: analyser

        source: Wallpapers.current
    }

    Timer {
        id: cooldownTimer

        interval: 30
        onTriggered: {
            if (root.cooldownPending) {
                root.cooldownPending = false;
                root.reloadHyprRules();
                restart();
            }
        }
    }

    Timer {
        id: cAnimCompleteTimer

        interval: Tokens.anim.durations.expressiveSlowEffects
        onTriggered: root.requestReloadHyprRules()
    }

    component Transparency: QtObject {
        readonly property bool enabled: Tokens.transparency.enabled
        readonly property real base: Math.max(0, Math.min(1, Tokens.transparency.base - (root.light ? 0.1 : 0)))
        readonly property real layers: Math.max(0, Math.min(1, Tokens.transparency.layers))

        onEnabledChanged: {
            if (enabled)
                root.requestReloadHyprRules();
            else
                cAnimCompleteTimer.start();
        }
        onBaseChanged: {
            if (root.lastBaseTransparency > base)
                root.requestReloadHyprRules();
            else
                cAnimCompleteTimer.start();
            root.lastBaseTransparency = base;
        }
    }

    component ScreenScheme: QtObject {
        id: screenScheme

        required property ShellScreen modelData
        readonly property M3Palette palette: M3Palette {}
        readonly property M3TPalette tPalette: M3TPalette {
            src: screenScheme.palette
        }
        readonly property FileView file: FileView {
            path: `${Paths.state}/schemes/${screenScheme.modelData.name}.json`
            watchChanges: true
            printErrors: false
            onFileChanged: reload()
            onLoaded: {
                try {
                    root.fill(screenScheme.palette, JSON.parse(text()));
                    root.setScreenScheme(screenScheme.modelData.name, screenScheme);
                } catch (e) {
                    root.setScreenScheme(screenScheme.modelData.name, null);
                }
            }
            onLoadFailed: root.setScreenScheme(screenScheme.modelData.name, null)
        }

        Component.onDestruction: root.setScreenScheme(modelData.name, null)
    }

    component M3TPalette: QtObject {
        property QtObject src: root.palette

        readonly property color m3primary_paletteKeyColor: root.layer(src.m3primary_paletteKeyColor)
        readonly property color m3secondary_paletteKeyColor: root.layer(src.m3secondary_paletteKeyColor)
        readonly property color m3tertiary_paletteKeyColor: root.layer(src.m3tertiary_paletteKeyColor)
        readonly property color m3neutral_paletteKeyColor: root.layer(src.m3neutral_paletteKeyColor)
        readonly property color m3neutral_variant_paletteKeyColor: root.layer(src.m3neutral_variant_paletteKeyColor)
        readonly property color m3background: root.layer(src.m3background, 0)
        readonly property color m3onBackground: root.layer(src.m3onBackground)
        readonly property color m3surface: root.layer(src.m3surface, 0)
        readonly property color m3surfaceDim: root.layer(src.m3surfaceDim, 0)
        readonly property color m3surfaceBright: root.layer(src.m3surfaceBright, 0)
        readonly property color m3surfaceContainerLowest: root.layer(src.m3surfaceContainerLowest)
        readonly property color m3surfaceContainerLow: root.layer(src.m3surfaceContainerLow)
        readonly property color m3surfaceContainer: root.layer(src.m3surfaceContainer)
        readonly property color m3surfaceContainerHigh: root.layer(src.m3surfaceContainerHigh)
        readonly property color m3surfaceContainerHighest: root.layer(src.m3surfaceContainerHighest)
        readonly property color m3onSurface: root.layer(src.m3onSurface)
        readonly property color m3surfaceVariant: root.layer(src.m3surfaceVariant, 0)
        readonly property color m3onSurfaceVariant: root.layer(src.m3onSurfaceVariant)
        readonly property color m3inverseSurface: root.layer(src.m3inverseSurface, 0)
        readonly property color m3inverseOnSurface: root.layer(src.m3inverseOnSurface)
        readonly property color m3outline: root.layer(src.m3outline)
        readonly property color m3outlineVariant: root.layer(src.m3outlineVariant)
        readonly property color m3shadow: root.layer(src.m3shadow)
        readonly property color m3scrim: root.layer(src.m3scrim)
        readonly property color m3surfaceTint: root.layer(src.m3surfaceTint)
        readonly property color m3primary: root.layer(src.m3primary)
        readonly property color m3onPrimary: root.layer(src.m3onPrimary)
        readonly property color m3primaryContainer: root.layer(src.m3primaryContainer)
        readonly property color m3onPrimaryContainer: root.layer(src.m3onPrimaryContainer)
        readonly property color m3inversePrimary: root.layer(src.m3inversePrimary)
        readonly property color m3secondary: root.layer(src.m3secondary)
        readonly property color m3onSecondary: root.layer(src.m3onSecondary)
        readonly property color m3secondaryContainer: root.layer(src.m3secondaryContainer)
        readonly property color m3onSecondaryContainer: root.layer(src.m3onSecondaryContainer)
        readonly property color m3tertiary: root.layer(src.m3tertiary)
        readonly property color m3onTertiary: root.layer(src.m3onTertiary)
        readonly property color m3tertiaryContainer: root.layer(src.m3tertiaryContainer)
        readonly property color m3onTertiaryContainer: root.layer(src.m3onTertiaryContainer)
        readonly property color m3error: root.layer(src.m3error)
        readonly property color m3onError: root.layer(src.m3onError)
        readonly property color m3errorContainer: root.layer(src.m3errorContainer)
        readonly property color m3onErrorContainer: root.layer(src.m3onErrorContainer)
        readonly property color m3success: root.layer(src.m3success)
        readonly property color m3onSuccess: root.layer(src.m3onSuccess)
        readonly property color m3successContainer: root.layer(src.m3successContainer)
        readonly property color m3onSuccessContainer: root.layer(src.m3onSuccessContainer)
        readonly property color m3primaryFixed: root.layer(src.m3primaryFixed)
        readonly property color m3primaryFixedDim: root.layer(src.m3primaryFixedDim)
        readonly property color m3onPrimaryFixed: root.layer(src.m3onPrimaryFixed)
        readonly property color m3onPrimaryFixedVariant: root.layer(src.m3onPrimaryFixedVariant)
        readonly property color m3secondaryFixed: root.layer(src.m3secondaryFixed)
        readonly property color m3secondaryFixedDim: root.layer(src.m3secondaryFixedDim)
        readonly property color m3onSecondaryFixed: root.layer(src.m3onSecondaryFixed)
        readonly property color m3onSecondaryFixedVariant: root.layer(src.m3onSecondaryFixedVariant)
        readonly property color m3tertiaryFixed: root.layer(src.m3tertiaryFixed)
        readonly property color m3tertiaryFixedDim: root.layer(src.m3tertiaryFixedDim)
        readonly property color m3onTertiaryFixed: root.layer(src.m3onTertiaryFixed)
        readonly property color m3onTertiaryFixedVariant: root.layer(src.m3onTertiaryFixedVariant)
    }

    component M3Palette: QtObject {
        property color m3primary_paletteKeyColor: "#a8627b"
        property color m3secondary_paletteKeyColor: "#8e6f78"
        property color m3tertiary_paletteKeyColor: "#986e4c"
        property color m3neutral_paletteKeyColor: "#807477"
        property color m3neutral_variant_paletteKeyColor: "#837377"
        property color m3background: "#191114"
        property color m3onBackground: "#efdfe2"
        property color m3surface: "#191114"
        property color m3surfaceDim: "#191114"
        property color m3surfaceBright: "#403739"
        property color m3surfaceContainerLowest: "#130c0e"
        property color m3surfaceContainerLow: "#22191c"
        property color m3surfaceContainer: "#261d20"
        property color m3surfaceContainerHigh: "#31282a"
        property color m3surfaceContainerHighest: "#3c3235"
        property color m3onSurface: "#efdfe2"
        property color m3surfaceVariant: "#514347"
        property color m3onSurfaceVariant: "#d5c2c6"
        property color m3inverseSurface: "#efdfe2"
        property color m3inverseOnSurface: "#372e30"
        property color m3outline: "#9e8c91"
        property color m3outlineVariant: "#514347"
        property color m3shadow: "#000000"
        property color m3scrim: "#000000"
        property color m3surfaceTint: "#ffb0ca"
        property color m3primary: "#ffb0ca"
        property color m3onPrimary: "#541d34"
        property color m3primaryContainer: "#6f334a"
        property color m3onPrimaryContainer: "#ffd9e3"
        property color m3inversePrimary: "#8b4a62"
        property color m3secondary: "#e2bdc7"
        property color m3onSecondary: "#422932"
        property color m3secondaryContainer: "#5a3f48"
        property color m3onSecondaryContainer: "#ffd9e3"
        property color m3tertiary: "#f0bc95"
        property color m3onTertiary: "#48290c"
        property color m3tertiaryContainer: "#b58763"
        property color m3onTertiaryContainer: "#000000"
        property color m3error: "#ffb4ab"
        property color m3onError: "#690005"
        property color m3errorContainer: "#93000a"
        property color m3onErrorContainer: "#ffdad6"
        property color m3success: "#B5CCBA"
        property color m3onSuccess: "#213528"
        property color m3successContainer: "#374B3E"
        property color m3onSuccessContainer: "#D1E9D6"
        property color m3primaryFixed: "#ffd9e3"
        property color m3primaryFixedDim: "#ffb0ca"
        property color m3onPrimaryFixed: "#39071f"
        property color m3onPrimaryFixedVariant: "#6f334a"
        property color m3secondaryFixed: "#ffd9e3"
        property color m3secondaryFixedDim: "#e2bdc7"
        property color m3onSecondaryFixed: "#2b151d"
        property color m3onSecondaryFixedVariant: "#5a3f48"
        property color m3tertiaryFixed: "#ffdcc3"
        property color m3tertiaryFixedDim: "#f0bc95"
        property color m3onTertiaryFixed: "#2f1500"
        property color m3onTertiaryFixedVariant: "#623f21"
        property color term0: "#353434"
        property color term1: "#ff4c8a"
        property color term2: "#ffbbb7"
        property color term3: "#ffdedf"
        property color term4: "#b3a2d5"
        property color term5: "#e98fb0"
        property color term6: "#ffba93"
        property color term7: "#eed1d2"
        property color term8: "#b39e9e"
        property color term9: "#ff80a3"
        property color term10: "#ffd3d0"
        property color term11: "#fff1f0"
        property color term12: "#dcbc93"
        property color term13: "#f9a8c2"
        property color term14: "#ffd1c0"
        property color term15: "#ffffff"
    }
}
