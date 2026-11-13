local Tooltip = require("./Tooltip")
local Vide = require("./Packages/Vide")
local VideFoundation = require("./Packages/VideFoundation")
local layers = require("./layers")
local types = require("./types")

local show = Vide.show
local ControlState = VideFoundation.Enums.ControlState

--* Roblox's Unibar IconHost.lua caps badges at 99. Its 8 px from the top was measured live: the source reads it from
--* UnibarStyle in CorePackages, which is not on disk.
local MAX_BADGE = 99
local BADGE_TOP = 8

--- An icon as the topbar draws it, inside the topbar's FoundationProvider.
local function IconView(props: types.IconProps): GuiObject
	local tokens = VideFoundation.Hooks.useTokens()
	local preferences = VideFoundation.Hooks.usePreferences()
	local cursor = VideFoundation.Hooks.useCursor(VideFoundation.Enums.CursorType.SkinToneCircle)
	local tooltipLayer = layers.tooltipLayer()

	--! Vide.read infers the whole `T | () -> T` union under the new solver, so each prop is read with its own refinement.
	local function iconName(): string?
		local value = props.icon
		return if type(value) == "function" then value() else value
	end

	local function image(): Content?
		local value = props.image
		return if type(value) == "function" then value() else value
	end

	local function label(): string?
		local value = props.label
		local text = if type(value) == "function" then value() else value
		return if text == "" then nil else text
	end

	local function badge(): number | boolean | nil
		local value = props.badge
		return if type(value) == "function" then value() else value
	end

	local function tooltipTitle(): string?
		local value = props.tooltip
		local text = if type(value) == "function" then value() else value
		return if text == "" then nil else text
	end

	local function buttonSize(): number
		return tokens().Size.Size_1100
	end

	local function glyphSize(): number
		return tokens().Size.Size_600
	end

	local function hasGlyph(): boolean
		return iconName() ~= nil or image() ~= nil
	end

	--* Roblox's menu and Unibar glyphs measured rgb(247, 247, 248), the emphasis color, not the Icon default.
	local function glyphStyle(): { Color3: Color3?, Transparency: number? }
		local emphasis = tokens().Color.Content.Emphasis
		return { Color3 = emphasis.Color3, Transparency = emphasis.Transparency }
	end

	--* The glyph sits where it sits in a round icon, so a label grows the pill to the right only.
	local function glyphInset(): UDim
		return UDim.new(0, (buttonSize() - glyphSize()) / 2)
	end

	local function isSelected(): boolean
		local selected = props.selected
		return selected ~= nil and selected()
	end

	local function badgeCount(): number?
		local value = badge()
		return if type(value) == "number" and value > 0 then math.min(value, MAX_BADGE) else nil
	end

	local function hasBadge(): boolean?
		return if badge() == true or badgeCount() ~= nil then true else nil
	end

	local tooltipOpen = Vide.source(false)
	--* Like Roblox's, a click hides the tooltip until the pointer leaves and comes back.
	local latched = false
	local timer: thread? = nil

	local function cancelTimer()
		if timer then
			task.cancel(timer)
			timer = nil
		end
	end
	Vide.cleanup(cancelTimer)

	local function setTooltipLater(open: boolean, delay: number)
		cancelTimer()
		timer = task.delay(delay, function()
			timer = nil
			tooltipOpen(open)
		end)
	end

	local function onStateChanged(state: VideFoundation.ControlState)
		if state == ControlState.Hover then
			if latched then
				return
			end
			if tooltipOpen() then
				cancelTimer()
			elseif Tooltip.isGroupActive() then
				cancelTimer()
				tooltipOpen(true)
			else
				setTooltipLater(true, Tooltip.DELAY)
			end
		elseif state == ControlState.Default or state == ControlState.Disabled then
			latched = false
			if tooltipOpen() then
				setTooltipLater(false, Tooltip.LINGER)
			else
				cancelTimer()
			end
		end
	end

	local function onActivated()
		latched = true
		cancelTimer()
		tooltipOpen(false)

		local selected = props.selected
		if selected then
			selected(not selected())
		end
		if props.onActivated then
			props.onActivated()
		end
	end

	local button = VideFoundation.View({
		tag = "radius-circle auto-x",
		Size = function()
			return UDim2.fromOffset(buttonSize(), buttonSize())
		end,
		LayoutOrder = props.order,
		backgroundStyle = function()
			local backplate = tokens().Color.OverMedia.OverMedia_0
			return {
				Color3 = backplate.Color3,
				--* Roblox's own topbar buttons scale the backplate by the player's transparency setting.
				Transparency = backplate.Transparency * preferences().preferredTransparency,
			}
		end,
		selection = {
			Selectable = true,
			SelectionImageObject = cursor,
		},
		isDisabled = props.isDisabled,
		onActivated = onActivated,
		onStateChanged = onStateChanged,
		children = {
			--* The same 36 px circle Roblox's Unibar draws behind an icon whose menu is open.
			VideFoundation.View({
				tag = "radius-circle",
				Position = function()
					local inset = (buttonSize() - tokens().Size.Size_900) / 2
					return UDim2.fromOffset(inset, inset)
				end,
				Size = function()
					local inset = buttonSize() - tokens().Size.Size_900
					return UDim2.new(1, -inset, 1, -inset)
				end,
				backgroundStyle = function()
					local hover = tokens().Color.State.Hover
					return { Color3 = hover.Color3, Transparency = hover.Transparency }
				end,
				Visible = isSelected,
				ZIndex = 0,
			}),
			VideFoundation.View({
				tag = "auto-x row align-y-center gap-xsmall",
				Size = UDim2.fromScale(0, 1),
				padding = {
					left = function()
						return if hasGlyph() then glyphInset() else UDim.new(0, tokens().Padding.Medium)
					end,
					right = function()
						return if label() then UDim.new(0, tokens().Padding.Medium) else glyphInset()
					end,
				},
				children = {
					show(iconName, function(name)
						return VideFoundation.Icon({
							name = name,
							style = glyphStyle,
							size = glyphSize,
							LayoutOrder = 1,
						})
					end),
					show(function()
						return if iconName() == nil then image() else nil
					end, function(content)
						return VideFoundation.Image({
							ImageContent = content,
							Size = function()
								return UDim2.fromOffset(glyphSize(), glyphSize())
							end,
							LayoutOrder = 1,
						})
					end),
					show(label, function(text)
						return VideFoundation.Text({
							Text = text,
							tag = "auto-xy text-title-medium content-emphasis",
							LayoutOrder = 2,
						})
					end),
					--* With a label the badge trails it inside the pill, as Unibar's MenuTrailingBadge does in menu
					--* rows; on the glyph's corner it would cover the label's first letter.
					show(function()
						return if label() then hasBadge() else nil
					end, function()
						return {
							--* An empty item doubles the row gap between the label and the badge.
							VideFoundation.View({ LayoutOrder = 3 }),
							VideFoundation.StatusIndicator({
								value = badgeCount,
								variant = VideFoundation.Enums.StatusIndicatorVariant.Emphasis,
								LayoutOrder = 4,
							}),
						}
					end),
				},
			}),
			--* Without a label, on the glyph's corner as on Roblox's Unibar icons: a count as IconHost draws it, a dot
			--* inside the surface ring NineDotActivityIndicator draws, which moves the dot 2 px right and down.
			show(function()
				return if label() then nil else hasBadge()
			end, function()
				local function position(): UDim2
					return UDim2.fromOffset(tokens().Gap.XXLarge, BADGE_TOP)
				end
				return Vide.switch(function()
					return badgeCount() ~= nil
				end)({
					[true] = function()
						return VideFoundation.StatusIndicator({
							value = badgeCount,
							variant = VideFoundation.Enums.StatusIndicatorVariant.Emphasis,
							Position = position,
							ZIndex = 3,
						})
					end,
					[false] = function()
						return VideFoundation.View({
							tag = "auto-xy padding-xxsmall radius-circle bg-surface-0",
							Position = position,
							ZIndex = 3,
							children = {
								VideFoundation.StatusIndicator({
									variant = VideFoundation.Enums.StatusIndicatorVariant.Emphasis,
								}),
							},
						})
					end,
				})
			end),
		},
	})

	if tooltipLayer then
		Tooltip.Tooltip({
			anchor = button,
			layer = tooltipLayer,
			triggerRadius = function()
				return tokens().Size.Size_900 / 2
			end,
			title = tooltipTitle,
			isOpen = tooltipOpen,
		})
	end

	return button
end

return IconView
