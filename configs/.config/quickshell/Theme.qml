pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // Catppuccin Mocha
    readonly property color text: "#cdd6f4"
    readonly property color surface0: "#313244"
    readonly property color surface1: "#45475a"
    readonly property color blue: "#89b4fa"
    readonly property color lavender: "#b4befe"
    readonly property color sapphire: "#74c7ec"
    readonly property color sky: "#89dceb"
    readonly property color green: "#a6e3a1"
    readonly property color yellow: "#f9e2af"
    readonly property color peach: "#fab387"
    readonly property color maroon: "#eba0ac"
    readonly property color red: "#f38ba8"
    readonly property color mauve: "#cba6f7"

    // pywal (~/.cache/wal/colors.json), fallback: mocha
    readonly property color walBg: wal.adapter.colors.color0
    readonly property color fg: wal.adapter.special.foreground
    readonly property color inactive: wal.adapter.colors.color8
    readonly property color island: Qt.rgba(walBg.r, walBg.g, walBg.b, 0.5)

    readonly property string fontFamily: "CaskaydiaCove Nerd Font"
    readonly property int fontSize: 16
    readonly property int radius: 16

    FileView {
        id: wal
        path: Quickshell.env("HOME") + "/.cache/wal/colors.json"
        watchChanges: true
        onFileChanged: reload()

        adapter: JsonAdapter {
            property JsonObject special: JsonObject {
                property string foreground: "#cdd6f4"
            }
            property JsonObject colors: JsonObject {
                property string color0: "#181825"
                property string color8: "#45475a"
            }
        }
    }
}
