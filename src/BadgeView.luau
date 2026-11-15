local Vide = require("./Packages/Vide")
local VideFoundation = require("./Packages/VideFoundation")

type Value<T> = VideFoundation.Value<T>

--* Roblox's Unibar IconHost.lua caps badges at 99. Kaan's choice: a count past it reads 99+.
local MAX_BADGE = 99

export type Badge = number | boolean | string | nil
export type BadgeKind = "Count" | "Dot" | "Text"

local function kindOf(value: Badge): BadgeKind?
	if type(value) == "string" then
		return if value ~= "" then "Text" else nil
	elseif type(value) == "number" then
		return if value > 0 then "Count" else nil
	elseif value == true then
		return "Dot"
	end
	return nil
end

local function countOf(value: Badge): number?
	return if type(value) == "number" and value > 0 then value else nil
end

export type BadgeViewProps = {
	value: () -> Badge,
	--- Draws a dot inside a surface ring, as NineDotActivityIndicator does on an icon's corner.
	ringed: boolean?,
	--- Fades the whole badge, as a disabled icon or a closing list fades its content.
	--! Foundation's badges take no transparency, so a badge given one is drawn in a CanvasGroup.
	transparency: (() -> number)?,
	Position: Value<UDim2>?,
	LayoutOrder: number?,
	ZIndex: number?,
}

--- A badge as Roblox draws one: a count or a dot in Foundation's emphasis StatusIndicator, and text, like TopbarPlus's
--- notice label, in a Badge of the same blue.
local function BadgeView(props: BadgeViewProps): GuiObject
	local variant = VideFoundation.Enums.StatusIndicatorVariant.Emphasis

	local badge = Vide.switch(function()
		return kindOf(props.value())
	end)({
		Count = function()
			return VideFoundation.StatusIndicator({
				value = function()
					return countOf(props.value())
				end,
				max = MAX_BADGE,
				variant = variant,
			})
		end,
		Dot = function()
			if not props.ringed then
				return VideFoundation.StatusIndicator({ variant = variant })
			end
			return VideFoundation.View({
				tag = "auto-xy padding-xxsmall radius-circle bg-surface-0",
				children = {
					VideFoundation.StatusIndicator({ variant = variant }),
				},
			})
		end,
		Text = function()
			return VideFoundation.Badge({
				text = function()
					local value = props.value()
					return if type(value) == "string" then value else nil
				end,
				variant = VideFoundation.Enums.BadgeVariant.Emphasis,
				size = VideFoundation.Enums.BadgeSize.XSmall,
			})
		end,
	})

	return VideFoundation.View({
		tag = "auto-xy",
		GroupTransparency = props.transparency,
		Position = props.Position,
		LayoutOrder = props.LayoutOrder,
		ZIndex = props.ZIndex,
		children = { badge },
	})
end

return {
	kindOf = kindOf,
	BadgeView = BadgeView,
}
