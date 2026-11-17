#version 440
// 11-15 La hoja como un solo material (diseño Fable, tsuka-transicion-elementos, ronda 6 aprobada).
// Port línea por línea del array FRAG del prototipo (WebGL) a GLSL 440 para ShaderEffect.
// Coordenadas: las del prototipo (px lógicos de la barra de 56; y del prototipo, Y0 = 58 = arriba de la hoja visible).
// Diferencias con el prototipo, solo de plomería (no de look):
//  - el campo de distancias se lee con texelFetch (exacto, sin filtrar), igual que NEAREST en WebGL;
//  - cada pixel real promedia N×N muestras del material en la rejilla del campo (N = SB / dpr, hasta 4): es lo que hace
//    el navegador al reducir el lienzo del prototipo a tamaño real, sin un FBO intermedio.
// Compilar (los dos): /usr/lib/qt6/bin/qsb --glsl "300 es,330" --hlsl 50 --msl 12 -o hoja.frag.qsb hoja.frag  (ídem hoja.vert)
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float uSB;
    float uYT;
    float uY0;
    float uH2;
    float uFase;
    float uNivel;
    float uPY;
    float uPI;
    float uTime;
    float uEl;
    vec2 uRes;
    vec3 uEco;
    vec3 uTemple;
    vec3 uBase;
    vec3 uTinte;
};
layout(binding = 1) uniform sampler2D uSdf;

float gs(float x, float s) { return exp(-x * x / (2. * s * s)); }
float sst(float a, float b, float x) { float t = clamp((x - a) / (b - a), 0., 1.); return t * t * (3. - 2. * t); }
float hash2(vec2 p) { return fract(sin(p.x * 127.1 + p.y * 311.7) * 43758.5453); }
float ruido(vec2 p) { vec2 i = floor(p), f = fract(p); vec2 u = f * f * (3. - 2. * f);
    return mix(mix(hash2(i), hash2(i + vec2(1., 0.)), u.x), mix(hash2(i + vec2(0., 1.)), hash2(i + vec2(1., 1.)), u.x), u.y); }
float fbm(vec2 p) { return .5 * ruido(p) + .3 * ruido(p * 2.1 + vec2(5.2, 1.3)) + .2 * ruido(p * 4.3 + vec2(1.7, 9.2)); }
float sx(float y) { float t = max(0., (y - uY0) / (uH2 - uY0)); return -3. * t * t; }
float onda(float y) { float f = (y - 18.) / 54. * 6.2832; return 3.5 + 3.3 * sin(f + .85 * sin(f)); }
float acero(float xs, float y) {
    float v, t, u, n = ruido(vec2(xs * 2.4, y * .055)), largo = .62 + .38 * sst(.25, .75, ruido(vec2(3.1, y / 34.)));
    if (xs < 9.5) v = .05 + .34 * gs(xs - 8.9, .22);
    else if (xs < 19.5) { t = (xs - 9.5) / 10.; t += .03 * sin(y / 31.); v = .2 + .1 * t + .5 * gs(t - .56, .2) * largo + .34 * gs(t - .74, .035) * (.5 + .5 * largo) + (n - .5) * .03; }
    else if (xs < 20.6) v = .2 + .72 * gs(xs - 20.12, .19) - .1 * gs(xs - 19.6, .15);
    else if (xs < 45.5) { u = (xs - 20.6) / 24.9; v = .32 - .06 * u + .08 * gs(u - .08, .06) + .035 * sin(y / 47. + 1.) * (1. - u) + (n - .5) * .035 + .05 * sst(.8, 1., u); }
    else { t = (xs - 45.5) / 2.5; v = (.5 + .3 * t) * (1. - .5 * gs(xs - 45.5, .15)) + .5 * gs(xs - 47.6, .25); }
    return v;
}
vec3 seg(vec3 a, vec3 b, float t0, float t1, float t) { return mix(a, b, clamp((t - t0) / (t1 - t0), 0., 1.)); }
vec3 rampa(float t) { t = clamp(t, 0., 1.); vec3 c = seg(vec3(30., 5., 4.), vec3(84., 12., 8.), 0., .14, t);
    if (t > .14) c = seg(vec3(84., 12., 8.), vec3(156., 30., 14.), .14, .3, t);
    if (t > .3) c = seg(vec3(156., 30., 14.), vec3(214., 70., 22.), .3, .5, t);
    if (t > .5) c = seg(vec3(214., 70., 22.), vec3(246., 134., 40.), .5, .7, t);
    if (t > .7) c = seg(vec3(246., 134., 40.), vec3(255., 204., 108.), .7, .87, t);
    if (t > .87) c = seg(vec3(255., 204., 108.), vec3(255., 244., 216.), .87, 1., t);
    return c; }
