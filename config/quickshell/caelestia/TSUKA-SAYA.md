# Tsuka 柄 + Saya 鞘: el par de barras final (diseño Fable)

Diseño (fuente de verdad): `/mnt/Compartido/Nero/diseno-fable/tsuka-saya-final/` (tsuka-saya-final.html, COMUN.md,
TSUKA-DISENO.md, SAYA-DISENO.md). Capturas: `/mnt/Compartido/Nero/diseno-fable/tsuka-saya-capturas/`.
Sustituye a la Tsuka de prueba (TSUKA.md, histórico).

- **Tsuka** (izquierda, 56 px): pomo con el ojo de Nero · cordón tejido (dos cintas sobre piel de raya) con las ventanas
  de escritorio (零 + los de ESTE monitor + el especial) · gemas (modos arriba, vigías abajo) · menuki con apps y título ·
  hora 12 h en el fuchi (cuadritos llenos = p. m.) · guarda · habaki · hoja de 40 px con temple y marcas grabadas
  (red, Bluetooth, bandeja, grabación). Placas por zona (cabeza, modos, agarre, vigías, guarda) encima de las ventanas.
  La hoja: clic o jalar ≥ 12 px = tajo + menú de lunas de siempre; clic derecho = bloquear.
- **Saya** (derecha, 8 px): laca, boca (Nero), pasador + cordón (música), incrustación (luces), rayas (avisos), contera.
  Cursor 140 ms en el borde (o clic) = desenvaina el bloque de 148 px (11-15 tarde; antes 76). Lenguas (mensaje de
  Nero 6 s, canción 3 s, candado 3 s) solo en el monitor con foco. El contenedor viejo del OSD se apaga con `saya`.
- **Barras en la vaina** (SAYA-DISENO.md §4.2, §4.3, §5.5, decisiones 17–23): la sección Barras (y 154–360; 112–290 en
  XENEON) lleva **Amanecer · Reiatsu · Eclipse**, los MISMOS componentes de `modules/osd` (`BarraLuces`,
  `BarraVolumen`, `BarraBrillo`) a `scale: s.bs` (0.5 = 36×160; 0.42 = 30×134 en XENEON), en fila, con lectura
  (día/tarde/noche, "43 %") y rótulo (LUZ/SON/BRI) debajo, y los conmutadores CANDADO (`luces-bloqueo` en Zangetsu) y
  CLÓSET (`closet on|off` en Zangetsu) abajo. Quietas en reposo (`despierto` falso): su `Nucleo` solo late al tocarlas
  o si cambia el valor, y se duerme solo. Arrastre/rueda/teclas/doble clic (favorito) = como el OSD; clic derecho en
  Amanecer = candado, en Reiatsu = silencio; clic medio en Reiatsu = pausa. La canción va en una fila (carátula 46,
  título Anton 14, artista, onda de 23). Avisos en fila (cantidad + etiqueta).
- **OSD con la vaina guardada:** la sección Barras sale como lengüeta de 64 px con SOLO la barra tocada (x = 14),
  misma instancia que la del bloque; se guarda a 1.6 s. Desenvainada: la tocada se mueve en su lugar y las otras dos
  bajan a 35 % esos 1.6 s (no si la moviste tú con la mano). Super+F4 (xeneon-control) desenvaina entera la vaina
  del XENEON 25 s. Las barras están en la capa `barras` de Saya.qml (encima de la sección, sin recorte, para que
  reciban el mouse y el aura/burbuja salgan del bloque).

