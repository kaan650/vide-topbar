local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local GroupView = require("./GroupView")
local IconView = require("./IconView")
local RowMenuView = require("./RowMenuView")
local Vide = require("./Packages/Vide")
local VideFoundation = require("./Packages/VideFoundation")
local create = require("./Utility/create")
local useFreeGap = require("./avoid")
local gamepad = require("./gamepad")
local layers = require("./layers")
local localize = require("./localize")
local overflow = require("./overflow")
local registry = require("./registry")
local shortcuts = require("./shortcuts")
local trackAbsolute = require("./Utility/trackAbsolute")
local types = require("./types")
local useBackplate = require("./Utility/useBackplate")
local useHealthBarWidth = require("./healthBar")

type Value<T> = VideFoundation.Value<T>
type Entry = registry.Entry
type Side = types.Side

export type MountOptions = {
	--- PlayerGui by default. In a story, pass a frame: the topbar runs along its top edge.
	target: Instance?,
	displayOrder: number?,
	enabled: Value<boolean>?,
	colorMode: Value<VideFoundation.ColorMode>?,
	--- The gamepad button that moves the selection onto the topbar, DPadUp by default. `false` leaves the topbar to the
	--- gamepad's virtual cursor.
	gamepadHighlightKey: (Enum.KeyCode | false)?,
	--- GUI objects that other code puts on the topbar, such as another library's icons. The icons keep to the widest
	--- stretch of the bar that the shown ones leave free, and those that no longer fit move into the overflow menu.
	--- Objects below the topbar, like an open dropdown, don't count.
	avoid: Value<{ GuiObject }>?,
}

local DEFAULT_DISPLAY_ORDER = 10
--* Roblox's ⋯ button: its "three-bars-horizontal" glyph and its "More" tooltip (CoreScripts.TopBar.MoreMenu).
local OVERFLOW_ICON = "three-bars-horizontal"
local OVERFLOW_TOOLTIP = "More"
local OVERFLOW_ORDER = 2 ^ 30
local DEFAULT_HIGHLIGHT_KEY = Enum.KeyCode.DPadUp
local RESTING_WIDTH_ATTRIBUTE = overflow.RESTING_WIDTH_ATTRIBUTE

local function sideOf(value: Value<Side>?): Side
	local side = if type(value) == "function" then value() else value
	return side or "Left"
end

local function entriesOn(side: Side): () -> { [number]: Entry }
	return Vide.derive(function()
		local onSide = {}
		for id, entry in registry.topbar.entries() do
			local entrySide = if entry.kind == "Icon"
				then sideOf(entry.props.side)
				elseif entry.kind == "Group" then sideOf(entry.props.side)
				else nil
			if entrySide == side then
				onSide[id] = entry
			end
		end
		return onSide
	end)
end

local function EntryView(entry: Entry, side: () -> Side, overflowAnchor: () -> GuiObject?): GuiObject?
	if entry.kind == "Icon" then
		local menu = entry.menu
		if menu and menu.style == "Row" then
			return RowMenuView(entry, side, overflowAnchor)
		end
		return IconView(entry, "Standalone", side, overflowAnchor)
	elseif entry.kind == "Group" then
		return GroupView(entry, side, overflowAnchor)
	end
	return nil
end

local function liveTopbarInset(): () -> Rect
	local inset = Vide.source(GuiService.TopbarInset)
	Vide.cleanup(GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(function()
		inset(GuiService.TopbarInset)
	end))
	return inset
end

--* The shape of FoundationProvider's `preferences` prop.
type Preferences = {
	preferredTextSize: Enum.PreferredTextSize?,
	preferredTransparency: number?,
	reducedMotion: boolean?,
	scale: number?,
}

local function livePreferences(): () -> Preferences?
	local function current(): Preferences?
		return {
			preferredTransparency = GuiService.PreferredTransparency,
			reducedMotion = GuiService.ReducedMotionEnabled,
		}
	end

	local preferences = Vide.source(current())
	for _, property in { "PreferredTransparency", "ReducedMotionEnabled" } do
		Vide.cleanup(GuiService:GetPropertyChangedSignal(property):Connect(function()
			preferences(current())
		end))
	end
	return preferences
end

type Hint = { icon: GuiObject, key: Enum.KeyCode }

