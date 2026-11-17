#version 440
// 11-15 Tsuka v3 mejora 6: habaki limado en diagonal (neko-gaki) con sus dos cuerpos, del color del marco, y su
// sombra; port de estatico2() del prototipo v3 (modo Ahora). Corre UNA vez: el Item lo cachea en una capa.
// Compilar: /usr/lib/qt6/bin/qsb --glsl "100 es,120,150,300 es,330" --hlsl 50 --msl 12 -o habaki.frag.qsb habaki.frag
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 caja;    // x0, y0, ancho, alto (unidades de la barra)
    vec4 marco;   // rgb 0-1; w = hab0
};
// ── común (copiado en cada sombreador del material v3; qsb no tiene #include) ──
float hash12(vec2 p) { vec3 p3 = fract(vec3(p.xyx) * .1031); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.x + p3.y) * p3.z); }
float ruido(vec2 p) { vec2 i = floor(p), f = fract(p), u = f * f * (3. - 2. * f);
    return mix(mix(hash12(i), hash12(i + vec2(1., 0.)), u.x), mix(hash12(i + vec2(0., 1.)), hash12(i + vec2(1., 1.)), u.x), u.y); }
float gs(float x, float s) { return exp(-x * x / (2. * s * s)); }
float sdR(vec2 p, vec2 c, vec2 h, float r) { vec2 q = abs(p - c) - h + r; return min(max(q.x, q.y), 0.) + length(max(q, 0.)) - r; }
const vec3 LUZ = vec3(-.5, -.62, .6);
void main() {
    vec2 p = caja.xy + qt_TexCoord0 * caja.zw;
    float hy = marco.w - 6., hb = marco.w + 20.;
    vec4 o = vec4(0.);
    if (p.x > 8. && p.x < 48. && p.y > hb && p.y < hb + 3.) o = vec4(0., 0., 0., .5);
    float t = (p.y - hy) / 26., xl = 6. + 1.5 * t, xr = 50. - 1.5 * t;
    if (p.y >= hy - .5 && p.y <= hb + .5 && p.x >= xl - .5 && p.x <= xr + .5) o = vec4(vec3(42., 45., 56.) / 255., 1.);
    if (p.y >= hy && p.y <= hb && p.x >= xl && p.x <= xr) {
        float u = (p.x - xl) / (xr - xl);
        float v = (.1 + .34 * gs(u - .3, .12) + .1 * gs(u - .66, .18)) * (1. - .62 * pow(abs(2. * u - 1.), 3.)) * (.72 + .28 * pow(.5 + .5 * sin((p.x * .9 + p.y * 1.5) * 2.1), 2.)) * (p.y > hy + 9.5 ? .8 : 1.)
            - .12 * gs(p.y - (hy + 9.8), .45) + .07 * gs(p.y - (hy + 1.2), .5) - .08 * gs(p.y - hb, .8);
        o = vec4(marco.rgb * (.16 + 1.25 * v), 1.);
    }
    fragColor = vec4(o.rgb * o.a, o.a) * qt_Opacity;
}
