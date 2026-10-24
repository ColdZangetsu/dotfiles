-- Monitores
-- Por modelo, no por puerto: así da igual en qué conector esté cada cable
local ASUS = "desc:ASUSTek COMPUTER INC XG27ACDMS"
local LG = "desc:LG Electronics LG ULTRAGEAR"
local XENEON = "desc:Cyrix Corporation XENEON EDGE"
hl.monitor({ output = ASUS, mode = "2560x1440@279.96", position = "2560x0", scale = 1.0, vrr = 2 }) -- G-Sync solo en pantalla completa
hl.monitor({ output = LG, mode = "2560x1440@59.95", position = "0x0", scale = 1.0, vrr = 0 })
hl.monitor({ output = XENEON, mode = "2560x720@60.27", position = "960x1440", scale = 1.6, vrr = 0 })

-- Workspaces
-- "gaming" (el 零 de la barra): solo existe mientras hay Steam o un juego abierto
hl.workspace_rule({ workspace = "name:gaming", monitor = ASUS })
hl.workspace_rule({ workspace = "1", monitor = ASUS, default = true, persistent = true })
hl.workspace_rule({ workspace = "2", monitor = ASUS, default = true, persistent = true })
hl.workspace_rule({ workspace = "3", monitor = ASUS, default = true, persistent = true })
hl.workspace_rule({ workspace = "4", monitor = LG, default = true, persistent = true })
hl.workspace_rule({ workspace = "5", monitor = LG, default = true, persistent = true })
hl.workspace_rule({ workspace = "6", monitor = LG, default = true, persistent = true })
hl.workspace_rule({ workspace = "7", monitor = XENEON, default = true, persistent = true })
hl.workspace_rule({ workspace = "8", monitor = XENEON, default = true, persistent = true })

-- Steam y los juegos se abren en "gaming"
-- Battle.net (Lutris/Wine): la clase es el .exe del juego; Overwatch se agrega cuando lo instale
local gamingApps = "^(steam|steam_app_.*|gamescope|Hollow Knight.*|Minecraft.*|(?i:blackopscoldwar\\.exe))$"
hl.window_rule({ match = { class = gamingApps }, workspace = "name:gaming" })
hl.window_rule({ match = { content = "game" }, workspace = "name:gaming" })
hl.window_rule({ match = { title = "^(Call of Duty.*Black Ops Cold War.*)$" }, workspace = "name:gaming" })
-- Minecraft (CurseForge): tratarlo como juego igual que los de Steam
hl.window_rule({ match = { class = "^(Minecraft.*)$" }, opaque = true, immediate = true, idle_inhibit = "always" })

-- Super + rueda: cambiar workspace solo dentro del monitor actual, sin dar la vuelta
-- (en el último se queda ahí), así adelante siempre desliza a la izquierda y atrás a la derecha
local function ws_monitor(dir)
    return function()
        local mon, actual = hl.get_active_monitor(), hl.get_active_workspace()
        if not mon or not actual then return end
        local ids = {}
        for _, ws in ipairs(hl.get_workspaces()) do
            -- incluye los escritorios con nombre (ej. "gaming", id negativo), no los especiales
            if not ws.special and ws.monitor and ws.monitor.name == mon.name
                and not (ws.name or ""):match("^special") then
                table.insert(ids, ws.id)
            end
        end
        -- los de nombre ("gaming", el 零 de la barra) primero y luego los numerados en orden
        table.sort(ids, function(a, b)
            if (a > 0) ~= (b > 0) then return a < 0 end
            return a < b
        end)
        for i, id in ipairs(ids) do
            if id == actual.id and ids[i + dir] then
                local destino = ids[i + dir]
                if destino < 0 then
                    for _, ws in ipairs(hl.get_workspaces()) do
                        if ws.id == destino then return hl.dispatch(hl.dsp.focus({ workspace = "name:" .. ws.name })) end
                    end
                end
                return hl.dispatch(hl.dsp.focus({ workspace = destino }))
            end
        end
    end
end
-- Global para que la rueda sobre la barra de Caelestia use la misma lógica
_G.ws_monitor = ws_monitor
hl.bind("SUPER + mouse_down", ws_monitor(1))
hl.bind("SUPER + mouse_up", ws_monitor(-1))

-- Claude Code en su propio workspace especial (con su icono en la barra)
local fn = require("utils.functions")
hl.window_rule({ match = { class = "^claude$" }, workspace = "special:claude" })