## Mango final (11-15 04:55, commit f1dcab4)
La empuñadura ya trae el mango final de TSUKA-DISENO.md §3.3: tela **hilo por hilo** (`Mat.pintaTela`, port de
`pintaTela()` del prototipo: alas en abanico, cinturas alternas, trama, arrugas, pelusa), **varillas satinadas** cruzadas en
X (misma geometría de antes, con vetas, brillo y sombra), **nudos**, **dōgane** (manguito del título, `Mat.dogane`) y filetes
de hueso en pomo/manguito/collar. Lo de dentro de los rombos no cambió.
- **Color (ajuste del usuario 11-15):** varillas = tono CLARO del fondo, tela = tono OSCURO, siempre más oscura
  (`Mat.mango(<fam>FixedDim, on<Fam>FixedVariant)`, familia primary o tertiary en el LG; contraste WCAG ≥ 4.5; rojo →
  tela morada / marco hueso). Con los fondos del 11-15: ASUS/STREAM `#b6c1ce`/`#29415b`, LG `#c9bdae`/`#65481d`,
  XENEON `#adc7c8`/`#244e50` (varilla/tela).
- **Cómo se pinta:** un `Canvas` a 2x por monitor (Canvas.Image, Cooperative), una vez, 250 ms después de que se asiente
  la geometría; al terminar se congela en un `Image` (PNG en memoria) y el Canvas se oculta. Se repinta solo si cambian
  los dos colores o la geometría (probado cambiando DP-3.json en el banco). Costo: 13–84 ms por monitor al arrancar
  (se ve en el journal: `tsuka: tela <monitor> N ms`). Reposo real: 0.08 % sin mover el cursor.
- Las sombras del Canvas de Qt SÍ siguen `ctx.scale` (al revés que en un lienzo HTML): por eso `R = 1`.
- **Revertir solo el mango:** `git -C ~/.config/quickshell revert f1dcab4` + reiniciar el shell (vuelve el cordón SVG).

## Hilo rojo y hoja con elemento (11-15 tarde; diseño Fable aprobado)
Diseño (fuente de verdad): `/mnt/Compartido/Nero/diseno-fable/tsuka-transicion-elementos/` (prototipo
`tsuka-transicion-elementos.html`, commit 084df97; `DISENO.md`; `fotogramas/`). Capturas del banco:
`.../tsuka-transicion-elementos/capturas-linux/`. Commits: a2e553d (hoja + tajo), 9a3911a (hilo), 281246d (ventanitas
y repintados), más los de este documento.

**El hilo rojo** (`Hilo.qml`, `hilo.js` = port de `irA/paso1/pinta1`): el filo del rombo activo es un hilo cuyas dos
puntas son muelles (guía ω 20 ζ .62, la otra ω 13 ζ .85 con 70 ms de retraso; versión breve ω 34/26 si el cambio llega
a < 380 ms, con UN remate 240 ms después de la última llegada). Luna negra redonda con borde encendido, nudo viejo que
se deshilacha, chispas y sonrojo en los cruces, brillo de seda, golpe por el tejido, anillo de diamante, corona
(7 → 16 px) y halo del eco. En reposo el activo queda **eclipsado**. Monitor sin foco: 1 px al 60 %, corona 6 %, siempre
breve. Tope de la rueda = las dos puntas cabecean. Sustituye al filo que se deslizaba, al destello y al cabeceo.
- Va en **su propia ventanita** (capa Top, namespace `tsuka-hilo`, 56 × ~350 px desde `g.cord0`, máscara vacía: el mouse
  pasa a los rombos de abajo). Tres lienzos: `bajo` (halo, sonrojo; aditivo), `medio` (luna, hilo, chispas, nudo) y
  `sobre` (borde de la luna, seda, golpe, anillo; aditivo). Los kanji van entre `medio` y `sobre`. Lo aditivo es
  `aditivo.frag` (color con alfa 0 en premultiplicado = se suma).
- Solo corre durante el cambio (~1.35 s): FrameAnimation con física a pasos de 2 ms; repinta hasta 120/s los primeros
  300 ms, 60/s hasta 650 ms y 24/s en la cola. En reposo: nada.
- Gotcha: el Canvas de Qt NO limpia `setLineDash` con `reset()` ni `restore()` (el nudo deshilachado dejaba el hilo
  invisible). Se limpia a mano.

