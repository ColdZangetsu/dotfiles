import QtQuick
import Caelestia.Config
import qs.components
import qs.services
import Quickshell

ButtonBase {
    id: root

    property alias icon: label.text
    readonly property alias label: label

    font: Tokens.font.icon.medium
    padding: type === IconButton.Text ? Tokens.padding.extraSmall / 2 : Tokens.padding.small

    activeColour: type === IconButton.Filled ? Colours.of(QsWindow.window ?? this).palette.m3primary : Colours.of(QsWindow.window ?? this).palette.m3secondary
    inactiveColour: {
        if (!isToggle && type === IconButton.Filled)
            return Colours.of(QsWindow.window ?? this).palette.m3primary;
        return type === IconButton.Filled ? Colours.of(QsWindow.window ?? this).tPalette.m3surfaceContainer : Colours.of(QsWindow.window ?? this).palette.m3secondaryContainer;
    }
    activeOnColour: type === IconButton.Filled ? Colours.of(QsWindow.window ?? this).palette.m3onPrimary : type === IconButton.Tonal ? Colours.of(QsWindow.window ?? this).palette.m3onSecondary : Colours.of(QsWindow.window ?? this).palette.m3primary
    inactiveOnColour: {
        if (!isToggle && type === IconButton.Filled)
            return Colours.of(QsWindow.window ?? this).palette.m3onPrimary;
        return type === IconButton.Tonal ? Colours.of(QsWindow.window ?? this).palette.m3onSecondaryContainer : Colours.of(QsWindow.window ?? this).palette.m3onSurfaceVariant;
    }

    implicitWidth: implicitHeight
    implicitHeight: {
        // Ensure even size so icon is centered properly
        const h = label.implicitHeight + padding * 2;
        if (h % 2 !== 0)
            return h + 1;
        return h;
    }

    MaterialIcon {
        id: label

        anchors.centerIn: parent
        anchors.verticalCenterOffset: 1 // AHHHHHHH material symbols whyyyy
        color: root.onColour
        fontStyle: root.font
        fill: !root.isToggle || root.internalChecked ? 1 : 0

        Behavior on fill {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
