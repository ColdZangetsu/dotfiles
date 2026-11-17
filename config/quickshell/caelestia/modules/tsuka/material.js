.pragma library

// 11-15 Tsuka + Saya (diseño final de Fable): medidas y MATERIAL estático.
// Port directo de geo(), material(), tsuba() y vaina() de
// /mnt/Compartido/Nero/diseno-fable/tsuka-saya-final/tsuka-saya-final.html (mismas coordenadas).
// El material se entrega como SVG (data:) y lo pinta un Image UNA vez (textura cacheada); solo se
// regenera si cambia el eco del monitor (otro fondo) o el alto. Qt SVG no soporta clipPath: cada pieza
// es su propio SVG y el viewBox hace de recorte. Nada aquí corre por cuadro.
// 11-15 mango final: la tela (pintaTela) va en un Canvas pintado una vez; colores en mango().

var G_ARRIBA = ["casa", "musica", "cine", "juego"];
var G_ABAJO = ["zangetsu", "stream", "apagado", "respaldo", "temp"];

function azar(sem) {
    var s = sem;
    return function () {
        s = (s * 16807) % 2147483647;
        return s / 2147483647;
    };
}

// ---------- medidas (TSUKA-DISENO §2.1, SAYA-DISENO §2) ----------
function geo(H, compacta, nWs, arriba, abajo) {
    var c = !!compacta, g = { H: H, compacta: c };
    g.pomoH = c ? 52 : 96; g.ojoC = c ? 22 : 36; g.cord0 = c ? 56 : 100;
    g.bladeH = c ? 48 : 64; g.blade0 = H - g.bladeH;
    g.hab0 = g.blade0 - 8 - 80; g.mar0 = g.hab0 + 24; g.jala0 = g.blade0 + 8;
    g.guard0 = g.hab0 - 6 - 12; g.clock0 = g.guard0 - 72; g.fuchi0 = g.clock0 - 8; g.gripEnd = g.fuchi0 - 6;
    g.N = Math.max(0, Math.floor((g.gripEnd - g.cord0) / 48)); g.cordFin = g.cord0 + 48 * g.N;
    g.nWs = nWs; g.iWs = c ? 0 : 1; g.iEsp = g.iWs + nWs; g.libre = g.iEsp + 1; g.headEnd = g.cord0 + 48 * g.libre;
    g.n = Math.max(0, g.N - g.libre);
    g.men = g.n >= 6 ? Math.min(8, Math.max(4, Math.floor(g.n / 2))) : 0;
    g.iMen = g.libre + Math.floor((g.n - g.men) / 2);
    g.menuki0 = g.cord0 + 48 * g.iMen; g.menukiH = 48 * g.men;
    g.gemas = []; g.gA = [g.libre, g.iMen]; g.gB = [g.iMen + g.men, g.N];
    if (g.men) {
        (arriba || G_ARRIBA).slice(0, Math.max(0, g.gA[1] - g.gA[0])).forEach(function (id, j) { g.gemas.push({ id: id, fila: g.gA[0] + j, zona: "modos", y: g.cord0 + 48 * (g.gA[0] + j) }); });
        (abajo || G_ABAJO).slice(0, Math.max(0, g.gB[1] - g.gB[0])).forEach(function (id, j) { g.gemas.push({ id: id, fila: g.gB[0] + j, zona: "vigias", y: g.cord0 + 48 * (g.gB[0] + j) }); });
    }
    g.nArriba = g.gemas.filter(function (x) { return x.zona === "modos"; }).length;
    g.nAbajo = g.gemas.length - g.nArriba;
    // 11-15 (barras de Fable en la vaina): SAYA-DISENO.md §2; bs = escala de Amanecer/Reiatsu/Eclipse (36x160 / 30x134)
    g.s = c ? { nero: [0, 44], suena: [50, 56], luz: [112, 178], avisos: [296, 40], fin: 346, largo: H - 8, punta: 20, bs: 0.42 }
            : { nero: [4, 64], suena: [76, 70], luz: [154, 206], avisos: [368, 48], fin: 462, largo: H - 24, punta: 40, bs: 0.5 };
    return g;
}

// ---------- color ----------
function hex2(n) { var s = Math.round(Math.max(0, Math.min(255, n))).toString(16); return s.length < 2 ? "0" + s : s; }
function rgb(c) {
    if (typeof c !== "string") c = String(c);
    c = c.replace("#", "");
    if (c.length === 8) c = c.slice(2); // #aarrggbb de Qt
    return [parseInt(c.slice(0, 2), 16), parseInt(c.slice(2, 4), 16), parseInt(c.slice(4, 6), 16)];
}
// p de a sobre b (color-mix in srgb, a p%, b)
function mezcla(a, b, p) {
    var x = rgb(a), y = rgb(b);
    return "#" + hex2(x[0] * p + y[0] * (1 - p)) + hex2(x[1] * p + y[1] * (1 - p)) + hex2(x[2] * p + y[2] * (1 - p));
}

