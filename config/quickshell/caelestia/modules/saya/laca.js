.pragma library

// 11-15 Saya v3 (propuesta tsuka-saya-v3 de Fable, modo "Ahora", mejoras 8 y 9): ayudas del material.
// La laca de la vaina y el nashiji del bloque se calculan pixel por pixel como en el prototipo, pero en la GPU
// (vaina.frag / nashiji.frag, ShaderEffect con layer: corre una vez y queda como textura). Aquí solo queda lo
// que no es por pixel.
// Nota 11-15: se probó primero un Canvas con createImageData/putImageData (como `sombrea` del prototipo) y
// dejó el hilo principal de quickshell al 100 % para siempre después de pintar (escribir en CanvasPixelArray
// grandes); por eso es sombreador.

// las y de los surcos entre secciones (a la mitad del hueco entre una y la siguiente), [a, b, c, -1] (-1 = ninguno)
function divisiones(s) {
    var o = ["nero", "suena", "luz", "avisos"], l = [];
    for (var i = 0; i + 1 < o.length; i++) l.push(Math.round((s[o[i]][0] + s[o[i]][1] + s[o[i + 1]][0]) / 2));
    return [l[0], l[1], l[2], -1];
}

// hilos del cordón: líneas diagonales finas sobre cada vuelta (SVG estático, sin color: el color lo pone QML)
function hilos(w, h) {
    var b = '';
    for (var x = 0; x < w; x += 1.1) b += '<path d="M' + x.toFixed(2) + ' 0L' + (x + .9).toFixed(2) + ' ' + h + '"/>';
    var s = '<svg xmlns="http://www.w3.org/2000/svg" width="' + w + '" height="' + h + '" viewBox="0 0 ' + w + ' ' + h + '"><g stroke="#000" stroke-opacity=".28" stroke-width=".3" fill="none">' + b + '</g></svg>';
    return "data:image/svg+xml;utf8," + encodeURIComponent(s);
}
