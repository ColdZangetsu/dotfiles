#version 440
// 11-15 luz aditiva para los lienzos del hilo rojo: el color se SUMA a lo de abajo (alfa 0 en premultiplicado),
// como globalCompositeOperation = 'lighter' sobre la tela en el prototipo.
// Compilar: /usr/lib/qt6/bin/qsb --glsl "100 es,120,150,300 es,330" --hlsl 50 --msl 12 -o aditivo.frag.qsb aditivo.frag
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
};
layout(binding = 1) uniform sampler2D source;
void main() {
    vec4 c = texture(source, qt_TexCoord0);
    fragColor = vec4(c.rgb, 0.0) * qt_Opacity;
}
