.pragma library
// 11-15 La hoja con elemento (diseño Fable: /mnt/Compartido/Nero/diseno-fable/tsuka-transicion-elementos/, DISENO.md §2).
// Port tal cual de formaAgua/formaFuego/formaViento + campo() del prototipo: la FORMA del elemento se pinta en una
// máscara y de ahí sale el campo de distancias con signo que lee hoja.frag. La forma no depende del color: se calcula
// una vez por elemento y por largo de hoja (y se guarda en disco, ~/.cache/caelestia/tsuka/).
// Coordenadas del prototipo: YT = 28 (arriba del dibujo), Y0 = 58 (arriba de la hoja visible), H2 = Y0 + largo, YF = H2 + 26.

var YT = 28, Y0 = 58, SB = 4, VERSION = 1;

function geoHoja(largo) { var H2 = Y0 + largo; return { YT: YT, Y0: Y0, H2: H2, YF: H2 + 26, SB: SB, w: 56 * SB, h: (H2 + 26 - YT) * SB }; }

// qué elemento le toca a un monitor (DISENO.md §2.4): tsuka.json manda; si no, el tono de la tela; si no, ninguno ("")
function rgb2hsl(h) {
    var r = parseInt(h.slice(1, 3), 16) / 255, g = parseInt(h.slice(3, 5), 16) / 255, b = parseInt(h.slice(5, 7), 16) / 255;
    var mx = Math.max(r, g, b), mn = Math.min(r, g, b), d = mx - mn, hh = 0, l = (mx + mn) / 2, s = d ? d / (1 - Math.abs(2 * l - 1)) : 0;
    if (d) hh = mx === r ? ((g - b) / d) % 6 : mx === g ? (b - r) / d + 2 : (r - g) / d + 4;
    return [(hh * 60 + 360) % 360, s, l];
}
function elementoDe(monitor, telaHex, conf) {
    var m = conf && conf[monitor];
    if (m === "agua" || m === "fuego" || m === "viento" || m === "ninguno") return m === "ninguno" ? "" : m;
    if (!telaHex || telaHex.length < 7) return "";
    var hsl = rgb2hsl(telaHex), h = hsl[0];
    if (hsl[1] < .08) return "";
    if (h >= 190 && h < 270) return "agua";
    if (h >= 335 || h < 70) return "fuego";
    if (h >= 70 && h < 190) return "viento";
    return "";
}
function codigo(el) { return el === "fuego" ? 0 : el === "agua" ? 1 : 2; }

// ── utilidades del prototipo ──
function azar(sem) { var s = sem; return function () { s = (s * 16807) % 2147483647; return s / 2147483647; }; }
function clamp(v, a, b) { return v < a ? a : v > b ? b : v; }
function sst(a, b, x) { var t = clamp((x - a) / (b - a), 0, 1); return t * t * (3 - 2 * t); }
function cinta(cl, wf) {
    var n = cl.length, L = [], R = [], i;
    for (i = 0; i < n; i++) {
        var a = cl[Math.max(0, i - 1)], b = cl[Math.min(n - 1, i + 1)], dx = b[0] - a[0], dy = b[1] - a[1], d = Math.sqrt(dx * dx + dy * dy) || 1, w = wf(i / (n - 1));
        L.push([cl[i][0] - dy / d * w, cl[i][1] + dx / d * w]); R.push([cl[i][0] + dy / d * w, cl[i][1] - dx / d * w]);
    }
    return L.concat(R.reverse());
}
function rutaPoli(c, p) { c.moveTo(p[0][0], p[0][1]); for (var i = 1; i < p.length; i++) c.lineTo(p[i][0], p[i][1]); c.closePath(); }
function poli(c, fx, ya, yb, paso, sigue) {
    var y, n = 0;
    if (ya < yb) for (y = ya; y <= yb; y += paso, n++) { if (n || sigue) c.lineTo(fx(y), y); else c.moveTo(fx(y), y); }
    else for (y = ya; y >= yb; y -= paso, n++) { if (n || sigue) c.lineTo(fx(y), y); else c.moveTo(fx(y), y); }
}
function trazaPts(c, pts) { for (var i = 0; i < pts.length; i++) { if (i) c.lineTo(pts[i][0], pts[i][1]); else c.moveTo(pts[i][0], pts[i][1]); } }
function gota(c, x, y, r, ang) {
    c.save(); c.translate(x, y); c.rotate(ang); c.beginPath(); c.moveTo(0, -r * 2.1);
    c.quadraticCurveTo(r * 1.15, -r * .1, 0, r); c.quadraticCurveTo(-r * 1.15, -r * .1, 0, -r * 2.1); c.closePath(); c.fill(); c.restore();
}

