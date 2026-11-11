local vars = require("variables")

hl.config({
    input = {
        kb_layout          = "us",
        numlock_by_default = false,
        repeat_delay       = 250,
        repeat_rate        = 35,
        focus_on_close     = 1,
        accel_profile      = "flat",   -- sin aceleración (igual que Windows sin "Mejorar precisión")
        sensitivity        = 0,

        touchpad           = {
            natural_scroll       = true,
            disable_while_typing = vars.touchpadDisableTyping,
            scroll_factor        = vars.touchpadScrollFactor,
        },
    },

    binds = {
        scroll_event_delay = 0,
    },

    cursor = {
        hotspot_padding = 1,
    },
})

-- Touch del XENEON: apagado normalmente (en juegos/pantalla completa escondía el mouse); el modo música
-- (Super+F2, ~/.local/bin/modo-musica) lo prende mientras está activo. Siempre mapeado a su pantalla.
hl.device({ name = "wch.cn-touchscreen", enabled = false, output = "DP-3" })
