#version 440
// 11-15 Tsuka v3 mejora 1: herrajes de metal (pomo, dōgane, fuchi). Port de metal() del prototipo v3 (modo Ahora):
// canto redondeado y pulido que toma la luz, surco, fondo de nanako (granitos) o satinado; más oscuro que la tela,
// teñido con ella; sin líneas claras. Corre UNA vez: el Item lo cachea en una capa (layer) y no cambia en reposo.
// Compilar: /usr/lib/qt6/bin/qsb --glsl "100 es,120,150,300 es,330" --hlsl 50 --msl 12 -o herraje.frag.qsb herraje.frag
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 caja;    // x0, y0, ancho, alto de la pieza (unidades de la barra)
    vec4 forma;   // centro x, centro y, medio ancho, medio alto del rectángulo redondeado
    vec4 radios;  // radio arriba, radio abajo, nanako desde y, nanako hasta y
    vec4 base;    // tela del monitor (rgb 0-1)
    vec4 marco;   // marco del monitor (rgb 0-1)
    vec4 extra;   // x: y de los remaches (0 = sin), y: 1 = cartela del título, z: 1 = nanako en todo
};
// ── común (copiado en cada sombreador del material v3; qsb no tiene #include) ──
float hash12(vec2 p) { vec3 p3 = fract(vec3(p.xyx) * .1031); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.x + p3.y) * p3.z); }
float ruido(vec2 p) { vec2 i = floor(p), f = fract(p), u = f * f * (3. - 2. * f);
    return mix(mix(hash12(i), hash12(i + vec2(1., 0.)), u.x), mix(hash12(i + vec2(0., 1.)), hash12(i + vec2(1., 1.)), u.x), u.y); }
float gs(float x, float s) { return exp(-x * x / (2. * s * s)); }
float sdR(vec2 p, vec2 c, vec2 h, float r) { vec2 q = abs(p - c) - h + r; return min(max(q.x, q.y), 0.) + length(max(q, 0.)) - r; }
const vec3 LUZ = vec3(-.5, -.62, .6);
float sd(vec2 p) { return sdR(p, forma.xy, forma.zw, p.y < forma.y ? radios.x : radios.y); }
void main() {
    vec2 p = caja.xy + qt_TexCoord0 * caja.zw;
    float d = sd(p);
    if (d > 0.) { fragColor = vec4(0.); return; }
    float e = -d, u = p.x / 56., v, dif;
    vec2 gr = vec2(sd(p + vec2(.3, 0.)) - sd(p - vec2(.3, 0.)), sd(p + vec2(0., .3)) - sd(p - vec2(0., .3))) / .6;
    bool grano = extra.z > .5 || (p.y > radios.z && p.y < radios.w);
    if (e < 2.6) {
        float t = e / 2.6, nz = sin(t * 1.5708), nq = cos(t * 1.5708);
        dif = max(0., nq * (gr.x * LUZ.x + gr.y * LUZ.y) + nz * LUZ.z); v = .06 + .26 * dif + .34 * pow(dif, 9.);
    } else if (e < 3.3) v = .035;
    else if (grano) {
        float pp = 2.7, row = floor(p.y / (pp * .866) + .5), xo = mod(row, 2.) * pp / 2.;
        float cx = floor((p.x - xo) / pp + .5) * pp + xo, cy = row * pp * .866;
        vec2 r = (p - vec2(cx, cy)) / (pp * .5); float rr = dot(r, r);
        if (rr < 1.) { float nz2 = sqrt(1. - rr); dif = max(0., r.x * LUZ.x + r.y * LUZ.y + nz2 * LUZ.z); v = .05 + .17 * dif + .16 * pow(dif, 10.); } else v = .028;
    } else v = .1 + (ruido(vec2(p.x * 2.2, p.y * .05)) - .5) * .05 + .05 * gs(u - .36, .1);
    v *= 1. - .6 * pow(abs(2. * u - 1.), 2.4); v += .035 * gs(u - .34, .08);
    float k = .2 + 1.7 * v, m = clamp(v * 1.1 - .35, 0., .3);
    vec3 c = mix(base.rgb * k, marco.rgb, m);
    // remaches del pomo (degradado radial: claro arriba a la izquierda)
    if (extra.x > 0.) for (int i = 0; i < 2; i++) {
        vec2 rc = vec2(i == 0 ? 9.5 : 46.5, extra.x);
        if (distance(p, rc) < 1.7) c = mix(mix(base.rgb * 1.9, marco.rgb, .3), base.rgb * .3, clamp(distance(p, rc - vec2(.5, .6)) / 1.9, 0., 1.));
    }
    // cartela lisa hundida para el título (rgba(0,0,0,.42))
    if (extra.y > .5) {
        float dh = forma.w * 2.;
        if (sdR(p, vec2(28.5, forma.y), vec2(8., (dh - 18.) / 2.), 3.) < 0.) c *= .58;
    }
    fragColor = vec4(c, 1.) * qt_Opacity;
}