// ── las tres formas (DISENO.md §2.1), con la curvatura sx de esta hoja ──
function pintaForma(c, el, H2) {
    var YF = H2 + 26;
    function sx(y) { var t = Math.max(0, (y - Y0) / (H2 - Y0)); return -3 * t * t; }
    if (el === "agua") {
        var crestas = [], pts = (function () {
            var r = azar(12), l = [], a = 32 / 6.2832, b = a * .78, th, n = -1, A = 9, Y = YT - 20, y = Y;
            for (th = 0; y < YF + 6; th += .09) {
                var ni = Math.floor((th + Math.PI) / 6.2832);
                if (ni !== n) { n = ni; A = 7.2 + r() * 3.4; if (y > 44 && y < 112) A = Math.min(A, 6.6); }
                var h = Math.pow((1 + Math.cos(th)) / 2, 1.1); y = Y + a * th - b * Math.sin(th) + 5.2 * h * h; var x = 44.4 - A * h;
                l.push([x + sx(y), y]); if (Math.abs(((th + .045) % 6.2832)) < .09 && th > 1) crestas.push([x + sx(y), y, l.length - 1]);
            }
            return l;
        })();
        c.beginPath(); trazaPts(c, pts); poli(c, function (y) { return 45.5 + sx(y); }, YF + 8, YT - 22, 4, true); c.closePath(); c.fill();
        crestas.forEach(function (p, i) { gota(c, p[0] - 2.4, p[1] + 4.6, 1.15, 2.5); if (i % 2 === 0) { c.beginPath(); c.arc(p[0] - 4.9, p[1] + 7.8, .8, 0, 6.3); c.fill(); } });
    } else if (el === "fuego") {
        var y0, n = 0, rio = [], yy;
        for (yy = YT - 6; yy <= YF + 10; yy += 3) rio.push([42.5 + .5 * Math.sin(yy / 6.1) + sx(yy), yy]);
        c.beginPath(); rutaPoli(c, cinta(rio, function (t) { return 2.75 + .5 * Math.sin(t * 64); })); c.fill();
        for (y0 = YF + 14; y0 > YT - 4; y0 -= 20.5, n++) {
            var enM = y0 > 64 && y0 - 28 < 120, Dx = enM ? 4.6 : (n % 2 ? 9.6 : 7.4), Lg = n % 2 ? 31 : 26, cl = [], i, t, f = [];
            for (i = 0; i <= 26; i++) {
                t = i / 26; var y = y0 - Lg * t;
                cl.push([42.2 - Dx * Math.pow(Math.sin(t * 1.5708), 1.5) + 1.1 * Math.sin(t * 6.283) * (1 - t) + (enM ? 1.6 : 3.2) * Math.pow(sst(.62, 1, t), 2) + sx(y), y + 2.2 * Math.pow(sst(.8, 1, t), 2)]);
            }
            c.beginPath(); rutaPoli(c, cinta(cl, function (t) { return (enM ? 3.3 : 5.2) * Math.pow(1 - t, .95) * (.45 + .55 * Math.sin(Math.min(1, t * 3.2) * 1.5708)); })); c.fill();
            var b = cl[10], fx = enM ? 2.4 : 5;
            for (i = 0; i <= 14; i++) { t = i / 14; f.push([b[0] - .6 - fx * Math.pow(t, 1.25) + .8 * Math.sin(t * 3.1), b[1] + 1.5 - 12.5 * Math.pow(t, .9)]); }
            c.beginPath(); rutaPoli(c, cinta(f, function (t) { return (enM ? 1.5 : 2.4) * Math.pow(1 - t, .8) * (.6 + .4 * Math.sin(Math.min(1, t * 4) * 1.5708)); })); c.fill();
        }
    } else {
        var onda = function (y) { var f = (y - 18) / 54 * 6.2832; return 3.5 + 3.3 * Math.sin(f + .85 * Math.sin(f)); };
        c.beginPath(); poli(c, function (y) { return 43.4 - onda(y) + sx(y); }, YT - 30, YF + 10, 1); poli(c, function (y) { return 45.5 + sx(y); }, YF + 10, YT - 30, 4, true); c.closePath(); c.fill();
    }
}