**La hoja con elemento** (`Hoja.qml`, `hoja.frag`/`hoja.vert` → `.qsb`, `elementos.js`): ASUS/STREAM = 水 agua,
LG = 火 fuego (luz del acero, ronda 6), XENEON = 風 viento. Acero y elemento son UN material: `hoja.frag` es el `FRAG`
del prototipo línea por línea; cada pixel real promedia N×N muestras (4×4 a escala 1, 3×3 en el XENEON a 1.6) como el
navegador al reducir el lienzo. La forma del elemento → campo de distancias (`elementos.js`, port de `campo()`),
calculado UNA vez por elemento y largo de hoja (~0.3 s) y guardado en `~/.cache/caelestia/tsuka-sdf-v1-<el>-<largo>.bmp64`
(BMP en base64; el Canvas de Qt guarda a devicePixelRatio, por eso no se usa `save()`).
- Va en **su propia ventanita** (capa Top, namespace `tsuka-hoja`, 56 × (largo − 5) px pegada abajo, empieza bajo el
  habaki, máscara vacía). Pinta tinta, material, pavesas, filo y la VISTA de las marcas (`MarcaVista`); el mouse
  (jalar, red/BT/bandeja) sigue en la ventana de siempre. Debe ir encima: el borde de Caelestia oscurecía la capa Bottom.
- Viva en reposo (la luz se mueve dentro del metal) a `hojaFps` (12 por omisión). Se congela en modo trabajo (gema
  trabajo), tras 3 min sin actividad (IdleMonitor, respeta inhibidores; cubre bloqueo y pantallas apagadas), con la
  barra retirada y en pantalla completa (ahí Tsuka ni está cargada).
- Empuñar: baja 3 px y la franja de luz recorre la hoja (700 ms, 0.95). Jalar: la carga c = jalón/18 enciende el
  material (τ 70 ms), la hoja sigue al cursor; soltar: regresa con muelle ω 30 ζ .55. Fuego: filo al rojo y 5 pavesas.
- Tajo (`El.tajo`, 900 ms): las dos líneas de siempre cruzan la pantalla; la estela (cinta y gotas / lenguas y pavesas
  / hilos de aire y hojas) vive en los primeros 260 px junto a la hoja, con la densidad del prototipo. El lienzo es una
  franja de 260 px girada a lo largo del corte. Probarlo sin abrir las lunas: `qs -c caelestia ipc call tsuka tajo`.
- Respiro del minuto (opcional, apagado): `"respiroMinuto": true`.

**Ajustes en `~/.config/caelestia/tsuka.json`** (en vivo, sin reiniciar):
| Ajuste | Qué hace |
|---|---|
| `"hiloRojo": false` | vuelve el filo de antes (marco que se desliza + destello) |
| `"hojaElemento": false` | vuelve la hoja SVG de antes (sin elemento, sin ventanita, sin tajo nuevo) |
| `"hojaViva": false` | hoja con elemento pero quieta en reposo (solo se mueve al tocarla): reposo ≈ 0 % |
| `"hojaFps": 12` | cuadros/s de la hoja viva en reposo (30 = más fluida, ~2.5× el costo) |
| `"elemento": {"DP-1": "fuego", "DP-2": "agua", "DP-3": "viento"}` | elemento por monitor (`agua|fuego|viento|ninguno`); sin la clave: DP-1 fuego y el resto por el tono de la tela (190–270° agua, 335–70° fuego, 70–190° viento) |
| `"respiroMinuto": true` | el temple respira al cambiar el minuto (monitor con foco) |

**Costo (medido en el banco: Hyprland anidado, 3 salidas + la ventana anidada, CPU del proceso qs leída de /proc; `nvidia-smi pmon` infla un poco):**
| Momento | CPU |
|---|---|
| Reposo con la hoja quieta (`hojaViva: false`) | ≈ 0.05 % (igual que antes) |
| Hoja viva a 30 cuadros/s | ≈ 15 % (≈ 3.7 % por ventana; el banco tiene 4) |
| Hoja viva a 12 (por omisión) | ≈ 4.8 % (≈ 1.2 % por monitor) |
| 10 cambios de escritorio en 15 s, filo de antes | 4.4 % |
| 10 cambios en 15 s, hilo rojo | ≈ 17 % (≈ 0.2 núcleo-segundos por cambio, ~1.3 s) |
El costo de cada cuadro es casi fijo (~1.3–2 ms entre el hilo de render de Qt y el driver de NVIDIA) aunque la
ventana sea chica: lo que cuenta es CUÁNTOS cuadros. GPU: < 1 % de SM.