float Dt(vec2 px) { ivec2 q = ivec2(clamp(px, vec2(0.), uRes - 1.)); vec4 c = texelFetch(uSdf, q, 0); return (c.r * 255. * 256. + c.g * 255.) / 65535. * 32. - 16.; }
float linea(float xs, float ly, float sep, float amp, float lag, float fu, float gr, float k, bool fuera) {
    float xl = 43.4 - sep - 3.5 * (fuera ? amp : 1.) - amp * (onda(ly - lag - uFase * 3.) - 3.5);
    float tr = .4 + .6 * sst(.25, .6, ruido(vec2(k * 7.3 + 1., ly / 36. + uFase * .25)));
    return gs(xs - xl, gr) * fu * tr; }

// el material en un pixel del campo (px entero de la rejilla SB); devuelve color premultiplicado (0..1) y alfa
vec4 material(vec2 px) {
    float lx = (px.x + .5) / uSB, ly = uYT + (px.y + .5) / uSB, xs = lx - sx(ly);
    if (xs < 7.5 || xs > 48.4) return vec4(0.);
    float niv = clamp(uNivel + uPI * gs(ly - uPY, 13.), 0., 1.), fase = uFase;
    float d = Dt(px), v = acero(xs, ly); vec3 col = uTinte * v;
    float n0 = ruido(vec2(xs * 2.4, ly * .055)), gx = (Dt(px + vec2(1., 0.)) - Dt(px - vec2(1., 0.))) * uSB * .5, gy = (Dt(px + vec2(0., 1.)) - Dt(px - vec2(0., 1.))) * uSB * .5, lado = gx * -.62 + gy * -.78;
    float pared = gs(d + .25, .5), dentro = sst(-.3, .3, d), q, n;
    if (uEl < .5) {
        float lab = gs(d + .55, .55), ll = lab * lado, f1 = 1. - .3 * max(0., ll) + .45 * max(0., -ll); col *= f1;
        float late = 1. + .05 * sin(uTime * 5.3 + ly * .21) + .035 * sin(uTime * 8.7 - ly * .37);
        if (d < .3) { q = (exp(d / mix(2.6, 4.2, niv)) * mix(.4, .8, niv) + exp(d / 9.) * mix(.1, .22, niv)) * (.35 + 1.7 * v) * (.75 + .5 * n0) * late; col += vec3(235., 62., 14.) * q; }
        float dn = d + (fbm(vec2(lx * 1.7 + 3., ly * 1.2)) - .5) * 1.5, den = sst(-1.2, 1.4, dn);
        if (den > 0.) {
            float dd = max(0., dn + .4), wq = fbm(vec2(lx * .2 + 7., ly * .1 - fase * 1.1)); n = fbm(vec2(lx * .42 + wq * 2.6 + fase * 1.3, ly * .2 + wq * 2. - fase * 2.4));
            float hondo = 1. - exp(-dd / mix(2., 1.5, niv)), somb = exp(-dd / 1.5) * max(0., -lado) * .4, base = mix(.78, 1.06, sst(44.6, 38.5, xs));
            float xm = xs - 29., tras = max(gs(length(vec2(xm, ly - 75.)), 5.2), max(gs(length(vec2(xm, ly - 91.)), 5.), gs(length(vec2(xm, ly - 109.)), 5.4)));
            float calor = (hondo * mix(.97, 1.06, niv) * (.76 + .42 * n) * late + .1 * niv) * base * (1. - somb) * (1. - .62 * tras); vec3 cf = rampa(calor);
            float refl = (.42 + 1.9 * v) * (1. + (n0 - .5) * .5), em = den * (.3 + .7 * hondo) * refl * mix(1., 1.12, niv), tin = den * .95;
            float nie = pow(hash2(px * vec2(.71, 1.37)), 10.) * gs(dn - .1, .9) * mix(70., 120., niv);
            col = col * mix(vec3(1.), vec3(.74, .24, .17), tin) + cf * em + nie * vec3(1., .62, .3);
        }
    } else {
        if (d < .4) { float kk = pared * lado; col *= 1. - .6 * kk * (kk > 0. ? 1. : 1.5); }
        if (d < .3) { q = exp(d / mix(2.8, 4.4, niv)) * mix(.26, .55, niv) * (.6 + .8 * v); col += uEco * q; }
        float lin = 0.;
        if (uEl > 1.5) {
            float gm = sst(56., 66., ly) * sst(128., 118., ly), guarda = mix(sst(27.5, 32., xs), sst(35.4, 37.6, xs), gm), sum = 0.;
            if (d > 0.) { sum = linea(xs, ly, -1.9, 1., 0., .95, .3, 3., false) + linea(xs, ly, -3.7, 1., 0., .5, .32, 4., false); lin = sum * mix(.8, 1., niv) * sst(45.4, 44.6, xs); }
            else { sum = linea(xs, ly, 2.3, .82, 4., .7, .3, 0., true) + linea(xs, ly, 4.9, .62, 9., .5, .33, 1., true) + linea(xs, ly, 7.9, .42, 15., .32, .38, 2., true);
                float e2 = min(1., sum * guarda * mix(.95, 1.3, niv)); col = mix(col, mix(uTemple, vec3(255., 250., 240.), mix(.3, .6, niv)), e2); }
        } else if (d > 0.) lin = pow(.5 + .5 * cos(d * 2.5 - fase * 2.1), 5.) * exp(-d / 5.5) * sst(.6, 1.6, d) * mix(.6, .9, niv);
        if (dentro > 0.) {
            float wx = fbm(vec2(lx * .22 + 3., ly * .11 + fase * .9));
            n = uEl > 1.5 ? .25 + .6 * ruido(vec2(xs * 1.9 + .6 * sin(ly / 17.), ly * .045 + fase * .8)) : fbm(vec2(lx * .5 + wx * 3.2 + fase * 1.1, ly * .24 + wx * 2.4));
            float dd = max(0., d), fr = exp(-dd / mix(1.25, 1.7, niv)), honda = 1. - exp(-dd / 4.5), ve = mix(.4, .62, niv) * (.62 + .76 * n) * (1. - .35 * honda);
            vec3 cu = mix(mix(uBase * 2.1, uEco, .45), uTemple, .2), bb = col * .4 + cu * ve * 1.25, lc = mix(uTemple, vec3(255., 250., 240.), mix(.5, .8, niv));
            float kf = fr * mix(.92, 1., niv), la = lin * mix(95., 150., niv);
            float caus = pow(sst(.52, .78, n), 2.) * mix(26., 70., niv), nie = pow(hash2(px * vec2(.73, 1.31)), 14.) * mix(55., 90., niv) * exp(-dd / 3.5);
            col = mix(col, mix(bb, lc, kf) + nie + caus + la * vec3(.8, .92, 1.), dentro);
        }
    }
    float al = sst(7.5, 8.1, xs) * sst(48.4, 47.95, xs);
    return vec4(clamp(col / 255., 0., 1.) * al, al);
}

void main() {
    // cuántas muestras del campo caben en un pixel real (4 a escala 1 con SB = 4; 3 en el XENEON a 1.6)
    vec2 dtc = fwidth(qt_TexCoord0);
    vec2 paso = dtc * uRes;
    int nx = int(clamp(floor(paso.x + .5), 1., 4.)), ny = int(clamp(floor(paso.y + .5), 1., 4.));
    vec2 base = qt_TexCoord0 * uRes - paso * .5;
    vec4 acc = vec4(0.);
    for (int j = 0; j < 4; j++) {
        if (j >= ny) break;
        for (int i = 0; i < 4; i++) {
            if (i >= nx) break;
            acc += material(floor(base + paso * vec2((float(i) + .5) / float(nx), (float(j) + .5) / float(ny))));
        }
    }
    fragColor = acc / float(nx * ny) * qt_Opacity;
}
