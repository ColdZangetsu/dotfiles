import QtQuick

// 11-15 Tsuka v3: una pieza de material sombreada en la GPU (fragmentShader = *.frag.qsb) y cacheada en una capa a 2x:
// el sombreador corre una vez y de nuevo solo si cambian sus parámetros (colores del fondo o geometría). En reposo, y
// en los cuadros de otras animaciones de la ventana, solo se dibuja la textura.
ShaderEffect {
    property real dpr: 1
    // [r, g, b] 0-255 -> vec4 0-1 (w = dato extra)
    function v4(c: var, w: real): vector4d {
        return Qt.vector4d(c[0] / 255, c[1] / 255, c[2] / 255, w);
    }
    layer.enabled: true
    layer.smooth: true
    layer.textureSize: Qt.size(Math.ceil(width * 2 * dpr), Math.ceil(height * 2 * dpr))
}