**Revertir:** solo apagar → los ajustes de arriba. Código: `git -C ~/.config/quickshell revert 281246d 9a3911a a2e553d`
(o `git -C ~/.config/quickshell checkout acca4f1 -- caelestia`) y reiniciar el shell.

## Material v3 de la Tsuka (11-15 noche; propuesta v3 de Fable, mejoras 1-7 aprobadas)
Fuente: `/mnt/Compartido/Nero/diseno-fable/tsuka-saya-v3/` (`CAMBIOS.md`, `tsuka-saya-v3.html` en modo "Ahora",
commit 2fe5f8a). No cambian el hilo rojo, la hoja con elemento, los colores sacados del fondo (`Mat.mango`), la tela
hilo por hilo, las varillas ni las medidas. Las mejoras 8-9 (Saya) van aparte.

| # | Qué cambió | Dónde | Revertir |
|---|---|---|---|
| base | `metal.js` (ojo y gemas en Canvas) y `Pieza.qml` (sombreador que corre una vez, cacheado en capa) | — | solo junto con todas |
| 1 | herrajes de metal: pomo, dōgane (con cartela lisa hundida) y fuchi; canto pulido, surco, nanako; más oscuros que la tela, sin líneas claras | `herraje.frag`, Tsuka.qml | `git revert 1967cbd` |
| 2 | ojo vivo: cuenca, iris con fibras y anillo, luz por abajo, pupila, brillo, sombra y párpado de metal (color del marco); resplandor aditivo sobre el pomo; sigue al cursor | `Ojo.qml`, `metal.js` | `git revert bd30e3a` |
| 3 | piel de raya: nódulos nacarados en cada rombo (sombreador DEBAJO de la tela, que deja los rombos transparentes); velo de hueso 6/10 % en vez de la textura SVG | `piel.frag`, `material.js` (`pintaTela(..., true)`), Tsuka.qml | `git revert 1ec9c9c` |
| 4 | gemas talladas: engaste oscuro, 8 facetas y mesa; encendida con luz propia aditiva; apagada piedra de la tela; SIN destello en cruz | `Gema.qml`, `metal.js` | `git revert 588c675` |
| 5 | NERO, app, título y hora tallados (hueco oscuro arriba-izq., canto del marco abajo-der.; copias del Text con z −1) | Tsuka.qml | `git revert 69425e3` |
| 6 | tsuba de hueso con veta, cordoncillo y sombra (72 x 20); habaki limado neko-gaki | `habaki.frag`, `tsuba.frag`, Tsuka.qml | `git revert 2706b1a` |
| 7 | sombra de 14 px sobre el escritorio en lugar de la raya de 1 px (hasta donde empieza la hoja) | Tsuka.qml | `git revert 90ded98` |

Cada commit se revierte solo (probado con `git revert --no-commit` uno por uno). Todo: `git revert 90ded98 … c402d44` o
`git checkout b36e5c7 -- caelestia/modules/tsuka`. Después, reiniciar el shell.
Shaders: `/usr/lib/qt6/bin/qsb --glsl "100 es,120,150,300 es,330" --hlsl 50 --msl 12 -o X.frag.qsb X.frag`.

