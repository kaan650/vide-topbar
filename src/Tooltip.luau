local TextService = game:GetService("TextService")

local Vide = require("./Packages/Vide")
local VideFoundation = require("./Packages/VideFoundation")
local VideRipple = require("./Packages/VideRipple")
local create = require("./Utility/create")

--* Roblox's topbar tooltips are UIBlox's TooltipV2 (UIBlox/App/Dialog/TooltipV2 in the Studio install's
--* LuaPackages); the values below are its Constants.lua, opening downwards under a Unibar icon.
local CARET_SIZE = Vector2.new(16, 8)
local CARET_DISTANCE = 4
local CONTENT_TO_CARET_TIP = CARET_SIZE.Y - 1
local CONTENT_TO_CARET_CENTER = CONTENT_TO_CARET_TIP - CARET_SIZE.Y / 2
local SHADOW_TOP = 2
local SHADOW_BOTTOM = 6
local SHADOW_SIDE = 4
local SHADOW_SLICE = Rect.new(12, 12, 13, 13)
local SCREEN_MARGIN = 12
local MAX_WIDTH = 240
local MAX_HEADER_LINES = 2
--* UIBlox's GetTextSize pads every measurement by this.
local TEXT_SIZE_PADDING = Vector2.new(2, 2)
local HIDDEN_DISTANCE = -4
local SPRING: VideRipple.SpringOptions<number> = { dampingRatio = 1, frequency = 1 / 0.2 }

--* The 0.65 s delay and 0.1 s linger are Unibar IconHost's useTimeHysteresis(0.6, 0.65, 0.70); moving on to the next
--* icon within TOOLTIP_DISPLAY_COOLDOWN skips the delay, as areTooltipsDisplaying() snaps it there.
local DELAY = 0.65
local LINGER = 0.1
local GROUP_WINDOW = 0.15

type ColorStyleValue = { Color3: Color3?, Transparency: number? }

local SHADOW_STYLE: ColorStyleValue = { Color3 = Color3.new(0, 0, 0), Transparency = 0.5 }

local openCount = 0
local lastClosedAt = -math.huge

local function isGroupActive(): boolean
	return openCount > 0 or os.clock() - lastClosedAt < GROUP_WINDOW
end

local legacyFonts: { [string]: Enum.Font } = {}
for _, legacyFont in Enum.Font:GetEnumItems() do
	local ok, font = pcall(Font.fromEnum, legacyFont)
	if ok then
		legacyFonts[`{font.Family}|{font.Weight.Name}|{font.Style.Name}`] = legacyFont
	end
end

--- The Enum.Font that draws `font`, so TextService:GetTextSize can measure it without yielding, as UIBlox's
--- GetLegacyFont does. Builder Sans weights without their own enum fall back to the nearest one.
local function legacyFont(font: Font): Enum.Font
	local exact = legacyFonts[`{font.Family}|{font.Weight.Name}|{font.Style.Name}`]
	if exact then
		return exact
	end
	local weight = font.Weight.Value
	return if weight >= Enum.FontWeight.ExtraBold.Value
		then Enum.Font.BuilderSansExtraBold
		elseif weight >= Enum.FontWeight.SemiBold.Value then Enum.Font.BuilderSansBold
		elseif weight >= Enum.FontWeight.Medium.Value then Enum.Font.BuilderSansMedium
		else Enum.Font.BuilderSans
end

--! AbsolutePosition changes without its changed signal when an ancestor is parented (the tooltip layer read (0, 0)
--! while it sat at (0, -58)), so these subscribe to the signals but always return the live value.
local function trackAbsolute(instance: GuiObject): (() -> Vector2, () -> Vector2)
	local version = Vide.source(0)
	local function bump()
		version(version() + 1)
	end
	Vide.cleanup(instance:GetPropertyChangedSignal("AbsolutePosition"):Connect(bump))
	Vide.cleanup(instance:GetPropertyChangedSignal("AbsoluteSize"):Connect(bump))

	return function()
		version()
		return instance.AbsolutePosition
	end, function()
		version()
		return instance.AbsoluteSize
	end
end

export type TooltipProps = {
	anchor: GuiObject,
	layer: GuiObject,
	--- Half the height of what the tooltip points at: Unibar points at its 36 px hit circle, not the 44 px cell.
	triggerRadius: () -> number,
	title: () -> string?,
	isOpen: () -> boolean,
}

