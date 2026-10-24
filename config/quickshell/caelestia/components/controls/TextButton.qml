import QtQuick
import Caelestia.Config
import qs.components
import qs.services
import Quickshell

ButtonBase {
    id: root

    property alias text: label.text
    readonly property alias label: label

    horizontalPadding: Tokens.padding.medium
    verticalPadding: Tokens.padding.small

    activeColour: type === TextButton.Filled ? Colours.of(QsWindow.window ?? this).palette.m3primary : Colours.of(QsWindow.window ?? this).palette.m3secondary
    inactiveColour: {
        if (!isToggle && type === TextButton.Filled)
            return Colours.of(QsWindow.window ?? this).palette.m3primary;
        return type === TextButton.Filled ? Colours.of(QsWindow.window ?? this).tPalette.m3surfaceContainer : Colours.of(QsWindow.window ?? this).palette.m3secondaryContainer;
    }
    activeOnColour: {
        if (type === TextButton.Text)
            return Colours.of(QsWindow.window ?? this).palette.m3primary;
        return type === TextButton.Filled ? Colours.of(QsWindow.window ?? this).palette.m3onPrimary : Colours.of(QsWindow.window ?? this).palette.m3onSecondary;
    }
    inactiveOnColour: {
        if (!isToggle && type === TextButton.Filled)
            return Colours.of(QsWindow.window ?? this).palette.m3onPrimary;
        if (type === TextButton.Text)
            return Colours.of(QsWindow.window ?? this).palette.m3primary;
        return type === TextButton.Filled ? Colours.of(QsWindow.window ?? this).palette.m3onSurface : Colours.of(QsWindow.window ?? this).palette.m3onSecondaryContainer;
    }

    implicitWidth: label.implicitWidth + horizontalPadding * 2
    implicitHeight: label.implicitHeight + verticalPadding * 2

    StyledText {
        id: label

        anchors.centerIn: parent
        color: root.onColour
        font: root.font
    }
}
