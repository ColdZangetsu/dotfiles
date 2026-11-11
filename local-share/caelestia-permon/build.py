#!/usr/bin/env python3
# Arma una copia de Caelestia shell con colores por monitor.
#
# Copia /etc/xdg/quickshell/caelestia a ~/.config/quickshell/caelestia (que
# Quickshell carga antes que la del sistema) y la modifica para que cada
# monitor use su propia paleta de ~/.local/state/caelestia/schemes/<monitor>.json.
# Si un monitor no tiene archivo, usa la paleta global (scheme.json) como siempre.
#
# Para volver a la normal: borrar ~/.config/quickshell/caelestia y reiniciar el shell.
import re
import shutil
import subprocess
import sys
from pathlib import Path

SRC = Path("/etc/xdg/quickshell/caelestia")
DST = Path.home() / ".config/quickshell/caelestia"
STAMP = DST / ".permon-version"


def pkg_version():
    out = subprocess.run(["pacman", "-Q", "caelestia-shell"], capture_output=True, text=True)
    return out.stdout.strip()


def replace_once(text, old, new, what):
    if text.count(old) != 1:
        sys.exit(f"No encontré exactamente una vez {what} en Colours.qml; "
                 "Caelestia cambió y hay que ajustar el parche.")
    return text.replace(old, new)


def patch_colours(path):
    t = path.read_text()

    # load() reutilizable para cualquier paleta
    t = replace_once(t, """        for (const [name, colour] of Object.entries(scheme.colours)) {
            const propName = name.startsWith("term") ? name : `m3${name}`;
            if (colours.hasOwnProperty(propName))
                colours[propName] = `#${colour}`;
        }
    }
""", """        root.fill(colours, scheme);
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
""", "el bucle de load()")

    # La paleta transparente toma de una paleta configurable, no solo la global
    t = replace_once(t, """    component M3TPalette: QtObject {
""", """    component ScreenScheme: QtObject {
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

""", "component M3TPalette")
    head, sep, rest = t.partition("component M3TPalette: QtObject {")
    body, sep2, tail = rest.partition("component M3Palette: QtObject {")
    body = body.replace("root.palette.", "src.")
    t = head + sep + body + sep2 + tail
    path.write_text(t)


def patch_file(root, rel, old, new, what):
    f = root / rel
    t = f.read_text()
    if t.count(old) != 1:
        sys.exit(f"No encontré {what} en {rel}; Caelestia cambió y hay que ajustar el parche.")
    f.write_text(t.replace(old, new))


