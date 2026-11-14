local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local Tooltip = require("@game/ReplicatedStorage/Packages/VideTopbar/Tooltip")
local useBackplate = require("@game/ReplicatedStorage/Packages/VideTopbar/Utility/useBackplate")
local stage = require("../stage")

local HOTKEYS: { [string]: { Enum.KeyCode } } = {
	none = {},
	M = { Enum.KeyCode.M },
	["Ctrl+M"] = { Enum.KeyCode.LeftControl, Enum.KeyCode.M },
	["Ctrl+Alt+Delete"] = { Enum.KeyCode.LeftControl, Enum.KeyCode.LeftAlt, Enum.KeyCode.Delete },
}

return stage.part({
	summary = "A tooltip held open under a stand-in icon. Slide `position` to an edge: the box moves in and the caret "
		.. "stays on the icon. Toggle `open` to see it spring in and out.",
	controls = {
		open = true,
		title = "Settings",
		hotkeys = UILabs.Choose({ "Ctrl+M", "M", "Ctrl+Alt+Delete", "none" }),
		position = UILabs.Slider(0.5, 0, 1, 0.01),
	},
	build = function(controls)
		local tokens = VideFoundation.Hooks.useTokens()
		local position: () -> number = controls.position

		local layer = VideFoundation.View({ tag = "size-full", ZIndex = 2 })
		local anchor = VideFoundation.View({
			tag = "radius-circle",
			AnchorPoint = function()
				return Vector2.new(position(), 0)
			end,
			Position = function()
				return UDim2.new(position(), 0, 0, tokens().Gap.Medium)
			end,
			Size = function()
				local size = tokens().Size.Size_1100
				return UDim2.fromOffset(size, size)
			end,
			backgroundStyle = useBackplate(),
			children = {
				VideFoundation.Icon({
					name = "gear",
					size = function()
						return tokens().Size.Size_600
					end,
					style = function()
						local emphasis = tokens().Color.Content.Emphasis
						return { Color3 = emphasis.Color3, Transparency = emphasis.Transparency }
					end,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
				}),
			},
		})

		Tooltip.Tooltip({
			anchor = anchor,
			layer = layer,
			triggerRadius = function()
				return tokens().Size.Size_900 / 2
			end,
			title = function()
				local title = controls.title()
				return if title == "" then nil else title
			end,
			hotkeys = function()
				return HOTKEYS[controls.hotkeys()] or {}
			end,
			isOpen = controls.open,
		})

		return { anchor, layer }
	end,
})
