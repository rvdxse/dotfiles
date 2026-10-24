---@module 'hl'

local monitors = require("monitors")
local programs = require("programs")
local env = require("env")
local autostart = require("autostart")
local appearance = require("appearance")
local input = require("input")
local keybinds = require("keybinds")
local rules = require("rules")
local user_binds = require("user_binds")

local windowrules = require("windowrules")

hl.layer_rule({
	match = {
		namespace = "swaync-control-center",
	},
	blur = true,
	ignore_alpha = 0.5,
})

local home = os.getenv("HOME")

local function read_mode()
	local f = io.open(home .. "/.config/hypr/mode", "r")
	if not f then
		return "tiling"
	end
	local m = f:read("*l")
	f:close()
	return m == "stacking" and "stacking" or "tiling"
end

local stacking = (read_mode() == "stacking")

if stacking then
	dofile(home .. "/.config/hypr/stacking.lua")
else
	hl.window_rule({
		match = { class = ".*" },
		["hyprbars:no_bar"] = true,
	})
end

hl.layer_rule({
	match = {
		namespace = "swaync-notification-window",
	},
	ignore_alpha = 0.5,
	animation = "appleEase",
})