-- Super + A: mostrar/ocultar el workspace de Claude (lo abre si no está corriendo)
-- (antes Super+C; desde 2026-10-21 Super+C = hablarle a Nero por voz)
hl.bind("SUPER + A", fn.toggle("claude"))

-- Super + C: Nero por voz (graba, pregunta a la sesión fija del bot de WhatsApp y contesta
-- en voz alta); otra vez mientras escucha/piensa = cancelar. ~/.local/bin/nero-voz
hl.bind("SUPER + C", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/nero-voz"))

-- Super + Alt + C: PRUEBA Gemini Live (10-23), "llamada" en tiempo real con Nero; otra vez = colgar
hl.bind("SUPER + ALT + C", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/nero-live"))

-- Teclado US internacional con AltGr (como en Windows): AltGr + n = ñ
hl.config({ input = { kb_variant = "altgr-intl" } })

-- Selector de fondos de Wallpaper Engine (wallmux-we-gui)
hl.window_rule({ match = { class = "^(wallmux-we-gui)$" }, float = true, center = true, size = { "monitor_w*0.70", "monitor_h*0.75" } })

-- Bordes de ventana con los colores del monitor donde está cada ventana
-- (va con Caelestia por monitor, ver ~/.local/share/caelestia-permon/LEEME.md)
hl.on("hyprland.start", function()
    hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/bordes-por-monitor")
end)

-- Cierra juegos que se quedan colgados al salir (Cold War con Proton)
hl.on("hyprland.start", function()
    hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/vigilante-juegos")
end)

-- [desactivado: ahora en ~/.config/pipewire/pipewire.conf.d/99-micro-limpio.conf] EasyEffects: micro limpio (reducción de ruido) como NVIDIA Broadcast
-- hl.on("hyprland.start", function()
--     hl.exec_cmd("sh -c 'easyeffects --service-mode -w & sleep 5; easyeffects -l \"Micro limpio\"'")
-- end)

-- Super + Shift + Q: cerrar a la fuerza la ventana activa (juegos colgados al salir)
hl.bind("SUPER + SHIFT + Q", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/forzar-cierre"))

-- Super + S: abrir Steam (si ya está abierto, lo trae al frente)
hl.bind("SUPER + S", hl.dsp.exec_cmd("steam"))

-- Super + Shift + R: empezar/parar grabación de LG + ASUS (~/Vídeos/Grabaciones)
hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/grabar-monitores dos"))

-- ASUS como monitor principal para juegos (Wine/Proton): así ofrecen 280 Hz
hl.on("hyprland.start", function()
    hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/asus-principal")
end)

-- Redimensionar agarrando el borde de la ventana con el mouse (sin teclas), con 15 px de margen para atinarle
hl.config({ general = { resize_on_border = true, extend_border_grab_area = 15, hover_icon_on_border = true } })

-- Super + G: alternar flotante / mosaico (más fácil que Super + Alt + Espacio)
hl.bind("SUPER + G", hl.dsp.window.float())

-- Rockstar Games Launcher (Proton le pone clase steam_app_default): flotante al 60% x 70% en vez de pantalla completa
hl.window_rule({ match = { title = "^(Rockstar Games Launcher)$" }, tag = "+float_60_70" })

-- Red Dead Redemption 2: siempre en pantalla completa en el monitor de juegos (arranca en ventana 1280x720)
hl.window_rule({ match = { title = "^(Red Dead Redemption 2)$" }, float = false, fullscreen = true, monitor = ASUS })

-- Horas de trabajo (/mnt/Compartido/Nero/horas-trabajo/horas.py, tkinter = XWayland): ventanitas flotantes al centro
hl.window_rule({
    match  = { class = "^(Tk)$", title = "^(Horas de trabajo|Horas de la quincena|Ahorro de la quincena)$" },
    float  = true,
    center = true,
})

-- Horas de trabajo: al iniciar sesión pregunta las horas del día (solo de 18:00 a 12:00 y si faltan; ver horas.py)
hl.on("hyprland.start", function()
    hl.exec_cmd("sh -c 'sleep 10; exec python /mnt/Compartido/Nero/horas-trabajo/horas.py'")
end)

-- Reinicio remoto: si la PC entró sola (bandera), modo trabajo + bloqueo (ver ~/Nero/reinicio-remoto)
hl.on("hyprland.start", function()
    hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/arranque-remoto-sesion")
end)
