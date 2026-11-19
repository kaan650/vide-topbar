local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
local Vide = require("@game/ReplicatedStorage/Packages/Vide")
local VideTopbar = require("@game/ReplicatedStorage/Packages/VideTopbar")
local create = require("@game/ReplicatedStorage/Packages/VideTopbar/Utility/create")
local stage = require("./stage")

local ICONS = { "gear", "bell", "star", "flag", "crown", "music-note", "house", "trophy" }
--* Where a story's topbar puts its icons: Padding.Small from the left, Gap.Large from the right, Gap.Medium from the
--* top, Size_1100 tall.
local STRIP_LEFT = 8
local STRIP_RIGHT = 16
local STRIP_TOP = 12
local STRIP_HEIGHT = 44
local OTHER_COLOR = Color3.fromRGB(196, 110, 36)

--- A stand-in for UI that other code put on the topbar.
local function Other(props: {
	name: string,
	text: string,
	position: UDim2,
	anchorPoint: Vector2?,
	size: () -> UDim2,
	visible: (() -> boolean)?,
}): Frame
	return create("Frame")({
		Name = props.name,
		AnchorPoint = props.anchorPoint or Vector2.zero,
		Position = props.position,
		Size = props.size,
		Visible = props.visible or true,
		BackgroundColor3 = OTHER_COLOR,
		BackgroundTransparency = 0.2,
		create("UICorner")({ CornerRadius = UDim.new(0, 8) }),
		create("TextLabel")({
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = props.text,
			TextColor3 = Color3.new(1, 1, 1),
			FontFace = Font.fromName("BuilderSans", Enum.FontWeight.Medium),
			TextSize = 15,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}),
	})
end

return stage.topbar({
	summary = "`avoid` keeps the icons clear of UI that other code puts on the topbar, here in orange: they keep to "
		.. "the widest stretch of the bar it leaves free, and what no longer fits moves into the ⋯ menu. Hidden UI, "
		.. "and UI under the topbar like an open dropdown, doesn't count.",
	screen = "Tablet 768",
	controls = {
		otherLeft = UILabs.Slider(140, 0, 400, 10),
		otherRight = UILabs.Slider(90, 0, 400, 10),
		otherShown = true,
		dropdown = false,
		left = UILabs.Slider(3, 0, 12, 1),
		right = UILabs.Slider(2, 0, 12, 1),
	},
	options = function(controls, scene)
		local otherLeft: () -> number = controls.otherLeft
		local otherRight: () -> number = controls.otherRight
		local otherShown: () -> boolean = controls.otherShown
		local dropdown: () -> boolean = controls.dropdown

		local left = Other({
			name = "OtherLeft",
			text = "Other UI",
			position = UDim2.fromOffset(STRIP_LEFT, STRIP_TOP),
			size = function()
				return UDim2.fromOffset(otherLeft(), STRIP_HEIGHT)
			end,
		})
		local right = Other({
			name = "OtherRight",
			text = "Other UI",
			anchorPoint = Vector2.new(1, 0),
			position = UDim2.new(1, -STRIP_RIGHT, 0, STRIP_TOP),
			size = function()
				return UDim2.fromOffset(otherRight(), STRIP_HEIGHT)
			end,
		})
		local list = Other({
			name = "OtherDropdown",
			text = "Dropdown",
			position = UDim2.fromOffset(STRIP_LEFT, STRIP_TOP + STRIP_HEIGHT + 8),
			size = function()
				return UDim2.fromOffset(200, 160)
			end,
			visible = dropdown,
		})

		create("Frame")({
			Name = "OtherUI",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Visible = otherShown,
			Parent = scene,
			left,
			right,
			list,
		})
		return { avoid = { left, right, list } }
	end,
	build = function(controls)
		Vide.indexes(stage.upTo(controls.left), function(_, index: number)
			VideTopbar.Icon({
				order = index,
				icon = ICONS[(index - 1) % #ICONS + 1],
				label = if index == 1 then "Shop" else nil,
				tooltip = `Left {index}`,
				onActivated = stage.action(`left {index}`),
			})
			return nil
		end)

		Vide.indexes(stage.upTo(controls.right), function(_, index: number)
			VideTopbar.Icon({
				side = "Right",
				order = -index,
				icon = ICONS[(index + 3) % #ICONS + 1],
				tooltip = `Right {index}`,
				onActivated = stage.action(`right {index}`),
			})
			return nil
		end)
	end,
})