**Rendimiento.** Lo pixel por pixel del prototipo (herrajes, piel, habaki, tsuba) NO va en JS: escribir
`CanvasImageData` desde el JS de Qt provoca tormentas del recolector de basura (medido: ~10 s de CPU al arrancar y a
veces el shell se queda al 100 % para siempre). Va en sombreadores que corren una vez y quedan en una capa a 2x
(`Pieza.qml`, `layer.enabled`); solo vuelven a correr si cambian colores o geometría. Ojo y gemas: Canvas que se
repintan solo al cambiar (el ojo, mientras se mueve; las gemas, al cambiar de estado). Reposo: sin timers nuevos.
Medido en el banco (3 pantallas + la de la ventana, hojaViva false, dos corridas cada una): reposo antes 0.25 / 0.25 %,
después 0.18 / 0.27 % de un núcleo (igual, dentro del ruido); CPU de los primeros 30 s de arranque antes 593 / 625 ticks,
después 592 / 551 (igual). La tela sigue en ~50 ms por monitor (15 en la XENEON); los sombreadores no cuestan CPU medible.
Los `Mat.kashira/dogane/fuchi/habaki/tsuba/ventanaSame` de `material.js` quedan sin uso (se dejan para revertir fácil).

**Diferencias con el prototipo:** el ruido/hash de la GPU no es el mismo número a número que el del prototipo (mismo
carácter, otro sorteo de granitos y nódulos); el hueco entre nódulos conserva la piel teñida con la tela (ajuste 11-15)
en vez del gris neutro; la gema "te llama" y el cursor encima conservan su canto en hueso; el glifo de la gema va a 9 px
(prototipo ≈ 5 px, se perdía); en la XENEON compacta el pomo no lleva franja de nanako (no hay NERO).

## Saya v3: laca honda y nashiji (11-15, mejoras 8 y 9 de tsuka-saya-v3, aprobadas)
Fuente: `/mnt/Compartido/Nero/diseno-fable/tsuka-saya-v3/tsuka-saya-v3.html`, modo "Ahora" (`laca()`, `pintaVaina()`,
`pintaBloque()`). Capturas del banco: `.../tsuka-saya-v3/capturas-linux/banco-saya-*.png`.
- **8 · vaina** (`modules/saya/vaina.frag`): laca honda con el reflejo largo del eco que se corta a tramos, polvo de hueso
  bajo el barniz, boca de cuerno con veta, contera teñida con la tela, pasador de metal (canto pulido) y el hueco de la
  incrustación. En QML (cambian con el estado): vueltas del cordón con volumen + hilos (`Laca.hilos`), franjas de las
  luces con degradado y resplandor de la luz 1, la boca que llama (sigue en hueso alto, 14 px).
- **9 · bloque** (`modules/saya/nashiji.frag`): nashiji (escamas de hueso y metal dorado a tres profundidades, dos reflejos
  diagonales, canto de luz del marco), surcos tallados entre secciones (el de Luz/Avisos bajo CANDADO · CLÓSET en el
  monitor alto) y el sello 鞘 en el tono del marco. La lengüeta del OSD usa la misma franja del nashiji.
  Las tres barras del OSD no cambian.
- Colores: `Mat.mango` del monitor (tela oscura / marco clarito, igual que el mango) + eco. Cambian en vivo con el fondo.
- Costo: es un sombreador (`ShaderEffect` con `layer.enabled`): corre una vez en la GPU y queda como textura; solo se
  vuelve a pintar si cambia un uniforme (fondo, alto). 0 ms de CPU al arrancar. Reposo medido en el banco (hojaViva
  false, 180 s, sin contar una ráfaga ajena de ~1 s por minuto que ya estaba): guardada 0.10 → 0.11 %, desenvainada
  0.16 → 0.09 % (ruido).
- Gotcha: un `Canvas` con `createImageData`/`putImageData` grandes (el `sombrea` del prototipo) deja el hilo principal
  de quickshell al 100 % para siempre después de pintar. Por eso no se usa aquí.
- `Mat.vaina()` y `Mat.bloque()` (SVG de antes) se quedan en `material.js` sin uso; los vuelve a usar el revert.
- Revertir: `git -C ~/.config/quickshell revert <commit mejora 9>` (bloque) y/o `<commit mejora 8>` (vaina), en ese
  orden si son las dos, y reiniciar el shell. En la rama v3-saya: 9 = dd4de3b, 8 = 9e0da03 (los hashes cambian si se
  pasan a otra rama con cherry-pick: buscarlos con `git log --oneline --grep "Saya v3 mejora"`).

