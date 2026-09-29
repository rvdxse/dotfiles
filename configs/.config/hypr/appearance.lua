-- Converted from hyprlang (hyprland.conf) to Lua config, Hyprland 0.55+
-- Docs: https://wiki.hypr.land/Configuring/Start/

----------------------------------
---- PYWAL COLORS (source =) ----
----------------------------------
-- В lua-конфиге нет прямого аналога "source =" для файла с $переменными,
-- поэтому парсим colors-hyprland.conf вручную и кладём в таблицу wal.

local wal = {}
do
	local f = io.open(os.getenv("HOME") .. "/.cache/wal/colors-hyprland.conf", "r")
	if f then
		for line in f:lines() do
			local name, value = line:match("^%$(%w+)%s*=%s*(.+)$")
			if name then
				wal[name] = value
			end
		end
		f:close()
	end
end

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 10,
		gaps_workspaces = 40,
		border_size = 3,
		col = {
			active_border = wal.color6 or "rgba(ffffffee)",
			inactive_border = "rgba(00000000)",
		},
		resize_on_border = true,
		allow_tearing = false,
		layout = "dwindle",
	},

	decoration = {
		rounding = 10,
		active_opacity = 0.9,
		inactive_opacity = 0.8,

		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
			color = 0xee1a1a1a, -- rgba(1a1a1aee)
		},

		blur = {
			enabled = true,
			size = 8,
			passes = 3,
			ignore_opacity = true,
			vibrancy = 2,
			brightness = 1.25,
			contrast = 1.05,
			noise = 0.015,
			-- new_optimizations больше не в API 0.55, blur-пайплайн переписан — не переносил
		},
	},

	animations = {
		enabled = true,
	},
})

-- Bezier-кривые (bezier = name, x1, y1, x2, y2)
hl.curve("specialWorkSwitch", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("emphasizedAccel", { type = "bezier", points = { { 0.3, 0 }, { 0.8, 0.15 } } })
hl.curve("emphasizedDecel", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("standard", { type = "bezier", points = { { 0.2, 0 }, { 0, 1 } } })

-- Анимации (animation = leaf, onoff, speed, curve, style)
hl.animation({ leaf = "layersIn", enabled = true, speed = 5, bezier = "emphasizedDecel", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 4, bezier = "emphasizedAccel", style = "slide" })
hl.animation({ leaf = "fadeLayers", enabled = true, speed = 5, bezier = "standard" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3, bezier = "emphasizedDecel" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "emphasizedAccel" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3, bezier = "standard" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "standard" })
hl.animation({
	leaf = "specialWorkspace",
	enabled = true,
	speed = 4,
	bezier = "specialWorkSwitch",
	style = "slidefadevert 15%",
})
hl.animation({ leaf = "fade", enabled = true, speed = 6, bezier = "standard" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 6, bezier = "standard" })
hl.animation({ leaf = "border", enabled = true, speed = 6, bezier = "standard" })

-------------------
---- LAYOUTS ------
-------------------

hl.config({
	dwindle = {
		preserve_split = true,
		smart_resizing = true, -- проверь актуальность опции в 0.55 wiki
	},
	master = {
		new_status = "master",
	},
})

----------------
---- MISC ----
----------------

hl.config({
	misc = {
		disable_splash_rendering = true, -- проверь актуальность имени опции
		force_default_wallpaper = 0,
		disable_hyprland_logo = true,
	},
	ecosystem = {
		no_update_news = true,
		-- enforce_permissions = true,
	},
	cursor = {
		inactive_timeout = 3,
	},
})

--------------------------------
---- WORKSPACE / WINDOW RULES --
--------------------------------

-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 10, gaps_in = 10 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 10, gaps_in = 10 })

hl.window_rule({
	name = "apply",
	match = { focus = false },
	no_shadow = true,
})
