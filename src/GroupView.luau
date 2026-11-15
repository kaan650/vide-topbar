local DividerView = require("./DividerView")
local IconView = require("./IconView")
local Vide = require("./Packages/Vide")
local VideFoundation = require("./Packages/VideFoundation")
local registry = require("./registry")
local types = require("./types")
local useBackplate = require("./Utility/useBackplate")

--* Roblox's Unibar (Chrome/ChromeShared/Unibar/UnibarMenu.lua): icon cells side by side on one pill with
--* UNIBAR_END_PADDING at both ends.

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