// ---------- texturas ----------
function patSame(id) {
    var h = '<pattern id="' + (id || "same") + '" width="30" height="30" patternUnits="userSpaceOnUse">', r = azar(7);
    for (var i = 0; i < 46; i++) h += '<circle cx="' + (r() * 30).toFixed(1) + '" cy="' + (r() * 30).toFixed(1) + '" r="' + (.7 + r() * .8).toFixed(2) + '" fill="#efe6d8" fill-opacity="' + (.1 + r() * .16).toFixed(2) + '"/>';
    return h + '</pattern>';
}
var PAT_TELA = '<pattern id="tela" width="3" height="3" patternUnits="userSpaceOnUse"><rect width="1.5" height="1.5" fill="#fff" fill-opacity=".04"/></pattern>';
var PAT_LIMA = '<pattern id="lima" width="5" height="5" patternUnits="userSpaceOnUse" patternTransform="rotate(-32)"><rect width="5" height="1" fill="#efe6d8" fill-opacity=".07"/></pattern>';
// 11-15 usuario: los herrajes (pomo, manguito, collar) toman un poco del color de la tela de su monitor
// t = "tela,marco": los tonos hondos se tiñen con la tela y los claros con el marco (claro), para que el metal conserve volumen
function tm(c, t) {
    if (!t) return c;
    var p = String(t).split(","), y = rgb(c), l = (y[0] + y[1] + y[2]) / 765;
    if (l > .11 && p[1]) return mezcla(p[1], mezcla(p[0], c, .28), .12);   // brillo apenas insinuado (más oscuro que 8d22b4c)
    return mezcla(p[0], c, .30);
}
// 11-15 usuario: pomo, manguito y collar MÁS OSCUROS que la tela de su monitor
function osc(t, k) { var c = rgb(t ? String(t).split(",")[0] : "#1d2028"); return "rgb(" + Math.round(c[0] * k) + "," + Math.round(c[1] * k) + "," + Math.round(c[2] * k) + ")"; }
function grMetal(t) { return '<linearGradient id="metal" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="' + osc(t, .58) + '"/><stop offset=".5" stop-color="' + osc(t, .40) + '"/><stop offset="1" stop-color="' + osc(t, .27) + '"/></linearGradient>'; }

function svg(vx, vy, w, h, cuerpo) {
    return '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="' + w + '" height="' + h + '" viewBox="' + vx + ' ' + vy + ' ' + w + ' ' + h + '">' + cuerpo + '</svg>';
}
function url(s) { return "data:image/svg+xml;utf8," + encodeURIComponent(s); }

// ---------- kashira (pomo) ----------
function kashira(g, t) {
    var c = g.compacta, pb = g.pomoH - 6, rr = c ? 15 : 17, t0 = c ? 3 : 5, h = '<defs>' + PAT_LIMA + grMetal(t) + '</defs>';
    var cap = 'M4 ' + pb + ' L4 ' + (t0 + rr) + ' Q4 ' + t0 + ' ' + (4 + rr) + ' ' + t0 + ' L' + (52 - rr) + ' ' + t0 + ' Q52 ' + t0 + ' 52 ' + (t0 + rr) + ' L52 ' + pb + ' Z';
    h += '<path d="' + cap + '" fill="url(#metal)"/><path d="' + cap + '" fill="url(#lima)" opacity=".5"/>';
    h += '<path d="M6.5 ' + (t0 + rr + 2) + ' Q6.5 ' + (t0 + 2.5) + ' ' + (5 + rr) + ' ' + (t0 + 2.5) + ' L' + (51 - rr) + ' ' + (t0 + 2.5) + ' Q49.5 ' + (t0 + 2.5) + ' 49.5 ' + (t0 + rr + 2) + '" fill="none" stroke="#efe6d8" stroke-opacity=".08"/>';
    h += '<rect x="4" y="' + (pb - 8) + '" width="48" height="8" fill="' + osc(t, .22) + '"/><path d="M4.5 ' + (pb - 7.5) + 'H51.5" stroke="#000" stroke-opacity=".35" stroke-width=".8"/>';
    h += '<circle cx="9.5" cy="' + (pb - 4) + '" r="1.4" fill="' + tm('#8a8f9c', t) + '" fill-opacity=".7"/><circle cx="46.5" cy="' + (pb - 4) + '" r="1.4" fill="' + tm('#8a8f9c', t) + '" fill-opacity=".7"/>';
    return url(svg(0, 0, 56, g.pomoH, h));
}

