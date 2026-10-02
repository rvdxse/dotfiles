-- ~/.config/hypr/keybinds.lua
---@module 'hl'
--
-- Conventions (the keybinds-menu script parses this file, keep the format):
--   bind("KEYS", "Description", action [, opts])  main bind, shown in the menu
--   also("KEYS", action [, opts])                 extra action on the same keys, hidden
--   doc("KEYS", "Description")                    menu-only entry for binds made in loops
--   -- == Section name ==                          starts a new menu section

local mod = "SUPER"
local terminal = "kitty"
local scripts = os.getenv("HOME") .. "/.config/hypr/scripts"

local exec = hl.dsp.exec_cmd

local function register(keys, action, opts)
	if opts then
		hl.bind(keys, action, opts)
	else
		hl.bind(keys, action)
	end
end

local function bind(keys, _desc, action, opts)
	-- If your Hyprland accepts `description` in opts, pass it here instead of dropping it:
	-- opts = vim.tbl_extend("force", opts or {}, { description = _desc })
	register(keys, action, opts)
end

local function also(keys, action, opts)
	register(keys, action, opts)
end

local function doc(_keys, _desc) end
-- == SIGMA ==
bind("SUPER + slash", "Keybinds list", exec("keybinds-menu --menu"))

-- == Apps ==
bind("SUPER + Return", "Terminal", exec(terminal))
bind("SUPER + E", "File manager (Nautilus)", exec("nautilus"))
bind("SUPER + B", "Browser (Zen)", exec("zen-browser"))
bind("SUPER + C", "VS Code", exec("code"))
bind("SUPER + N", "Notes (Obsidian)", exec("obsidian"))
bind("SUPER + M", "Telegram (AyuGram)", exec("AyuGram"))
bind("SUPER + A", "Claude web app", exec("open-webapp https://claude.ai"))
bind("SUPER + Y", "YouTube web app", exec("open-webapp https://youtube.com"))
bind("SUPER + D", "lazydocker", exec(terminal .. " -e lazydocker"))
bind("CONTROL + SHIFT + Escape", "Task manager (btop)", exec(terminal .. " --class taskmgr -e btop"))
bind("SUPER + V", "Clipboard history", exec("vicinae vicinae://launch/clipboard/history?toggle=true"))

-- == Voice ==
bind("SUPER + R", "Voice input: hold to record (voxtype)", exec("voxtype record start"))
also("SUPER + R", exec("voxtype record stop"), { release = true })

-- == Windows ==
bind("SUPER + Q", "Close window", hl.dsp.window.close())
bind("SUPER + W", "Toggle floating", hl.dsp.window.float())
bind("SUPER + F11", "Toggle fullscreen", hl.dsp.window.fullscreen())
bind("SUPER + P", "Toggle pseudotile", hl.dsp.window.pseudo())
bind("SUPER + semicolon", "Toggle split direction", hl.dsp.layout("togglesplit"))
bind(
	"SUPER + O",
	"Toggle window opacity",
	hl.dsp.window.set_prop({ prop = "opaque", value = "toggle", window = "active" })
)

-- Focus and move by direction (arrows + vim keys)
local dirs = { left = "H", down = "J", up = "K", right = "L" }
for dir, key in pairs(dirs) do
	register(mod .. " + " .. dir, hl.dsp.focus({ direction = dir }))
	register(mod .. " + " .. key, hl.dsp.focus({ direction = dir }))
	register(mod .. " + CONTROL + " .. dir, hl.dsp.window.move({ direction = dir }))
	register(mod .. " + CONTROL + " .. key, hl.dsp.window.move({ direction = dir }))
end
doc("SUPER + Arrows / H J K L", "Focus window in direction")
doc("SUPER + CTRL + Arrows / H J K L", "Move window in direction")

-- Mouse
bind("SUPER + mouse:272", "Drag window (left mouse button)", hl.dsp.window.drag(), { mouse = true })
bind("SUPER + mouse:273", "Resize window (right mouse button)", hl.dsp.window.resize(), { mouse = true })
bind("SUPER + Z", "Drag window (keyboard + mouse)", hl.dsp.window.drag(), { mouse = true })
bind("SUPER + X", "Resize window (keyboard + mouse)", hl.dsp.window.resize(), { mouse = true })

