.pragma library

// 11-15 Tsuka v3 (propuesta de Fable, modo "Ahora"; aprobada por Ovi): lo que se pinta con Canvas del material nuevo
// (ojo vivo y gemas talladas). Port de tsuka-saya-v3.html (commit 2fe5f8a de /mnt/Compartido/Nero/diseno-fable/tsuka-saya-v3),
// mismas coordenadas y fórmulas. Lo que en el prototipo es pixel por pixel (herrajes, piel, habaki, tsuba) va en
// sombreadores (*.frag) que corren UNA vez (Pieza.qml): escribir pixeles desde el JS de Qt (CanvasImageData) dispara
// tormentas del recolector de basura (medido en el banco: 10 s de CPU al arrancar y a veces 100 % sin fin).
// C = Mat.mango(...): { base: tela [r,g,b], marco: [r,g,b], ... }.

var HUESO = [239, 230, 216], ALTO = [255, 250, 240], TINTA = [12, 14, 18];

function clamp(v, a, b) { return v < a ? a : v > b ? b : v; }
function mix(a, b, t) { return a + (b - a) * t; }
function mez(a, b, t) { return [mix(a[0], b[0], t), mix(a[1], b[1], t), mix(a[2], b[2], t)]; }
function esc(c, k) { return [c[0] * k, c[1] * k, c[2] * k]; }
function rgba(c, a) { return 'rgba(' + Math.round(clamp(c[0], 0, 255)) + ',' + Math.round(clamp(c[1], 0, 255)) + ',' + Math.round(clamp(c[2], 0, 255)) + ',' + (a === undefined || a === null ? 1 : +a.toFixed(3)) + ')'; }
// color de QML -> [r, g, b] 0-255
function deColor(q) { return [q.r * 255, q.g * 255, q.b * 255]; }