// ---------- color del mango: AJUSTE DEL USUARIO 11-15 ----------
// "La tela siempre más oscura que el marco: el marco un color clarito del fondo y la tela un color oscuro del fondo".
// Las dos salen de la paleta Material del monitor (la misma familia que el eco: primary, o tertiary en el LG):
//   marco (varillas) = <fam>FixedDim (tono ~80) con saturación ≤ 0.20 y luz 0.68–0.76
//   tela  (seda)     = on<Fam>FixedVariant (tono ~30) con saturación 0.38–0.56 y luz 0.18–0.26
// Contraste garantizado: razón WCAG marco/tela ≥ 4.5 (si no, baja la luz de la tela hasta 0.12 y luego sube la del marco).
// Rojo (335°–25°): la tela se va a morado (285°) y el marco a hueso (37°): el rojo solo es el filo del activo.
function rgb2hsl(c) {
    var r = c[0] / 255, g = c[1] / 255, b = c[2] / 255, mx = Math.max(r, g, b), mn = Math.min(r, g, b), d = mx - mn, h = 0, l = (mx + mn) / 2;
    if (d) h = mx === r ? ((g - b) / d) % 6 : mx === g ? (b - r) / d + 2 : (r - g) / d + 4;
    return [(h * 60 + 360) % 360, d ? d / (1 - Math.abs(2 * l - 1)) : 0, l];
}
function hsl2rgb(h, s, l) {
    var c = (1 - Math.abs(2 * l - 1)) * s, x = c * (1 - Math.abs((h / 60) % 2 - 1)), m = l - c / 2, r = 0, g = 0, b = 0;
    if (h < 60) { r = c; g = x; } else if (h < 120) { r = x; g = c; } else if (h < 180) { g = c; b = x; } else if (h < 240) { g = x; b = c; } else if (h < 300) { r = x; b = c; } else { r = c; b = x; }
    return [(r + m) * 255, (g + m) * 255, (b + m) * 255];
}
function lumRel(c) {
    var f = function (v) { v /= 255; return v <= .03928 ? v / 12.92 : Math.pow((v + .055) / 1.055, 2.4); };
    return .2126 * f(c[0]) + .7152 * f(c[1]) + .0722 * f(c[2]);
}
function hexDe(c) { return "#" + hex2(c[0]) + hex2(c[1]) + hex2(c[2]); }
function esRojo(hsl) { return hsl[1] > .12 && (hsl[0] >= 335 || hsl[0] <= 25); }
function mango(claroHex, oscuroHex) {
    var cl = rgb2hsl(rgb(claroHex)), os = rgb2hsl(rgb(oscuroHex));
    var mH = cl[0], mS = Math.max(.06, Math.min(.2, cl[1])), mL = Math.max(.68, Math.min(.76, cl[2]));
    if (esRojo(cl)) { mH = 37; mS = .2; }
    var tH = esRojo(os) ? 285 : os[0], tS = Math.max(.38, Math.min(.56, os[1])), tL = Math.max(.18, Math.min(.26, os[2]));
    var razon = function () { return (lumRel(hsl2rgb(mH, mS, mL)) + .05) / (lumRel(hsl2rgb(tH, tS, tL)) + .05); };
    while (razon() < 4.5 && tL > .12) tL -= .005;
    while (razon() < 4.5 && mL < .86) mL += .005;
    var m = hsl2rgb(mH, mS, mL);
    return {
        marco: m, tela: hsl2rgb(tH, tS, tL), razon: razon(),
        // tela: hondo / base / claro con las mismas proporciones que hsl(T,56,9) / (T,52,29) / (T,44,62) de la especificación
        base: hsl2rgb(tH, tS, tL), hondo: hsl2rgb(tH, Math.min(1, tS * 1.08), tL * .31), claro: hsl2rgb(tH, tS * .85, Math.min(.7, tL + .33)),
        marcoHex: hexDe(m), telaHex: hexDe(hsl2rgb(tH, tS, tL))
    };
}
// la rampa del volumen cilíndrico de la varilla: la misma de la gris instalada (#0c0d11 … #7d838f … #090a0d),
// expresada como fracción del pico y aplicada al color del marco
var RAMPA = [[0, .1], [.1, .28], [.3, .62], [.43, 1], [.5, .85], [.66, .49], [.86, .24], [1, .07]];
function escala(c, k) { return "rgb(" + Math.round(c[0] * k) + "," + Math.round(c[1] * k) + "," + Math.round(c[2] * k) + ")"; }