--- A hint for a gamepad player: the highlight key under the icon it would select until they have used it, then B under
--- the selected icon until they have left the topbar with it once. Drawn like an icon, the button's glyph on the
--- topbar's backplate, under the icon rather than in it, so selecting an icon doesn't widen it and shift its
--- neighbours.
local function GamepadHint(
	layer: GuiObject,
	highlightKey: Enum.KeyCode?,
	state: gamepad.Gamepad,
	getRoot: () -> Instance?,
	isReady: () -> boolean
)
	local tokens = VideFoundation.Hooks.useTokens()
	local backplate = useBackplate()
	local layerPosition = trackAbsolute(layer)

	local preferredInput = Vide.source(UserInputService.PreferredInput)
	Vide.cleanup(UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
		preferredInput(UserInputService.PreferredInput)
	end))
	local selected = Vide.source(GuiService.SelectedObject)
	local getSelected: () -> GuiObject? = selected
	Vide.cleanup(GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(function()
		selected(GuiService.SelectedObject)
	end))

	--* Icons appear after the topbar does, so the hint looks again whenever the topbar's contents change, at most once a
	--* frame. Without it a player already on a gamepad never saw it.
	local contents = Vide.source(0)
	local pending = false
	Vide.effect(function()
		local root = getRoot()
		if root == nil then
			return
		end
		local function changed()
			if pending then
				return
			end
			pending = true
			task.defer(function()
				pending = false
				contents(Vide.untrack(contents) + 1)
			end)
		end
		Vide.cleanup(root.DescendantAdded:Connect(changed))
		Vide.cleanup(root.DescendantRemoving:Connect(changed))
	end)

	local function hint(): Hint?
		local root = getRoot()
		if preferredInput() ~= Enum.PreferredInput.Gamepad or root == nil then
			return nil
		end
		local selectedObject = getSelected()
		if selectedObject and gamepad.isInside(selectedObject, root) then
			if state.usedBack() or not selectedObject:GetAttribute(gamepad.ICON_ATTRIBUTE) then
				return nil
			end
			return { icon = selectedObject, key = Enum.KeyCode.ButtonB }
		end
		if highlightKey == nil or state.usedHighlight() then
			return nil
		end
		--* The holders stay hidden until TopbarInset loads, which adds nothing to the topbar, so the hint waits on that
		--* as well as on its contents.
		contents()
		if not isReady() then
			return nil
		end
		local icon = state.iconToSelect()
		return if icon then { icon = icon, key = highlightKey } else nil
	end

	--! Not `Vide.show(hint, ...)`: show reads its input from two nodes, and Vide's updates aren't glitch-free, so the
	--! component could be built before its value was set and index nil.
	local shown = Vide.source(nil :: Hint?)
	local getShown: () -> Hint? = shown
	Vide.effect(function()
		local nextHint = hint()
		local previous = Vide.untrack(getShown)
		if nextHint == nil then
			if previous ~= nil then
				shown(nil)
			end
		elseif previous == nil or previous.icon ~= nextHint.icon or previous.key ~= nextHint.key then
			shown(nextHint)
		end
	end)

	--* The hint moves from icon to icon with the selection, so it follows whichever icon it is under.
	local moved = Vide.source(0)
	Vide.effect(function()
		local current = getShown()
		if current == nil then
			return
		end
		local function bump()
			moved(Vide.untrack(moved) + 1)
		end
		Vide.cleanup(current.icon:GetPropertyChangedSignal("AbsolutePosition"):Connect(bump))
		Vide.cleanup(current.icon:GetPropertyChangedSignal("AbsoluteSize"):Connect(bump))
	end)

	local view = VideFoundation.View({
		tag = "radius-circle",
		Visible = function()
			return getShown() ~= nil
		end,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = function()
			moved()
			local current = getShown()
			if current == nil then
				return UDim2.new()
			end
			local icon = current.icon
			local position = icon.AbsolutePosition - layerPosition()
			return UDim2.fromOffset(
				position.X + icon.AbsoluteSize.X / 2,
				position.Y + icon.AbsoluteSize.Y + tokens().Gap.Small
			)
		end,
		Size = function()
			local size = tokens().Size.Size_900
			return UDim2.fromOffset(size, size)
		end,
		backgroundStyle = backplate,
		children = {
			VideFoundation.Image({
				ImageContent = function()
					local current = getShown()
					return if current
						then Content.fromUri(UserInputService:GetImageForKeyCode(current.key))
						else Content.none
				end,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = function()
					local size = tokens().Size.Size_600
					return UDim2.fromOffset(size, size)
				end,
			}),
		},
	})
	view.Name = "VideTopbarGamepadHint"
	view.Parent = layer
	Vide.cleanup(view)
