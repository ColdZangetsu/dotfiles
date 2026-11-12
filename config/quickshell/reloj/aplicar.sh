#!/usr/bin/env bash
# Deja el borrador Eclipse como EL reloj del XENEON (hypr-user.lua sigue lanzando "qs -c reloj", no se toca).
#   ./aplicar.sh           -> ~/.config/quickshell/reloj pasa a reloj.bak-antes-fable y el borrador toma su lugar
#   ./aplicar.sh deshacer  -> regresa el reloj anterior
set -e
Q="$HOME/.config/quickshell"; AQUI="$(cd "$(dirname "$0")" && pwd)"
reiniciar() { qs -c reloj kill 2>/dev/null || true; qs -p "$AQUI" kill 2>/dev/null || true; sleep 1.5; qs -c reloj -n -d; }
case "${1:-aplicar}" in
  aplicar)
    [ -e "$Q/reloj.bak-antes-fable" ] && { echo "Ya existe $Q/reloj.bak-antes-fable (¿ya estaba aplicado?). Usa: $0 deshacer"; exit 1; }
    mv "$Q/reloj" "$Q/reloj.bak-antes-fable"
    cp -r "$AQUI" "$Q/reloj"
    reiniciar; echo "Aplicado. Revertir: $0 deshacer" ;;
  deshacer)
    [ -d "$Q/reloj.bak-antes-fable" ] || { echo "No hay respaldo $Q/reloj.bak-antes-fable"; exit 1; }
    rm -rf "$Q/reloj.fable-quitado"; mv "$Q/reloj" "$Q/reloj.fable-quitado"
    mv "$Q/reloj.bak-antes-fable" "$Q/reloj"
    reiniciar; echo "Reloj anterior de vuelta (el aplicado quedó en $Q/reloj.fable-quitado)." ;;
  *) echo "uso: $0 [aplicar|deshacer]"; exit 1 ;;
esac
