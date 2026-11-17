#version 440
// 11-15 Saya v3, mejora 8: la vaina de laca honda (port de laca() / pintaVaina() en modo "Ahora" de
// /mnt/Compartido/Nero/diseno-fable/tsuka-saya-v3/tsuka-saya-v3.html). Lienzo de 16 x largo: la vaina va en
// x 8..16; a la izquierda sobresalen el pasador (3 px) y la sombra del hueco de la incrustación.
// Corre UNA vez: el ShaderEffect tiene layer.enabled y solo se vuelve a pintar si cambia un uniforme
// (colores del fondo o geometría). 2 x 2 muestras por pixel.
// Compilar: /usr/lib/qt6/bin/qsb --glsl "100 es,120,150,300 es,330" --hlsl 50 --msl 12 -o vaina.frag.qsb vaina.frag
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 tam;       // 16 x largo (unidades lógicas)
    float dpr;
    float t0;       // arriba de la boca
    float largo;
    float punta;
    float pc;       // centro del pasador (Suena)
    float lc;       // centro de la incrustación (Luz)
    vec4 base;      // tela oscura del fondo (0-1)
    vec4 marco;     // marco clarito del fondo
    vec4 eco;       // eco del monitor
};

float hash2(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}
float ruido(vec2 p) {
    vec2 i = floor(p), f = p - i, u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash2(i), hash2(i + vec2(1.0, 0.0)), u.x), mix(hash2(i + vec2(0.0, 1.0)), hash2(i + vec2(1.0, 1.0)), u.x), u.y);
}
float gs(float x, float s) { return exp(-x * x / (2.0 * s * s)); }
float sdR(vec2 p, vec2 c, vec2 hw, float r) {
    vec2 q = abs(p - c) - hw + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}
float sdP(vec2 p) { return sdR(p, vec2(10.5, pc), vec2(5.5, 12.0), 3.0); }

// metal del pasador: más oscuro que la tela y teñido con ella; canto redondeado y pulido, satinado
vec3 metal(vec2 p, float d) {
    vec3 LUZ = vec3(-0.5, -0.62, 0.6);
    float e = -d, u = p.x / 56.0, v, dif;
    float gx = (sdP(p + vec2(0.3, 0.0)) - sdP(p - vec2(0.3, 0.0))) / 0.6;
    float gy = (sdP(p + vec2(0.0, 0.3)) - sdP(p - vec2(0.0, 0.3))) / 0.6;
    if (e < 2.6) {
        float t = e / 2.6, nz = sin(t * 1.5708), nq = cos(t * 1.5708);
        dif = max(0.0, nq * (gx * LUZ.x + gy * LUZ.y) + nz * LUZ.z);
        v = 0.06 + 0.26 * dif + 0.34 * pow(dif, 9.0);
    } else if (e < 3.3) {
        v = 0.035;
    } else {
        v = 0.1 + (ruido(vec2(p.x * 2.2, p.y * 0.05)) - 0.5) * 0.05 + 0.05 * gs(u - 0.36, 0.1);
    }
    v *= 1.0 - 0.6 * pow(abs(2.0 * u - 1.0), 2.4);
    v += 0.035 * gs(u - 0.34, 0.08);
    float k = 0.2 + 1.7 * v, m = clamp(v * 1.1 - 0.35, 0.0, 0.3);
    return mix(base.rgb * k, marco.rgb, m);
}

// laca honda: reflejo largo que toma el eco y se interrumpe a tramos + motas de polvo de hueso bajo el barniz
vec3 laca(vec2 p, float u) {
    float v = 0.02 + 0.55 * gs(u - 0.3, 0.07) * (0.45 + 0.55 * smoothstep(0.2, 0.7, ruido(vec2(2.2, p.y / 60.0)))) + 0.13 * gs(u - 0.46, 0.22);
    vec3 c = mix(vec3(205.0, 210.0, 222.0) / 255.0, eco.rgb, 0.55);
    float f = hash2(floor(p * 2.5)) > 0.988 ? 60.0 / 255.0 : 0.0;
    return vec3(5.0, 6.0, 9.0) / 255.0 + c * v + f * vec3(1.0, 0.95, 0.85);
}

vec4 muestra(vec2 p) {
    const float X = 8.0;
    float d = sdP(p);
    if (d <= 0.0)
        return vec4(metal(p, d), 1.0);
    vec4 o = vec4(0.0);     // premultiplicado
    float lx = p.x - X, L = largo, P = punta;
    if (p.x >= X && p.y >= t0 && p.y <= L && !(p.y > L - P && lx < (p.y - (L - P)) * 8.0 / P)) {
        vec3 c;
        if (p.y < t0 + 16.0) {
            // boca de cuerno con su veta
            float t = (p.y - t0) / 16.0, sv = 1.0 + 0.13 * sin(lx * 5.5 + 2.0 * ruido(vec2(p.x * 0.7, p.y * 0.3)));
            float k = (1.0 - 0.5 * t) * sv * (0.75 + 0.5 * gs(lx / 8.0 - 0.35, 0.25));
            c = vec3(179.0, 168.0, 150.0) / 255.0 * k;
        } else if (p.y > L - P - 26.0) {
            // contera: metal teñido con la tela
            float v = 0.1 + 0.5 * gs(lx / 8.0 - 0.38, 0.2) - 0.12 * gs(p.y - (L - P - 25.0), 0.6);
            c = base.rgb * (0.28 + 2.5 * v);
        } else {
            c = laca(p, lx / 8.0);
        }
        if (p.y >= t0 + 16.0 && p.y < t0 + 17.0)
            c *= 0.4;   // la junta oscura bajo la boca
        o = vec4(c, 1.0);
    }
    // el hueco donde va hundida la incrustación de las luces (negro al 70 %)
    if (p.x >= X - 0.5 && p.x < X + 8.5 && p.y >= lc - 3.5 && p.y < lc + 3.5)
        o = o * 0.3 + vec4(0.0, 0.0, 0.0, 0.7);
    return o;
}

void main() {
    vec2 p = qt_TexCoord0 * tam, h = vec2(0.25 / max(dpr, 1.0));
    vec4 c = 0.25 * (muestra(p + vec2(-h.x, -h.y)) + muestra(p + vec2(h.x, -h.y)) + muestra(p + vec2(-h.x, h.y)) + muestra(p + vec2(h.x, h.y)));
    fragColor = c * qt_Opacity;
}
