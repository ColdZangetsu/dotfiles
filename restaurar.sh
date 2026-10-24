#!/bin/sh
# Copia config/, bin/ y systemd-user/ a su lugar. Lo que ya exista se respalda como *.antes-restaurar.
set -e
cd "$(dirname "$0")"
copiar() { # origen destino
    mkdir -p "$2"
    for f in "$1"/* "$1"/.[!.]*; do
        [ -e "$f" ] || continue
        d="$2/$(basename "$f")"
        [ -e "$d" ] && [ ! -e "$d.antes-restaurar" ] && mv "$d" "$d.antes-restaurar"
        cp -a "$f" "$d"
        echo "  $d"
    done
}
echo "~/.config";              copiar config "$HOME/.config"
echo "~/.local/bin";           copiar bin "$HOME/.local/bin"
echo "~/.config/systemd/user"; copiar systemd-user "$HOME/.config/systemd/user"
echo
echo "Listo. Falta: cambiar ZANGETSU_IP en bin/ si se usa, copiar a mano sistema/etc/, y habilitar los servicios (ver README)."