def patch_launcher(root):
    """Lanzador (tecla Super) al centro de la pantalla y más angosto, estilo Omarchy."""
    patch_file(root, "modules/drawers/Panels.qml", """        panels: root

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
    }
""", """        panels: root

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
    }
""", "el ancla del lanzador")
    # Entrada: aparece subiendo un poco y desvaneciéndose, en vez de salir de abajo
    patch_file(root, "modules/launcher/Wrapper.qml",
               "    anchors.bottomMargin: (-implicitHeight - 5) * offsetScale\n",
               "    anchors.verticalCenterOffset: 40 * offsetScale\n",
               "la animación del lanzador")
    # Zona de clics: la del panel flotante (y nada cuando está cerrado)
    patch_file(root, "modules/drawers/Regions.qml", """        panel: root.panels.launcher
        y: root.win.height - height
        height: panel.height * (1 - root.panels.launcher.offsetScale) + root.borderThickness
""", """        panel: root.panels.launcher
        height: root.panels.launcher.visible ? panel.height : 0
""", "la zona de clics del lanzador")
    patch_file(root, "modules/launcher/ContentList.qml",
               "root.implicitWidth: root.Tokens.sizes.launcher.itemWidth\n",
               "root.implicitWidth: root.Tokens.sizes.launcher.itemWidth * 0.75\n",
               "el ancho del lanzador")
    # El fondo crece al abrir y se encoge al cerrar, desde el centro (si no, se queda
    # un rectángulo oscuro un momento al cerrar, porque ya no se esconde tras la orilla)
    patch_file(root, "modules/drawers/ContentWindow.qml", """        PanelBg {
            id: launcherBg

            panel: panels.launcher
            deformAmount: 0.1
        }
""", """        PanelBg {
            id: launcherBg

            readonly property real grow: 1 - panels.launcher.offsetScale

            panel: panels.launcher
            deformAmount: 0.1
            implicitWidth: panel.width * (0.9 + 0.1 * grow) * (grow > 0.01 ? 1 : 0)
            implicitHeight: panel.height * grow
            x: panel.x + bar.implicitWidth + (panel.width - implicitWidth) / 2
            y: panel.y + root.borderThickness + (panel.height - implicitHeight) / 2
        }
""", "el fondo del lanzador")
    # Solo el nombre de la app, sin descripción, en filas más bajitas
    patch_file(root, "modules/launcher/items/AppItem.qml",
               "    implicitHeight: Tokens.sizes.launcher.itemHeight\n",
               "    implicitHeight: Math.round(Tokens.sizes.launcher.itemHeight * 0.7)\n",
               "la altura de las apps")
    patch_file(root, "modules/launcher/items/AppItem.qml",
               "            implicitHeight: name.implicitHeight + comment.implicitHeight\n",
               "            implicitHeight: name.implicitHeight\n",
               "el texto de las apps")
    patch_file(root, "modules/launcher/items/AppItem.qml",
               "                id: comment\n",
               "                id: comment\n\n                visible: false\n",
               "la descripción de las apps")
    patch_file(root, "modules/launcher/AppList.qml",
               "    implicitHeight: (Tokens.sizes.launcher.itemHeight + spacing) * Math.min(Config.launcher.maxShown, count) - spacing\n",
               "    implicitHeight: Math.min(contentHeight, (Math.round(Tokens.sizes.launcher.itemHeight * 0.7) + spacing) * Config.launcher.maxShown - spacing)\n",
               "la altura de la lista")
    # Ancho justo para el nombre más largo de las apps que se están mostrando
    patch_file(root, "modules/launcher/AppList.qml", """    property string displayText
""", """    property string displayText

    readonly property real fitWidth: {
        if (displayState !== "apps")
            return Tokens.sizes.launcher.itemWidth * 0.75;
        let w = 0;
        for (const e of (model.values ?? []).slice(0, Config.launcher.maxShown))
            w = Math.max(w, nameMetrics.advanceWidth(e?.name ?? ""));
        const row = Math.round(Tokens.sizes.launcher.itemHeight * 0.7) - Tokens.padding.small * 2;
        return Math.max(300, Math.ceil(w + row * 0.8 + Tokens.spacing.medium + Tokens.padding.medium * 2 + Tokens.padding.large * 2 + 28));
    }

    FontMetrics {
        id: nameMetrics

        font: root.Tokens.font.body.medium
    }
""", "el inicio de AppList")
    patch_file(root, "modules/launcher/ContentList.qml",
               "root.implicitWidth: root.Tokens.sizes.launcher.itemWidth * 0.75\n",
               "root.implicitWidth: appList.item?.fitWidth ?? root.Tokens.sizes.launcher.itemWidth * 0.75\n",
               "el ancho ajustable del lanzador")
    # Si un nombre no cabe (al bajar en la lista), se corta con "…"
    patch_file(root, "modules/launcher/items/AppItem.qml", """                text: root.modelData?.name ?? ""
                font: Tokens.font.body.medium
""", """                text: root.modelData?.name ?? ""
                font: Tokens.font.body.medium
                width: root.width - icon.width - favouriteIcon.width - Tokens.rounding.extraLargeIncreased
                elide: Text.ElideRight
""", "el nombre de las apps")


def patch_osicon(root):
    """Logo de la barra a color (Nero) en vez de pintado con el tema, y más grande."""
    rel = "modules/bar/components/OsIcon.qml"
    patch_file(root, rel, """    implicitWidth: Math.round(Tokens.font.body.large.pointSize * 1.2)
    implicitHeight: Math.round(Tokens.font.body.large.pointSize * 1.2)
""", """    implicitWidth: Math.round(Tokens.font.body.large.pointSize * 2)
    implicitHeight: Math.round(Tokens.font.body.large.pointSize * 2)
""", "el tamaño del logo")
    patch_file(root, rel, """        ColouredIcon {
            source: SysInfo.osLogo
            implicitSize: Math.round(Tokens.font.body.large.pointSize * 1.2)
            colour: Colours.palette.m3tertiary
        }""", """        Image {
            source: SysInfo.osLogo
            width: Math.round(Tokens.font.body.large.pointSize * 2)
            height: width
            sourceSize.width: width * 2
            sourceSize.height: height * 2
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
        }""", "el ícono a color del logo")


