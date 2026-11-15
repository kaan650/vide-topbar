local VideFoundation = require("./Packages/VideFoundation")
local types = require("./types")

--* Roblox's Unibar (Chrome/ChromeShared/Unibar/UnibarMenu.lua): dividers DIVIDER_CELL_WIDTH wide holding a 1 px line.
local DIVIDER_CELL_WIDTH = 5
local DIVIDER_WIDTH = 1

--- A divider between the icon cells of a group or a row menu.
local function DividerView(props: types.DividerProps): GuiObject
	local tokens = VideFoundation.Hooks.useTokens()

	return VideFoundation.View({
		Size = UDim2.new(0, DIVIDER_CELL_WIDTH, 1, 0),
		LayoutOrder = props.order,
		children = {
			VideFoundation.View({
				AnchorPoint = Vector2.new(0, 0.5),
				Position = function()
					return UDim2.new(0, tokens().Size.Size_50, 0.5, 0)
				end,
				Size = function()
					return UDim2.fromOffset(DIVIDER_WIDTH, tokens().Size.Size_700)
				end,
				backgroundStyle = function()
					local stroke = tokens().Color.Stroke.Emphasis
					return { Color3 = stroke.Color3, Transparency = stroke.Transparency }
				end,
			}),
		},
	})
end

return DividerView
