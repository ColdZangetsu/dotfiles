import QtQuick
import Caelestia.Config
import qs.components
import qs.services
import Quickshell

StyledRect {
    property bool first
    property bool last

    color: Colours.of(QsWindow.window ?? this).tPalette.m3surfaceContainer
    topLeftRadius: first ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
    topRightRadius: first ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
    bottomLeftRadius: last ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
    bottomRightRadius: last ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
}