def patch_dash_logo(root):
    """Logo del dashboard a color (Nero) en vez de pintado con el tema."""
    patch_file(root, "modules/dashboard/dash/User.qml", """        ColouredIcon {
            id: icon

            source: SysInfo.osLogo
            implicitSize: Tokens.sizes.dashboard.logoSize
            colour: Colours.palette.m3onPrimaryContainer
        }""", """        Image {
            id: icon

            source: SysInfo.osLogo
            width: Tokens.sizes.dashboard.logoSize
            height: width
            sourceSize.width: width * 2
            sourceSize.height: height * 2
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
        }""", "el logo del dashboard")


def patch_lock_video(root):
    """Bloqueo con fondo animado (~/.config/caelestia/bloqueo.mp4) y sin desenfoque.
    Si el video no existe, usa el fondo normal de Caelestia."""
    rel = "modules/lock/LockSurface.qml"
    patch_file(root, rel, "import QtQuick.Effects\n", "import QtQuick.Effects\nimport QtMultimedia\nimport Quickshell\n", "los imports del bloqueo")
    patch_file(root, rel, "            blurEnabled: true\n", "            blurEnabled: !root.videoFondo\n", "el desenfoque del bloqueo")
    patch_file(root, rel,
               "sourceComponent: Config.lock.useWallpaper ? wallpaperBackground : screencopyBackground",
               "sourceComponent: root.videoFondo ? videoBackground : Config.lock.useWallpaper ? wallpaperBackground : screencopyBackground",
               "el fondo del bloqueo")
    patch_file(root, rel, """    Component {
        id: screencopyBackground
""", """    // Si el video falla (o no existe) vuelve al fondo normal de Caelestia
    property bool videoFalla: false
    readonly property bool videoFondo: !videoFalla

    Component {
        id: videoBackground

        Video {
            source: "file://" + Quickshell.env("HOME") + "/.config/caelestia/bloqueo.mp4"
            fillMode: VideoOutput.PreserveAspectCrop
            loops: MediaPlayer.Infinite
            muted: true
            autoPlay: true
            onErrorOccurred: root.videoFalla = true
        }
    }

    Component {
        id: screencopyBackground
""", "el componente del fondo del bloqueo")


PAL = re.compile(r"\bColours\.(palette|tPalette)\b")


def patch_tray_title(root):
    """bar.tray.iconSubs también acepta "title:<título>" como id, para apps con id
    cambiante (Battle.net con Wine sale como wine-0x....)."""
    patch_file(root, "modules/bar/components/TrayItem.qml",
               "source: Icons.getTrayIcon(root.modelData.id, root.modelData.icon)",
               "source: Icons.getTrayIcon(root.modelData.id, root.modelData.icon, root.modelData.title)",
               "el ícono de la bandeja")
    patch_file(root, "utils/Icons.qml", """    function getTrayIcon(id: string, icon: string): string {
        for (const sub of GlobalConfig.bar.tray.iconSubs.values)
            if (sub.id === id)""", """    function getTrayIcon(id: string, icon: string, title: string): string {
        for (const sub of GlobalConfig.bar.tray.iconSubs.values)
            if (sub.id === id || (title && sub.id === `title:${title}`))""", "getTrayIcon")


def patch_fav_order(root):
    """Favoritos del lanzador en el orden de launcher.favouriteApps (no por uso)."""
    patch_file(root, "modules/launcher/services/Apps.qml", "    list: appDb.apps\n", """    list: {
        const fav = GlobalConfig.launcher.favouriteApps;
        const rank = a => {
            const i = fav.indexOf(a.id);
            return i < 0 ? fav.length : i;
        };
        return [...appDb.apps].sort((a, b) => rank(a) - rank(b) || b.frequency - a.frequency || a.name.localeCompare(b.name));
    }
""", "la lista de apps del lanzador")


def patch_ws_wheel(root):
    """Rueda sobre la barra: solo escritorios de ese monitor, sin dar la vuelta (ws_monitor en hypr-user.lua)."""
    patch_file(root, "modules/bar/Bar.qml", """            else if (angleDelta.y < 0 || mon.activeWorkspace?.id > 1)
                Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({ workspace = "r${angleDelta.y > 0 ? "-" : "+"}1" })` : `workspace r${angleDelta.y > 0 ? "-" : "+"}1`);""", """            else if (Hypr.usingLua)
                // ws_monitor viene de ~/.config/caelestia/hypr-user.lua: se mueve solo entre los escritorios de este monitor, sin dar la vuelta
                Hypr.dispatch(`ws_monitor(${angleDelta.y > 0 ? -1 : 1})`);
            else if (angleDelta.y < 0 || mon.activeWorkspace?.id > 1)
                Hypr.dispatch(`workspace r${angleDelta.y > 0 ? "-" : "+"}1`);""", "la rueda de escritorios en la barra")


