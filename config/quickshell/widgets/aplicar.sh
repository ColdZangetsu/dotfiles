#!/usr/bin/env bash
# Deja el borrador como LOS widgets del ASUS (el servicio widgets-escritorio sigue lanzando "qs -c widgets").
#   ./aplicar.sh           -> ~/.config/quickshell/widgets pasa a widgets.bak-antes-fable y el borrador toma su lugar
#   ./aplicar.sh deshacer  -> regresa los widgets anteriores
set -e
Q="$HOME/.config/quickshell"; AQUI="$(cd "$(dirname "$0")" && pwd)"
reiniciar() { qs -p "$AQUI" kill 2>/dev/null || true; systemctl --user restart widgets-escritorio.service; }
case "${1:-aplicar}" in
  aplicar)
    [ -e "$Q/widgets.bak-antes-fable" ] && { echo "Ya existe $Q/widgets.bak-antes-fable (¿ya estaba aplicado?). Usa: $0 deshacer"; exit 1; }
    mv "$Q/widgets" "$Q/widgets.bak-antes-fable"
    cp -r "$AQUI" "$Q/widgets"
    reiniciar; echo "Aplicado. Revertir: $AQUI/aplicar.sh deshacer" ;;
  deshacer)
    [ -d "$Q/widgets.bak-antes-fable" ] || { echo "No hay respaldo $Q/widgets.bak-antes-fable"; exit 1; }
    rm -rf "$Q/widgets.fable-quitado"; mv "$Q/widgets" "$Q/widgets.fable-quitado"
    mv "$Q/widgets.bak-antes-fable" "$Q/widgets"
    reiniciar; echo "Widgets anteriores de vuelta (el aplicado quedó en $Q/widgets.fable-quitado)." ;;
  *) echo "uso: $0 [aplicar|deshacer]"; exit 1 ;;
esac
