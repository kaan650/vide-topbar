local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local Vide = require("./Packages/Vide")
local VideFoundation = require("./Packages/VideFoundation")
local BadgeView = require("./BadgeView")
local VideRipple = require("./Packages/VideRipple")
local create = require("./Utility/create")
local disabled = require("./Utility/disabled")
local gamepad = require("./gamepad")
local isPointOn = require("./Utility/isPointOn")
local menuBadge = require("./Utility/menuBadge")
local menuTransition = require("./menuTransition")
local overflow = require("./overflow")
local registry = require("./registry")
local trackAbsolute = require("./Utility/trackAbsolute")
local types = require("./types")
local useBackplate = require("./Utility/useBackplate")

local show = Vide.show
local ControlState = VideFoundation.Enums.ControlState
local IconVariant = VideFoundation.Enums.IconVariant

--* Roblox's ⋯ menu is the Unibar's SubMenu (Chrome/ChromeShared/Unibar/SubMenu.lua): four icon cells wide plus the
--* Unibar's left margin and end padding, rows of Size_1400. The 8 px gap under the bar and the 8 px corners were
--* measured on it; Constants.lua's 10 px values are overridden by UnibarStyle.

type ColorStyle = useBackplate.ColorStyle

local CLEAR: ColorStyle = { Color3 = Color3.new(0, 0, 0), Transparency = 1 }
--* Kaan's choice: a row's own list opens in place, with a row back at the top; Roblox's SubMenu has none to copy.
local OPENS_PAGE_ICON = "chevron-small-right"
local BACK_ICON = "chevron-small-left"
--* Above every row's LayoutOrder, which is an int32.
local BACK_ORDER = -2 ^ 31

export type MenuProps = {
	rows: registry.Container,
	--- What the menu opens under, read as it opens: the icon, or the overflow icon it is hidden in.
	anchor: () -> GuiObject,
	--- The screen X the list centres on, given where the anchor is.
	centerX: (anchorPosition: Vector2, anchorSize: Vector2) -> number,
	layer: GuiObject,
	isOpen: () -> boolean,
	--- The icon's menu transition, shared so the list and the icon's x move as one.
	transition: () -> number,
	spring: VideRipple.Spring<number>,
	closeOnOutsideClick: () -> boolean,
	close: () -> (),
	--- The rows whose own lists are open in place of this one, deepest last. Emptied once the list has closed.
	path: Vide.Source<{ registry.IconEntry }>,
}

--- What a row needs from its list.
type RowContext = {
	isOpen: () -> boolean,
	transition: () -> number,
	--- Whether pressing the row opens its own list in place of this one.
	opensPage: (entry: registry.IconEntry) -> boolean,
	press: (entry: registry.IconEntry) -> (),
}

local function isLocked(props: types.IconProps): boolean
	local value = props.isLocked
	return (if type(value) == "function" then value() else value) == true
end

--- Whether a row takes presses, from the list or from its shortcut.
local function canPress(props: types.IconProps): boolean
	return not isLocked(props) and not disabled.isDisabled(props)
end

--- What pressing a row does, from the list or from its shortcut. The menu closes either way, as Roblox's closes on
--- any click.
local function activateRow(props: types.IconProps, close: () -> ())
	if not canPress(props) then
		return
	end
	close()
	local selected = props.selected
	if selected then
		selected(not selected())
	end
	if props.onActivated then
		props.onActivated()
	end
end

--* Roblox's ⋯ menu names a row with its integration's label, which the icon's tooltip shows too, so an icon with
--* only a tooltip, as a bar icon often has, is named by it in a list.
local function labelOf(props: types.IconProps): string
	local label = props.label
	local text = if type(label) == "function" then label() else label
	if text == nil or text == "" then
		local tooltip = props.tooltip
		text = if type(tooltip) == "function" then tooltip() else tooltip
	end
	return text or ""
end