--- UIBlox's TooltipV2 rebuilt from Foundation tokens and images, drawn into `layer` under `anchor`.
local function Tooltip(props: TooltipProps)
	local tokens = VideFoundation.Hooks.useTokens()
	local preferences = VideFoundation.Hooks.usePreferences()
	local anchorPosition, anchorSize = trackAbsolute(props.anchor)
	local layerPosition, layerSize = trackAbsolute(props.layer)

	local function shownTitle(): string?
		return if props.isOpen() then props.title() else nil
	end

	local function surface(): ColorStyleValue
		local color = tokens().Color.Surface.Surface_300
		return {
			Color3 = color.Color3,
			Transparency = (color.Transparency or 0) * preferences().preferredTransparency,
		}
	end

	Vide.show(shownTitle, function(title, present)
		local visibility, spring = VideRipple.useSpring(0, SPRING)
		spring:setGoal(1)

		local counted = true
		openCount += 1
		local function release()
			if counted then
				counted = false
				openCount -= 1
				lastClosedAt = os.clock()
			end
		end
		Vide.cleanup(release)
		Vide.effect(function()
			if present() then
				spring:setGoal(1)
			else
				spring:setGoal(0)
				release()
			end
		end)

		local boxSize = Vide.source(Vector2.zero)

		local function triggerCenter(): Vector2
			return anchorPosition() - layerPosition() + anchorSize() / 2
		end

		--* TooltipController's getOrientationAndContentOffset: the box shifts away from the nearer screen edge until
		--* it clears the margin, while the caret stays on the trigger.
		local function contentOffset(): number
			local center = triggerCenter().X
			local half = boxSize().X / 2
			local toLeft = center - SCREEN_MARGIN
			local toRight = layerSize().X - center - SCREEN_MARGIN
			return if toLeft <= toRight then math.max(0, half - toLeft) else -math.max(0, half - toRight)
		end

		local function distanceOffset(): number
			if preferences().reducedMotion then
				return 0
			end
			--* Rounded as TooltipCallout does, so the slide steps the same way in every direction.
			return math.floor((1 - visibility()) * HIDDEN_DISTANCE + 0.5)
		end

		local boxTop = CONTENT_TO_CARET_TIP

		local group = VideFoundation.View({
			GroupTransparency = function()
				return 1 - visibility()
			end,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = function()
				local center = triggerCenter()
				local top = center.Y + props.triggerRadius() + CARET_DISTANCE + distanceOffset()
				return UDim2.fromOffset(center.X + contentOffset(), top)
			end,
			Size = function()
				local box = boxSize()
				return UDim2.fromOffset(box.X + SHADOW_SIDE * 2, boxTop + box.Y + SHADOW_BOTTOM)
			end,
			children = {
				VideFoundation.Image({
					Image = "component_assets/dropshadow_17_4",
					imageStyle = SHADOW_STYLE,
					slice = { center = SHADOW_SLICE },
					Position = UDim2.fromOffset(0, boxTop - SHADOW_TOP),
					Size = function()
						local box = boxSize()
						return UDim2.fromOffset(box.X + SHADOW_SIDE * 2, box.Y + SHADOW_TOP + SHADOW_BOTTOM)
					end,
					ZIndex = 1,
				}),
				VideFoundation.Image({
					Image = "component_assets/triangleDown_16",
					imageStyle = surface,
					Rotation = 180,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = function()
						local x = SHADOW_SIDE + boxSize().X / 2 - contentOffset()
						return UDim2.fromOffset(x, boxTop - CONTENT_TO_CARET_CENTER)
					end,
					Size = UDim2.fromOffset(CARET_SIZE.X, CARET_SIZE.Y),
					ZIndex = 2,
				}),
				VideFoundation.View({
					tag = "auto-xy col gap-small padding-medium radius-medium",
					backgroundStyle = surface,
					Position = UDim2.fromOffset(SHADOW_SIDE, boxTop),
					ZIndex = 2,
					onAbsoluteSizeChanged = function(box)
						boxSize(box.AbsoluteSize)
					end,
					children = {
						--! A raw TextLabel: Foundation's text-defaults rule overrides LineHeight 1, and a wrapped label
						--! with automatic width collapses to 0 px, so the size is measured the way TooltipCallout does.
						create("TextLabel")({
							Name = "Header",
							BackgroundTransparency = 1,
							Text = function()
								return title()
							end,
							FontFace = function()
								return tokens().Typography.CaptionMedium.Font
							end,
							TextSize = function()
								return tokens().Typography.CaptionMedium.FontSize
							end,
							LineHeight = 1,
							TextColor3 = function()
								return tokens().Color.Content.Emphasis.Color3
							end,
							TextTransparency = function()
								return tokens().Color.Content.Emphasis.Transparency
							end,
							TextXAlignment = Enum.TextXAlignment.Left,
							TextYAlignment = Enum.TextYAlignment.Center,
							TextWrapped = true,
							TextTruncate = Enum.TextTruncate.AtEnd,
							RichText = true,
							Size = function()
								local caption = tokens().Typography.CaptionMedium
								local maxSize = Vector2.new(
									MAX_WIDTH - tokens().Padding.Medium * 2,
									caption.FontSize * MAX_HEADER_LINES
								)
								local measured = TextService:GetTextSize(
									title(),
									caption.FontSize,
									legacyFont(caption.Font),
									Vector2.new(maxSize.X, math.huge)
								)
								local size = Vector2.new(measured.X, math.min(measured.Y, maxSize.Y))
									+ TEXT_SIZE_PADDING
								return UDim2.fromOffset(math.min(size.X, maxSize.X), math.min(size.Y, maxSize.Y))
							end,
						}),
					},
				}),
			},
		})
		group.Name = "VideTopbarTooltip"
		group.Parent = props.layer
		Vide.cleanup(group)

		return group, 0.3
	end)
end

return {
	DELAY = DELAY,
	LINGER = LINGER,
	isGroupActive = isGroupActive,
	Tooltip = Tooltip,
}
