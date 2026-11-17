# Tsuka — la barra izquierda (diseño Fable)

> **Histórico.** La Tsuka final (con Saya) está en `TSUKA-SAYA.md`.

La barra izquierda como **empuñadura de espada puesta de pie**. Boceto aprobado (v2):
`/mnt/Compartido/Nero/diseno-fable/tsuka-barra-izquierda.html` · capturas reales: `/mnt/Compartido/Nero/diseno-fable/tsuka-capturas/`.

De arriba a abajo:
- **Pomo = ojo de Nero** (+ "NERO" en Anton). `vigila` = entrecerrado · `trabaja` = abierto con el eco del monitor ·
  `escribio` = abierto mirando a la pantalla y su mensaje asoma como lengua de hoja. Nero nunca usa rojo.
- **Cordón** con un rombo por escritorio de ESE monitor (kanji Yuji Boku): ASUS 一二三 (+ 零 arriba si existe "gaming"),
  LG 四五六, XENEON 七八 (así están las reglas en `~/.config/caelestia/hypr-user.lua`). Hueso = con ventanas,
  apagado = vacío, **un solo filo rojo = activo** (se desliza 200 ms). Clic = ir; rueda = `ws_monitor` como antes.
- **Título** de la ventana al frente en ese monitor, girado (se oculta si no cabe, p. ej. XENEON).
- **Hora** (Anton, 24 h) sobre la **guarda de hueso** (lo único que se sale 16 px del ancho).
- **3 puntos**: red (eco si hay red) · volumen (apagado si silencio) · bandeja.
- **La hoja** (abajo) = sesión: clic o jalar hacia abajo abre el **menú de lunas de siempre** (`screenState.session`).
- **Empuñada** (cursor encima 140 ms): se abre a 232 px ENCIMA de las ventanas y explica cada pieza: qué hace Nero,
  apps por escritorio (clic = ir), fecha, red, volumen (clic = silenciar, rueda = volumen), bandeja (íconos: clic =
  abrir, clic derecho = menú), "Bloquear · Dormir · Apagar". La zona reservada sigue siendo 56 px: la parte empuñada
  solo agranda la máscara de entrada (`Regions.qml`).
- **Pantalla completa** (juego): BarWrapper ya la descarga (`fullscreen`) → se retira y no anima nada.
- Movimiento solo al cambiar de estado (160–220 ms). Sin bucles ni Canvas: Shapes (CurveRenderer) que solo se
  re-teselan durante la transición del ojo. Reposo medido: 0.2 % CPU.

## Archivos
| Archivo | Qué |
|---|---|
| `modules/tsuka/Tsuka.qml` | la barra completa (misma interfaz que `Bar`: closeTray/checkPopout/salir/handleWheel + `alcance`) |
| `modules/tsuka/Pomo.qml` | el ojo de Nero |
| `modules/tsuka/Tinta.qml` | paleta fija del boceto (un solo rojo) |
| `services/TsukaConf.qml` | interruptor + estado de Nero (FileView `watchChanges`, sin sondeo); IPC `tsuka estado` |
| `modules/bar/BarWrapper.qml` | carga `Tsuka` o la `Bar` de siempre según el interruptor; sin `clip` con Tsuka |
| `modules/drawers/Regions.qml` | región extra de entrada para la parte empuñada |

La barra de antes (`modules/bar/Bar.qml` y sus componentes) **no se tocó**.

## Interruptor (en vivo, sin reiniciar el shell)
`~/.config/caelestia/tsuka.json` → `{"activa": true}`.
**Volver a la barra de antes, un comando:**
```
echo '{"activa": false}' > ~/.config/caelestia/tsuka.json
```
(y `{"activa": true}` para regresar a Tsuka). Si el archivo falta o está mal = barra de antes.
Deshacer del todo: `git -C ~/.config/quickshell revert <commits de Tsuka>`.

## Estado de Nero
`~/.local/bin/nero-estado` escribe `~/.local/state/nero/estado` (JSON `{estado, texto, hora}`) de forma atómica:
```
nero-estado vigila
nero-estado trabaja "respaldando Zangetsu"
nero-estado escribio "Ya quedó el respaldo."
nero-estado            # imprime el actual
```
`escribio` vuelve solo a `vigila` a los 15 min, o al empuñar la barra > 0.7 s (se da por leído), o con clic al ojo.
`trabaja` caduca a las 3 h (por si el bot se queda a medias). Desde Zangetsu: `ssh pc nero-pc 'nero-estado escribio "…"'`.

## Ojo
- `~/.local/share/caelestia-permon/update.sh` hace `rm -rf caelestia/` al actualizarse Caelestia: Tsuka se recupera con
  `git -C ~/.config/quickshell checkout -- caelestia/` (igual que los demás parches Fable).
- Fuentes: Anton, Inter (`~/.local/share/fonts/inter`, v4.1 de rsms/inter), Yuji Boku (`~/.local/share/fonts/pincel`).
- Reinicio del shell solo desbloqueado: `qs -c caelestia kill; sleep 2; systemd-run --user --collect qs -c caelestia -n`.
