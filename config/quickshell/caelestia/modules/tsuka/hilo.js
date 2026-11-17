.pragma library
// 11-15 El hilo rojo (diseño Fable aprobado: tsuka-transicion-elementos, DISENO.md §1).
// Port de irA/paso1/pinta1 del prototipo. Coordenadas: y local del lienzo, 0 = arriba del cordón (g.cord0);
// la fila k ocupa [48k, 48k + 48] y su rombo va de 48k + 7 a 48k + 41.
// Se pinta en tres lienzos: "bajo" (luz aditiva bajo todo: halo, sonrojo), "medio" (normal: luna negra, nudo viejo,
// chispas, hilo, punta) y "sobre" (luz aditiva encima: borde de la luna, brillo de seda, golpe por el tejido, anillo).
// Los kanji son Text de QML entre "medio" y "sobre"; su color y su golpe salen de este estado.

var ROJO = [224, 48, 58], ROJOV = [255, 106, 94], ALTO = [255, 250, 240], VACIO = [5, 6, 10];

function clamp(v, a, b) { return v < a ? a : v > b ? b : v; }
function mez(a, b, t) { return [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t]; }
function rgba(c, a) { return "rgba(" + Math.round(c[0]) + "," + Math.round(c[1]) + "," + Math.round(c[2]) + "," + (a === undefined ? 1 : clamp(a, 0, 1).toFixed(3)) + ")"; }
function azar(sem) { var s = sem; return function () { s = (s * 16807) % 2147483647; return s / 2147483647; }; }

function nuevo(act, NF, sombra) {
    var e = { act: act, a: 48 * act + 7, b: 48 * act + 41, va: 0, vb: 0, ta: 48 * act + 7, tb: 48 * act + 41, lider: "b", dir: 1,
        tCambio: -1e9, tSeg: -1e9, cruzado: true, breve: false, tLlegada: -1e9, I: 0, pend: false, tArr: -1e9, golpe: 0, vg: 0,
        sombra: sombra, tPaso: [], dPaso: [], fant: null, quieto: true, luz: [], NF: NF };
    for (var k = 0; k < NF; k++) e.luz.push(k === act ? 1 : 0);
    return e;
}
// sin animación (arranque, cambio de geometría, "movimiento": false)
function salta(e, n) { e.act = n; e.a = e.ta = 48 * n + 7; e.b = e.tb = 48 * n + 41; e.va = e.vb = 0; e.cruzado = true; e.pend = false; e.tLlegada = -1e9; e.golpe = e.vg = 0; for (var k = 0; k < e.NF; k++) e.luz[k] = k === n ? 1 : 0; }

// cambio de escritorio. foco = este monitor tiene el foco (sin foco: siempre breve y sin remate)
function irA(e, n, T, foco) {
    if (n === e.act) return;
    var y0 = 48 * n;
    e.dir = n > e.act ? 1 : -1;
    e.breve = !foco || T - e.tCambio < 380;
    e.sinRemate = !foco;
    if (!e.breve && e.cruzado && Math.abs(e.a - e.ta) < 3) e.fant = { y0: 48 * e.act, t: T };
    e.tCambio = T; e.act = n; e.cruzado = false; e.pend = false;
    e.lider = e.dir > 0 ? "b" : "a"; e.tSeg = T + (e.breve ? 0 : 70);
    if (e.lider === "b") e.tb = y0 + 41; else e.ta = y0 + 7;
    e.quieto = false;
}
// tope de la rueda: las dos puntas cabecean ~5 px y regresan
function tope(e, d) { e.va += d * 150; e.vb += d * 150; e.quieto = false; }

