hl.config({
	plugin = {
		hyprbars = {
			bar_blur = false,
			bar_height = 32,
			bar_color = "rgb(30, 30, 46)",
			bar_title_enabled = true,
			bar_text_size = 16,
			bar_text_align = "center",
			bar_buttons_alignment = "left",
			bar_padding = 15,
			bar_button_padding = 6,
			bar_text_font = "CaskaydiaCove Nerd Font",
			on_double_click = [[hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })']],
		},
	},
})

hl.plugin.hyprbars.add_button({
	bg_color = "#f38ba8",
	fg_color = "rgb(ffffff)",
	size = 15,
	icon = "",
	action = "hyprctl dispatch 'hl.dsp.window.close()'",
})

hl.plugin.hyprbars.add_button({
	bg_color = "#f9e2af",
	fg_color = "rgb(000000)",
	size = 15,
	icon = "",
	action = [[hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })']],
})

hl.plugin.hyprbars.add_button({
	bg_color = "#a6e3a1",
	fg_color = "rgb(000000)",
	size = 15,
	icon = "",
	action = [[hyprctl dispatch 'hl.dsp.window.move({ workspace = "special:minimized", follow = false })']],
})

hl.window_rule({
	match = { float = true },
	border_size = 0,
})

hl.window_rule({
	match = { fullscreen = 1 },
	rounding = 0,
	opacity = "1 override",
	border_size = 0,
})

hl.window_rule({
	match = { class = ".*" },
	float = true,
})
