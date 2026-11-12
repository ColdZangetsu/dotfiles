#!/usr/bin/env bash
# Reloj del XENEON — borrador Eclipse. NO cambia nada instalado.
#   ./probar.sh captura   -> dibuja fuera de pantalla (no abre ventanas) y deja PNGs en esta carpeta
#   ./probar.sh           -> cambia EN VIVO al borrador en el XENEON (el reloj actual se cierra mientras)
#   ./probar.sh volver    -> regresa al reloj de siempre
#   RELOJ_TEMA=caelestia ./probar.sh   -> mismo diseño con los colores del fondo
#   RELOJ_SIN_ANIM=1 ./probar.sh       -> sin transiciones
set -e
AQUI="$(cd "$(dirname "$0")" && pwd)"
case "${1:-vivo}" in
  captura)
    cd "$AQUI"
    F="$AQUI/.fondo-prueba.png"
    [ -f "$F" ] || ffmpeg -loglevel error -y -ss 3 -i /mnt/Compartido/Nero/fondos/tarde-xeneon.mp4 -frames:v 1 -vf scale=1530:430 "$F" 2>/dev/null || F=""
    export QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software QT_SCALE_FACTOR=1.6
    qml6 prueba.qml -- "$AQUI/captura-lleno.png" "$F"
    qml6 prueba.qml -- "$AQUI/captura-vacio.png" "$F" vacio
    echo "Listo: $AQUI/captura-lleno.png y captura-vacio.png" ;;
  vivo)
    qs -c reloj kill 2>/dev/null || true; qs -p "$AQUI" kill 2>/dev/null || true
    sleep 1.5
    qs -p "$AQUI" -n -d
    echo "Borrador puesto en el XENEON. Para regresar: $0 volver" ;;
  volver)
    qs -p "$AQUI" kill 2>/dev/null || true
    sleep 1.5
    qs -c reloj -n -d
    echo "Reloj de siempre de vuelta." ;;
  *) echo "uso: $0 [captura|vivo|volver]"; exit 1 ;;
esac
