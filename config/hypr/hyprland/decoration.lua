local vars = require("variables")

hl.config({
    decoration = {
        rounding = vars.windowRounding,
        rounding_power = vars.windowRoundingPower,

        blur = {
            enabled           = vars.blurEnabled,
            xray              = vars.blurXray,
            special           = vars.blurSpecialWs,
            ignore_opacity    = true, -- Allows opacity blurring
            new_optimizations = true,
            popups            = vars.blurPopups,
            input_methods     = vars.blurInputMethods,
            size              = vars.blurSize,
            passes            = vars.blurPasses,
            -- 11-12 receta Fable: cristal más oscuro y cremoso (costo casi nulo)
            brightness        = 0.80,
            contrast          = 0.95,
            vibrancy          = 0.22,
            vibrancy_darkness = 0.30,
            noise             = 0.02,
        },

        shadow = {
            enabled      = vars.shadowEnabled,
            range        = vars.shadowRange,
            render_power = vars.shadowRenderPower,
            color        = vars.shadowColour,
        },
    },
})