// un paso de física (dt en s, T en ms); sombraReposo = 0.8 (eclipsado)
function paso(e, dt, T, sombraReposo) {
    if (e.quieto) return;
    var y0 = 48 * e.act, k;
    if (T >= e.tSeg) { e.ta = y0 + 7; e.tb = y0 + 41; }
    var wl = e.breve ? 34 : 20, zl = e.breve ? .85 : .62, ws = e.breve ? 26 : 13, zs = e.breve ? .95 : .85;
    var wa = e.lider === "a" ? wl : ws, za = e.lider === "a" ? zl : zs, wb = e.lider === "b" ? wl : ws, zb = e.lider === "b" ? zl : zs;
    var pa = e.a, pb = e.b;
    e.va += (-wa * wa * (e.a - e.ta) - 2 * za * wa * e.va) * dt; e.a += e.va * dt;
    e.vb += (-wb * wb * (e.b - e.tb) - 2 * zb * wb * e.vb) * dt; e.b += e.vb * dt;
    if (e.lider === "a" && e.a < e.ta - 8) { e.a = e.ta - 8; e.va = -e.va * .3; } else if (e.lider === "b" && e.b > e.tb + 8) { e.b = e.tb + 8; e.vb = -e.vb * .3; }
    var p0 = e.lider === "a" ? pa : pb, p1 = e.lider === "a" ? e.a : e.b, tg = e.lider === "a" ? e.ta : e.tb;
    for (k = 0; k <= e.NF; k++) { var Y = 48 * k; if ((p0 - Y) * (p1 - Y) <= 0 && p0 !== p1) { e.tPaso[k] = T; e.dPaso[k] = p1 > p0 ? 1 : -1; } }
    if (!e.cruzado && (p0 - tg) * (p1 - tg) <= 0) {
        e.cruzado = true; e.tArr = T;
        if (e.breve) { e.pend = !e.sinRemate; e.vg = -1.4; } else { e.tLlegada = T; e.I = 1; e.vg = -3.4; }
    }
    if (e.pend && T - e.tArr > 240) { e.pend = false; e.tLlegada = T; e.I = .75; e.vg = -2; }
    e.vg += (-26 * 26 * e.golpe - 2 * .42 * 26 * e.vg) * dt; e.golpe += e.vg * dt;
    var obj = (!e.cruzado || T - e.tLlegada < 170 || e.pend) ? .92 : sombraReposo;
    e.sombra += (obj - e.sombra) * (1 - Math.exp(-dt / (obj > e.sombra ? .05 : .38)));
    for (k = 0; k < e.NF; k++) { var q = k === e.act ? 1 : 0; e.luz[k] += (q - e.luz[k]) * (1 - Math.exp(-dt / (q ? .05 : .11))); }
    if (Math.abs(e.va) < 1 && Math.abs(e.vb) < 1 && Math.abs(e.a - e.ta) < .05 && Math.abs(e.b - e.tb) < .05 && T >= e.tSeg && e.cruzado && !e.pend &&
        T - e.tLlegada > 1150 && Math.abs(e.golpe) < .002 && Math.abs(e.vg) < .02 && Math.abs(e.sombra - sombraReposo) < .008) {
        e.a = e.ta; e.b = e.tb; e.va = e.vb = 0; e.golpe = e.vg = 0; e.sombra = sombraReposo; for (k = 0; k < e.NF; k++) e.luz[k] = k === e.act ? 1 : 0; e.quieto = true;
    }
}

// cuánto tapa la luna a la fila k (0..1), para el color del kanji
function cubre(e, k) {
    var lo = Math.min(e.a, e.b), hi = Math.max(e.a, e.b), y0 = 48 * k, s0 = Math.max(lo, y0 + 7), s1 = Math.min(hi, y0 + 41);
    return s1 > s0 ? (s1 - s0) / 34 : 0;
}