// ---------- la tela del mango (hineri-maki): TSUKA-DISENO.md §3.3, port de pintaTela() del prototipo ----------
// ctx = contexto 2D del Canvas (ya escalado); L = alto del lienzo (gripEnd - cord0); C = mango(); R = escala de pintado
// (solo multiplica desenfoques/desplazamientos de sombra, que en Canvas 2D no siguen la transformación).
// Semilla fija: sale idéntica en cada arranque. Se pinta UNA vez por monitor (y de nuevo solo si cambia fondo o alto).
// v3 mejora 3 (pielAparte): la piel de raya la pinta un sombreador DEBAJO de la tela (piel.frag); aquí los rombos de
// las filas que se ven quedan transparentes. Sin ella, los puntitos de antes.
function pielFondo(C) { var h = C.hondo; return [h[0] * .55 + 28 * .45, h[1] * .55 + 27 * .45, h[2] * .55 + 24 * .45]; }
function pintaTela(ctx, g, C, R, pielAparte) {
    var L = g.gripEnd - g.cord0, rnd = azar(20261115), k, i;
    var base = C.base, claro = C.claro, hondo = C.hondo;
    function col(f) {
        var a = f <= 1 ? hondo : base, b = f <= 1 ? base : claro, t = f <= 1 ? Math.max(0, (f - .3) / .7) : Math.min(1, (f - 1) / .9);
        return 'rgb(' + Math.round(a[0] + (b[0] - a[0]) * t) + ',' + Math.round(a[1] + (b[1] - a[1]) * t) + ',' + Math.round(a[2] + (b[2] - a[2]) * t) + ')';
    }
    function lerp(p, q, t) { return [p[0] + (q[0] - p[0]) * t, p[1] + (q[1] - p[1]) * t]; }
    function ruta(pts, Y) { ctx.beginPath(); for (var j = 0; j < pts.length; j++) { if (j) ctx.lineTo(pts[j][0], pts[j][1] + Y); else ctx.moveTo(pts[j][0], pts[j][1] + Y); } ctx.closePath(); }
    function linea(p, q, Y, estilo, ancho) { ctx.beginPath(); ctx.moveTo(p[0], p[1] + Y); ctx.lineTo(q[0], q[1] + Y); ctx.strokeStyle = estilo; ctx.lineWidth = ancho; ctx.stroke(); }
    function perfil(u) { return u < .1 ? .58 + u / .1 * .6 : u < .3 ? 1.18 - (u - .1) / .2 * .16 : u < .78 ? 1.02 - (u - .3) / .48 * .14 : .88 - (u - .78) / .22 * .34; }

    /* piel de raya (solo se verá dentro de los rombos) */
    ctx.fillStyle = 'rgb(' + Math.round(hondo[0] * .55 + 28 * .45) + ',' + Math.round(hondo[1] * .55 + 27 * .45) + ',' + Math.round(hondo[2] * .55 + 24 * .45) + ')'; ctx.fillRect(0, 0, 56, L); /* 11-15: piel teñida con la tela */
    if (pielAparte) {
        for (i = 0; i < L * 2.4; i++) { rnd(); rnd(); rnd(); rnd(); }   /* misma semilla para el resto de la tela */
        ctx.save(); ctx.globalCompositeOperation = 'destination-out'; ctx.fillStyle = '#000';
        for (k = 0; k < g.N; k++) if (!(g.men && k >= g.iMen && k < g.iMen + g.men)) {
            ctx.beginPath(); ctx.moveTo(28, 48 * k + 5.5); ctx.lineTo(49.5, 48 * k + 24); ctx.lineTo(28, 48 * k + 42.5); ctx.lineTo(6.5, 48 * k + 24); ctx.closePath(); ctx.fill();
        }
        ctx.restore();
    } else
    for (i = 0; i < L * 2.4; i++) { ctx.beginPath(); ctx.arc(rnd() * 56, rnd() * L, .6 + rnd() * .8, 0, 6.3); ctx.fillStyle = 'rgba(239,230,216,' + (.07 + rnd() * .15).toFixed(3) + ')'; ctx.fill(); }

    /* un tramo de cinta: de la cintura (w0–w1) al otro extremo (e0–e1), hilo por hilo */
    function tramo(w0, w1, e0, e1, Y, f, cintura) {
        var poly = [w0, e0, e1, w1], N = 18, j, u, a, b, c, d, t, gr;
        var dx = (e0[0] + e1[0] - w0[0] - w1[0]) / 2, dy = (e0[1] + e1[1] - w0[1] - w1[1]) / 2, largo = Math.sqrt(dx * dx + dy * dy);
        ctx.save(); ctx.shadowColor = 'rgba(0,0,0,.85)'; ctx.shadowBlur = 3 * R; ctx.shadowOffsetY = 1.3 * R; ctx.shadowOffsetX = .5 * R; ctx.fillStyle = col(.5 * f); ruta(poly, Y); ctx.fill(); ctx.restore();
        ctx.save(); ruta(poly, Y); ctx.clip();
        for (j = 0; j < N; j++) {
            u = (j + .5) / N;
            var fj = perfil(u) * f * (1 + (rnd() - .5) * .13) * (rnd() < .08 ? 1.14 : 1);
            a = lerp(w0, w1, j / N); b = lerp(e0, e1, j / N); c = lerp(e0, e1, (j + 1) / N); d = lerp(w0, w1, (j + 1) / N);
            ctx.fillStyle = ctx.strokeStyle = col(fj); ctx.lineWidth = .3; ruta([a, b, c, d], Y); ctx.fill(); ctx.stroke();
        }
        for (j = 1; j < N; j++) {
            a = lerp(w0, w1, j / N); b = lerp(e0, e1, j / N);
            linea(a, b, Y, 'rgba(0,0,0,' + (.2 + rnd() * .16).toFixed(3) + ')', .4);
            if (j % 2) linea([a[0], a[1] - .45], [b[0], b[1] - .45], Y, 'rgba(255,255,255,.05)', .3);
        }
        var dt = 1.5 / largo;
        for (j = 0; j < N; j++) for (t = dt * (j % 2 ? .5 : 1); t < 1; t += dt) {
            a = lerp(lerp(w0, w1, j / N), lerp(e0, e1, j / N), t); b = lerp(lerp(w0, w1, (j + 1) / N), lerp(e0, e1, (j + 1) / N), t);
            linea(a, b, Y, 'rgba(0,0,0,' + (.1 + rnd() * .12).toFixed(3) + ')', .45);
        }
        var m0 = lerp(w0, w1, .5), m1 = lerp(e0, e1, .5);
        gr = ctx.createLinearGradient(m0[0], m0[1] + Y, m1[0], m1[1] + Y);
        if (cintura) { gr.addColorStop(0, 'rgba(0,0,0,.34)'); gr.addColorStop(.5, 'rgba(255,255,255,.1)'); gr.addColorStop(1, 'rgba(0,0,0,.34)'); }
        else { gr.addColorStop(0, 'rgba(0,0,0,.5)'); gr.addColorStop(.14, 'rgba(0,0,0,.16)'); gr.addColorStop(.42, 'rgba(255,255,255,.07)'); gr.addColorStop(.75, 'rgba(0,0,0,.1)'); gr.addColorStop(1, 'rgba(0,0,0,.46)'); }
        ctx.fillStyle = gr; ruta(poly, Y); ctx.fill();
        if (!cintura) for (j = 0; j < 4; j++) {
            u = .12 + rnd() * .76; a = lerp(w0, w1, u); b = lerp(a, lerp(e0, e1, u + (rnd() - .5) * .08), .28 + rnd() * .3);
            gr = ctx.createLinearGradient(a[0], a[1] + Y, b[0], b[1] + Y); gr.addColorStop(0, 'rgba(0,0,0,.55)'); gr.addColorStop(1, 'rgba(0,0,0,0)');
            linea(a, b, Y, gr, .8); linea([a[0], a[1] - .7], [b[0], b[1] - .7], Y, 'rgba(255,255,255,.07)', .4);
        }
        a = lerp(w0, w1, .46); b = lerp(e0, e1, .46); if (!cintura) b = lerp(a, b, .5);
        gr = ctx.createLinearGradient(a[0], a[1] + Y, b[0], b[1] + Y); gr.addColorStop(0, 'rgba(255,255,255,' + (cintura ? .3 : .22) + ')'); gr.addColorStop(1, 'rgba(255,255,255,' + (cintura ? .3 : 0) + ')');
        linea(a, b, Y, gr, .7);
        gr = ctx.createLinearGradient(a[0], a[1] + Y, b[0], b[1] + Y); gr.addColorStop(0, 'rgba(0,0,0,' + (cintura ? .5 : .4) + ')'); gr.addColorStop(1, 'rgba(0,0,0,' + (cintura ? .5 : 0) + ')');
        linea([a[0], a[1] + .9], [b[0], b[1] + .9], Y, gr, .8);
        for (j = 0; j < 9; j++) {
            u = rnd(); t = .1 + rnd() * .8; a = lerp(lerp(w0, w1, u), lerp(e0, e1, u), t); b = lerp(lerp(w0, w1, u), lerp(e0, e1, u), Math.min(1, t + .05 + rnd() * .08));
            linea(a, [b[0] + (rnd() - .5) * .8, b[1] + (rnd() - .5) * .8], Y, 'rgba(255,255,255,' + (.06 + rnd() * .1).toFixed(3) + ')', .35);
        }
        ctx.restore();
        linea(w0, e0, Y, 'rgba(255,255,255,.2)', .6); linea([w0[0], w0[1] + .7], [e0[0], e0[1] + .7], Y, 'rgba(255,255,255,.08)', .8);
        linea(w1, e1, Y, 'rgba(0,0,0,.6)', .7);
    }
    var Cc = [28, -7], D = [36.27, 0], E = [28, 7], F = [19.73, 0];
    function salta(k) { return g.men && k > g.iMen && k < g.iMen + g.men; }
    for (k = 0; k <= g.N; k++) if (!salta(k)) { tramo(Cc, D, [56, -30.7], [56, 7], 48 * k, .8); tramo(F, E, [0, -7], [0, 30.7], 48 * k, .74); }
    for (k = 0; k <= g.N; k++) if (!salta(k)) { tramo(Cc, F, [0, -30.7], [0, -2.5], 48 * k, 1.04); tramo(D, E, [56, 2.5], [56, 30.7], 48 * k, .96); }
    for (k = 0; k <= g.N; k++) if (!salta(k)) { if (k % 2) tramo(Cc, D, F, E, 48 * k, .9, true); else tramo(Cc, F, D, E, 48 * k, 1.1, true); }

    /* marco de los rombos: las varillas satinadas cruzadas en X (geometría de la instalada), en el tono CLARO del fondo */
    var M = C.marco;
    function varilla(Y, esA) {
        var sg = esA ? 1 : -1, P4 = esA ? [[-2, -32.4], [58, 18.4], [58, 32.4], [-2, -18.4]] : [[58, -32.4], [-2, 18.4], [-2, 32.4], [58, -18.4]];
        var nx = -.646 * sg, ny = .763, gr, j;
        ctx.save(); ctx.shadowColor = 'rgba(0,0,0,.85)'; ctx.shadowBlur = 3.2 * R; ctx.shadowOffsetY = 1.6 * R; ctx.shadowOffsetX = .4 * R; ruta(P4, Y); ctx.fillStyle = escala(M, .17); ctx.fill(); ctx.restore();
        gr = ctx.createLinearGradient(28 - nx * 5.34, Y - ny * 5.34, 28 + nx * 5.34, Y + ny * 5.34);
        for (j = 0; j < RAMPA.length; j++) gr.addColorStop(RAMPA[j][0], escala(M, RAMPA[j][1]));
        ruta(P4, Y); ctx.fillStyle = gr; ctx.fill();
        ctx.save(); ruta(P4, Y); ctx.clip();
        for (j = 0; j < 9; j++) {
            var o = (-.8 + j * .2 + (rnd() - .5) * .08) * 5.34, a = [-2, (-2 - 28) * .8467 * sg], b = [58, (58 - 28) * .8467 * sg];
            if (!esA) { a = [58, -(58 - 28) * .8467]; b = [-2, (28 + 2) * .8467]; }
            linea([a[0] + nx * o, a[1] + ny * o], [b[0] + nx * o, b[1] + ny * o], Y, j % 2 ? 'rgba(255,255,255,' + (.03 + rnd() * .05).toFixed(3) + ')' : 'rgba(0,0,0,' + (.08 + rnd() * .1).toFixed(3) + ')', .45);
        }
        var c0 = esA ? [-2, -25.4 - 1.1] : [58, -25.4 - 1.1], c1 = esA ? [58, 25.4 - 1.1] : [-2, 25.4 - 1.1];
        linea(c0, c1, Y, 'rgba(255,250,240,.2)', .7);
        if (!esA) { ruta(P4, Y); ctx.fillStyle = 'rgba(0,0,0,.2)'; ctx.fill(); }
        ctx.restore();
        linea(P4[0], P4[1], Y, 'rgba(255,250,240,.16)', .6); linea(P4[3], P4[2], Y, 'rgba(0,0,0,.8)', .8);
    }
    for (k = 0; k <= g.N; k++) if (!salta(k)) { varilla(48 * k, !!(k % 2)); varilla(48 * k, !(k % 2)); }
    for (i = 0; i < g.N; i++) if (!(g.men && i >= g.iMen && i < g.iMen + g.men)) [0, 56].forEach(function (e) {
        var y = 48 * i + 24, v = e ? 47.6 : 8.4;
        ruta([[e, y - 9], [v, y], [e, y + 9]], 0); ctx.fillStyle = escala(M, .33); ctx.fill();
        ruta([[e, y - 9], [v, y], [e, y]], 0); ctx.fillStyle = 'rgba(255,255,255,.1)'; ctx.fill(); ruta([[e, y], [v, y], [e, y + 9]], 0); ctx.fillStyle = 'rgba(0,0,0,.45)'; ctx.fill();
        linea([v, y], [e, y], 0, 'rgba(0,0,0,.8)', .8); linea([v, y - .9], [e, y - 9.6], 0, 'rgba(255,250,240,.2)', .6);
    });

    /* nudos: vueltas horizontales de la misma cinta */
    function nudo(y0, alto) {
        var n = Math.max(1, Math.round(alto / 4.6)), th = alto / n, j, x, gr;
        for (j = 0; j < n; j++) {
            var y = y0 + j * th; gr = ctx.createLinearGradient(0, y, 0, y + th);
            gr.addColorStop(0, col(.5)); gr.addColorStop(.3, col(1.16)); gr.addColorStop(.62, col(.9)); gr.addColorStop(1, col(.4));
            ctx.fillStyle = gr; ctx.fillRect(0, y, 56, th);
            for (x = -4; x < 58; x += 1.5) linea([x + (rnd() - .5) * .3, y + .4], [x + th * .55, y + th - .4], 0, 'rgba(0,0,0,' + (.14 + rnd() * .12).toFixed(3) + ')', .4);
            linea([0, y + .5], [56, y + .5], 0, 'rgba(255,255,255,.16)', .5); linea([0, y + th], [56, y + th], 0, 'rgba(0,0,0,.75)', .8);
        }
    }
    if (g.men) { var m0 = g.menuki0 - g.cord0; ctx.fillStyle = tm('#0f1115', C.telaHex + ',' + C.marcoHex); ctx.fillRect(0, m0, 56, g.menukiH); nudo(m0, 9); nudo(m0 + g.menukiH - 9, 9); }
    if (g.gripEnd - g.cordFin >= 8) nudo(g.cordFin - g.cord0, g.gripEnd - g.cordFin);

    /* volumen del mango */
    var cil = ctx.createLinearGradient(0, 0, 56, 0);
    cil.addColorStop(0, 'rgba(0,0,0,.7)'); cil.addColorStop(.09, 'rgba(0,0,0,.36)'); cil.addColorStop(.3, 'rgba(0,0,0,0)'); cil.addColorStop(.6, 'rgba(255,255,255,.05)'); cil.addColorStop(.74, 'rgba(0,0,0,0)'); cil.addColorStop(.92, 'rgba(0,0,0,.4)'); cil.addColorStop(1, 'rgba(0,0,0,.74)');
    ctx.fillStyle = cil; ctx.fillRect(0, 0, 56, L);
}

