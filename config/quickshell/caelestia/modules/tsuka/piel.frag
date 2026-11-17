#version 440
// 11-15 Tsuka v3 mejora 3: piel de raya de verdad (port de pielAhora() del prototipo v3): nódulos nacarados, cada uno una
// cupulita con su brillo, algunos más grandes; solo dentro de los rombos de las filas que se ven. Va DEBAJO de la tela
// (que deja esos rombos transparentes). Corre UNA vez: el Item lo cachea en una capa.
// Compilar: /usr/lib/qt6/bin/qsb --glsl "100 es,120,150,300 es,330" --hlsl 50 --msl 12 -o piel.frag.qsb piel.frag
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 caja;    // x0, y0, ancho, alto (coordenadas de la tela: y = 0 en cord0)
    vec4 filas;   // N filas, primera fila del menuki, filas del menuki
    vec4 fondo;   // hueco entre nódulos: la piel teñida con la tela (rgb 0-1)
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
    float fila = floor(p.y / 48.), yl = p.y - 48. * fila;
    bool tapada = filas.z > 0. && fila >= filas.y && fila < filas.y + filas.z;
    if (fila < 0. || fila >= filas.x || tapada || abs(p.x - 28.) / 21.5 + abs(yl - 24.) / 18.5 > 1.) { fragColor = vec4(0.); return; }
    float g = 2.35, F = 9.; vec2 c0 = floor(p / g), bxy = vec2(0.);
    for (int j = -1; j <= 1; j++) for (int i = -1; i <= 1; i++) {
        vec2 ab = c0 + vec2(float(i), float(j));
        vec2 c = (ab + .2 + .6 * vec2(hash12(ab), hash12(ab + vec2(31., 17.)))) * g;
        float r = g * (.36 + .2 * hash12(ab + vec2(5., 3.))) * (hash12(ab + vec2(9., 2.)) > .93 ? 1.65 : 1.);
        vec2 dd = (p - c) / r; float f = dot(dd, dd);
        if (f < F) { F = f; bxy = dd; }
    }
    vec3 col;
    if (F >= 1.) col = fondo.rgb * (.7 + .3 * ruido(p * 1.3));
    else {
        float nz = sqrt(1. - F), dif = max(0., bxy.x * LUZ.x + bxy.y * LUZ.y + nz * LUZ.z), v = .1 + .42 * dif + .55 * pow(dif, 14.);
        col = vec3(214., 204., 186.) / 255. * v;
    }
    fragColor = vec4(col, 1.) * qt_Opacity;
}