--- A row as SubMenu's MenuRow draws it: the icon in its cell, the label filling the rest, a badge trailing it.
local function MenuRow(entry: registry.IconEntry, layoutOrder: () -> number, context: RowContext): GuiObject
	local props = entry.props
	local tokens = VideFoundation.Hooks.useTokens()
	local cursor = VideFoundation.Hooks.useCursor(VideFoundation.Enums.CursorType.RoundedSlot)
	local state = Vide.source(ControlState.Default :: VideFoundation.ControlState)
	local transition = context.transition

	local function iconName(): string?
		local value = props.icon
		return if type(value) == "function" then value() else value
	end

	local function image(): Content?
		local value = props.image
		return if type(value) == "function" then value() else value
	end

	local function label(): string
		return labelOf(props)
	end

	local function badge(): BadgeView.Badge
		return menuBadge(props, entry.menu)
	end

	local function hasBadge(): boolean?
		return if BadgeView.kindOf(badge()) ~= nil then true else nil
	end

	local function opensPage(): boolean?
		return if context.opensPage(entry) then true else nil
	end

	local function imageSize(): Vector2
		local scale = props.imageScale
		local ratio = props.imageRatio
		local height = tokens().Size.Size_600 * ((if type(scale) == "function" then scale() else scale) or 1)
		return Vector2.new(height * ((if type(ratio) == "function" then ratio() else ratio) or 1), height)
	end

	local function hasGlyph(): boolean?
		return if iconName() ~= nil or image() ~= nil then true else nil
	end

	local function isSelected(): boolean
		local selected = props.selected
		return selected ~= nil and selected()
	end

	--* Everything in a row fades with the list, as CommonIcon fades SubMenu's icons: with reduced motion the list
	--* doesn't shrink away, so anything left opaque would stand on its own until the list is removed.
	local function fade(transparency: number): number
		return transparency + (1 - transparency) * (1 - transition())
	end

	local function faded(style: ColorStyle): ColorStyle
		return { Color3 = style.Color3, Transparency = fade(style.Transparency or 0) }
	end

	local function isDisabled(): boolean
		return disabled.isDisabled(props)
	end

	local function rowStyle(): ColorStyle
		local colors = tokens().Color.State
		local current = state()
		local color = if current == ControlState.Pressed
			then colors.Press
			elseif current == ControlState.Hover then colors.Hover
			else nil
		return if color then faded({ Color3 = color.Color3, Transparency = color.Transparency }) else CLEAR
	end

	local function glyphStyle(): ColorStyle
		local emphasis = tokens().Color.Content.Emphasis
		return faded({ Color3 = emphasis.Color3, Transparency = disabled.dimmed(emphasis.Transparency, isDisabled()) })
	end

	--* CommonIcon draws an integration's glyph filled while it is active, in a row as on the bar.
	local function glyphVariant(): "Regular" | "Filled"
		return if isSelected() then IconVariant.Filled else IconVariant.Regular
	end

	local function glyphSize(): number
		return tokens().Size.Size_600
	end

	return VideFoundation.View({
		tag = "radius-medium row align-y-center gap-small",
		Size = function()
			return UDim2.new(1, 0, 0, tokens().Size.Size_1400)
		end,
		LayoutOrder = layoutOrder,
		padding = {
			left = function()
				return UDim.new(0, tokens().Padding.Small)
			end,
			right = function()
				return UDim.new(0, tokens().Padding.Small)
			end,
		},
		backgroundStyle = rowStyle,
		stateLayer = { affordance = VideFoundation.Enums.StateLayerAffordance.None },
		selection = {
			Selectable = true,
			SelectionImageObject = cursor,
		},
		--* A closing list takes no more presses: with reduced motion it fades where it stands, and clicking a row
		--* again during the fade pressed it again.
		isDisabled = function()
			return not context.isOpen() or isDisabled()
		end,
		onStateChanged = function(newState: VideFoundation.ControlState)
			state(newState)
		end,
		onActivated = function()
			context.press(entry)
		end,
		children = {
			show(hasGlyph, function()
				local cell = tokens().Size.Size_1100
				local highlight = tokens().Size.Size_900
				--! Foundation's Icon drops `tag`, so everything in the cell is centered with props.
				local anchor = Vector2.new(0.5, 0.5)
				local center = UDim2.fromScale(0.5, 0.5)
				return VideFoundation.View({
					Size = UDim2.fromOffset(cell, cell),
					LayoutOrder = 1,
					children = {
						--* IconHost's SelectedHighlighter: the row's icon is circled while what it opens is open.
						VideFoundation.View({
							tag = "radius-circle",
							AnchorPoint = anchor,
							Position = center,
							Size = UDim2.fromOffset(highlight, highlight),
							backgroundStyle = function()
								local hover = tokens().Color.State.Hover
								return faded({ Color3 = hover.Color3, Transparency = hover.Transparency })
							end,
							Visible = isSelected,
						}),
						show(iconName, function(name)
							return VideFoundation.Icon({
								name = name,
								style = glyphStyle,
								variant = glyphVariant,
								size = glyphSize,
								AnchorPoint = anchor,
								Position = center,
							})
						end),
						show(function()
							return if iconName() == nil then image() else nil
						end, function(content)
							return VideFoundation.Image({
								ImageContent = content,
								--* White leaves the image's own colors untinted, as Image draws it without a style.
								imageStyle = function()
									return faded({
										Color3 = Color3.new(1, 1, 1),
										Transparency = disabled.dimmed(0, isDisabled()),
									})
								end,
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
			end),
			create("TextLabel")({
				Name = "Label",
				BackgroundTransparency = 1,
				LayoutOrder = 2,
				Size = UDim2.fromScale(0, 1),
				Text = label,
				FontFace = function()
					return tokens().Typography.TitleLarge.Font
				end,
				TextSize = function()
					return tokens().Typography.TitleLarge.FontSize
				end,
				LineHeight = 1,
				TextColor3 = function()
					return tokens().Color.Content.Emphasis.Color3
				end,
				--* MenuRow fades the label in with the menu.
				TextTransparency = function()
					return fade(disabled.dimmed(0, isDisabled()))
				end,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				RichText = true,
				create("UIFlexItem")({
					FlexMode = Enum.UIFlexMode.Fill,
				}),
			}),
			show(hasBadge, function()
				--! Foundation's badges take no transparency, so the badge fades as a CanvasGroup.
				return VideFoundation.View({
					tag = "auto-xy",
					LayoutOrder = 3,
					GroupTransparency = function()
						return 1 - transition()
					end,
					children = {
						BadgeView.BadgeView({ value = badge }),
					},
				})
			end),
			show(opensPage, function()
				return VideFoundation.Icon({
					name = OPENS_PAGE_ICON,
					style = glyphStyle,
					size = glyphSize,
					LayoutOrder = 4,
				})
			end),
		},
	})
end

--- The list an icon's `menu` opens, drawn into `layer` under `anchor` while `isOpen`. A row with a menu of its own
--- opens it in place of the list, which slides over to it.
local function MenuView(props: MenuProps)
	local tokens = VideFoundation.Hooks.useTokens()
	local preferences = VideFoundation.Hooks.usePreferences()
	local backplate = useBackplate()
	local layerPosition, layerSize = trackAbsolute(props.layer)
	local path = props.path
	local getPath: () -> { registry.IconEntry } = path

	local function rowCount(rows: registry.Container): number
		local count = 0
		for _, entry in rows.entries() do
			if entry.kind == "Icon" then
				count += 1
			end
		end
		return count
	end

	local function width(): number
		local size = tokens().Size
		local padding = tokens().Padding
		return size.Size_1100 * 4 + padding.Small + padding.XSmall * 2
	end

	--* An overflowed icon with a list still opens it under the ⋯, as it would on the bar. A row menu can't open
	--* sideways from inside a list, so its icons come in as a page.
	local function opensPage(entry: registry.IconEntry): boolean
		local rows = entry.menu
		return rows ~= nil and (entry.overflowOf == nil or rows.style == "Row")
	end

	--* One list per icon, as SubMenuHost has one menuTransition: pressing the icon again mid-animation turns the same
	--* list around instead of starting a new one, and the list is removed once it has fully closed.
	local transition = props.transition
	local mounted = Vide.source(false)

	--! Removing the list from inside the spring's own callback could destroy other animations mid-step (Ripple issue
	--! #23), so a closed list is removed a step later.
	local function unmountIfClosed()
		task.defer(function()
			if not props.isOpen() then
				mounted(false)
				path({})
			end
		end)
	end
	Vide.cleanup(props.spring:onComplete(unmountIfClosed))

	Vide.effect(function()
		if props.isOpen() then
			mounted(true)
		elseif Vide.untrack(transition) == 0 then
			unmountIfClosed()
		end
	end)

	show(function()
		return if mounted() then true else nil
	end, function()
		local trigger = Vide.untrack(props.anchor)
		local anchorPosition, anchorSize = trackAbsolute(trigger)

		--* SubMenuHost closes the menu on any click or tap; here a click on the list is left to its rows, which close
		--* it when pressed, so a disabled or locked row keeps it open as a desktop menu does. Roblox has no such rows.
		--* The click that opens it must not count, whichever of its events comes first, so closing is armed a frame
		--* after each opening. A click on the icon itself both closes it here and toggles it there; deferring this
		--* close lets either order end closed.
		local armed = false
		local arming: thread? = nil
		local function disarm()
			if arming then
				task.cancel(arming)
				arming = nil
			end
		end
		Vide.cleanup(disarm)
		Vide.effect(function()
			if props.isOpen() then
				disarm()
				armed = false
				arming = task.delay(0, function()
					arming = nil
					armed = true
				end)
			end
		end)

		local list: GuiObject? = nil

		local function isOnList(position: Vector2): boolean
			return list ~= nil and isPointOn(list, position)
		end

		local function closeFromOutside(position: Vector2)
			if armed and props.isOpen() and props.closeOnOutsideClick() and not isOnList(position) then
				task.defer(props.close)
			end
		end

		local lastTouch = Vector2.zero
		Vide.cleanup(UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				closeFromOutside(Vector2.new(input.Position.X, input.Position.Y))
			end
		end))
		Vide.cleanup(UserInputService.TouchStarted:Connect(function(touch)
			lastTouch = Vector2.new(touch.Position.X, touch.Position.Y)
		end))
		Vide.cleanup(UserInputService.TouchTap:Connect(function(positions)
			--* A drag that ends where it started is still a tap; one that moved is not.
			if positions[1] == lastTouch then
				closeFromOutside(lastTouch)
			end
		end))

		local function anchorBottom(): number
			return anchorPosition().Y - layerPosition().Y + anchorSize().Y
		end

		--* SubMenu keeps the topbar's height and an icon cell free under the list (here from the anchor's bottom, 2 px
		--* off), and when the rows don't fit it cuts the last one in half so the list reads as scrollable.
		local function fullHeight(count: number): number
			local rowHeight = tokens().Size.Size_1400
			local canvas = rowHeight * count
			local available = layerSize().Y - anchorBottom() - tokens().Size.Size_1100
			if canvas <= available then
				return canvas
			end
			local fitting = math.floor(available / rowHeight)
			local half = rowHeight * 0.5
			return if rowHeight * fitting + half <= available
				then rowHeight * fitting + half
				else rowHeight * fitting - half
		end

		--* Kaan's choice: centred under the icon, as TopbarPlus's dropdowns are, and kept inside the screen margin.
		--* Roblox's own list starts at the topbar's left edge instead, since it belongs to the Unibar there.
		local function position(): UDim2
			local margin = tokens().Gap.Large
			local left = props.centerX(anchorPosition(), anchorSize()) - layerPosition().X - width() / 2
			local x = math.clamp(left, margin, math.max(margin, layerSize().X - margin - width()))
			return UDim2.fromOffset(x, anchorBottom() + tokens().Gap.Small)
		end

		--- The page the list is on, sliding between whole pages: 0 is the menu's own rows, n the nth row opened.
		local page, pageSpring = VideRipple.useSpring(#Vide.untrack(getPath), menuTransition.SPRING)
		--- The rows whose pages are drawn: the open ones, and one being left until the slide back to its parent ends.
		local drawn = Vide.source(Vide.untrack(getPath))
		local getDrawn: () -> { registry.IconEntry } = drawn

		Vide.effect(function()
			local current = getPath()
			local reducedMotion = preferences().reducedMotion
			Vide.untrack(function()
				local shown = getDrawn()
				local leaving = #current < #shown
				for index, entry in current do
					if shown[index] ~= entry then
						leaving = false
						break
					end
				end
				if not leaving or reducedMotion then
					drawn(current)
				end
				pageSpring:setGoal(#current)
				if reducedMotion then
					pageSpring:setPosition(#current)
				end
				return nil
			end)
		end)
		Vide.cleanup(pageSpring:onComplete(function()
			task.defer(function()
				drawn(Vide.untrack(getPath))
			end)
		end))

		local function rowsAt(depth: number): registry.Container
			local entry = getDrawn()[depth]
			return if entry and entry.menu then entry.menu else props.rows
		end

		local function pageHeight(depth: number): number
			return fullHeight(rowCount(rowsAt(depth)) + (if depth > 0 then 1 else 0))
		end

		--* The list's height moves between two pages' as it slides from one to the other.
		local function height(): number
			local at = math.clamp(page(), 0, #getDrawn())
			local low = math.floor(at)
			local high = math.ceil(at)
			return pageHeight(low) + (pageHeight(high) - pageHeight(low)) * (at - low)
		end

		local rowViews = setmetatable({}, { __mode = "k" }) :: { [registry.IconEntry]: GuiObject }
		local backViews = setmetatable({}, { __mode = "k" }) :: { [registry.IconEntry]: GuiObject }
		local backRows = setmetatable({}, { __mode = "k" }) :: { [registry.IconEntry]: boolean }

		--* SubMenu with a gamepad keeps the selection in the list, so a page change moves it onto the new page.
		local function selectLater(target: () -> GuiObject?)
			if list == nil or not gamepad.isInside(GuiService.SelectedObject, list) then
				return
			end
			task.defer(function()
				local view = target()
				if view and view.Parent then
					GuiService.SelectedObject = view
				end
			end)
		end

		local function push(entry: registry.IconEntry)
			local nextPath = table.clone(Vide.untrack(getPath))
			table.insert(nextPath, entry)
			path(nextPath)
			selectLater(function()
				return backViews[entry]
			end)
		end

		local function pop(): boolean
			local current = Vide.untrack(getPath)
			local left = current[#current]
			if left == nil then
				return false
			end
			local nextPath = table.clone(current)
			table.remove(nextPath)
			path(nextPath)
			selectLater(function()
				return rowViews[left]
			end)
			return true
		end

		local function press(entry: registry.IconEntry)
			if backRows[entry] then
				pop()
			elseif opensPage(entry) then
				if canPress(entry.props) then
					push(entry)
				end
			else
				--* An overflowed icon's row presses the hidden icon, so its toggle, its menu and its tooltip state
				--* behave as on the bar.
				local hidden = entry.overflowOf
				local activateHidden = if hidden then registry.activators[hidden] else nil
				if activateHidden then
					props.close()
					activateHidden()
				else
					activateRow(entry.props, props.close)
				end
			end
		end

		local context: RowContext = {
			isOpen = props.isOpen,
			transition = transition,
			opensPage = opensPage,
			press = press,
		}

		local function Page(rows: registry.Container, parent: registry.IconEntry?, index: () -> number): GuiObject
			local back: GuiObject? = nil
			if parent then
				local backEntry: registry.IconEntry = {
					kind = "Icon",
					props = {
						icon = BACK_ICON,
						label = function()
							return labelOf(parent.props)
						end,
					},
				}
				backRows[backEntry] = true
				back = MenuRow(backEntry, function()
					return BACK_ORDER
				end, context)
				backViews[parent] = back
			end

			local function count(): number
				return rowCount(rows) + (if parent then 1 else 0)
			end

			return create("ScrollingFrame")({
				Name = "Page",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = function()
					return UDim2.fromOffset((index() - page()) * width(), 0)
				end,
				Size = function()
					return UDim2.fromOffset(width(), fullHeight(count()))
				end,
				--* Pages off to the side stay out of a gamepad's reach.
				Visible = function()
					return math.abs(index() - page()) < 1
				end,
				CanvasSize = function()
					return UDim2.fromOffset(0, tokens().Size.Size_1400 * count())
				end,
				ScrollBarThickness = 0,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				Selectable = false,
				create("UIListLayout")({
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				back,
				Vide.indexes(registry.entriesOf(rows), function(entry: () -> registry.Entry): GuiObject?
					local row = entry()
					if row.kind ~= "Icon" then
						return nil
					end
					--* An overflow menu's rows are rebuilt as icons come and go, which can move a row; its order is
					--* read live.
					local function layoutOrder(): number
						local current = entry()
						return if current.kind == "Icon"
							then current.rowOrder or overflow.readOrder(current.props)
							else 0
					end
					local view = MenuRow(row, layoutOrder, context)
					rowViews[row] = view
					return view
				end),
			})
		end

		local frame = VideFoundation.View({
			tag = "radius-medium",
			--* SubMenu stops a gamepad at its bottom row.
			selectionGroup = { SelectionBehaviorDown = Enum.SelectionBehavior.Stop },
			Position = position,
			Size = function()
				local full = height()
				--* SubMenu grows the list from the top, except with reduced motion.
				local shown = if preferences().reducedMotion then full else full * transition()
				return UDim2.fromOffset(width(), shown)
			end,
			ClipsDescendants = true,
			backgroundStyle = function(): ColorStyle
				local fill = backplate()
				local transparency = fill.Transparency or 0
				return {
					Color3 = fill.Color3,
					Transparency = transparency + (1 - transparency) * (1 - transition()),
				}
			end,
			children = {
				Page(props.rows, nil, function()
					return 0
				end),
				Vide.values(getDrawn, function(parent: registry.IconEntry, index: () -> number): GuiObject
					return Page(parent.menu :: registry.Container, parent, index)
				end),
			},
		})
		frame.Name = "VideTopbarMenu"
		list = frame
		frame.Parent = props.layer
		Vide.cleanup(frame)

		--* SubMenu with a gamepad: opening the menu from a selected icon moves the selection into the list, and pressing
		--* a row lets go of it (MenuRow's onMenuRowActivated). B is handled with the topbar's other gamepad input; it
		--* leaves a page before it closes the menu.
		gamepad.openMenus[frame] = { close = props.close, trigger = trigger, back = pop }
		Vide.cleanup(function()
			gamepad.openMenus[frame] = nil
		end)
		Vide.effect(function()
			if props.isOpen() then
				if GuiService.SelectedObject == trigger then
					task.defer(function()
						if props.isOpen() then
							GuiService:Select(frame)
						end
					end)
				end
			elseif gamepad.isInside(GuiService.SelectedObject, frame) then
				GuiService.SelectedObject = nil
			end
		end)

		return frame
	end)
end

return {
	activateRow = activateRow,
	canPress = canPress,
	MenuView = MenuView,
}
