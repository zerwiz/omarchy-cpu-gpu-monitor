import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
    id: root
    moduleName: "io.github.zerwiz.cpu-gpu-monitor"
    ipcTarget: "io.github.zerwiz.cpu-gpu-monitor"
    manageIpc: false
    property var cpuData: ({})
    property var gpuData: ({})
    property var profiles: []
    property string activeProfile: ""
    property int profileIndex: 0
    property bool cursorActive: false
    readonly property int refreshIntervalSec: Math.max(1, parseInt(setting("refreshIntervalSec", 3), 10) || 3)
    readonly property bool showCpu: setting("showCpu", true) === "true" || setting("showCpu", true) === true
    readonly property bool showGpu: setting("showGpu", true) === "true" || setting("showGpu", true) === true
    readonly property bool showPowerProfiles: setting("showPowerProfiles", true) === "true" || setting("showPowerProfiles", true) === true

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    function refresh() {
        if (!cpuProc.running) cpuProc.running = true
        if (!gpuProc.running) gpuProc.running = true
        if (!profilesProc.running) profilesProc.running = true
    }

    function updateCpu(raw) {
        cpuData = Model.parseCpuUsage(raw)
    }

    function updateGpu(raw) {
        gpuData = Model.parseGpuUsage(raw)
    }

    function updateProfiles(raw) {
        var parsed = Model.parsePowerProfiles(raw)
        profiles = parsed.profiles
        activeProfile = parsed.activeProfile
        var idx = profiles.indexOf(activeProfile)
        profileIndex = idx >= 0 ? idx : 0
    }

    function setProfile(profile) {
        if (!profile || actionProc.running) return
        actionProc.command = ["omarchy-powerprofiles-set", "autodetect", profile]
        actionProc.running = true
    }

    function selectProfileByDelta(delta) {
        if (profiles.length === 0) return
        profileIndex = (profileIndex + delta + profiles.length) % profiles.length
    }

    function activateSelectedProfile() {
        if (profileIndex < 0 || profileIndex >= profiles.length) return
        setProfile(profiles[profileIndex])
    }

    IpcHandler {
        target: "io.github.zerwiz.cpu-gpu-monitor"
        function open() { root.open() }
        function close() { root.close() }
        function show() { root.open() }
        function hide() { root.close() }
        function toggle() { root.toggle() }
    }

    onOpenedChanged: {
        if (opened) {
            refresh()
            cursorActive = false
        }
    }

    Process {
        id: cpuProc
        command: ["sh", "-c", "cat /proc/stat | head -1"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.updateCpu(text)
        }
    }

    Process {
        id: gpuProc
        command: ["nvidia-smi", "--query-gpu=index,temperature.gpu,utilization.gpu,power.draw,memory.used,memory.total", "--format=csv"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.updateGpu(text)
        }
    }

    Process {
        id: profilesProc
        command: ["omarchy-powerprofiles-list", "--active-state"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.updateProfiles(text)
        }
    }

    Process {
        id: actionProc
        onExited: root.refresh()
    }

    Timer {
        interval: root.refreshIntervalSec * 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: {
        refresh()
    }

    BarIconButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        text: root.showGpu && root.gpuData.gpuUtil ? root.gpuData.gpuUtil + "%" : (root.showCpu ? root.cpuData.usagePercent + "%" : "⚡")
        slotSize: Style.bar.iconSlot
        tooltipText: (root.showCpu ? "CPU: " + root.cpuData.usagePercent + "%" : "") + (root.showCpu && root.showGpu ? " | " : "") + (root.showGpu ? "GPU: " + root.gpuData.gpuUtil + "%" : "")
        onPressed: function(b) {
            if (b === Qt.LeftButton) root.toggle()
        }
    }

    KeyboardPanel {
        id: panel
        anchorItem: button
        owner: root
        bar: root.bar
        open: root.opened
        focusTarget: keyCatcher
        contentWidth: panel.fittedContentWidth(Style.space(320))
        contentHeight: panel.fittedContentHeight(column.implicitHeight)

        PanelKeyCatcher {
            id: keyCatcher
            anchors.fill: parent
            onMoveRequested: function(dx, dy) {
                if (!root.cursorActive) { root.cursorActive = true; return }
                if (dx !== 0) root.selectProfileByDelta(dx)
                else if (dy !== 0) root.selectProfileByDelta(dy)
            }
            onActivateRequested: if (root.cursorActive) root.activateSelectedProfile()
            onCloseRequested: root.close()

            Column {
                id: column
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: Style.space(14)

                Column {
                    width: parent.width
                    spacing: Style.space(8)
                    visible: root.showCpu

                    PanelSectionHeader {
                        text: "CPU"
                        foreground: root.bar.foreground
                        fontFamily: root.bar.fontFamily
                    }

                    InfoPair {
                        label: "Usage"
                        value: root.cpuData.usagePercent + "%"
                    }
                    Bar { fraction: (root.cpuData.usagePercent || 0) / 100 }

                    Row {
                        width: parent.width
                        spacing: Style.space(20)

                        Column {
                            width: (parent.width - parent.spacing) / 2
                            spacing: Style.spacing.labelGap
                            InfoPair { label: "User"; value: root.cpuData.user ? String(root.cpuData.user) : "—" }
                            InfoPair { label: "System"; value: root.cpuData.system ? String(root.cpuData.system) : "—" }
                        }

                        Column {
                            width: (parent.width - parent.spacing) / 2
                            spacing: Style.spacing.labelGap
                            InfoPair { label: "Idle"; value: root.cpuData.idle ? String(root.cpuData.idle) : "—" }
                            InfoPair { label: "Total"; value: root.cpuData.total ? String(root.cpuData.total) : "—" }
                        }
                    }
                }

                PanelSeparator {
                    foreground: root.bar.foreground
                    visible: root.showCpu && root.showGpu
                }

                Column {
                    width: parent.width
                    spacing: Style.space(8)
                    visible: root.showGpu

                    PanelSectionHeader {
                        text: "GPU"
                        foreground: root.bar.foreground
                        fontFamily: root.bar.fontFamily
                    }

                    InfoPair {
                        label: "Load"
                        value: root.gpuData.gpuUtil + "%"
                    }
                    Bar { fraction: (root.gpuData.gpuUtil || 0) / 100 }

                    InfoPair {
                        label: "VRAM"
                        value: root.gpuData.memUsed + " / " + root.gpuData.memTotal + " MiB (" + root.gpuData.memPercent + "%)"
                    }
                    Bar { fraction: (root.gpuData.memPercent || 0) / 100 }

                    Row {
                        width: parent.width
                        spacing: Style.space(20)

                        Column {
                            width: (parent.width - parent.spacing) / 2
                            spacing: Style.spacing.labelGap
                            InfoPair { label: "Temp"; value: Model.formatTemp(root.gpuData.temp) }
                            InfoPair { label: "Power"; value: Model.formatPower(root.gpuData.power) }
                        }
                    }
                }

                PanelSeparator {
                    foreground: root.bar.foreground
                    visible: (root.showCpu || root.showGpu) && root.showPowerProfiles
                }

                Column {
                    width: parent.width
                    spacing: Style.space(10)
                    visible: root.showPowerProfiles && profiles.length > 0

                    PanelSectionHeader {
                        text: "POWER PROFILE"
                        foreground: root.bar.foreground
                        fontFamily: root.bar.fontFamily
                    }

                    Row {
                        id: profileRow
                        width: parent.width
                        spacing: Style.space(6)
                        readonly property real cellWidth: profiles.length > 0
                            ? (width - spacing * (profiles.length - 1)) / profiles.length
                            : 0

                        Repeater {
                            model: profiles
                            Button {
                                required property var modelData
                                required property int index
                                width: profileRow.cellWidth
                                iconText: Model.profileIcon(modelData)
                                iconSize: Style.font.title
                                text: String(modelData).replace("-", " ")
                                fontSize: Style.font.bodySmall
                                foreground: root.bar.foreground
                                fontFamily: root.bar.fontFamily
                                horizontalPadding: Style.spacing.controlPaddingX
                                verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
                                bordered: true
                                active: root.activeProfile === modelData
                                hasCursor: root.cursorActive && root.profileIndex === index
                                onClicked: root.setProfile(modelData)
                                onHovered: function(h) {
                                    if (h) {
                                        root.cursorActive = true
                                        root.profileIndex = index
                                    }
                                }
                            }
                        }
                    }

                    InfoLabelRow {
                        text: "Left/Right to navigate, Enter to apply"
                        hint: "Current: " + (root.activeProfile || "—")
                    }
                }
            }
        }
    }

    component InfoPair: Column {
        property string label: ""
        property string value: ""

        width: parent.width
        spacing: Style.spacing.labelGap

        Row {
            width: parent.width
            spacing: Style.space(8)

            Text {
                text: label
                color: root.bar.foreground
                opacity: 0.6
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.bodySmall
            }
            Item { width: Math.max(0, parent.width - parent.children[0].implicitWidth - parent.children[2].implicitWidth - parent.spacing * 2); height: 1 }
            Text {
                text: value
                color: root.bar.foreground
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.bodySmall
            }
        }
    }

    component InfoLabelRow: Column {
        property string text: ""
        property string hint: ""

        width: parent.width
        spacing: Style.space(2)

        Text {
            width: parent.width
            text: text
            color: root.bar.foreground
            opacity: 0.6
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        }

        Text {
            width: parent.width
            text: hint
            color: root.bar.foreground
            opacity: 0.9
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        }
    }

    component Bar: Item {
        property real fraction: 0

        width: parent.width
        implicitHeight: Style.space(6)

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Qt.rgba(root.bar.foreground.r, root.bar.foreground.g, root.bar.foreground.b, 0.12)
        }

        Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            radius: height / 2
            color: root.bar.foreground
            width: Math.max(height, parent.width * Math.max(0, Math.min(1, fraction)))

            Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 220 } }
        }
    }
}