// campo de distancias con signo (positivo dentro), en px lógicos, desde el alfa de la máscara (getImageData().data)
// y empacado en 16 bits (R alto, G bajo) sobre [-16, 16], como glHoja() del prototipo. "sal" = data de createImageData.
function campo(al, w, h, sal) {
    var din = new Float32Array(w * h), dout = new Float32Array(w * h), A = new Float32Array(w * h), G = 1e4, i, x, y, v;
    for (i = 0; i < w * h; i++) { var a = al[i * 4 + 3] / 255; A[i] = a; if (a > .5) { din[i] = G; dout[i] = 0; } else { din[i] = 0; dout[i] = G; } }
    [din, dout].forEach(function (d) {
        for (y = 0; y < h; y++) for (x = 0; x < w; x++) { i = y * w + x; v = d[i]; if (!v) continue; if (x > 0) v = Math.min(v, d[i - 1] + 1); if (y > 0) { v = Math.min(v, d[i - w] + 1); if (x > 0) v = Math.min(v, d[i - w - 1] + 1.414); if (x < w - 1) v = Math.min(v, d[i - w + 1] + 1.414); } d[i] = v; }
        for (y = h - 1; y >= 0; y--) for (x = w - 1; x >= 0; x--) { i = y * w + x; v = d[i]; if (!v) continue; if (x < w - 1) v = Math.min(v, d[i + 1] + 1); if (y < h - 1) { v = Math.min(v, d[i + w] + 1); if (x < w - 1) v = Math.min(v, d[i + w + 1] + 1.414); if (x > 0) v = Math.min(v, d[i + w - 1] + 1.414); } d[i] = v; }
    });
    for (i = 0; i < w * h; i++) {
        var D = (din[i] > 0 ? din[i] - 1 + A[i] : -(dout[i] - A[i])) / SB;
        v = Math.round(clamp((D + 16) / 32, 0, 1) * 65535);
        sal[i * 4] = v >> 8; sal[i * 4 + 1] = v & 255; sal[i * 4 + 2] = 0; sal[i * 4 + 3] = 255;
    }
}

