#version 440
// 11-15 Saya v3, mejora 9: el bloque desenvainado en nashiji (port de pintaBloque() en modo "Ahora" de
// /mnt/Compartido/Nero/diseno-fable/tsuka-saya-v3/tsuka-saya-v3.html): laca honda teñida apenas con la tela del
// monitor, escamas de hueso y de metal dorado a tres profundidades bajo el barniz, dos reflejos diagonales, canto
// de luz en el borde, divisiones talladas (surco oscuro + canto) y el corte de abajo a la izquierda.
// Sirve también para la lengüeta del OSD (64 px): y0 = desde qué y del bloque empieza, para que sea el mismo material.
// Corre UNA vez: layer.enabled en el ShaderEffect; se repinta solo si cambia un uniforme. 2 x 2 muestras por pixel.
// Compilar: /usr/lib/qt6/bin/qsb --glsl "100 es,120,150,300 es,330" --hlsl 50 --msl 12 -o nashiji.frag.qsb nashiji.frag
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 tam;       // ancho x alto (unidades lógicas)
    float dpr;
    float corte;    // 16
    float y0;       // y del bloque completo donde empieza este lienzo
    vec4 divs;      // y de los surcos (en este lienzo); < 0 = sin surco
    vec4 base;      // tela oscura del fondo (0-1)
    vec4 marco;     // marco clarito del fondo
};

float hash2(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}
float gs(float x, float s) { return exp(-x * x / (2.0 * s * s)); }

vec3 nashiji(vec2 p) {
    float W = tam.x, x = p.x, y = p.y + y0, u = x / 148.0, dg = (x + y * 0.55) / 260.0;
    float v = 0.03 + 0.05 * gs(u - 0.05, 0.1) + 0.06 * gs(dg - 0.42, 0.07) + 0.025 * gs(dg - 0.8, 0.12) - 0.02 * smoothstep(0.6, 1.0, x / W);
    vec3 tb = mix(base.rgb, vec3(12.0, 14.0, 18.0) / 255.0, 0.82);
    vec3 c = (vec3(12.0, 14.0, 18.0) / 255.0 + vec3(150.0, 150.0, 165.0) / 255.0 * v) * 0.6 + tb * 0.9;
    vec3 es = mix(marco.rgb, vec3(220.0, 186.0, 120.0) / 255.0, 0.6), hueso = vec3(239.0, 230.0, 216.0) / 255.0;
    // escamas a tres profundidades (finas y brillantes arriba, grandes y hondas abajo)
    for (int k = 0; k < 3; k++) {
        float fk = float(k);
        float gsz = k == 0 ? 4.2 : (k == 1 ? 6.5 : 10.0);
        float umb = k == 0 ? 0.07 : (k == 1 ? 0.1 : 0.13);
        float ra = k == 0 ? 0.5 : (k == 1 ? 0.85 : 1.5);
        float bri = k == 0 ? 0.8 : (k == 1 ? 0.42 : 0.2);
        vec2 ce = floor(vec2(x, y) / gsz);
        if (hash2(ce + vec2(fk * 37.0, fk * 11.0)) > umb)
            continue;
        vec2 cc = (ce + 0.15 + 0.7 * vec2(hash2(ce + vec2(3.0, fk)), hash2(ce + vec2(fk, 7.0)))) * gsz;
        float rad = ra * (0.6 + 0.8 * hash2(ce + vec2(13.0, 5.0))), an = hash2(ce + vec2(0.0, 9.0)) * 3.14;
        vec2 dd = vec2(x, y) - cc;
        float ca = cos(an), sa = sin(an);
        vec2 e = vec2(dd.x * ca + dd.y * sa, (-dd.x * sa + dd.y * ca) * 1.7);
        float q = length(e) / rad;
        if (q < 1.0) {
            float br = pow(1.0 - q * q, 1.5) * bri * (0.35 + 0.65 * hash2(ce + vec2(21.0, 2.0)));
            c += (hash2(ce + vec2(2.0, 31.0)) > 0.35 ? es : hueso) * br;
        }
    }
    return c;
}

vec4 sobre(vec4 o, vec3 c, float a) { return vec4(c * a, a) + o * (1.0 - a); }

vec4 muestra(vec2 p) {
    float W = tam.x, H = tam.y;
    if (p.y > H - corte && p.x < p.y - (H - corte))
        return vec4(0.0);
    vec4 o = vec4(nashiji(p), 1.0);
    // canto de luz en el borde (toma el marco) y la sombra hacia el lado del monitor
    if (p.x < 5.0) {
        float t = p.x / 5.0;
        o = sobre(o, marco.rgb, t < 0.3 ? mix(0.5, 0.12, t / 0.3) : mix(0.12, 0.0, (t - 0.3) / 0.7));
    }
    if (p.x > W - 26.0)
        o = sobre(o, vec3(0.0), 0.5 * (p.x - (W - 26.0)) / 26.0);
    // divisiones talladas: surco oscuro y su canto debajo
    if (p.x >= 14.0 && p.x < W - 14.0) {
        for (int i = 0; i < 4; i++) {
            float d = divs[i];
            if (d < 0.0)
                continue;
            if (p.y >= d && p.y < d + 1.0)
                o = sobre(o, vec3(0.0), 0.55);
            else if (p.y >= d + 1.0 && p.y < d + 2.0)
                o = sobre(o, marco.rgb, 0.1);
        }
    }
    return o;
}

void main() {
    vec2 p = qt_TexCoord0 * tam, h = vec2(0.25 / max(dpr, 1.0));
    vec4 c = 0.25 * (muestra(p + vec2(-h.x, -h.y)) + muestra(p + vec2(h.x, -h.y)) + muestra(p + vec2(-h.x, h.y)) + muestra(p + vec2(h.x, h.y)));
    fragColor = c * qt_Opacity;
}
