function fish_greeting
    # Bienvenida estilo "TERMINAL ONLINE" (config en ~/.config/fastfetch/config.jsonc)
    # Respaldo de la anterior (banner de Caelestia): fish_greeting.fish.bak-nero
    command -v fastfetch &> /dev/null && fastfetch
end