-- == Workspaces ==
for i = 1, 10 do
	local key = i % 10 -- workspace 10 lives on the 0 key
	register(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	register(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
doc("SUPER + 1...0", "Go to workspace 1-10")
doc("SUPER + SHIFT + 1...0", "Move window to workspace 1-10")
bind("SUPER + mouse_down", "Next workspace", hl.dsp.focus({ workspace = "e+1" }))
bind("SUPER + mouse_up", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))
bind("SUPER + S", "Toggle scratchpad (special:magic)", hl.dsp.workspace.toggle_special("magic"))
bind("SUPER + SHIFT + S", "Send window to scratchpad", hl.dsp.window.move({ workspace = "special:magic" }))

-- == Screenshots ==
local satty = "grim -t ppm - | satty --filename - "
	.. "--output-filename ~/Pictures/Screenshots/$(date +'%Y%m%d-%H%M%S').png "
	.. "--copy-command wl-copy"

bind("Print", "Screenshot: whole screen to clipboard", exec("grimblast copy screen"))
bind("SUPER + Print", "Screenshot: annotate (satty)", exec(satty))
bind("SUPER + SHIFT + P", "Color picker (copy and paste)", exec("hyprpicker -a | wl-copy && wtype -M ctrl v -m ctrl"))

-- == Desktop ==
bind("SUPER + G", "Toggle waybar", exec("pkill -SIGUSR1 waybar"))
bind("SUPER + SHIFT + W", "Restart waybar", exec("pkill waybar; waybar"))
bind("SUPER + SHIFT + N", "Notification center", exec("swaync-client -t -sw"))
bind("SUPER + SHIFT + T", "Change wallpaper", exec(scripts .. "/wallpaper_change"))
bind("SUPER + SHIFT + R", "Power menu (wlogout)", exec("pgrep -x wlogout && pkill -x wlogout || wlogout"))
bind("SUPER + equal", "Zoom in", exec("hyprctl keyword cursor:zoom_factor 2.0"))
bind("SUPER + SHIFT + minus", "Zoom reset", exec("hyprctl keyword cursor:zoom_factor 1.0"))
bind("SUPER + slash", "Show this cheatsheet", exec(scripts .. "/keybinds-menu --menu"))

-- Hotkeys lock: F1 enters an empty submap where only F1 works, F1 again leaves it
bind("SUPER + F1", "Disable / enable all hotkeys", hl.dsp.submap("hide"))
also("SUPER + F1", exec('swayosd-client --custom-message "Hotkeys Disabled"'))

hl.define_submap("hide", function()
	also("SUPER + F1", hl.dsp.submap("reset"))
	also("SUPER + F1", exec('swayosd-client --custom-message "Hotkeys Enabled"'))
end)

-- == Hardware keys ==
local locked = { locked = true }

bind("switch:on:Lid Switch", "Lock screen when lid closes", exec("loginctl lock-session"), locked)

bind("XF86AudioRaiseVolume", "Volume up", exec("swayosd-client --output-volume +2"), locked)
bind("XF86AudioLowerVolume", "Volume down", exec("swayosd-client --output-volume -2"), locked)
bind("XF86AudioMute", "Mute output", exec("swayosd-client --output-volume mute-toggle"), locked)
bind("XF86AudioMicMute", "Mute microphone", exec("pamixer --default-source -t"), locked)
bind("XF86MonBrightnessUp", "Brightness up", exec("swayosd-client --brightness raise"), locked)
bind("XF86MonBrightnessDown", "Brightness down", exec("swayosd-client --brightness lower"), locked)

bind("XF86AudioNext", "Media: next", exec("playerctl next"), locked)
bind("XF86AudioPrev", "Media: previous", exec("playerctl previous"), locked)
bind("XF86AudioPlay", "Media: play/pause", exec("playerctl play-pause"), locked)
bind("XF86AudioPause", "Media: play/pause", exec("playerctl play-pause"), locked)
