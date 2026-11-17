#version 440
// 11-15 Tsuka v3 mejora 6: tsuba de hueso con veta y cordoncillo en relieve, la incrustación del rombo, y su sombra
// sobre el habaki y sobre el escritorio (caja local 72 x 20); port de estatico2() del prototipo v3 (modo Ahora).
// Corre UNA vez: el Item lo cachea en una capa.
// Compilar: /usr/lib/qt6/bin/qsb --glsl "100 es,120,150,300 es,330" --hlsl 50 --msl 12 -o tsuba.frag.qsb tsuba.frag
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 marco;   // rgb 0-1
};
// ── común (copiado en cada sombreador del material v3; qsb no tiene #include) ──
float hash12(vec2 p) { vec3 p3 = fract(vec3(p.xyx) * .1031); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.x + p3.y) * p3.z); }
float ruido(vec2 p) { vec2 i = floor(p), f = fract(p), u = f * f * (3. - 2. * f);
    return mix(mix(hash12(i), hash12(i + vec2(1., 0.)), u.x), mix(hash12(i + vec2(0., 1.)), hash12(i + vec2(1., 1.)), u.x), u.y); }
float gs(float x, float s) { return exp(-x * x / (2. * s * s)); }
float sdR(vec2 p, vec2 c, vec2 h, float r) { vec2 q = abs(p - c) - h + r; return min(max(q.x, q.y), 0.) + length(max(q, 0.)) - r; }
const vec3 LUZ = vec3(-.5, -.62, .6);
vec4 sobre(vec4 o, vec3 c, float a) { return vec4(c * a + o.rgb * (1. - a), a + o.a * (1. - a)); }   // premultiplicado
void main() {
    vec2 p = qt_TexCoord0 * vec2(72., 20.);
    vec4 o = vec4(0.);
    if (p.x > 3. && p.x < 53. && p.y < 2.) o = vec4(marco.rgb * .5, 1.);
    if (p.x > 4. && p.x < 52. && p.y > 10. && p.y < 12.) o = vec4(marco.rgb * .36, 1.);
    if (sdR(p, vec2(30., 6.), vec2(42., 4.), 3.) <= 0.) {
        float yy = p.y - 2., t = yy / 8.;
        vec3 col = t < .3 ? mix(vec3(255., 250., 240.), vec3(239., 230., 216.), t / .3) : t < .8 ? mix(vec3(239., 230., 216.), vec3(201., 192., 178.), (t - .3) / .5) : mix(vec3(201., 192., 178.), vec3(143., 136., 124.), (t - .8) / .2);
        col /= 255.;
        float k = (1. + (ruido(vec2(p.x * .3, yy * 2.6)) - .5) * .12) * (p.x < 58. && t > .45 ? 1. + .1 * sin((p.x - yy * .75) * 1.57) : 1.) * (1. - .4 * smoothstep(68.5, 72., p.x)) + .07 * gs(t - .12, .08);
        float dq = abs(p.x - 64.) + abs(yy - 4.);
        o = vec4(dq < 2.6 ? (dq > 1.95 ? col * .55 : vec3(12., 14., 18.) / 255.) : col * k, 1.);
    }
    if (p.x > 5. && p.x < 51. && p.y > 12. && p.y < 17.) o = sobre(o, vec3(0.), .55 * (1. - (p.y - 12.) / 5.));
    if (p.x > 54. && p.x < 71. && p.y > 10. && p.y < 19.) o = sobre(o, vec3(0.), .4 * (1. - (p.y - 10.) / 9.));
    fragColor = o * qt_Opacity;
}