def patch_ws_kanji(root):
    """Escritorios numerados en kanji (bar.workspaces.displayType = Text y labels vacíos en shell.json)."""
    patch_file(root, "modules/bar/components/workspaces/Workspace.qml", """                const capitalisation = Config.bar.workspaces.capitalisation;""", """                // Números en kanji (一 二 三 …) para los escritorios numerados
                const kanji = ["〇", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十"];
                if (Number.isInteger(Number(wsName)) && wsName >= 0 && wsName <= 10)
                    return kanji[wsName];

                const capitalisation = Config.bar.workspaces.capitalisation;""", "el texto de los escritorios")
    # Fuente a pincel (appearance.font.workspaces = "Yuji Boku" en shell.json) un poco más grande para que se note el trazo
    patch_file(root, "modules/bar/components/workspaces/Workspace.qml", """            font.family: Tokens.font.workspaces
""", """            font.family: Tokens.font.workspaces
            font.pointSize: Tokens.font.body.small.pointSize * 1.5 // kanji a pincel más grandes
""", "la fuente de los escritorios")


def patch_ws_gaming(root):
    """Escritorio con nombre ("gaming") del monitor arriba del primero en la barra, como 〇."""
    rel = "modules/bar/components/workspaces/Workspaces.qml"
    patch_file(root, rel, """        if (Config.bar.workspaces.showUnoccupied)
            return Array.from({
                length: shown
            }, (_, i) => i + 1);
""", """        if (Config.bar.workspaces.showUnoccupied) {
            // Escritorios con nombre de este monitor (ej. "gaming") arriba del primero numerado
            const named = Hypr.workspaces.values.filter(w => w.id < 0 && w.monitor === root.monitor && !w.name.startsWith("special:")).map(w => w.id);
            return named.concat(Array.from({
                length: shown
            }, (_, i) => groupOffset + i + 1));
        }
""", "la lista de escritorios")
    patch_file(root, rel, """        return Math.floor((activeWsId - 1) / shown) * shown;
""", """        // En un escritorio con nombre (id negativo) se usa el grupo de los numerados de este monitor
        const ids = Hypr.workspaces.values.filter(w => w.id > 0 && w.monitor === root.monitor).map(w => w.id);
        const id = activeWsId > 0 ? activeWsId : (ids.length ? Math.min(...ids) : 1);
        return Math.floor((id - 1) / shown) * shown;
""", "el grupo de escritorios")
    patch_file(root, rel, """    function workspaceIndex(id: int): int {
        if (!Config.bar.workspaces.showUnoccupied)
            return wsIds.indexOf(id);

        let index = id - 1;
        while (index < 0)
            index += shown;
        return index % shown;
    }
""", """    function workspaceIndex(id: int): int {
        return wsIds.indexOf(id);
    }
""", "el índice de escritorios")
    patch_file(root, rel, """                ws: Config.bar.workspaces.showUnoccupied ? root.groupOffset + index + 1 : modelData
""", """                ws: modelData
""", "el id de cada escritorio")
    patch_file(root, rel, """                if (Hypr.activeWsId !== ws)
                    Hypr.focusWorkspace(ws);
""", """                if (Hypr.activeWsId !== ws)
                    Hypr.focusWorkspace(ws < 0 ? `name:${Hypr.workspaces.values.find(w => w.id === ws)?.name ?? ""}` : ws);
""", "el clic en un escritorio")
    patch_file(root, "modules/bar/components/workspaces/Workspace.qml", """                // Números en kanji (一 二 三 …) para los escritorios numerados
""", """                // El escritorio "gaming" va como cero (零)
                if (ws?.name === "gaming")
                    return "零";

                // Números en kanji (一 二 三 …) para los escritorios numerados
""", "el nombre del escritorio gaming")