// geometría: los dos cantos del rombo son una doble hélice que baja por el mango
function xLado(y, lado) { var yl = ((y % 48) + 48) % 48, d = yl < 7 ? 0 : yl < 24 ? (yl - 7) * 20 / 17 : yl < 41 ? (41 - yl) * 20 / 17 : 0; return 28 + lado * d; }
function trazaHilo(c, lo, hi, ox, oy, soloCruces) {
    var r0 = Math.floor(lo / 48), r1 = Math.floor(hi / 48), r, y0, a, b, m, k, j, pts;
    function pinta(p) { for (j = 0; j < p.length; j++) { if (j) c.lineTo(p[j][0], p[j][1]); else c.moveTo(p[j][0], p[j][1]); } }
    if (!soloCruces) for (r = r0; r <= r1; r++) {
        y0 = 48 * r; a = Math.max(lo, y0 + 7); b = Math.min(hi, y0 + 41); if (b - a < .05) continue;
        var arr = a <= y0 + 7.001, aba = b >= y0 + 40.999, ys = [a]; m = y0 + 24; if (m > a && m < b) ys.push(m); ys.push(b);
        var Lp = ys.map(function (y) { return [xLado(y, -1) + ox, y + oy]; }), Rp = ys.map(function (y) { return [xLado(y, 1) + ox, y + oy]; }).reverse();
        c.beginPath();
        if (arr && aba) { pinta(Lp.concat(Rp.slice(1, -1))); c.closePath(); }
        else if (arr) pinta(Rp.concat(Lp.slice(1)));
        else if (aba) pinta(Lp.concat(Rp.slice(1)));
        else { pinta(Lp); pts = Rp; for (j = 0; j < pts.length; j++) { if (j) c.lineTo(pts[j][0], pts[j][1]); else c.moveTo(pts[j][0], pts[j][1]); } }
        c.stroke();
    }
    else for (k = Math.floor((lo + 7) / 48); k <= Math.ceil((hi - 7) / 48); k++) {
        y0 = 48 * k; a = Math.max(lo, y0 - 7); b = Math.min(hi, y0 + 7); if (b - a < .05) continue;
        c.beginPath(); c.moveTo(28 + ox, a + oy); c.lineTo(28 + ox, b + oy); c.stroke();
    }
}
function rombo(c, y0) { c.beginPath(); c.moveTo(28, y0 + 7); c.lineTo(48, y0 + 24); c.lineTo(28, y0 + 41); c.lineTo(8, y0 + 24); c.closePath(); }