// ---------- dōgane: el manguito del título (TSUKA-DISENO §3.3b), entre los dos nudos del menuki ----------
function dogane(g, t) {
    if (!g.men) return "";
    // 11-15 usuario: el manguito va MÁS OSCURO que la tela y sin aspecto de "marco/seleccionado"
    var d0 = g.menuki0 + 9, dh = g.menukiH - 18, h = '<defs>' + PAT_LIMA;
    var tela = rgb(t ? String(t).split(",")[0] : "#1d2028");
    function os(k) { return "rgb(" + Math.round(tela[0] * k) + "," + Math.round(tela[1] * k) + "," + Math.round(tela[2] * k) + ")"; }
    h += '<linearGradient id="collar" x1="0" x2="1" y1="0" y2="0"><stop offset="0" stop-color="' + os(.30) + '"/><stop offset=".35" stop-color="' + os(.62) + '"/><stop offset=".6" stop-color="' + os(.46) + '"/><stop offset="1" stop-color="' + os(.26) + '"/></linearGradient>';
    h += '<linearGradient id="cil" x1="0" x2="1" y1="0" y2="0"><stop offset="0" stop-color="#000" stop-opacity=".5"/><stop offset=".3" stop-color="#000" stop-opacity="0"/><stop offset=".62" stop-color="#fff" stop-opacity=".025"/><stop offset=".74" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity=".55"/></linearGradient></defs>';
    h += '<rect x="1.5" y="' + d0 + '" width="53" height="' + dh + '" rx="2.5" fill="url(#collar)"/><rect x="1.5" y="' + d0 + '" width="53" height="' + dh + '" rx="2.5" fill="url(#lima)" opacity=".35"/>';
    h += '<path d="M3 ' + (d0 + 3.5) + 'H53 M3 ' + (d0 + dh - 3.5) + 'H53" stroke="#000" stroke-opacity=".35" stroke-width=".8"/>';
    h += '<rect x="1.5" y="' + d0 + '" width="53" height="' + dh + '" fill="url(#cil)" opacity=".7"/>';
    return url(svg(0, d0 - 1, 56, dh + 2, h));
}

