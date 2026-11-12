// Elige la variante según el monitor. No dibuja ni calcula nada: carga UNA variante (cada una es Base + su pintor)
// y le enlaza las mismas entradas, así A, B y C conviven sin duplicar la lógica base.
//
//   EscritoriosPorMonitor {
//       pantalla: screen.name                     // "DP-1", "DP-2", "DP-3"…
//       mapa: ({ "DP-3": "A" })                   // monitor → variante ("A" Eclipse · "B" Lunas · "C" Tajo)
//       porDefecto: "B"                           // los que no estén en el mapa
//       modelo: …; activo: …; onElegido: i => …   // lo demás, igual que cualquier variante suelta
//   }
import QtQuick

Loader {
    id: s

    // ---------- elección ----------
    property string pantalla: ""
    property var mapa: ({})
    property string porDefecto: "B"
    readonly property string variante: {
        var v = mapa ? mapa[pantalla] : undefined
        if (v !== "A" && v !== "B" && v !== "C") v = porDefecto
        return v === "A" || v === "C" ? v : "B"
    }

    // ---------- entradas que se pasan tal cual a la variante (mismos nombres y valores que Base) ----------
    property var modelo: []
    property int activo: 0
    property Paleta paleta: Paleta {}
    property bool reducirMovimiento: false
    property bool fondo: true
    property bool mostrarVentanas: true
    property real escala: 1
    property real ancho: 40
    property real celda: 32
    property real separacion: 4
    property real margen: 4
    property string fuenteKanji: "Yuji Boku"
    property string fuenteIconos: "Material Symbols Rounded"
    property bool usarRueda: false
    property bool resaltar: false
    property int capDesde: -1
    property real capTiempo: -1
    readonly property var _entradas: ["paleta", "reducirMovimiento", "fondo", "mostrarVentanas", "escala", "ancho", "celda", "separacion",
        "margen", "fuenteKanji", "fuenteIconos", "usarRueda", "resaltar", "capDesde", "capTiempo", "modelo", "activo"]

    signal elegido(int i)
    signal rueda(int dir)

    Component { id: varA; EscritoriosEclipse {} }
    Component { id: varB; EscritoriosLunas {} }
    Component { id: varC; EscritoriosTajo {} }

    sourceComponent: variante === "A" ? varA : variante === "C" ? varC : varB

    onLoaded: {
        var it = item
        _entradas.forEach(function (n) { it[n] = Qt.binding(function () { return s[n] }) })
        it.elegido.connect(s.elegido)
        it.rueda.connect(s.rueda)
        it.fija()       // primer cuadro ya en su sitio, sin animar desde el escritorio 0
    }
}
