local IconView = require("./IconView")
local Vide = require("./Packages/Vide")
local VideFoundation = require("./Packages/VideFoundation")
local registry = require("./registry")
local types = require("./types")
local useBackplate = require("./Utility/useBackplate")

--* Roblox's Unibar (Chrome/ChromeShared/Unibar/UnibarMenu.lua): icon cells side by side on one pill with
--* UNIBAR_END_PADDING at both ends, and dividers DIVIDER_CELL_WIDTH wide holding a 1 px line.
local DIVIDER_CELL_WIDTH = 5
local DIVIDER_WIDTH = 1

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

--- A group's pill, with its icons drawn as Unibar cells. `overflowAnchor` is passed on to them (see IconView).
local function GroupView(
	group: registry.GroupEntry,
	side: () -> types.Side,
	overflowAnchor: (() -> GuiObject?)?
): GuiObject
	local tokens = VideFoundation.Hooks.useTokens()
	local backplate = useBackplate()

	local function endPadding(): UDim
		return UDim.new(0, tokens().Padding.XSmall)
	end

	return VideFoundation.View({
		tag = "auto-x row align-y-center radius-circle",
		Size = function()
			return UDim2.fromOffset(0, tokens().Size.Size_1100)
		end,
		LayoutOrder = group.props.order,
		backgroundStyle = backplate,
		padding = {
			left = endPadding,
			right = endPadding,
		},
		children = Vide.indexes(registry.entriesOf(group.items), function(entry: () -> registry.Entry): GuiObject?
			local item = entry()
			if item.kind == "Icon" then
				return IconView(item, "Cell", side, overflowAnchor)
			elseif item.kind == "Divider" then
				return DividerView(item.props)
			end
			return nil
		end),
	})
end

return GroupView
