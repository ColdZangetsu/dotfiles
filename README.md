# Linux de Cold

Respaldo de mi escritorio: **CachyOS + Hyprland (config en Lua) + Caelestia (Quickshell)**, con fondos animados en 3 monitores.
Es para reinstalarlo yo, no es una guía pulida. Si te sirve algo, tómalo.

Monitores: **LG** (DP-1, 2560×1440), **ASUS** (DP-2, 2560×1440, el principal), **XENEON EDGE** (DP-3, 2560×720 táctil).
GPU: RTX 5070 (NVIDIA). Dual boot con Windows 11 vía Limine + Secure Boot.

## Qué hay aquí

| Carpeta | Va en | Qué es |
|---|---|---|
| `config/` | `~/.config/` | Hyprland, Caelestia (copia del shell **parchada**), foot, kitty, fish, fastfetch, fuzzel, btop, cava, wallmux, gtk/qt, easyeffects, nvim, micro |
| `bin/` | `~/.local/bin/` | Mis scripts: modo trabajo/casa, monitores, wallmux, govee, xodus, etc. |
| `systemd-user/` | `~/.config/systemd/user/` | Servicios y timers de usuario |
| `sistema/etc/` | `/etc/` | greetd (greeter de Makima), Limine, reglas udev del teclado, sshd |
| `paquetes-repo.txt` | | `pacman -Qqen` (repos oficiales + CachyOS) |
| `paquetes-aur.txt` | | `pacman -Qqem` (AUR) |
| `flatpaks.txt` | | Flatpaks |

Los **fondos** (videos de Wallpaper Engine grabados en HEVC 4:4:4) están en los [Releases](../../releases), porque GitHub no acepta archivos de más de 100 MB.

**No incluye** (a propósito): llaves y tokens, sesiones, el bot de WhatsApp / Nero, cosas del servidor (Zangetsu), IPs de Tailscale.
Donde un script necesita la IP del servidor dice `ZANGETSU_IP`: hay que cambiarla a mano.

## Reinstalar desde cero

1. **CachyOS** con el instalador, escritorio *Hyprland*, disco Btrfs + snapper, bootloader **Limine**.
2. Paquetes:
   ```sh
   sudo pacman -S --needed - < paquetes-repo.txt
   paru -S --needed - < paquetes-aur.txt        # o yay
   flatpak install flathub $(cat flatpaks.txt)
   pipx install wallmux                          # daemon de fondos (usa mpvpaper / awww)
   ```
3. Archivos de usuario (hace respaldo `*.antes-restaurar` de lo que ya exista):
   ```sh
   ./restaurar.sh
   ```
4. Archivos de sistema: copiarlos **a mano** viendo cada uno (`sistema/etc/...` → `/etc/...`), sobre todo
   `/etc/default/limine` (los UUID de los discos cambian) y `/etc/greetd/`.
5. Servicios de usuario:
   ```sh
   systemctl --user daemon-reload
   systemctl --user enable --now wallmux awww-daemon widgets-escritorio caelestia-permon.path govee-fondo.path
   ```
6. Fondos: bajar los videos del Release a `/mnt/Compartido/Nero/fondos` (o donde sea) y asignarlos con `wallmuxctl`.
   **No** meterlos a la biblioteca de wallmux, porque los recodifica a 4:2:0.
   Asignación: ASUS = `makima.mp4`, LG = `akali.mp4`, XENEON = `tarde-xeneon.mp4` (repuesto: `dresden-xeneon.mp4`).
   Hay versiones a 30 fps (`30fps-*`) que gastan bastante menos GPU.

## Notas que se me van a olvidar

- **Caelestia**: el shell corre desde la copia parchada en `~/.config/quickshell/caelestia` (colores por monitor y otros cambios).
  Si algo del shell falla después de actualizar, sospechar primero de esa copia contra la de `/etc/xdg/quickshell/caelestia`.
  Las actualizaciones grandes de Qt piden recompilar `quickshell-git`.
- **Monitores**: si cambio cables, correr `monitores-reacomodar`.
- **Secure Boot**: llaves propias con `sbctl` (`sbctl create-keys`, `sbctl enroll-keys -m` para conservar las de Microsoft),
  firmar Limine en las dos ESP y luego activar Secure Boot en el BIOS (MSI). El BIOS siempre arranca el disco de 512 → hace chainload a Limine.
- **sudo** desde herramientas sin terminal: usar `pkexec`.
- **Modo trabajo** (`modo-trabajo on` / `modo-casa`, o Super+Inicio): apaga monitores, luces y fondos, y deja un monitor virtual
  `STREAM` para jugar desde el iPad (Steam Link / Moonlight + Sunshine).
- **Fondos y GPU**: en Linux, 3 videos a 60 fps gastan ~+33 W contra ~+14 W en Windows. Por eso los de 30 fps.
- **Greeter**: greetd + Hyprland mínimo (`/etc/greetd/makima/`), con un video de Makima en loop; el reloj y la contraseña salen solo en el ASUS.
- **Fastfetch**: logo de Nero, "TERMINAL ONLINE".
