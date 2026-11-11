import QtQuick
import qs.services

// Etiqueta chica en mayúsculas espaciadas.
Txt {
    size: 10
    color: Theme.cardTextDim
    font.weight: Font.Medium
    font.capitalization: Font.AllUppercase
    font.letterSpacing: 1.4 * Theme.scale
}