end

--- The three holders. Without an inset (a story) the free area is the whole target.
local function Holders(
	inset: (() -> Rect)?,
	getRoot: () -> Instance?,
	highlightKey: Enum.KeyCode?,
	avoid: Value<{ GuiObject }>
): { GuiObject }
	local tokens = VideFoundation.Hooks.useTokens()

	--* Spacing from Roblox's TopBar/Constants.lua: buttons Gap.Medium from the top, Padding.Small after Roblox's
	--* own buttons and between icons, Gap.Large from the screen edge.
	local function top(): number
		return (if inset then inset().Min.Y else 0) + tokens().Gap.Medium
	end

	local function isReady(): boolean
		--* TopbarInset stays empty until Roblox's topbar has loaded.
		return inset == nil or inset().Height > 0
	end

	local function layer(name: string, zIndex: number): GuiObject
		local view = VideFoundation.View({
			tag = "size-full",
			ZIndex = zIndex,
		})
		view.Name = name
		return view
	end

	local menus = layer("Menus", 5)
	local tooltips = layer("Tooltips", 10)

	local layerPosition, screenSize = trackAbsolute(menus)
	local function screenWidth(): number
		return screenSize().X
	end
	local healthBarWidth = if inset then useHealthBarWidth(screenWidth) else nil

	--- Where the middle of the screen is in the topbar's space, which centre icons sit on. A phone with a camera cutout
	--- on one side only has a safe area off the screen's middle.
	local function screenMiddle(): number
		if inset == nil then
			return screenWidth() / 2
		end
		--* GetInsetArea has no changed signal; it is read again as the screen turns or Roblox's topbar changes.
		screenSize()
		inset()
		local screen = GuiService:GetInsetArea(Enum.ScreenInsets.None)
		local safe = GuiService:GetInsetArea(Enum.ScreenInsets.DeviceSafeInsets)
		return (screen.Min.X + screen.Max.X) / 2 - safe.Min.X
	end

	if inset then
		GamepadHint(tooltips, highlightKey, gamepad.useGamepad(getRoot, highlightKey), getRoot, isReady)
	end

	local gapStart, gapEnd = useFreeGap(avoid, layerPosition, function()
		return top(), top() + tokens().Size.Size_1100
	end, function()
		if inset then
			local area = inset()
			return area.Min.X, area.Max.X
		end
		return 0, screenWidth()
	end)

	--- Where the left holder starts: Padding.Small after Roblox's buttons, or after the start of the gap `avoid` leaves.
	local function leftStart(): number
		local start = (if inset then inset().Min.X else 0) + tokens().Padding.Small
		local avoided = gapStart()
		return if avoided then math.max(start, avoided + tokens().Padding.Small) else start
	end

	--- Where the right holder ends: Gap.Large from the free area's edge, or Padding.Small before Roblox's health bar
	--- while it shows, as Roblox spaces its own right-hand Unibar from it, or before the end of the gap `avoid`
	--- leaves. The bar ends Gap.Large from the screen's edge, wherever the free area ends.
	local function rightEnd(): number
		local right = (if inset then inset().Max.X else screenWidth()) - tokens().Gap.Large
		local healthBar = if healthBarWidth then healthBarWidth() else 0
		if healthBar > 0 then
			local healthBarLeft = screenWidth() - tokens().Gap.Large - healthBar
			right = math.min(right, healthBarLeft - tokens().Padding.Small)
		end
		local avoided = gapEnd()
		if avoided then
			right = math.min(right, avoided - tokens().Padding.Small)
		end
		return right
	end

	local entries: { [Side]: () -> { [number]: Entry } } = {
		Left = entriesOn("Left"),
		Center = entriesOn("Center"),
		Right = entriesOn("Right"),
	}

	--! Vide runs a scope's cleanups before it destroys what the scope owns, and cuts each scope from its owner, so while
	--! the topbar is removed its icons clean up with the providers above them already gone. A width written then
	--! re-planned the overflow and built an overflow icon outside them ("No StyleProvider found").
	local removing = false
	Vide.cleanup(function()
		removing = true
	end)

	--- Each drawn entry's width, by id, measured whether it is shown or hidden in an overflow menu.
	local widths = Vide.source({} :: { [number]: number })
	local function setWidth(id: number, width: number?)
		if removing then
			return
		end
		local current = Vide.untrack(widths)
		if current[id] ~= width then
			local updated = table.clone(current)
			updated[id] = width
			widths(updated)
		end
	end

	local function items(side: Side): { overflow.Item }
		local measured = widths()
		local list = {}
		for id, entry in entries[side]() do
			table.insert(list, { id = id, order = overflow.orderOf(entry), width = measured[id] or 0 })
		end
		return list
	end

	local hidden = Vide.derive(function(): overflow.Plan
		return overflow.plan({
			left = items("Left"),
			center = items("Center"),
			right = items("Right"),
			leftStart = leftStart(),
			rightEnd = rightEnd(),
			screenMiddle = screenMiddle(),
			gap = tokens().Padding.Small,
			overflowWidth = tokens().Size.Size_1100,
		})
	end)

	local function hiddenOn(side: Side): overflow.Hidden
		local plan = hidden()
		return if side == "Left" then plan.Left elseif side == "Right" then plan.Right else {}
	end

	local overflowButtons = {
		Left = Vide.source(nil :: GuiObject?),
		Right = Vide.source(nil :: GuiObject?),
	}

	--- The ⋯ holding `side`'s hidden entries: the side's own, or the one both sides share.
	local function overflowButtonFor(side: Side): GuiObject?
		local host = hidden().shared or side
		local button: (() -> GuiObject?)? = if host == "Left"
			then overflowButtons.Left
			elseif host == "Right" then overflowButtons.Right
			else nil
		return if button then button() else nil
	end

	--- The icon a side shows while some of its entries don't fit, holding them as rows of its menu, like the ⋯ menu
	--- Roblox moves Unibar items into. It sits at the side's screen edge.
	local function OverflowIcon(
		side: "Left" | "Right",
		button: Vide.Source<GuiObject?>,
		sideOf: () -> Side
	): () -> (GuiObject | { GuiObject })?
		local rows = registry.newContainer("Menu")
		Vide.effect(function()
			local plan = hidden()
			local sides: { overflow.HiddenSide } = {}
			if plan.shared == side then
				table.insert(sides, { hidden = plan.Left, entries = entries.Left() })
				table.insert(sides, { hidden = plan.Right, entries = entries.Right() })
			elseif plan.shared == nil then
				table.insert(sides, { hidden = hiddenOn(side), entries = entries[side]() })
			end
			rows.entries(overflow.rowsFor(sides))
		end)
		local overflowEntry: registry.IconEntry = {
			kind = "Icon",
			props = {
				icon = OVERFLOW_ICON,
				tooltip = OVERFLOW_TOOLTIP,
				order = if side == "Left" then -OVERFLOW_ORDER else OVERFLOW_ORDER,
			},
			menu = rows,
			isOverflow = true,
		}
		return Vide.show(function()
			local plan = hidden()
			local shown = if plan.shared then plan.shared == side else next(hiddenOn(side)) ~= nil
			return if shown then true else nil
		end, function()
			local view = IconView(overflowEntry, "Standalone", sideOf)
			button(view)
			Vide.cleanup(function()
				button(nil)
			end)
			return view
		end)
	end

	local function holder(side: Side, anchorPoint: Vector2, position: () -> UDim2): GuiObject
		local function sideOf(): Side
			return side
		end

		return VideFoundation.View({
			tag = "auto-x row align-y-center gap-small",
			AnchorPoint = anchorPoint,
			Position = position,
			Size = function()
				return UDim2.fromOffset(0, tokens().Size.Size_1100)
			end,
			Visible = isReady,
			children = {
				Vide.indexes(entries[side], function(entry: () -> Entry, id: number): GuiObject?
					local function isHidden(): boolean
						return hiddenOn(side)[id] == true
					end
					local view = EntryView(entry(), sideOf, function()
						return if isHidden() then overflowButtonFor(side) else nil
					end)
					if view == nil then
						return nil
					end

					--* A view reports the width it is heading for, so a row menu sliding open or shut reshuffles the
					--* overflow once rather than on every frame of it.
					local function measure()
						local resting = view:GetAttribute(RESTING_WIDTH_ATTRIBUTE)
						setWidth(id, if type(resting) == "number" then resting else view.AbsoluteSize.X)
					end
					Vide.cleanup(view:GetPropertyChangedSignal("AbsoluteSize"):Connect(measure))
					Vide.cleanup(view:GetAttributeChangedSignal(RESTING_WIDTH_ATTRIBUTE):Connect(measure))
					Vide.cleanup(function()
						setWidth(id, nil)
					end)
					measure()

					Vide.effect(function()
						view.Visible = not isHidden()
					end)
					return view
				end),
				if side == "Left"
					then OverflowIcon("Left", overflowButtons.Left, sideOf)
					elseif side == "Right" then OverflowIcon("Right", overflowButtons.Right, sideOf)
					else nil,
			},
		})
	end

	return layers.menuLayer(menus, function()
		return layers.tooltipLayer(tooltips, function()
			return {
				menus,
				tooltips,
				holder("Left", Vector2.zero, function()
					return UDim2.fromOffset(leftStart(), top())
				end),
				holder("Center", Vector2.new(0.5, 0), function()
					return UDim2.fromOffset(screenMiddle(), top())
				end),
				holder("Right", Vector2.new(1, 0), function()
					return UDim2.fromOffset(rightEnd(), top())
				end),
			}
		end)
	end)
