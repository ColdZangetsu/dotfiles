-- Hyprland mínimo para la pantalla de inicio (greetd). Solo muestra el greeter de Quickshell.
-- Por modelo, no por puerto: así da igual en qué conector esté cada cable
hl.monitor({ output = "desc:ASUSTek COMPUTER INC XG27ACDMS", mode = "2560x1440@279.96", position = "2560x0", scale = 1.0 })
hl.monitor({ output = "desc:LG Electronics LG ULTRAGEAR", mode = "2560x1440@59.95", position = "0x0", scale = 1.0 })
hl.monitor({ output = "desc:Cyrix Corporation XENEON EDGE", mode = "2560x720@60.27", position = "960x1440", scale = 1.6 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

hl.config({
    input = { kb_layout = "us", kb_variant = "altgr-intl" },
    misc = {
        disable_hyprland_logo = true,
        force_default_wallpaper = 0,
        background_color = "rgb(000000)",
    },
    animations = { enabled = false },
    ecosystem = { no_update_news = true, no_donation_nag = true },
})

hl.on("hyprland.start", function()
    hl.dispatch(hl.dsp.focus({ monitor = "desc:ASUSTek COMPUTER INC XG27ACDMS" }))
    -- Al entrar (o si el greeter se cierra) se apaga este Hyprland y greetd arranca tu sesión
    hl.exec_cmd("sh -c 'qs -p /etc/greetd/makima/shell.qml; hyprctl dispatch \"hl.dsp.exit()\"'")
end)