## Archivos
| Archivo | Qué |
|---|---|
| `modules/tsuka/Tsuka.qml` | barra izquierda (misma interfaz que `Bar` + `alcance/alcanceY/alcanceAlto`) |
| `modules/tsuka/material.js` | medidas (`geo`), MATERIAL como SVG (port de `material()/tsuba()/vaina()` del prototipo), `pintaTela`/`mango`/`dogane` (mango final) |
| `modules/tsuka/Ojo.qml`, `Gema.qml`, `Ico.qml` | ojo de cuatro números, gema tallada, íconos propios |
| `modules/tsuka/Hilo.qml`, `hilo.js`, `aditivo.frag(.qsb)` | el hilo rojo (física y lienzos) |
| `modules/tsuka/Hoja.qml`, `hoja.frag/.vert(.qsb)`, `elementos.js` | la hoja con elemento, el campo de distancias, pavesas y tajo |
| `modules/saya/Saya.qml` | barra derecha (vaina, bloque, secciones, barras Amanecer/Reiatsu/Eclipse, lengua, detalle, OSD) |
| `services/Espada.qml` | paleta, movimiento, íconos, regla del color, "solo habla una" |
| `services/TsukaConf.qml` | interruptor, Nero (estado, avance, mensajes), gemas, IPC `tsuka` y `saya` |
| `services/Portada.qml` | color de la carátula (ColorQuantizer, una vez por canción) |
| `modules/bar/BarWrapper.qml` | carga Tsuka o `Bar`; con Tsuka el STREAM también lleva barra; retirada de 0.5 s en pantalla completa |
| `modules/drawers/{ContentWindow,Regions,Exclusions}.qml` | Saya en la ventana de cajones; máscara de entrada; zona reservada derecha 8 px |
| `modules/osd/Wrapper.qml` | se retira con `saya` activa |
| `modules/notifications/Wrapper.qml` | con `saya`: avisos emergentes bajan a y = 76 (58 XENEON) y 16 px del borde |
| `modules/session/Content.qml`, `components/ScreenState.qml` | SUSPENDER/APAGAR de la placa abren las lunas con esa luna enfocada (solo el foco) |

## Rendimiento
El material (cordón, kashira, fuchi, hoja, habaki, tsuba, laca, bloque) es SVG pintado UNA vez como textura y solo se
regenera cuando cambia el eco (otro fondo) o el alto. Lo vivo son Shapes/Text que cambian con eventos. Sin Timer en
bucle: el cordón de la música usa un Timer de un disparo al siguiente 20 % (1/23 con la vaina abierta).
Medido en el banco (Hyprland anidado, 5 pantallas, mismo método): reposo ≈ 0.2 % (vieja Tsuka 0.15 %).
Barras (banco, 10 s por medida): desenvainada en reposo 0.01 núcleo-s, envainada 0; con el cursor encima de Reiatsu
despierta (llama, vidrio) ~2 s y se vuelve a dormir sola.

## Color (eco por monitor)
El eco NO es un hex fijo: sale de la paleta que wallmux genera para cada monitor
(`~/.local/state/caelestia/schemes/<monitor>.json`, vía `Colours.of(ventana)`, que vigila el archivo):
`m3primary` (ASUS/XENEON/STREAM) y `m3tertiaryFixed` (LG). Cambia en vivo al cambiar el fondo; los bitmaps del material
se regeneran solo en ese momento. Si el eco cae en rojo (345°–15°) se dibuja en hueso (`Espada.ecoSeguro`).
Probado: verde → cordón/iris/temple verdes; rojo → hueso.