// ---------- fuchi (collar de la hora) ----------
function fuchi(g, t) {
    var h = '<defs>' + PAT_LIMA + grMetal(t) + '</defs>', f = g.fuchi0;
    h += '<rect x="3" y="' + f + '" width="50" height="80" rx="3" fill="url(#metal)"/><rect x="3" y="' + f + '" width="50" height="80" rx="3" fill="url(#lima)" opacity=".45"/>';
    h += '<path d="M5 ' + (f + 3.5) + 'H51 M5 ' + (f + 76.5) + 'H51" stroke="#000" stroke-opacity=".35" stroke-width=".8"/>';
    return url(svg(0, f - 1, 56, 82, h));
}

// ---------- la hoja (grupo móvil). Dibujo desde y0-30 hasta H+26; el Item que la contiene recorta desde y0 ----------
function hojaY0(g) { return g.hab0 + 18; }
function hoja(g, eco, grueso) {
    var temple = mezcla(eco, "#fffaf0", .62);
    var y0 = g.hab0 + 18, yT = y0 - 30, yF = g.H + 26, largo = g.H - y0;
    function sx(y) { var t = Math.max(0, (y - y0) / largo); return -3 * t * t; }
    function linea(fx) { var d = '', y, n = 0; for (y = yT; y <= yF; y += 4, n++) d += (n ? ' L' : 'M') + fx(y).toFixed(2) + ' ' + y; return d; }
    function vuelve(fx) { var d = '', y; for (y = yF; y >= yT; y -= 4) d += ' L' + fx(y).toFixed(2) + ' ' + y; return d; }
    var fMune = function (y) { return 8 + sx(y); }, fShi = function (y) { return 20 + sx(y); }, fHa = function (y) { return 48 + sx(y); };
    var fHam = function (y) { return 40.6 + sx(y) + 2.4 * Math.sin(y / 6.5) + 1.1 * Math.sin(y / 2.7 + 1); };
    var fLuz = function (y) { return 27 + sx(y); };
    var h = '<defs><linearGradient id="lomo" x1="0" x2="1" y1="0" y2="0"><stop offset="0" stop-color="#0c0e12"/><stop offset=".25" stop-color="#20242d"/><stop offset="1" stop-color="#171a21"/></linearGradient>';
    h += '<linearGradient id="cara" x1="0" x2="1" y1="0" y2="0"><stop offset="0" stop-color="#2a2f3a"/><stop offset=".32" stop-color="#454c5a"/><stop offset=".5" stop-color="#333946"/><stop offset="1" stop-color="#262b35"/></linearGradient></defs>';
    h += '<path d="' + linea(fMune) + vuelve(fShi) + ' Z" fill="url(#lomo)"/>';
    h += '<path d="' + linea(fShi) + vuelve(fHa) + ' Z" fill="url(#cara)"/>';
    h += '<path d="' + linea(fLuz) + '" fill="none" stroke="' + eco + '" stroke-opacity=".1" stroke-width="6"/><path d="' + linea(fLuz) + '" fill="none" stroke="' + eco + '" stroke-opacity=".16" stroke-width="1.5"/>';
    h += '<path d="' + linea(fHam) + vuelve(fHa) + ' Z" fill="' + temple + '" fill-opacity=".36"/>';
    h += '<path d="' + linea(fHam) + '" fill="none" stroke="' + eco + '" stroke-opacity=".22" stroke-width="5"/><path d="' + linea(fHam) + '" fill="none" stroke="' + temple + '" stroke-opacity=".85" stroke-width=".9"/>';
    h += '<path d="' + linea(fMune) + '" fill="none" stroke="#000" stroke-opacity=".7" stroke-width="1.5"/><path d="' + linea(function (y) { return fMune(y) + 1.2; }) + '" fill="none" stroke="#efe6d8" stroke-opacity=".14"/>';
    h += '<path d="' + linea(fShi) + '" fill="none" stroke="#efe6d8" stroke-opacity=".4"/><path d="' + linea(function (y) { return fShi(y) - 1; }) + '" fill="none" stroke="#000" stroke-opacity=".45"/>';
    return url(svg(0, yT, 56, yF - yT, h));
}
// el filo (ha) va aparte: cambia de opacidad y de grosor sin repintar la hoja
function filoHoja(g, grueso) {
    var y0 = g.hab0 + 18, yT = y0 - 30, yF = g.H + 26, largo = g.H - y0;
    function sx(y) { var t = Math.max(0, (y - y0) / largo); return -3 * t * t; }
    var d = '', y, n = 0;
    for (y = yT; y <= yF; y += 4, n++) d += (n ? ' L' : 'M') + (48 + sx(y) - .6).toFixed(2) + ' ' + y;
    return url(svg(0, yT, 56, yF - yT, '<path d="' + d + '" fill="none" stroke="#fffaf0" stroke-width="' + (grueso || 1.2) + '"/>'));
}

