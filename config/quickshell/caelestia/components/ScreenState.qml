import Quickshell

PersistentProperties {
    required property ShellScreen modelData

    // Drawer visibilities
    property bool bar
    property bool osd
    property bool session
    property bool sesionEspejo   // 11-14: abierto como espejo de otra pantalla (sin focus grab)
    property string sesionFoco   // 11-15 Tsuka: luna que se enfoca al abrir (SUSPENDER = hibernate, APAGAR = shutdown)
    property bool launcher
    property bool dashboard
    property bool utilities
    property bool sidebar

    // Dashboard state
    property int dashboardTab
    property date dashboardDate: new Date()
}