## Interruptor (en vivo): `~/.config/caelestia/tsuka.json`
```json
{ "activa": true, "saya": true, "lenguasNero": true, "movimiento": true,
  "gemasArriba": ["casa", "musica", "cine", "juego"],
  "gemasAbajo": ["zangetsu", "stream", "apagado", "respaldo", "temp"] }
```
- **Volver a la barra vieja de Caelestia, un comando:** `echo '{"activa": false}' > ~/.config/caelestia/tsuka.json`
  (apaga Tsuka y Saya; marco de 6 px y OSD de siempre).
- Solo quitar Saya: `"saya": false`. Sin animaciones: `"movimiento": false`. Clic derecho al ojo alterna `lenguasNero`.
- Deshacer todo el código: `git -C ~/.config/quickshell checkout ea7f219 -- caelestia` (la Tsuka de prueba) y reiniciar.
- Deshacer solo las barras en la vaina (volver al bloque de 76 con barritas planas): `git -C ~/.config/quickshell revert <commit "Saya: barras de Fable">` y reiniciar.

## Nero: `~/.local/bin/nero-estado`
`duerme | vigila | escucha | trabaja "texto" [avance] | avance N | escribio "mensaje" | leido`.
Escribe `~/.local/state/nero/estado` y `mensajes.jsonl` (últimos 20). `escribio` ya no caduca; se lee pasando el
cursor 0.7 s por la sección Nero de la vaina, clic en la lengua, `Super+Shift+N`, o el bot (`nero-estado leido`).
`trabaja` caduca a las 3 h. Desde Zangetsu: `ssh pc nero-pc 'nero-estado escribio "…"'`.

## Gemas: `~/.local/state/nero/gemas/<nombre>` = `0|1|2` + línea de texto (`~/.local/bin/nero-gema`)
| Gema | La escribe | Clic |
|---|---|---|
| trabajo | modo-trabajo / modo-casa (+ nero-vigias) | mantener 480 ms: `modo-trabajo on` / `modo-casa` |
| musica | modo-musica (+ nero-vigias) | `modo-musica` (= Super+F2); color = portada |
| cine | nero-vigias (estado del Apple TV en Zangetsu) | mantener: alterna `modo-cine` en Zangetsu por ssh |
| juego | govee-juego-tecla, govee-juego-vigilante (+ GameMode de Caelestia) | `govee-juego-tecla` (= Super+F3) |
| zangetsu | nero-vigias (ping ZANGETSU_CABLE_IP / tailscale) | deja abierta la placa de vigías |
| stream | nero-vigias (sesiones del codificador NVENC), modo-trabajo al cerrar Moonlight | nada |
| apagado | apagado-auto (fase de aviso = 2) | encendida: `apagado-auto cancelar` |
| respaldo | nero-vigias (repo restic que llena Zangetsu) | nada |
| temp | nero-vigias (máx. CPU/GPU, umbrales 70/85 °C) | nada |
`nero-vigias.timer` corre cada 30 s (único sondeo; la barra no sondea nada).

## IPC y atajos
`qs -c caelestia ipc call tsuka estado|empunar <zona>|soltar` · `saya desenvainar|envainar|nero|osd volumen|luz|brillo`.
Super+Shift+N = `saya nero`; Super+Alt+N = `tsuka empunar guarda` (Super+N ya era el panel lateral; no hay tecla Ñ en el
teclado US altgr-intl).

## Notas
- Reinicio del shell SOLO desbloqueado: `qs -c caelestia kill; sleep 2; systemd-run --user --collect qs -c caelestia -n`.
  `~/.local/bin/tsuka-aplicar` lo hace solo al desbloquear y verifica; si no carga, regresa a ea7f219.
- `caelestia-permon/update.sh` borra la copia al actualizarse Caelestia: `git -C ~/.config/quickshell checkout -- caelestia/`.
- Banco de pruebas sin tocar la sesión: Hyprland anidado (`Hyprland -c` con salidas `hyprctl output create headless DP-1…`)
  + una copia del shell con `qs -p`. Allí `hl.dsp.cursor.move` solo entrega movimiento al cambiar de superficie.