// ──────── mejora 2 (el ojo) ────────
// ════════ 2 · el ojo de Nero, vivo (caja del ojo 56 x 44; ctx ya trasladado a ella) ════════
// o = { a: apertura, x, y: mirada, p: pupila, eco, marco (arrays), parpado: 0 reposo · 1 despierto (hacia hueso) · -1 dormido }
function almendra(ctx, a) { ctx.beginPath(); ctx.moveTo(5, 22); ctx.quadraticCurveTo(28, 30 - 32 * a, 51, 22); ctx.quadraticCurveTo(28, 30 + 16 * a, 5, 22); ctx.closePath(); }
// su resplandor sobre el pomo (se compone en modo aditivo; la opacidad sigue a la apertura)
function ojoLuz(ctx, eco) {
    var g = ctx.createRadialGradient(28, 22, 3, 28, 22, 27); g.addColorStop(0, rgba(eco, .2)); g.addColorStop(1, rgba(eco, 0));
    ctx.fillStyle = g; ctx.fillRect(0, -6, 56, 56);
}
function ojo(ctx, o) {
    var a = o.a, ix = 28 + o.x, iy = 22 + o.y, i, g, E = o.eco, pp = o.p || 1;
    // la cuenca: hundida en el metal
    almendra(ctx, a); ctx.fillStyle = '#020305'; ctx.fill();
    if (a > .005) {
        ctx.save(); almendra(ctx, a); ctx.clip(); ctx.globalAlpha = Math.min(1, 4 * a);
        g = ctx.createRadialGradient(28, 23, 2, 28, 23, 25); g.addColorStop(0, rgba(mez(E, HUESO, .4), .16)); g.addColorStop(1, rgba(E, 0)); ctx.fillStyle = g; ctx.fillRect(0, 0, 56, 44);
        // iris con anillo oscuro
        g = ctx.createRadialGradient(ix, iy, 2.4, ix, iy, 9.6);
        g.addColorStop(0, rgba(esc(E, .22))); g.addColorStop(.3, rgba(esc(E, .7))); g.addColorStop(.62, rgba(mez(E, ALTO, .3))); g.addColorStop(.86, rgba(esc(E, .42))); g.addColorStop(1, '#04050a');
        ctx.fillStyle = g; ctx.beginPath(); ctx.arc(ix, iy, 9.6, 0, 6.2832); ctx.fill();
        // fibras
        ctx.lineWidth = .45;
        for (i = 0; i < 30; i++) {
            var an = i * 6.2832 / 30 + .3 * Math.sin(i * 7.1), r0 = 3.6 + .6 * Math.sin(i * 3.3), r1 = 8.5 - .9 * Math.abs(Math.sin(i * 1.7));
            ctx.beginPath(); ctx.moveTo(ix + Math.cos(an) * r0, iy + Math.sin(an) * r0); ctx.lineTo(ix + Math.cos(an) * r1, iy + Math.sin(an) * r1);
            ctx.strokeStyle = i % 2 ? rgba(ALTO, .22) : 'rgba(0,0,0,.3)'; ctx.stroke();
        }
        // la luz que entra por abajo
        ctx.save(); ctx.beginPath(); ctx.arc(ix, iy, 9.2, 0, 6.2832); ctx.clip(); ctx.globalCompositeOperation = 'lighter';
        g = ctx.createRadialGradient(ix + 3.4, iy + 3.8, 0, ix + 3.4, iy + 3.8, 6); g.addColorStop(0, rgba(mez(E, ALTO, .5), .55)); g.addColorStop(1, rgba(E, 0));
        ctx.fillStyle = g; ctx.fillRect(ix - 10, iy - 10, 20, 20); ctx.restore();
        // pupila honda y brillo húmedo
        ctx.fillStyle = '#010102'; ctx.beginPath(); ctx.arc(ix, iy, 3.3 * pp, 0, 6.2832); ctx.fill();
        ctx.save(); ctx.translate(ix - 3, iy - 3.5); ctx.rotate(-.6); ctx.scale(2, 1.25); ctx.beginPath(); ctx.arc(0, 0, 1, 0, 6.2832); ctx.fillStyle = rgba(ALTO, .95); ctx.fill(); ctx.restore();
        ctx.fillStyle = rgba(ALTO, .5); ctx.beginPath(); ctx.arc(ix + 2.7, iy + 2.4, .6, 0, 6.2832); ctx.fill();
        // sombra del párpado sobre el ojo
        var yt = 26 - 16 * a; g = ctx.createLinearGradient(0, yt, 0, yt + 7.5); g.addColorStop(0, 'rgba(0,0,0,.85)'); g.addColorStop(1, 'rgba(0,0,0,0)'); ctx.fillStyle = g; ctx.fillRect(0, yt - 2, 56, 10);
        ctx.restore();
    }
    // párpado de metal con volumen
    var M = o.parpado > 0 ? mez(o.marco, HUESO, .45) : o.parpado < 0 ? esc(o.marco, .6) : o.marco;
    g = ctx.createLinearGradient(0, 8, 0, 26); g.addColorStop(0, rgba(mez(M, ALTO, .2))); g.addColorStop(1, rgba(esc(M, .5)));
    ctx.lineCap = 'round';
    ctx.beginPath(); ctx.moveTo(3.5, 23.2); ctx.quadraticCurveTo(28, 30 - 32 * a, 52.5, 23.2); ctx.strokeStyle = 'rgba(0,0,0,.6)'; ctx.lineWidth = 3.4; ctx.stroke();
    ctx.beginPath(); ctx.moveTo(3.5, 22.6); ctx.quadraticCurveTo(28, 30 - 32 * a - .6, 52.5, 22.6); ctx.strokeStyle = g; ctx.lineWidth = 2; ctx.stroke();
    ctx.beginPath(); ctx.moveTo(5, 22); ctx.quadraticCurveTo(28, 30 + 16 * a, 51, 22); ctx.strokeStyle = rgba(esc(M, .55)); ctx.lineWidth = 1; ctx.stroke();
}
// ──────── fin de la mejora 2 ────────

