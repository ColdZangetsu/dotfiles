#version 440
// vértice estándar de ShaderEffect; existe solo para compilarlo con las mismas versiones de GLSL que hoja.frag
layout(location = 0) in vec4 qt_Vertex;
layout(location = 1) in vec2 qt_MultiTexCoord0;
layout(location = 0) out vec2 qt_TexCoord0;
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
out gl_PerVertex { vec4 gl_Position; };
void main() {
    qt_TexCoord0 = qt_MultiTexCoord0;
    gl_Position = qt_Matrix * qt_Vertex;
}