// Q = { L: alto del lienzo, eco: [r,g,b], foco: bool, filas: [bool existe por fila] }
function pintaBajo(c, e, T, Q) {
    var u = T - e.tLlegada, I = e.I, i, yc = 48 * e.act + 24;
    if (u < 1200 && I > 0) {
        var rr = 22 + 40 * (1 - Math.exp(-u / 240)), al = .62 * I * Math.exp(-u / 330) * (1 - Math.exp(-u / 50));
        var g = c.createRadialGradient(28, yc, 6, 28, yc, rr); g.addColorStop(0, rgba(Q.eco, al)); g.addColorStop(.55, rgba(Q.eco, al * .45)); g.addColorStop(1, rgba(Q.eco, 0));
        c.fillStyle = g; c.fillRect(0, Math.max(0, yc - rr), 56, rr * 2);
    }
    for (i = 0; i <= e.NF; i++) {
        var tp = e.tPaso[i]; if (tp === undefined || tp === null) continue; var gl = Math.exp(-(T - tp) / 170); if (gl < .02) continue;
        var Y = 48 * i; c.beginPath(); c.moveTo(28, Y - 7); c.lineTo(36.27, Y); c.lineTo(28, Y + 7); c.lineTo(19.73, Y); c.closePath(); c.fillStyle = rgba(ROJOV, .4 * gl); c.fill();
    }
}
function pintaMedio(c, e, T, Q) {
    var i, y0, lo = Math.min(e.a, e.b), hi = Math.max(e.a, e.b), u = T - e.tLlegada, I = e.I;
    var bloom = u < 1200 ? I * Math.exp(-u / 260) * (1 - Math.exp(-u / 40)) : 0;
    // la luna negra: disco de radio 22 que entra por donde llega el hilo, recortado al rombo
    for (i = 0; i < e.NF; i++) {
        y0 = 48 * i; var act = i === e.act, s0 = Math.max(lo, y0 + 7), s1 = Math.min(hi, y0 + 41);
        if (s1 - s0 > .05 && e.sombra > .004) {
            var RD = 22, arr = s0 <= y0 + 7.01, aba = s1 >= y0 + 40.99, dy = arr && aba ? y0 + 24 : arr ? s1 - RD : aba ? s0 + RD : null, sm = e.sombra * (act ? 1 : .62);
            c.save(); c.beginPath(); if (dy === null) c.rect(0, s0, 56, s1 - s0); else c.arc(28, dy, RD, 0, 6.3); c.clip(); rombo(c, y0); c.clip();
            c.fillStyle = rgba(VACIO, sm); c.fillRect(0, y0, 56, 48); c.restore();
        }
    }
    // el nudo viejo se deshilacha
    if (e.fant && T - e.fant.t < 520) {
        var ef = T - e.fant.t; c.save(); c.setLineDash([3.2, .6 + ef / 26]); c.lineDashOffset = -ef / 30; rombo(c, e.fant.y0);
        c.strokeStyle = rgba(ROJO, .55 * Math.exp(-ef / 170)); c.lineWidth = 1.5; c.stroke(); c.restore();
    }
    // chispas de los cruces
    for (i = 0; i <= e.NF; i++) {
        var tq = e.tPaso[i]; if (tq === undefined || tq === null || T - tq > 340) continue; var dq = T - tq, rq = azar(i * 97 + 13), Yq = 48 * i, j;
        for (j = 0; j < 6; j++) {
            var lado = j % 2 ? 1 : -1, vxq = lado * (50 + rq() * 90), vyq = (e.dPaso[i] || 1) * (10 + rq() * 70) - 20, fq = (1 - Math.exp(-dq / 130)) * .13, xq = 28 + vxq * fq, yq = Yq + vyq * fq + 30 * (dq / 1000) * (dq / 1000) * 20;
            var rad = .45 + rq() * .5;
            if (xq < 1 || xq > 55) continue; c.fillStyle = rgba(mez(ALTO, ROJOV, clamp(dq / 200, 0, 1)), 1 - dq / 340); c.beginPath(); c.arc(xq, yq, rad, 0, 6.3); c.fill();
        }
    }
    // el hilo: corona, cruces (por debajo, tenue), filo; sin foco: 1 px al 60 %, corona al 6 %
    c.setLineDash([]); c.lineDashOffset = 0;      // el Canvas de Qt no lo limpia con reset() ni con restore()
    c.lineJoin = "miter"; c.lineCap = "round";
    c.strokeStyle = rgba(ROJO, Q.foco ? .22 + .22 * bloom : .06); c.lineWidth = 7 + 9 * bloom; trazaHilo(c, lo, hi, -.5, .5);
    c.strokeStyle = rgba(ROJO, Q.foco ? .34 : .2); c.lineWidth = 1.4; trazaHilo(c, lo, hi, 0, 0, true);
    c.strokeStyle = rgba(ROJO, Q.foco ? 1 : .6); c.lineWidth = Q.foco ? 2.2 + 1.2 * bloom : 1; trazaHilo(c, lo, hi, 0, 0);
    // la punta al rojo vivo
    var vl = e.lider === "a" ? e.va : e.vb, pl = e.lider === "a" ? e.a : e.b, hot = clamp(Math.abs(vl) / 520, 0, 1);
    if (hot > .03) [-1, 1].forEach(function (s) {
        var x = xLado(pl, s), g2 = c.createRadialGradient(x, pl, 0, x, pl, 6);
        g2.addColorStop(0, rgba(ALTO, .9 * hot)); g2.addColorStop(.3, rgba(ROJOV, .7 * hot)); g2.addColorStop(1, rgba(ROJOV, 0)); c.fillStyle = g2; c.fillRect(x - 6, pl - 6, 12, 12);
    });
}
function pintaSobre(c, e, T, Q) {
    var i, y0, lo = Math.min(e.a, e.b), hi = Math.max(e.a, e.b), u = T - e.tLlegada, I = e.I;
    // borde encendido de la luna (el terminador) mientras no tapa todo el rombo
    for (i = 0; i < e.NF; i++) {
        y0 = 48 * i; var act = i === e.act, s0 = Math.max(lo, y0 + 7), s1 = Math.min(hi, y0 + 41);
        if (s1 - s0 > .05 && e.sombra > .004) {
            var RD = 22, arr = s0 <= y0 + 7.01, aba = s1 >= y0 + 40.99, dy = arr && aba ? y0 + 24 : arr ? s1 - RD : aba ? s0 + RD : null, sm = e.sombra * (act ? 1 : .62);
            if (dy !== null && !(arr && aba)) {
                c.save(); rombo(c, y0); c.clip(); c.beginPath(); c.arc(28, dy, RD, 0, 6.3);
                c.strokeStyle = rgba(ROJOV, .4 * sm); c.lineWidth = 3.5; c.stroke(); c.strokeStyle = rgba(ALTO, .75 * sm); c.lineWidth = .9; c.stroke(); c.restore();
            }
        }
    }
    // brillo que resbala por la seda siguiendo la punta
    var vl = e.lider === "a" ? e.va : e.vb, pl = e.lider === "a" ? e.a : e.b, hot = clamp(Math.abs(vl) / 520, 0, 1);
    if (hot > .03) {
        var gs = c.createLinearGradient(0, pl - 26, 0, pl + 26);
        gs.addColorStop(0, rgba(ALTO, 0)); gs.addColorStop(.5, rgba(mez(ALTO, Q.eco, .5), .16 * hot)); gs.addColorStop(1, rgba(ALTO, 0)); c.fillStyle = gs; c.fillRect(0, pl - 26, 56, 52);
    }
    // el golpe corre por el tejido: dos pulsos que se alejan por los cantos
    if (u < 460 && I > 0) {
        var dq2 = 96 * (1 - Math.exp(-u / 170)), aq = I * .85 * Math.exp(-u / 150) * (1 - Math.exp(-u / 25)), yb0 = 48 * e.act, lim0 = 1, lim1 = Q.L - 1;
        if (aq > .02) {
            c.save(); c.lineCap = "round"; c.lineJoin = "round"; c.strokeStyle = rgba(mez(ALTO, ROJOV, .45), aq); c.lineWidth = 1.7;
            var u0 = Math.max(lim0, yb0 + 7 - dq2 - 16), u1 = Math.max(lim0, yb0 + 7 - dq2), d0 = Math.min(lim1, yb0 + 41 + dq2), d1 = Math.min(lim1, yb0 + 41 + dq2 + 16);
            if (u1 - u0 > .5) { trazaHilo(c, u0, u1, 0, 0); trazaHilo(c, u0, u1, 0, 0, true); }
            if (d1 - d0 > .5) { trazaHilo(c, d0, d1, 0, 0); trazaHilo(c, d0, d1, 0, 0, true); }
            c.restore();
        }
    }
    // anillo de diamante en el vértice donde se cierra
    if (u < 700 && I > 0) {
        var A = I * (u < 55 ? u / 55 : Math.exp(-(u - 55) / 150)), vy = 48 * e.act + (e.dir > 0 ? 41 : 7);
        if (A > .02) {
            var g3 = c.createRadialGradient(28, vy, 0, 28, vy, 9);
            g3.addColorStop(0, rgba(ALTO, .95 * A)); g3.addColorStop(.28, rgba(ROJOV, .6 * A)); g3.addColorStop(1, rgba(ROJOV, 0)); c.fillStyle = g3; c.fillRect(19, vy - 9, 18, 18);
            c.strokeStyle = rgba(ALTO, .85 * A); c.lineWidth = .7; c.beginPath(); c.moveTo(28 - 13 * A, vy); c.lineTo(28 + 13 * A, vy); c.moveTo(28, vy - 6 * A); c.lineTo(28, vy + 6 * A); c.stroke();
        }
    }
}
// ¿hay algo que pintar en los lienzos aditivos? (si no, se dejan vacíos y no se repintan)
function hayBajo(e, T) { if (T - e.tLlegada < 1200 && e.I > 0) return true; for (var i = 0; i <= e.NF; i++) if (e.tPaso[i] !== undefined && e.tPaso[i] !== null && T - e.tPaso[i] < 680) return true; return false; }
