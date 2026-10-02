import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Bluetooth
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

Variants {
    model: Quickshell.screens

PanelWindow {
    id: bar
    required property var modelData
    screen: modelData
    anchors { top: true; left: true; right: true }
    margins { top: 5; left: 5; right: 5 }
    implicitHeight: 44
    color: "transparent"

    // ───────────── helpers ─────────────
    function nf(cp) { return String.fromCodePoint(cp) }
    function term(...cmd) { Quickshell.execDetached(["kitty", "--class", "taskmgr", "-e", ...cmd]) }

    // Если воркспейсы не переключаются (новый Lua-синтаксис Hyprland),
    // замени тело на свою рабочую форму dispatch.
    function gotoWorkspace(id) {
        Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + id + " })"])
    }
    // function gotoWorkspace(id) { Hyprland.dispatch("workspace " + id) }

    // сюда можно вставить свои Nerd Font иконки воркспейсов из waybar
    property var wsIcons: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
    component Btn: MouseArea {
      cursorShape: Qt.PointingHandCursor
    }
    component Txt: Text {
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        color: Theme.fg
        verticalAlignment: Text.AlignVCenter
    }

    // "остров" = блок модулей с полупрозрачным фоном
    component Island: Rectangle {
        default property alias content: row.data
        color: Theme.island
        radius: Theme.radius
        implicitHeight: 34
        implicitWidth: row.implicitWidth + 32
        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 14
        }
    }

    // ───────────── состояние ─────────────
    property string updText: ""
    property int cpu: 0
    property real lastTotal: 0
    property real lastIdle: 0
    property string layoutName: "ENG"
    property string netKind: ""
    property string netLabel: ""
    property int netSignal: 0
    property bool clockAlt: false
    property bool inhibit: false
    property int lastPct: 100

    // ───────────── музыка ─────────────
    readonly property var player: {
        const list = Mpris.players.values.filter(p => !p.dbusName.includes("playerctld"));
        return list.find(p => p.isPlaying) ?? list[0] ?? null;
    }

    // ───────────── звук ─────────────
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [bar.sink] }
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property string volIcon: muted ? nf(0xF0581)
        : volume < 0.34 ? nf(0xF057F)
        : volume < 0.67 ? nf(0xF0580) : nf(0xF057E)
    function setVolume(v) {
        if (sink?.audio) sink.audio.volume = Math.max(0, Math.min(1, v))
    }

    // ───────────── батарея ─────────────
    readonly property var bat: UPower.displayDevice
    readonly property bool hasBattery: UPower.devices.values.some(d => d.isLaptopBattery)
    readonly property int batPct: Math.round(bat.percentage * 100)
    readonly property bool charging: bat.state === UPowerDeviceState.Charging
    readonly property var batIcons: [0xF008E, 0xF007A, 0xF007B, 0xF007C, 0xF007D, 0xF007E, 0xF007F, 0xF0080, 0xF0081, 0xF0082, 0xF0079]
    readonly property var batChgIcons: [0xF089F, 0xF089C, 0xF0086, 0xF0087, 0xF0088, 0xF089D, 0xF0089, 0xF089E, 0xF008A, 0xF008B, 0xF0085]
    readonly property string batIcon: nf((charging ? batChgIcons : batIcons)[Math.min(10, Math.round(batPct / 10))])

    Connections {
        target: UPower.displayDevice
        function onPercentageChanged() {
            const p = bar.batPct
            if (!bar.charging) {
                if (p <= 10 && bar.lastPct > 10)
                    Quickshell.execDetached(["notify-send", "-u", "critical", "Very Low Battery"])
                else if (p <= 20 && bar.lastPct > 20)
                    Quickshell.execDetached(["notify-send", "-u", "normal", "Low Battery"])
            }
            if (p >= 100 && bar.lastPct < 100)
                Quickshell.execDetached(["notify-send", "-u", "normal", "Battery Full!"])
            bar.lastPct = p
        }
        function onStateChanged() {
            if (bar.charging)
                Quickshell.execDetached(["notify-send", "-u", "normal", "Power Switch", "Charging"])
            else if (bar.bat.state === UPowerDeviceState.Discharging)
                Quickshell.execDetached(["notify-send", "-u", "normal", "Power Switch", "Discharging"])
        }
    }

    // ───────────── часы / idle ─────────────
    SystemClock { id: clock; precision: SystemClock.Minutes }
    IdleInhibitor { window: bar; enabled: bar.inhibit }

    // ───────────── bluetooth ─────────────
    readonly property var btAdapter: Bluetooth.defaultAdapter
    readonly property int btConnected: Bluetooth.devices.values.filter(d => d.connected).length

    // ───────────── CPU (/proc/stat каждые 10с) ─────────────
    function parseCpu(t) {
        const f = t.trim().split(/\s+/).slice(1).map(Number)
        const idle = f[3] + f[4]
        const total = f.reduce((a, b) => a + b, 0)
        if (lastTotal > 0 && total > lastTotal)
            cpu = Math.round(100 * (1 - (idle - lastIdle) / (total - lastTotal)))
        lastTotal = total
        lastIdle = idle
    }
    Process {
        id: cpuProc
        command: ["head", "-n1", "/proc/stat"]
        stdout: StdioCollector { onStreamFinished: bar.parseCpu(text) }
    }
    Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: cpuProc.running = true }
    Timer { interval: 1500; running: true; onTriggered: cpuProc.running = true }

    // ───────────── updates (твой скрипт из waybar) ─────────────
    Process {
      id: updProc
      command: ["sh", "-c", "~/.config/waybar/scripts/update-check.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try { bar.updText = (JSON.parse(text).text ?? "").trim() }
                catch (e) { bar.updText = text.trim() }
            }
        }
      }
    IpcHandler {
          target: "updates"
          function refresh(): void { updProc.running = true }
        }

    Timer { interval: 3600000; running: true; repeat: true; onTriggered: updProc.running = true }

    // ───────────── раскладка ─────────────
    function setLayout(n) {
        const s = (n || "").toLowerCase()
        layoutName = s.includes("ukr") ? "УКР"
            : s.includes("russ") ? "РУС"
            : (s.includes("english") || s.includes("us")) ? "ENG" : n
    }
    Process {
        id: kbProc
        command: ["hyprctl", "devices", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const kbs = JSON.parse(text).keyboards
                    const kb = kbs.find(k => k.main) ?? kbs[0]
                    bar.setLayout(kb.active_keymap)
                } catch (e) {}
            }
        }
    }
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activelayout")
                bar.setLayout(event.data.split(",").slice(1).join(","))
        }
    }

    // ───────────── сеть (nmcli, каждые 5с) ─────────────
    function parseNet(t) {
        const lines = t.trim().split("\n").filter(l => l.length)
        const w = lines.find(l => l.startsWith("yes:"))
        const e = lines.find(l => l.startsWith("ethernet:connected:"))
        if (w) {
            const p = w.split(":")
            netKind = "wifi"
            netSignal = parseInt(p[1]) || 0
            netLabel = p.slice(2).join(":")
        } else if (e) {
            netKind = "eth"
            netLabel = e.split(":")[2]
        } else {
            netKind = ""
            netLabel = ""
        }
    }
    Process {
        id: netProc
        command: ["sh", "-c",
            "nmcli -t -f ACTIVE,SIGNAL,SSID dev wifi list --rescan no 2>/dev/null | grep '^yes'; " +
            "nmcli -t -f TYPE,STATE,DEVICE device 2>/dev/null | grep '^ethernet:connected'"]
        stdout: StdioCollector { onStreamFinished: bar.parseNet(text) }
    }
    Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: netProc.running = true }
    readonly property string wifiIcon: nf(netSignal < 25 ? 0xF091F : netSignal < 50 ? 0xF0922 : netSignal < 75 ? 0xF0925 : 0xF0928)

    // ───────────── ЛЕВАЯ часть ─────────────
    RowLayout {
        anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
        spacing: 12

        // workspaces
        Island {
            Repeater {
                model: 9 
                Txt {
                    id: ws
                    required property int index
                    readonly property int wsId: index + 1
                    readonly property bool active: Hyprland.focusedWorkspace?.id === wsId
                    text: bar.wsIcons[index] ?? wsId
                    color: active ? Theme.sky : (wsArea.containsMouse ? Theme.sapphire : Theme.lavender)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Btn {
                        id: wsArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: bar.gotoWorkspace(ws.wsId)
                    }
                }
            }
        }

        // updates
        Island {
            visible: bar.updText !== ""
            Txt {
                text: bar.updText
                color: Theme.peach
                Btn {
                    anchors.fill: parent
                    onClicked: bar.term("aurora", "system-update")
                }
            }
        }

        // music
        Island {
            visible: bar.player !== null
            Txt {
                readonly property bool playing: bar.player?.isPlaying ?? false
                text: bar.nf(playing ? 0xF0388 : 0xF03E4) + " " + (bar.player?.trackTitle ?? "") + " - " + (bar.player?.trackArtist ?? "")
                color: playing ? Theme.mauve : Theme.maroon
                elide: Text.ElideRight
                Layout.maximumWidth: 420
                Btn {
                    anchors.fill: parent
                    onClicked: bar.player?.togglePlaying()
                    onWheel: (w) => { if (w.angleDelta.y > 0) bar.player?.next(); else bar.player?.previous() }
                }
            }
        }
    }

    // ───────────── ПРАВАЯ часть ─────────────
    RowLayout {
        anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
        spacing: 12

        // volume + slider (выезжает при наведении)
        Island {
            HoverHandler { id: volHover }
            RowLayout {
                spacing: 0
                Txt {
                    text: bar.muted ? bar.volIcon : bar.volIcon + " " + Math.round(bar.volume * 100) + "%"
                    color: Theme.maroon
                    Btn {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: (m) => {
                            if (m.button === Qt.RightButton) { if (bar.sink?.audio) bar.sink.audio.muted = !bar.muted }
                            else Quickshell.execDetached(["pavucontrol"])
                        }
                        onWheel: (w) => bar.setVolume(bar.volume + (w.angleDelta.y > 0 ? 0.05 : -0.05))
                    }
                }
                Item {
                    id: drawer
                    clip: true
                    Layout.preferredHeight: 24
                    Layout.preferredWidth: volHover.hovered ? 70 : 0
                    Behavior on Layout.preferredWidth { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

                    Item {
                        id: sl
                        x: 12
                        width: 50
                        height: parent.height
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 5
                            radius: 8
                            color: Theme.inactive
                            Rectangle {
                                width: parent.width * bar.volume
                                height: parent.height
                                radius: 8
                                color: Theme.fg
                            }
                        }
                        Btn {
                            anchors.fill: parent
                            onPressed: (m) => bar.setVolume(m.x / sl.width)
                            onPositionChanged: (m) => bar.setVolume(m.x / sl.width)
                        }
                    }
                }
            }
        }

        // cpu + battery + clock
        Island {
            Txt {
                text: bar.cpu + "% " + bar.nf(0xF2DB)
                color: Theme.yellow
                Btn { anchors.fill: parent; onClicked: bar.term("btop") }
            }
            Txt {
                visible: bar.hasBattery
                text: bar.batPct + "% " + bar.batIcon
                color: (!bar.charging && bar.batPct <= 20) ? Theme.red : Theme.green
            }
            Txt {
                text: bar.clockAlt
                    ? Qt.formatDateTime(clock.date, "dddd, MMMM d, yyyy (HH:mm)")
                    : Qt.formatDateTime(clock.date, "HH:mm")
                color: Theme.blue
                Btn { anchors.fill: parent; onClicked: bar.clockAlt = !bar.clockAlt }
            }
        }

        // idle inhibitor
        Island {
            Txt {
                text: bar.nf(bar.inhibit ? 0xF0176 : 0xF0FAA)
                Btn { anchors.fill: parent; onClicked: bar.inhibit = !bar.inhibit }
            }
        }

        // language + network + bluetooth
        Island {
            Txt {
                text: bar.layoutName
                Btn {
                    anchors.fill: parent
                    onClicked: Quickshell.execDetached(["hyprctl", "switchxkblayout", "current", "next"])
                }
            }
            Txt {
                visible: bar.netKind !== ""
                text: bar.netKind === "wifi" ? bar.wifiIcon : bar.nf(0xF0200) + " " + bar.netLabel
                Btn { anchors.fill: parent; onClicked: bar.term("nmtui") }
            }
            Txt {
                text: (!bar.btAdapter || !bar.btAdapter.enabled) ? bar.nf(0xF00B2)
                    : bar.btConnected > 0 ? bar.nf(0xF00B1) + " " + bar.btConnected
                    : bar.nf(0xF00AF)
                Btn {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (m) => {
                        if (m.button === Qt.RightButton) { if (bar.btAdapter) bar.btAdapter.enabled = !bar.btAdapter.enabled }
                        else bar.term("bluetui")
                    }
                }
            }
        }
        Island {
    visible: SystemTray.items.values.length > 0
    Repeater {
        model: SystemTray.items
        Item {
            id: trayItem
            required property SystemTrayItem modelData
            implicitWidth: 20
            implicitHeight: 20

            function toggleMenu() {
                if (menuPopup.visible) { menuPopup.visible = false; return }
                const p = trayItem.mapToItem(null, 0, 0)
                menuPopup.anchor.rect = Qt.rect(p.x, p.y, trayItem.width, trayItem.height + 8)
                menuPopup.visible = true
            }

            IconImage { anchors.fill: parent; source: trayItem.modelData.icon }

            QsMenuOpener { id: opener; menu: trayItem.modelData.menu }

            Btn {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: (m) => {
                    const it = trayItem.modelData
                    if (m.button === Qt.MiddleButton) it.secondaryActivate()
                    else if (m.button === Qt.RightButton || it.onlyMenu) { if (it.hasMenu) trayItem.toggleMenu() }
                    else it.activate()
                }
            }

            HyprlandFocusGrab {
                windows: [menuPopup]
                active: menuPopup.visible
                onCleared: menuPopup.visible = false
            }

            PopupWindow {
                id: menuPopup
                anchor.window: bar
                anchor.edges: Edges.Bottom | Edges.Left
                anchor.gravity: Edges.Bottom | Edges.Right
                anchor.adjustment: PopupAdjustment.Slide
                color: "transparent"
                implicitWidth: 220
                implicitHeight: menuBox.implicitHeight

                Rectangle {
                    id: menuBox
                    anchors.fill: parent
                    implicitHeight: col.implicitHeight + 12
                    radius: 12
                    color: Qt.rgba(Theme.walBg.r, Theme.walBg.g, Theme.walBg.b, 0.95)
                    border.color: Theme.surface1
                    border.width: 1

                    ColumnLayout {
                        id: col
                        anchors { fill: parent; margins: 6 }
                        spacing: 0
                        Repeater {
                            model: opener.children
                            Rectangle {
                                id: entry
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: modelData.isSeparator ? 9 : 30
                                radius: 8
                                color: (!modelData.isSeparator && modelData.enabled && entryArea.containsMouse) ? Theme.surface1 : "transparent"

                                Rectangle {
                                    visible: entry.modelData.isSeparator
                                    anchors.centerIn: parent
                                    width: parent.width - 16
                                    height: 1
                                    color: Theme.inactive
                                }
                                RowLayout {
                                    visible: !entry.modelData.isSeparator
                                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                                    spacing: 8
                                    IconImage {
                                        visible: entry.modelData.icon !== ""
                                        source: entry.modelData.icon
                                        implicitSize: 16
                                    }
                                    Txt {
                                        Layout.fillWidth: true
                                        text: entry.modelData.text
                                        font.pixelSize: 14
                                        elide: Text.ElideRight
                                        opacity: entry.modelData.enabled ? 1 : 0.4
                                    }
                                }
                                Btn {
                                    id: entryArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: !entry.modelData.isSeparator && entry.modelData.enabled
                                    onClicked: { entry.modelData.triggered(); menuPopup.visible = false }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
        
        // lock + power
        Island {
            Txt {
                text: bar.nf(0xF033E)
                color: Theme.lavender
                Btn {
                    anchors.fill: parent
                    onClicked: Quickshell.execDetached(["sh", "-c", "sleep 0.5; hyprlock --grace 0"])
                }
            }
            Txt {
                text: "\u23FB"
                color: Theme.red
                Btn {
                    anchors.fill: parent
                    onClicked: Quickshell.execDetached(["wlogout"])
                }
            }
        }
    }
}}
