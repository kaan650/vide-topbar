local Vide = require("@game/ReplicatedStorage/Packages/Vide")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local KeyCap = require("@game/ReplicatedStorage/Packages/VideTopbar/KeyCap")
local stage = require("../stage")

--* A letter, the keys renamed as UIBlox names them, and ones too wide for the square cap.
local KEYS = {
	Enum.KeyCode.M,
	Enum.KeyCode.LeftControl,
	Enum.KeyCode.LeftShift,
	Enum.KeyCode.LeftAlt,
	Enum.KeyCode.Escape,
	Enum.KeyCode.Return,
	Enum.KeyCode.Tab,
	Enum.KeyCode.F5,
	Enum.KeyCode.Tilde,
	Enum.KeyCode.Space,
	Enum.KeyCode.PageUp,
	Enum.KeyCode.NumLock,
}

local function keyNamed(name: string): Enum.KeyCode?
	for _, keyCode in Enum.KeyCode:GetEnumItems() do
		if keyCode.Name == name then
			return keyCode
		end
	end
	return nil
end

return stage.part({
	summary = "The keycaps tooltips draw shortcuts with, on the tooltip's surface. `key` takes any KeyCode name.",
	controls = {
		key = "Backspace",
	},
	build = function(controls)
		local tokens = VideFoundation.Hooks.useTokens()
		local caps: { any } = {}
		for index, keyCode in KEYS do
			caps[index] = KeyCap.KeyCap(function()
				return keyCode
			end, index)
		end
		table.insert(
			caps,
			Vide.values(function(): { Enum.KeyCode }
				local keyCode = keyNamed(controls.key())
				return if keyCode then { keyCode } else {}
			end, function(keyCode: Enum.KeyCode)
				return KeyCap.KeyCap(function()
					return keyCode
				end, #KEYS + 1)
			end)
		)

		return stage.row({
			VideFoundation.View({
				tag = "auto-xy row wrap gap-small padding-medium radius-medium",
				backgroundStyle = function()
					local surface = tokens().Color.Surface.Surface_300
					return { Color3 = surface.Color3, Transparency = surface.Transparency }
				end,
				children = caps,
			}),
		})
	end,
})
