local BadgeView = require("./BadgeView")
local MenuView = require("./MenuView")
local Tooltip = require("./Tooltip")
local Vide = require("./Packages/Vide")
local VideFoundation = require("./Packages/VideFoundation")
local gamepad = require("./gamepad")
local layers = require("./layers")
local overflow = require("./overflow")
local readBadge = require("./Utility/readBadge")
local useMenuTransition = require("./menuTransition")
local registry = require("./registry")
local shortcuts = require("./shortcuts")
local types = require("./types")
local useBackplate = require("./Utility/useBackplate")

local show = Vide.show
local ControlState = VideFoundation.Enums.ControlState

--* A corner badge sits 8 px from the top on Roblox's Unibar icons, measured live: IconHost reads it from UnibarStyle in
--* CorePackages, which is not on disk.
local BADGE_TOP = 8

--- "Standalone" is a round button of its own, like Roblox's menu button; "Cell" sits on a group's pill, like a
--- Unibar icon, and highlights a circle instead of its background.
export type Variant = "Standalone" | "Cell"

type ColorStyle = useBackplate.ColorStyle

local function withLayoutOrder(object: GuiObject, layoutOrder: number): GuiObject
	object.LayoutOrder = layoutOrder
	return object
end

--- An icon as the topbar draws it, inside the topbar's FoundationProvider. `overflowAnchor` returns the side's
--- overflow icon while this one is hidden in its menu, so this icon's own menu opens there instead.
local function IconView(
	entry: registry.IconEntry,
	variant: Variant,
	side: () -> types.Side,
	overflowAnchor: (() -> GuiObject?)?
): GuiObject
	local props = entry.props
	local menuRows = entry.menu
	local tokens = VideFoundation.Hooks.useTokens()
	local cursor = VideFoundation.Hooks.useCursor(VideFoundation.Enums.CursorType.SkinToneCircle)
	local backplate = useBackplate()
	local tooltipLayer = layers.tooltipLayer()
	local menuLayer = layers.menuLayer()

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

	--* A menu icon adds up its rows' badges, as TopbarPlus does for its menus and dropdowns; Roblox shows a dot on its
	--* ⋯ icon for activity inside, which a row's `true` or text badge gives here. The icon's own text wins.
	local function badge(): BadgeView.Badge
		local own = readBadge(props)
		if menuRows == nil or type(own) == "string" then
			return own
		end
		local count = if type(own) == "number" then math.max(own, 0) else 0
		local dot = own == true
		for _, row in menuRows.entries() do
			if row.kind == "Icon" then
				local rowBadge = readBadge(row.props)
				if type(rowBadge) == "number" then
					count += math.max(rowBadge, 0)
				elseif BadgeView.kindOf(rowBadge) ~= nil then
					dot = true
				end
			end
		end
		return if count > 0 then count elseif dot then true else nil
	end

	local function imageScale(): number
		local value = props.imageScale
		return (if type(value) == "function" then value() else value) or 1
	end

	local function imageRatio(): number
		local value = props.imageRatio
		return (if type(value) == "function" then value() else value) or 1
	end

	local function shortcutHint(): types.Shortcut?
		local value = props.shortcutHint
		return if type(value) == "function" then value() else value
	end

	local function isLocked(): boolean
		local value = props.isLocked
		return (if type(value) == "function" then value() else value) == true
	end

	local function autoDeselect(): boolean
		local value = props.autoDeselect
		return (if type(value) == "function" then value() else value) == true
	end

	local function closeOnOutsideClick(): boolean
		local value = props.closeOnOutsideClick
		return (if type(value) == "function" then value() else value) ~= false
	end

	local function tooltipTitle(): string?
		local value = props.tooltip
		local text = if type(value) == "function" then value() else value
		return if text == "" then nil else text
	end

	local function shortcut(): types.Shortcut?
		local value = props.shortcut
		return if type(value) == "function" then value() else value
	end

	local function minWidth(): number
		local value = props.minWidth
		return (if type(value) == "function" then value() else value) or 0
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
	local function glyphStyle(): ColorStyle
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

	local function hasBadge(): boolean?
		return if BadgeView.kindOf(badge()) ~= nil then true else nil
	end

	local controlState = Vide.source(ControlState.Default :: VideFoundation.ControlState)
	local menuOpen: Vide.Source<boolean> = props.menuOpen or Vide.source(false)
	local menuTransition, menuSpring = useMenuTransition(menuOpen)

	--* The 36 px circle Roblox draws behind a Unibar icon that is hovered, or whose window or menu is open. Its menu
	--* button fades it in with the menu, as HamburgerButton does.
	local function highlightStyle(): ColorStyle
		local colors = tokens().Color.State
		local current = controlState()
		local pressed = current == ControlState.Pressed or current == ControlState.SelectedPressed
		if variant == "Cell" and pressed then
			return { Color3 = colors.Press.Color3, Transparency = colors.Press.Transparency }
		end
		--* IconHost lights the circle for a gamepad selection as for a hover.
		local hovered = variant == "Cell" and (current == ControlState.Hover or current == ControlState.Selected)
		local strength = if isSelected() or hovered then 1 else menuTransition()
		return {
			Color3 = colors.Hover.Color3,
			Transparency = 1 - (1 - colors.Hover.Transparency) * strength,
		}
	end

	--* HamburgerButton shrinks its glyph out of a Size_900 frame and grows the x into a Size_700 one, each capped at
	--* the glyph size.
	local function glyphScale(): number
		if not menuRows then
			return glyphSize()
		end
		return math.min(glyphSize(), tokens().Size.Size_900 * (1 - menuTransition()))
	end

	local function closeScale(): number
		return math.min(glyphSize(), tokens().Size.Size_700 * menuTransition())
	end

	--* Kaan's choice: a labelled menu icon narrows into the round x while its menu is open, as TopbarPlus's menus swap
	--* their label for an X. Roblox has no labelled menu button to copy.
	local function collapses(): boolean
		return menuRows ~= nil and label() ~= nil
	end

	local function isCollapsing(): boolean
		return collapses() and menuTransition() > 0
	end

	--- How far the content has faded out: fully by the time the icon is half way to the x.
	local function contentFade(): number
		return if collapses() then math.min(1, menuTransition() * 2) else 0
	end

	local naturalWidth = Vide.source(0)

	--- How far the content sits from the left: centred when `minWidth` leaves room around it.
	local function contentOffset(): number
		return math.max(0, (minWidth() - naturalWidth()) / 2)
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
		controlState(state)
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

	local function activate()
		if isLocked() then
			return
		end
		latched = true
		cancelTimer()
		tooltipOpen(false)

		if menuRows then
			menuOpen(not menuOpen())
		end
		local selected = props.selected
		if selected then
			selected(not selected())
		end
		if (selected and selected()) or (menuRows and menuOpen()) then
			registry.latestSelection(entry)
		end
		if props.onActivated then
			props.onActivated()
		end
	end

	--* `autoDeselect` reacts to selections made after the icon was added, not to whatever was selected before it.
	local getLatestSelection: () -> registry.IconEntry? = registry.latestSelection
	local seenSelection = Vide.untrack(getLatestSelection)
	Vide.effect(function()
		local latest = getLatestSelection()
		if latest == seenSelection then
			return
		end
		seenSelection = latest
		if latest == entry or not Vide.untrack(autoDeselect) then
			return
		end
		local selected = props.selected
		if selected and Vide.untrack(selected) then
			selected(false)
		end
		menuOpen(false)
	end)

	shortcuts.useShortcut(shortcut, activate)
	registry.activators[entry] = activate
	Vide.cleanup(function()
		if registry.activators[entry] == activate then
			registry.activators[entry] = nil
		end
	end)

	local glyphSlot = show(function()
		return if hasGlyph() then true else nil
	end, function()
		--! Foundation's Icon drops `tag`, so the glyphs are centered with props: they scale from the middle.
		local anchor = Vector2.new(0.5, 0.5)
		local center = UDim2.fromScale(0.5, 0.5)
		--- An image's size: `imageScale` of the glyph size high, `imageRatio` times that wide.
		local function imageSize(): Vector2
			local height = glyphScale() * imageScale()
			return Vector2.new(height * imageRatio(), height)
		end

		return VideFoundation.View({
			--* The slot is the glyph's 24 px square, widened for an image wider than that.
			Size = function()
				local width = if iconName() == nil and image() ~= nil
					then math.max(glyphSize(), glyphSize() * imageScale() * imageRatio())
					else glyphSize()
				return UDim2.fromOffset(width, glyphSize())
			end,
			LayoutOrder = 2,
			children = {
				show(iconName, function(name)
					return VideFoundation.Icon({
						name = name,
						style = glyphStyle,
						size = glyphScale,
						AnchorPoint = anchor,
						Position = center,
					})
				end),
				show(function()
					return if iconName() == nil then image() else nil
				end, function(content)
					return VideFoundation.Image({
						ImageContent = content,
						AnchorPoint = anchor,
						Position = center,
						Size = function()
							local size = imageSize()
							return UDim2.fromOffset(size.X, size.Y)
						end,
					})
				end),
			},
		})
	end)

	--- Whether the icon is a pill sized by what it holds, rather than a round glyph.
	local function isPill(): boolean
		return label() ~= nil or props.leading ~= nil or props.trailing ~= nil
	end

	local button = VideFoundation.View({
		--* A pill sizes itself to its content while settled. A narrowing pill animates its width instead, and a round
		--* icon is sized from the measured content row: automatic size also counts the corner badge, which would
		--* widen the icon wherever it reached past the 44 px cell.
		tag = function()
			return if isPill() and not isCollapsing() then "radius-circle auto-x" else "radius-circle"
		end,
		Size = function()
			local size = buttonSize()
			if isCollapsing() then
				local resting = math.max(naturalWidth(), minWidth())
				local width = resting + (size - resting) * menuTransition()
				return UDim2.fromOffset(math.max(width, size), size)
			end
			local width = math.max(size, minWidth())
			if not isPill() then
				width = math.max(width, naturalWidth())
			end
			return UDim2.fromOffset(width, size)
		end,
		ClipsDescendants = collapses,
		LayoutOrder = props.order,
		backgroundStyle = if variant == "Standalone" then backplate else nil,
		stateLayer = if variant == "Cell" then { affordance = VideFoundation.Enums.StateLayerAffordance.None } else nil,
		selection = {
			Selectable = true,
			SelectionImageObject = cursor,
		},
		--* As IconHost: a gamepad never leaves the topbar upwards, and goes down only into the icon's open menu.
		selectionGroup = {
			SelectionBehaviorUp = Enum.SelectionBehavior.Stop,
			SelectionBehaviorDown = function()
				return if menuOpen() then Enum.SelectionBehavior.Escape else Enum.SelectionBehavior.Stop
			end,
		},
		isDisabled = props.isDisabled,
		onActivated = activate,
		onStateChanged = onStateChanged,
		children = {
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
				backgroundStyle = highlightStyle,
				ZIndex = 0,
			}),
			VideFoundation.View({
				tag = "auto-x row align-y-center gap-xsmall",
				Position = function()
					return UDim2.fromOffset(contentOffset(), 0)
				end,
				Size = UDim2.fromScale(0, 1),
				onAbsoluteSizeChanged = function(row: GuiObject)
					naturalWidth(row.AbsoluteSize.X)
				end,
				padding = {
					left = function()
						return if hasGlyph() then glyphInset() else UDim.new(0, tokens().Padding.Medium)
					end,
					right = function()
						return if label() then UDim.new(0, tokens().Padding.Medium) else glyphInset()
					end,
				},
				children = {
					if props.leading then withLayoutOrder(props.leading(), 1) else nil,
					glyphSlot,
					show(label, function(text)
						return VideFoundation.Text({
							Text = text,
							tag = "auto-xy text-title-medium",
							textStyle = function(): ColorStyle
								local emphasis = tokens().Color.Content.Emphasis
								local transparency = emphasis.Transparency
								return {
									Color3 = emphasis.Color3,
									Transparency = transparency + (1 - transparency) * contentFade(),
								}
							end,
							LayoutOrder = 3,
						})
					end),
					if props.trailing then withLayoutOrder(props.trailing(), 4) else nil,
					--* In a pill the badge trails the content, as Unibar's MenuTrailingBadge does in menu rows; on the
					--* glyph's corner it would cover the label's first letter.
					show(function()
						return if isPill() and contentFade() == 0 then hasBadge() else nil
					end, function()
						return {
							--* An empty item doubles the row gap between the label and the badge.
							VideFoundation.View({ LayoutOrder = 5 }),
							BadgeView.BadgeView({ value = badge, LayoutOrder = 6 }),
						}
					end),
				},
			}),
			--* On a round icon, on the glyph's corner as on Roblox's Unibar icons: a count as IconHost draws it, a dot
			--* inside the surface ring NineDotActivityIndicator draws, which moves the dot 2 px right and down.
			show(function()
				return if isPill() then nil else hasBadge()
			end, function()
				--* Kaan's choice: text shows as the dot here. Roblox only puts text badges on menu rows, and on a round
				--* icon a "NEW" covered the glyph beside it in a group.
				return BadgeView.BadgeView({
					value = function()
						local value = badge()
						return if type(value) == "string" then true else value
					end,
					ringed = true,
					Position = function()
						return UDim2.fromOffset(tokens().Gap.XXLarge + contentOffset(), BADGE_TOP)
					end,
					ZIndex = 3,
				})
			end),
			if menuRows
				then VideFoundation.Icon({
					name = "x",
					style = glyphStyle,
					size = closeScale,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					ZIndex = 2,
				})
				else nil,
		},
	})

	button:SetAttribute(gamepad.ICON_ATTRIBUTE, true)
	--* A locked icon takes no input at all, so it doesn't light up either, as TopbarPlus hides its click region.
	Vide.effect(function()
		button.Interactable = not isLocked()
	end)
	Vide.effect(function()
		button:SetAttribute(overflow.RESTING_WIDTH_ATTRIBUTE, math.max(naturalWidth(), minWidth(), buttonSize()))
	end)

	if tooltipLayer then
		Tooltip.Tooltip({
			anchor = button,
			layer = tooltipLayer,
			triggerRadius = function()
				return tokens().Size.Size_900 / 2
			end,
			title = tooltipTitle,
			hotkeys = function()
				return shortcuts.keysOf(shortcut() or shortcutHint())
			end,
			isOpen = tooltipOpen,
		})
	end

	if menuRows then
		local function close()
			menuOpen(false)
		end

		if menuLayer then
			local function anchor(): GuiObject
				return if overflowAnchor then overflowAnchor() or button else button
			end

			--- Where the list centres: on what it opens under, or on the round x a labelled icon narrows into. That x
			--- ends up at the edge its side's holder is anchored to; in the centre holder it drifts by half the narrowing.
			local function centerX(position: Vector2, extent: Vector2): number
				if anchor() ~= button or not collapses() then
					return position.X + extent.X / 2
				end
				local half = buttonSize() / 2
				return if side() == "Right" then position.X + extent.X - half else position.X + half
			end

			MenuView.MenuView({
				rows = menuRows,
				anchor = anchor,
				centerX = centerX,
				layer = menuLayer,
				isOpen = menuOpen,
				transition = menuTransition,
				spring = menuSpring,
				closeOnOutsideClick = closeOnOutsideClick,
				close = close,
			})
		end

		--* Rows' shortcuts work while the menu is closed too, for as long as the icon is on the topbar. An overflow
		--* menu's rows are icons that bind their own.
		Vide.indexes(registry.entriesOf(menuRows), function(rowEntry: () -> registry.Entry): nil
			local row = rowEntry()
			if row.kind == "Icon" and not entry.isOverflow then
				local rowProps = row.props
				shortcuts.useShortcut(function()
					local value = rowProps.shortcut
					return if type(value) == "function" then value() else value
				end, function()
					MenuView.activateRow(rowProps, close)
				end)
			end
			return nil
		end)
	end

	return button
end

return IconView
