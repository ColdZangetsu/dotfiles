#!/usr/bin/env bash
# Widgets del ASUS — borrador Eclipse. NO cambia nada instalado.
#   ./probar.sh             -> cierra los widgets actuales y pone el borrador (tema del archivo "tema")
#   ./probar.sh eclipse     -> igual, con vidrio negro + rojo
#   ./probar.sh caelestia   -> igual, con los colores del fondo (Caelestia)
#   ./probar.sh volver      -> regresa a los widgets de siempre
# El tema también se cambia en vivo: echo caelestia > tema   (o eclipse)
set -e
AQUI="$(cd "$(dirname "$0")" && pwd)"
case "${1:-vivo}" in
  vivo|eclipse|caelestia)
    [ "${1:-vivo}" = vivo ] || echo "$1" > "$AQUI/tema"
    systemctl --user stop widgets-escritorio.service 2>/dev/null || true
    qs -p "$AQUI" kill 2>/dev/null || true
    sleep 1.5
    qs -p "$AQUI" -n -d
    echo "Borrador puesto en el ASUS (tema: $(cat "$AQUI/tema")). Para regresar: $0 volver" ;;
  volver)
    qs -p "$AQUI" kill 2>/dev/null || true
    sleep 1.5
    systemctl --user start widgets-escritorio.service
    echo "Widgets de siempre de vuelta." ;;
  *) echo "uso: $0 [eclipse|caelestia|volver]"; exit 1 ;;
esac