// ---------- habaki ----------
function habaki(g) {
    var hy = g.hab0 - 6, hb = g.hab0 + 20, hab = 'M6 ' + hy + ' L50 ' + hy + ' L48.5 ' + hb + ' L7.5 ' + hb + ' Z';
    var h = '<defs>' + PAT_LIMA + '<linearGradient id="oro" x1="0" x2="1" y1="0" y2="0"><stop offset="0" stop-color="#1b1e25"/><stop offset=".3" stop-color="#4a505d"/><stop offset=".55" stop-color="#2b2f39"/><stop offset="1" stop-color="#15171c"/></linearGradient></defs>';
    h += '<path d="M8 ' + (hb + 1.5) + 'H48" stroke="#000" stroke-opacity=".5" stroke-width="3"/>';
    h += '<path d="' + hab + '" fill="url(#oro)" stroke="#2a2d38"/><path d="' + hab + '" fill="url(#lima)" opacity=".7"/>';
    h += '<path d="M6.5 ' + (hy + 1.5) + 'H49.5" stroke="#fffaf0" stroke-opacity=".35"/><path d="M7 ' + (hy + 9.5) + 'H49" stroke="#000" stroke-opacity=".55"/><path d="M7 ' + (hy + 10.5) + 'H49" stroke="#efe6d8" stroke-opacity=".16"/><path d="M8 ' + (hb - 1.5) + 'H48" stroke="#000" stroke-opacity=".7"/>';
    return url(svg(0, hy - 1, 56, 30, h));
}

// ---------- tsuba (guarda de hueso, 72 x 12) ----------
function tsuba() {
    var h = '<defs><linearGradient id="hg" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="#fffaf0"/><stop offset=".3" stop-color="#efe6d8"/><stop offset=".8" stop-color="#c9c0b2"/><stop offset="1" stop-color="#8f887c"/></linearGradient></defs>';
    h += '<rect x="3" y="0" width="50" height="2" fill="#6f7480"/><rect x="4" y="10" width="48" height="2" fill="#565b67"/>';
    h += '<path d="M0 2H69Q72 2 72 5V7Q72 10 69 10H0Z" fill="url(#hg)"/>';
    for (var x = 3; x < 58; x += 4) h += '<path d="M' + x + ' 6.4l2.2 3" stroke="#0c0e12" stroke-opacity=".28"/>';
    h += '<path d="M64 3.4L66.6 6L64 8.6L61.4 6Z" fill="#0c0e12"/><path d="M0 2.5H69" stroke="#fffaf0" stroke-opacity=".9"/>';
    return url(svg(0, 0, 72, 12, h));
}

