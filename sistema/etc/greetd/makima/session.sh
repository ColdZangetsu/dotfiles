#!/bin/sh
# Sesión del greeter (la lanza greetd como usuario "greeter").
export XDG_CACHE_HOME=/tmp/greeter-makima/cache
export XDG_STATE_HOME=/tmp/greeter-makima/state
export QT_QPA_PLATFORM=wayland
mkdir -p "$XDG_CACHE_HOME" "$XDG_STATE_HOME"

Hyprland --config /etc/greetd/makima/hyprland.lua >/tmp/greeter-makima/hyprland.log 2>&1
rc=$?

# Respaldo: si el greeter gráfico falló, inicio de sesión en texto para no quedarte fuera
if [ "$rc" -ne 0 ]; then
    exec agreety --cmd "uwsm start -e -D Hyprland hyprland.desktop"
fi