// ── fuego al jalar (vivo2 + pavesa del prototipo): filo al rojo y cinco pavesas que suben. k = carga, T = ms ──
function rgba(c, a) { return "rgba(" + Math.round(c[0]) + "," + Math.round(c[1]) + "," + Math.round(c[2]) + "," + (a === undefined ? 1 : Math.max(0, Math.min(1, a)).toFixed(3)) + ")"; }
function mez(a, b, t) { return [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t]; }
var F_OUT = [178, 60, 34], F_MID = [234, 122, 42], F_INV = [255, 223, 156];
function pavesa(c, x, y, r, giro, al, frio) {
    if (al <= .01) return;
    c.save(); c.globalAlpha = Math.min(1, al); c.translate(x, y); c.rotate(giro); c.beginPath();
    c.moveTo(-r, -r * .2); c.lineTo(-r * .2, -r); c.lineTo(r, -r * .5); c.lineTo(r * .7, r * .7); c.lineTo(-r * .5, r); c.closePath();
    var g = c.createLinearGradient(0, -r, 0, r); g.addColorStop(0, rgba(mez(F_INV, F_MID, frio || 0))); g.addColorStop(1, rgba(mez(F_MID, F_OUT, frio || 0)));
    c.strokeStyle = rgba([112, 18, 9], .85); c.lineWidth = .9; c.stroke(); c.fillStyle = g; c.fill(); c.restore();
}
function vivoFuego(c, k, T, g) {
    var H2 = g.H2, YF = g.YF, r, i;
    function sx(y) { var t = Math.max(0, (y - Y0) / (H2 - Y0)); return -3 * t * t; }
    function fHa(y) { return 48 + sx(y); }
    c.save(); c.globalCompositeOperation = "lighter"; c.beginPath(); poli(c, function (y) { return fHa(y) - .6; }, YT, YF, 4);
    c.strokeStyle = rgba(F_OUT, .5 * k); c.lineWidth = 2 + 5 * k; c.stroke(); c.strokeStyle = rgba(F_MID, .45 * k); c.lineWidth = 1 + 2 * k; c.stroke();
    c.restore();
    r = azar(911);
    for (i = 0; i < 5; i++) {
        var per = 620 + r() * 340, ed = ((T + r() * per) % per) / per, y0 = Y0 + 14 + r() * (H2 - Y0 - 10), vx = -5 - r() * 12, al = Math.min(1, k * 1.3) * Math.sin(Math.PI * Math.pow(ed, .6)), gi = r() * 6;
        pavesa(c, fHa(y0) - 3 + vx * ed + 2 * Math.sin(ed * 7 + gi), y0 - (20 + 22 * r()) * ed - 10 * ed * ed, 1 + .9 * r() * (1 - ed * .5), gi + ed * 3, al, ed * .7);
    }
}

// el campo empacado (RGBA, w×h) -> BMP de 24 bits en base64. Así no depende de la escala del monitor (el Canvas de Qt
// guarda a devicePixelRatio) y se puede guardar en disco como texto con FileView.
function bmp64(rgba, w, h) {
    var fila = (w * 3 + 3) & ~3, tam = 54 + fila * h, b = new Uint8Array(tam), x, y, o, i;
    function u32(p, v) { b[p] = v & 255; b[p + 1] = (v >> 8) & 255; b[p + 2] = (v >> 16) & 255; b[p + 3] = (v >>> 24) & 255; }
    b[0] = 66; b[1] = 77; u32(2, tam); u32(10, 54); u32(14, 40); u32(18, w); u32(22, h); b[26] = 1; b[28] = 24; u32(34, fila * h); u32(38, 2835); u32(42, 2835);
    for (y = 0; y < h; y++) {
        o = 54 + (h - 1 - y) * fila;
        for (x = 0; x < w; x++) { i = (y * w + x) * 4; b[o++] = rgba[i + 2]; b[o++] = rgba[i + 1]; b[o++] = rgba[i]; }
    }
    var A = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/", s = [], n;
    for (i = 0; i < tam; i += 3) {
        n = (b[i] << 16) | ((i + 1 < tam ? b[i + 1] : 0) << 8) | (i + 2 < tam ? b[i + 2] : 0);
        s.push(A[(n >> 18) & 63] + A[(n >> 12) & 63] + (i + 1 < tam ? A[(n >> 6) & 63] : "=") + (i + 2 < tam ? A[n & 63] : "="));
    }
    return s.join("");
}