// ──────── mejora 4 (las gemas) ────────
// ════════ 4 · gemas talladas (caja local 56 x 48, centro 28,24) ════════
function rombo2(ctx, cy, rx, ry) { ctx.beginPath(); ctx.moveTo(28, cy - ry); ctx.lineTo(28 + rx, cy); ctx.lineTo(28, cy + ry); ctx.lineTo(28 - rx, cy); ctx.closePath(); }
// la luz de la gema encendida sobre la piel (se compone en modo aditivo)
function gemaLuz(ctx, col) {
    ctx.save(); rombo2(ctx, 24, 20, 17); ctx.clip();
    var gl = ctx.createRadialGradient(28, 24, 4, 28, 24, 23); gl.addColorStop(0, rgba(col, .5)); gl.addColorStop(1, rgba(col, 0));
    ctx.fillStyle = gl; ctx.fillRect(0, 0, 56, 48); ctx.restore();
}
// engaste de metal oscuro con sombra, corona de 8 facetas y mesa; encendida = color propio; apagada = piedra oscura de la tela
// (sin el destello en cruz: 2fe5f8a)
// 11-17 «A · Brasa» (diseno-fable/gemas-legibles): encendida = mesa más grande (k .6) de piedra honda del mismo color,
// borde ALTO .5 / .6 y reflejo .1, para que el símbolo claro (Gema.qml) se lea encima. Apagada igual que antes.
function gema(ctx, on, col, C) {
    var cy = 24, O = [[28, cy - 12], [42, cy], [28, cy + 12], [14, cy]], B = C.base, M = C.marco, i;
    rombo2(ctx, cy + .9, 17, 14.8); ctx.fillStyle = 'rgba(0,0,0,.6)'; ctx.fill();
    var ge = ctx.createLinearGradient(14, cy - 12, 42, cy + 12);
    ge.addColorStop(0, rgba(mez(esc(B, 1.5), M, .25))); ge.addColorStop(.5, rgba(esc(B, .6))); ge.addColorStop(1, rgba(esc(B, .3)));
    rombo2(ctx, cy, 16.2, 14); ctx.fillStyle = ge; ctx.fill(); rombo2(ctx, cy, 14, 12); ctx.fillStyle = 'rgba(0,0,0,.7)'; ctx.fill();
    var Tm = O.map(function (p) { return [28 + (p[0] - 28) * .6, cy + (p[1] - cy) * .6]; }), br = [.5, .16, .06, .92];
    var osc = on ? esc(col, .12) : esc(B, .16), cla = on ? mez(col, ALTO, .45) : mez(esc(B, 1.25), M, .12);
    for (i = 0; i < 4; i++) {
        var a = O[i], b = O[(i + 1) % 4], ta = Tm[i], tb = Tm[(i + 1) % 4], m = [(a[0] + b[0]) / 2, (a[1] + b[1]) / 2], mt = [(ta[0] + tb[0]) / 2, (ta[1] + tb[1]) / 2];
        [[a, m, mt, ta, 1.08], [m, b, tb, mt, .8]].forEach(function (t) {
            ctx.beginPath(); ctx.moveTo(t[0][0], t[0][1]); ctx.lineTo(t[1][0], t[1][1]); ctx.lineTo(t[2][0], t[2][1]); ctx.lineTo(t[3][0], t[3][1]); ctx.closePath();
            ctx.fillStyle = rgba(mez(osc, cla, clamp(br[i] * t[4], 0, 1))); ctx.fill();
        });
    }
    var gm = ctx.createLinearGradient(Tm[3][0], Tm[0][1], Tm[1][0], Tm[2][1]);
    gm.addColorStop(0, rgba(on ? esc(col, .4) : esc(B, 1.05))); gm.addColorStop(.5, rgba(on ? esc(col, .22) : esc(B, .5))); gm.addColorStop(1, rgba(on ? esc(col, .1) : esc(B, .22)));
    function mesa() { ctx.beginPath(); Tm.forEach(function (p, j) { if (j) ctx.lineTo(p[0], p[1]); else ctx.moveTo(p[0], p[1]); }); ctx.closePath(); }
    mesa(); ctx.fillStyle = gm; ctx.fill(); ctx.strokeStyle = on ? rgba(ALTO, .5) : 'rgba(0,0,0,.4)'; ctx.lineWidth = on ? .6 : .4; ctx.stroke();
    ctx.save(); mesa(); ctx.clip(); ctx.beginPath(); ctx.moveTo(20, cy + 4); ctx.lineTo(32, cy - 8); ctx.strokeStyle = rgba(ALTO, on ? .1 : .08); ctx.lineWidth = 2; ctx.stroke(); ctx.restore();
}
// ──────── fin de la mejora 4 ────────
