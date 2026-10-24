#!/bin/sh
# Colores de Caelestia según el fondo. Lo llama wallmux con: <monitor> <imagen>
# - El ASUS (principal) cambia el tema global: shell, apps, terminal, Hyprland.
# - Los demás monitores guardan su propia paleta para la barra y paneles de ese
#   monitor (Caelestia por monitor, ver ~/.local/share/caelestia-permon).
# Puerto actual del ASUS (por modelo, para que no importe el conector)
PRINCIPAL=$(hyprctl monitors -j | jq -r '.[] | select(.description | startswith("ASUSTek COMPUTER INC XG27ACDMS")) | .name')
[ -n "$PRINCIPAL" ] || PRINCIPAL=DP-1
DIR="$HOME/.local/state/caelestia/schemes"

paleta() {  # <monitor> <imagen>
  mkdir -p "$DIR"
  caelestia wallpaper -p "$2" > "$DIR/.$1.tmp" && mv "$DIR/.$1.tmp" "$DIR/$1.json"
}

if [ "$1" = "all" ]; then
  monitores=$(hyprctl monitors -j | jq -r '.[].name')
else
  monitores="$1"
fi

for m in $monitores; do
  if [ "$m" = "$PRINCIPAL" ]; then
    caelestia wallpaper -f "$2"
    rm -f "$DIR/$m.json"
  else
    paleta "$m" "$2"
  fi
done