def patch_lock_eclipse(root):
    """2026-11-11 (Fable, variante segura: solo colores): bloqueo en tema Eclipse del sitio."""
    ROJO, ROSA, FG, LUNA = "#ff2448", "#ff7a8e", "#fff1f3", "#050203"
    patch_file(root, "modules/lock/center/Clock.qml",
               "        text: Time.hourStr\n        color: Colours.palette.m3primary\n",
               f"        text: Time.hourStr\n        color: \"{FG}\"\n", "lock eclipse: horas")
    patch_file(root, "modules/lock/center/Clock.qml",
               "        text: Time.minuteStr\n        color: Colours.palette.m3secondary\n",
               f"        text: Time.minuteStr\n        color: \"{ROJO}\"\n", "lock eclipse: minutos")
    patch_file(root, "modules/lock/Center.qml",
               "        text: Time.format(\"dddd • d MMM\").toUpperCase()\n        color: Colours.palette.m3onSurface\n",
               f"        text: Time.format(\"dddd • d MMM\").toUpperCase()\n        color: \"{ROSA}\"\n", "lock eclipse: fecha")
    patch_file(root, "modules/lock/center/PasswordInput.qml",
               "    color: Colours.tPalette.m3surfaceContainer\n    radius: Tokens.rounding.full\n",
               "    color: Qt.rgba(20 / 255, 4 / 255, 8 / 255, 0.55)\n    radius: Tokens.rounding.full\n", "lock eclipse: caja")
    patch_file(root, "modules/lock/LockSurface.qml",
               "            id: lockBg\n\n            anchors.fill: parent\n            color: Colours.palette.m3surface\n",
               f"            id: lockBg\n\n            anchors.fill: parent\n            color: \"{LUNA}\"\n", "lock eclipse: gota")


def patch_lock_kanji(root):
    """Contraseña del bloqueo: un kanji a pincel (一 二 三 …) por letra en lugar de figuras."""
    rel = "modules/lock/center/InputField.qml"
    patch_file(root, rel, """            PropertyAction {
                target: charShape
                property: "shape"
                value: MaterialShape.Circle
            }
""", "", "el cambio de figura de la contraseña")
    patch_file(root, rel, """        MaterialShape {
            id: charShape

            anchors.centerIn: parent
            implicitSize: charList.implicitHeight * 1.5
            shape: root.shapeQueue[char.index % root.shapeQueue.length] ?? MaterialShape.Circle
            color: Colours.palette.m3onSurface
""", """        StyledText {
            id: charShape

            anchors.centerIn: parent
            text: ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"][char.index % 10]
            font.family: Tokens.font.workspaces
            font.pixelSize: charList.implicitHeight * 1.5
            color: Colours.palette.m3onSurface
""", "las figuras de la contraseña")


def patch_users(root):
    changed = 0
    for f in root.rglob("*.qml"):
        if f.name == "Colours.qml" and f.parent.name == "services":
            continue
        t = f.read_text()
        if not PAL.search(t):
            continue
        # En la raíz de una ventana QsWindow.window es null; ahí "this" es la ventana
        t = PAL.sub(r"Colours.of(QsWindow.window ?? this).\1", t)
        if not re.search(r"^import Quickshell\s*$", t, re.M):
            # después del último import
            imports = list(re.finditer(r"^import .*$", t, re.M))
            pos = imports[-1].end() if imports else 0
            t = t[:pos] + "\nimport Quickshell" + t[pos:]
        f.write_text(t)
        changed += 1
    return changed


def main():
    if not SRC.is_dir():
        sys.exit(f"No existe {SRC}")
    tmp = DST.with_name(DST.name + ".tmp")
    shutil.rmtree(tmp, ignore_errors=True)
    shutil.copytree(SRC, tmp, symlinks=True)
    patch_colours(tmp / "services/Colours.qml")
    patch_launcher(tmp)
    patch_osicon(tmp)
    patch_dash_logo(tmp)
    patch_lock_video(tmp)
    patch_tray_title(tmp)
    patch_fav_order(tmp)
    patch_ws_wheel(tmp)
    patch_ws_kanji(tmp)
    patch_ws_gaming(tmp)
    patch_lock_kanji(tmp)
    patch_lock_eclipse(tmp)
    n = patch_users(tmp)
    (tmp / ".permon-version").write_text(pkg_version() + "\n")
    shutil.rmtree(DST, ignore_errors=True)
    tmp.rename(DST)
    print(f"Listo: {n} archivos adaptados ({pkg_version()}) en {DST}")


if __name__ == "__main__":
    main()