end

--- Puts the topbar on screen and draws every icon added with `VideTopbar.Icon`. Returns a function that removes it.
local function mount(options: MountOptions?): () -> ()
	assert(not registry.isMounted(), "VideTopbar is already mounted")
	local resolved: MountOptions = options or {}
	local target = resolved.target or (Players.LocalPlayer :: Player):WaitForChild("PlayerGui")
	local isLive = target:IsA("PlayerGui")
	local enabled: Value<boolean> = if resolved.enabled == nil then true else resolved.enabled

	local destroy = Vide.root(function()
		registry.setMounted(true)
		Vide.cleanup(function()
			registry.setMounted(false)
		end)

		local inset = if isLive then liveTopbarInset() else nil
		local device: VideFoundation.Device = if isLive and GuiService:IsTenFootInterface()
			then "Console"
			else "Desktop"

		--* Shortcuts go through the Input Action System; a story has no player input to bind.
		local inputContext: InputContext? = nil
		if isLive then
			local context = Instance.new("InputContext")
			context.Name = "VideTopbarShortcuts"
			Vide.cleanup(context)
			inputContext = context
		end

		local configuredKey = resolved.gamepadHighlightKey
		local highlightKey: Enum.KeyCode? = if configuredKey == false
			then nil
			else configuredKey or DEFAULT_HIGHLIGHT_KEY
		--* A source, as the gamepad hint looks for icons once the ScreenGui exists.
		local rootInstance = Vide.source(nil :: Instance?)
		local getRoot: () -> Instance? = rootInstance

		local provider = VideFoundation.FoundationProvider({
			colorMode = resolved.colorMode or "Dark",
			device = device,
			preferences = if isLive then livePreferences() else nil,
			children = function()
				return shortcuts.inputContext(inputContext, function()
					return Holders(inset, getRoot, highlightKey, resolved.avoid or {})
				end)
			end,
		})

		local root: GuiBase2d = if isLive
			then create("ScreenGui")({
				Name = "VideTopbar",
				DisplayOrder = resolved.displayOrder or DEFAULT_DISPLAY_ORDER,
				--* TopbarInset is measured from the device's safe area, topbar strip included, which on a phone with a
				--* notch or round corners starts inside the screen (62 px in and 20 px down on an iPhone 17 Pro held
				--* sideways, measured in the device emulator); with None the icons sat that far off Roblox's buttons.
				--! Not with IgnoreGuiInset: the two set each other. DeviceSafeInsets turns it on; CoreUISafeInsets
				--! turns it off and drops the strip, and setting it after CoreUISafeInsets makes this DeviceSafeInsets.
				ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
				ResetOnSpawn = false,
				ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
				Enabled = enabled,
				provider,
			})
			else create("Frame")({
				Name = "VideTopbar",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Visible = enabled,
				provider,
			})
		localize.useAutoLocalize(root)
		root.Parent = target
		Vide.cleanup(root)
		rootInstance(root)
		if inputContext then
			inputContext.Parent = root
		end
	end)

	return destroy
end

return mount