// ---------- piel de raya dentro de una ventana del cordón (fila que empieza en y) ----------
function ventanaSame(y) {
    var h = '<defs>' + patSame() + '</defs><polygon points="28,' + (y + 7) + ' 48,' + (y + 24) + ' 28,' + (y + 41) + ' 8,' + (y + 24) + '" fill="url(#same)"/>';
    return url(svg(0, y, 56, 48, h));
}
// halo de eco de un escritorio con ventanas (elipse 19 x 16, degradado radial eco 46 % -> 0)
function halo(eco) {
    var h = '<defs><radialGradient id="glow"><stop offset="0" stop-color="' + eco + '" stop-opacity=".46"/><stop offset="1" stop-color="' + eco + '" stop-opacity="0"/></radialGradient></defs><ellipse cx="28" cy="24" rx="19" ry="16" fill="url(#glow)"/>';
    return url(svg(0, 0, 56, 48, h));
}

// ---------- Saya: la laca (8 px x largo), en coordenadas de la vaina (y = 0 arriba del monitor) ----------
function vaina(g, eco) {
    var s = g.s, t0 = g.ojoC - 8, L = s.largo, p = s.punta, h = '';
    h += '<defs><linearGradient id="laca" x1="0" x2="1" y1="0" y2="0"><stop offset="0" stop-color="#040507"/><stop offset=".38" stop-color="#1a1e26"/><stop offset=".55" stop-color="#0e1014"/><stop offset="1" stop-color="#07080b"/></linearGradient>';
    h += '<linearGradient id="esp" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="#efe6d8" stop-opacity=".05"/><stop offset=".12" stop-color="' + eco + '" stop-opacity=".6"/><stop offset=".5" stop-color="' + eco + '" stop-opacity=".2"/><stop offset="1" stop-color="#efe6d8" stop-opacity=".04"/></linearGradient>';
    h += '<linearGradient id="contera" x1="0" x2="1" y1="0" y2="0"><stop offset="0" stop-color="#1a1d24"/><stop offset=".4" stop-color="#3a3f4b"/><stop offset="1" stop-color="#15171c"/></linearGradient></defs>';
    h += '<path d="M0 ' + t0 + 'H8V' + L + 'L0 ' + (L - p) + 'Z" fill="url(#laca)"/>';
    h += '<rect x="2" y="' + (t0 + 18) + '" width="1" height="' + (L - p - 48 - t0) + '" fill="url(#esp)"/>';
    h += '<path d="M.5 ' + t0 + 'V' + (L - p) + 'L8 ' + L + '" fill="none" stroke="#efe6d8" stroke-opacity=".24"/>';
    h += '<path d="M0 ' + (L - p - 26) + 'H8V' + L + 'L0 ' + (L - p) + 'Z" fill="url(#contera)"/><path d="M0 ' + (L - p - 25.5) + 'H8" stroke="#efe6d8" stroke-opacity=".4"/><path d="M0 ' + (L - p - 21.5) + 'H8" stroke="#000" stroke-opacity=".6"/><path d="M.5 ' + (L - p - 26) + 'V' + (L - p) + 'L8 ' + L + '" fill="none" stroke="#efe6d8" stroke-opacity=".35"/>';
    return url(svg(0, 0, 8, L, h));
}

// ---------- Saya: el bloque desenvainado (ancho x alto; 148, o 64 como OSD): nashiji + curva de la laca + corte de 16 px ----------
function bloque(alto, corte, ancho) {
    var c = corte === undefined ? 16 : corte;
    var A = ancho || 148;
    var forma = 'M0 0H' + A + 'V' + alto + 'H' + c + 'L0 ' + (alto - c) + 'Z';
    var h = '<defs>';
    var capas = [[37, 41, .2, .3, .16], [29, 53, .7, .62, .12], [43, 31, .44, .86, .1], [31, 47, .86, .12, .12]];
    capas.forEach(function (k, i) { h += '<pattern id="n' + i + '" width="' + k[0] + '" height="' + k[1] + '" patternUnits="userSpaceOnUse"><rect x="' + (k[0] * k[2]).toFixed(1) + '" y="' + (k[1] * k[3]).toFixed(1) + '" width="1" height="1" fill="#efe6d8" fill-opacity="' + k[4] + '"/></pattern>'; });
    h += '<linearGradient id="lz" x1="0" x2="' + A + '" y1="0" y2="0" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#efe6d8" stop-opacity=".07"/><stop offset="' + (22 / A).toFixed(3) + '" stop-color="#efe6d8" stop-opacity="0"/><stop offset=".6" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity=".35"/></linearGradient></defs>';
    h += '<path d="' + forma + '" fill="#0c0e12"/>';
    capas.forEach(function (k, i) { h += '<path d="' + forma + '" fill="url(#n' + i + ')"/>'; });
    h += '<path d="' + forma + '" fill="url(#lz)"/>';
    h += '<path d="M.5 0V' + (alto - c) + '" stroke="#efe6d8" stroke-opacity=".4"/>';
    return url(svg(0, 0, A, alto, h));
}

// ---------- Saya: hamon de la lengua (franja de 8 px, onda de 9 px) ----------
function hamon(ancho) {
    var h = '<defs><pattern id="hm" width="36" height="8" patternUnits="userSpaceOnUse"><path d="M0 8V5Q4.5 0 9 4T18 4T27 4T36 5V8Z" fill="#efe6d8" fill-opacity=".16"/><path d="M0 5Q4.5 0 9 4T18 4T27 4T36 5" fill="none" stroke="#fffaf0" stroke-opacity=".5" stroke-width=".8"/></pattern></defs>';
    h += '<rect width="' + ancho + '" height="8" fill="url(#hm)"/>';
    return url(svg(0, 0, ancho, 8, h));
}