// ── el tajo con la estela de su elemento (tajo() del prototipo, DISENO.md §2.3). Coordenadas de la pantalla de la barra.
// o = {ox, oy, W} origen del corte (cerca del filo, abajo) y ancho de la pantalla; P = {eco, temple, base} en [r,g,b] 0..255
function bez(x1, y1, x2, y2) {
    return function (x) {
        if (x <= 0) return 0; if (x >= 1) return 1; var t = x, i, f, d;
        for (i = 0; i < 8; i++) { f = 3 * x1 * t * (1 - t) * (1 - t) + 3 * x2 * t * t * (1 - t) + t * t * t - x; d = 3 * x1 * (1 - t) * (1 - t) + 6 * (x2 - x1) * t * (1 - t) + 3 * (1 - x2) * t * t; if (Math.abs(d) < 1e-6) break; t = clamp(t - f / d, 0, 1); }
        return 3 * y1 * t * (1 - t) * (1 - t) + 3 * y2 * t * t * (1 - t) + t * t * t;
    };
}
var cEntra = bez(.22, 1, .36, 1);
var ALTO = [255, 250, 240], HUESO = [239, 230, 216], BRASA = [179, 67, 42];
function esc(c, k) { return [c[0] * k, c[1] * k, c[2] * k]; }
function llena(c, polys, col) { c.fillStyle = col; polys.forEach(function (p) { c.beginPath(); rutaPoli(c, p); c.fill(); }); }
function perfila(c, polys, col, lw) { c.strokeStyle = col; c.lineWidth = lw; c.lineJoin = "round"; polys.forEach(function (p) { c.beginPath(); rutaPoli(c, p); c.stroke(); }); }
function largoTajo(o) { var dn = Math.sqrt(1 + .64), dx = 1 / dn, dy = -.8 / dn; return Math.min((o.W + 30 - o.ox) / dx, (o.oy + 30) / -dy); }
function tajo(c, tau, el, o, P) {
    // La línea cruza la pantalla (como el tajo de antes); la estela vive en el primer tramo de Le px junto a la hoja,
    // con la misma densidad que el prototipo (allí el corte visible medía ~230 px).
    var ox = o.ox, oy = o.oy, dn = Math.sqrt(1 + .64), dx = 1 / dn, dy = -.8 / dn, nx = -dy, ny = dx, Lm = largoTajo(o), Le = Math.min(Lm, o.Le || 260), r = azar(4242), i;
    function pt(s, comba, off) { var b = comba * Math.sin(Math.PI * s); return [ox + dx * s * Le - nx * (b + (off || 0)), oy + dy * s * Le - ny * (b + (off || 0))]; }
    function ptL(u, comba, off) { var b = u < Le ? comba * Math.sin(Math.PI * u / Le) : 0; return [ox + dx * u - nx * (b + (off || 0)), oy + dy * u - ny * (b + (off || 0))]; }
    var comba = el === "agua" ? 9 : el === "viento" ? 3 : 0, larga = el === "fuego" ? 430 : el === "agua" ? 260 : 170;
    function raya(t, off, ancho, col) {
        var p = cEntra(t / 210), op = 1 - clamp((t - 210) / larga, 0, 1), s, q; if (t <= 0 || op <= 0) return;
        var fin = p * Lm, u, pasoU = Le / 50;
        c.beginPath(); for (u = 0; u <= fin + 1e-6; u += (u < Le ? pasoU : 40)) { q = ptL(Math.min(u, fin), comba, off); if (u) c.lineTo(q[0], q[1]); else c.moveTo(q[0], q[1]); } q = ptL(fin, comba, off); c.lineTo(q[0], q[1]);
        c.strokeStyle = rgba(col || ALTO, op); c.lineWidth = ancho; c.lineCap = "round"; c.stroke();
    }
    var p = cEntra(tau / 210);
    if (el === "agua") {
        var op = 1 - clamp((tau - 230) / 330, 0, 1);
        if (op > 0 && tau > 0) {
            c.beginPath(); var s, q, gr;
            for (s = 0; s <= p; s += .01) { q = pt(s, comba, 0); if (s) c.lineTo(q[0], q[1]); else c.moveTo(q[0], q[1]); }
            for (s = p; s >= 0; s -= .01) { gr = -11 * Math.pow(Math.sin(Math.PI * s / Math.max(p, .01)), .7) * (.72 + .28 * Math.sin(s * 46 - tau * .018)) * (.55 + .45 * p); q = pt(s, comba, gr); c.lineTo(q[0], q[1]); }
            c.closePath(); c.fillStyle = rgba(P.eco, .3 * op); c.fill(); c.strokeStyle = rgba(P.temple, .55 * op); c.lineWidth = .8; c.stroke();
        }
        c.fillStyle = rgba(P.temple, 1);
        for (i = 0; i < 12; i++) {
            var s0 = .08 + r() * .84, nace = 210 * Math.pow(s0, 1.6) + 20, ed = tau - nace, vida = 420 + r() * 220, v1 = 30 + r() * 80, v2 = 30 + r() * 120, rad = .9 + r() * 1.2; if (ed <= 0 || ed >= vida) continue;
            var a = pt(s0, comba, 0), t = ed / 1000, vxx = dx * v2 + nx * v1, vyy = dy * v2 + ny * v1, X = a[0] + vxx * t, Y = a[1] + vyy * t + 380 * t * t;
            c.globalAlpha = Math.min(1, 3 * (1 - ed / vida)); gota(c, X, Y, rad, Math.atan2(vxx, -(vyy + 760 * t)));
        }
        c.globalAlpha = 1;
    } else if (el === "fuego") {
        var capas = [[1, [112, 18, 9]], [.8, [206, 62, 22]], [.58, [244, 128, 38]], [.36, [255, 204, 108]], [.17, ALTO]], apaga = 1 - clamp((tau - 330) / 300, 0, 1), fr = tau / 95, polys = [[], [], [], [], []];
        if (apaga > 0 && tau > 0) {
            capas.forEach(function (k, j) { var cl = [], s; for (s = 0; s <= p + 1e-6; s += .025) cl.push(pt(Math.min(s, p), 0, 0)); if (cl.length > 2) polys[j].push(cinta(cl, function (t) { return (6.5 * k[0] * Math.pow(Math.sin(Math.PI * Math.min(1, t * .96 + .02)), .55) * (1 + .18 * Math.sin(t * 40 + fr * 2))) * apaga; })); });
            for (i = 0; i < 12; i++) {
                var s1 = .04 + (i + r() * .9) / 12.5 * .9, nace1 = 210 * Math.pow(s1, 1.5), ed1 = tau - nace1, vida1 = 360 + r() * 240, largo = 15 + Math.pow(r(), 1.4) * 40, gi = r() * 6.28, ld = r() < .5 ? 1 : -1; if (ed1 <= 0 || ed1 >= vida1) continue;
                var e1 = ed1 / vida1, env = Math.pow(Math.sin(Math.PI * Math.pow(e1, .5)), .8) * (1 + .14 * Math.sin(gi + fr * 2.1)), b = pt(s1, 0, 0);
                capas.forEach(function (k, j) {
                    var cl = [], n, Lg = largo * env * k[0];
                    for (n = 0; n <= 12; n++) { var t = n / 12; cl.push([b[0] - dx * Lg * .95 * t + nx * ld * 2.5 * Math.sin(t * 4 + gi + fr * 1.3) * t * k[0], b[1] - dy * Lg * .95 * t - Lg * .85 * Math.pow(t, 1.5) - e1 * 5 * t]); }
                    polys[j].push(cinta(cl, function (t) { return (1.6 + largo * .13) * k[0] * (j ? .8 : 1) * Math.pow(1 - t, .7) * (.7 + .5 * Math.sin(Math.min(1, t * 2.6) * 1.5708)) * Math.min(1, env * 1.4); }));
                });
            }
            c.save(); c.globalCompositeOperation = "lighter"; perfila(c, polys[0], rgba([235, 62, 14], .13), 12); perfila(c, polys[0], rgba([235, 62, 14], .22), 5); c.restore();
            capas.forEach(function (k, j) { llena(c, polys[j], rgba(k[1])); });
        }
        r = azar(777);
        for (i = 0; i < 14; i++) {
            var s2 = .05 + r() * .9, nace2 = 210 * Math.pow(s2, 1.5) + r() * 120, ed2 = tau - nace2, vida2 = 480 + r() * 380, vx2 = -30 + r() * 46, vy2 = -34 - r() * 70, rd = 1.1 + r() * 1.7, g2 = r() * 6; if (ed2 <= 0 || ed2 >= vida2) continue;
            var a2 = pt(s2, 0, 0), t2 = ed2 / 1000, e2 = ed2 / vida2; pavesa(c, a2[0] + vx2 * t2 + 3 * Math.sin(ed2 * .012 + i), a2[1] + vy2 * t2 - 45 * t2 * t2, rd * (1 - e2 * .4), g2 + ed2 * .006, Math.min(1, 2.2 * (1 - e2)), e2);
        }
    } else {
        var tinta = esc(P.base, .42), dentro = mez(P.temple, ALTO, .45);
        [0, 1, 2, 3, 4].forEach(function (j) {
            var lj = Math.abs(j - 2), ret = lj * 48 + (j > 2 ? 20 : 0), hd = cEntra((tau - ret) / 290), tl = cEntra((tau - ret - 180) / 430), cl = [], sq; if (tau <= ret || tl >= 1) return;
            for (sq = tl; sq <= hd + 1e-6; sq += .012) cl.push(pt(sq, 3, (j - 2) * 6.5 + (8 - lj * 2.2) * Math.sin(sq * 8.5 - j * .8 - tau * .004) * Math.sin(Math.PI * sq)));
            if (cl.length < 4) return;
            var wq = function (m) { return function (t) { return m * (lj ? 1.25 - lj * .25 : 2.3) * Math.pow(Math.sin(Math.PI * t), .55); }; }, Pq = [cinta(cl, wq(1))];
            c.save(); c.globalCompositeOperation = "lighter"; perfila(c, Pq, rgba(P.eco, .2 * (1 - tl)), 5); c.restore();
            c.globalAlpha = 1 - tl * .7; llena(c, Pq, rgba(dentro)); llena(c, [cinta(cl, wq(.4))], rgba(ALTO)); c.globalAlpha = 1;
        });
        c.fillStyle = rgba(HUESO, .92); c.strokeStyle = rgba(tinta, .8); c.lineWidth = .6;
        for (i = 0; i < 6; i++) {
            var s3 = .15 + r() * .7, nace3 = 210 * Math.pow(s3, 1.5), ed3 = tau - nace3, vida3 = 560 + r() * 240, off3 = -14 + r() * 32, giro = r() * 6; if (ed3 <= 0 || ed3 >= vida3) continue;
            var e3 = ed3 / vida3, av3 = 150 * (1 - Math.exp(-e3 * 2.4)) / 2.4 * 1.6, a3 = pt(s3, 3, off3), X3 = a3[0] + dx * av3 + nx * 7 * Math.sin(ed3 * .011 + giro), Y3 = a3[1] + dy * av3 + ny * 7 * Math.sin(ed3 * .011 + giro) + 14 * e3 * e3;
            c.save(); c.globalAlpha = Math.min(1, 2.5 * (1 - e3)); c.translate(X3, Y3); c.rotate(giro + ed3 * .009); c.scale(1, .35 + .65 * Math.abs(Math.cos(ed3 * .013 + giro)));
            c.beginPath(); c.moveTo(-3.6, 0); c.quadraticCurveTo(-.5, -2.4, 3.6, 0); c.quadraticCurveTo(-.5, 2.4, -3.6, 0); c.fill(); c.restore();
        }
    }
    var cola = el === "fuego" ? mez(mez(ALTO, P.eco, clamp((tau - 150) / 160, 0, 1)), BRASA, clamp((tau - 300) / 260, 0, 1)) : ALTO;
    raya(tau, 0, 2.2, cola); raya(tau - 40, 9, .8, cola);
}
