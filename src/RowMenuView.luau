local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local DividerView = require("./DividerView")
local IconView = require("./IconView")
local Vide = require("./Packages/Vide")
local VideFoundation = require("./Packages/VideFoundation")
local gamepad = require("./gamepad")
local isPointOn = require("./Utility/isPointOn")
local menuTransition = require("./menuTransition")
local overflow = require("./overflow")
local registry = require("./registry")
local types = require("./types")
local useBackplate = require("./Utility/useBackplate")

--* Roblox's Unibar was built to collapse into its pinned icon and expand again (UnibarMenu.lua's toggleWidthTransition
--* and toggleIconTransition, never driven in this build): the pill's width follows the menu spring, and its icons come
--* out from behind the pinned one, clipped rather than faded.

--- An icon whose `menu` opens sideways: the icon is the first cell of a pill, and its menu's icons slide out of it
--- onto the rest. The right side's holder grows leftwards, so the icon stays at the screen's edge on every side.
local function RowMenuView(
	entry: registry.IconEntry,
	side: () -> types.Side,
	overflowAnchor: () -> GuiObject?
): GuiObject
	local props = entry.props
	local items = entry.menu :: registry.Container
	local tokens = VideFoundation.Hooks.useTokens()
	local backplate = useBackplate()

	local open: Vide.Source<boolean> = props.menuOpen or Vide.source(false)
	local transition, spring = menuTransition.useMenuTransition(open)
	local function close()
		open(false)
	end

	--* Hidden in an overflow menu, the row can't open here; its row there lists its icons instead.
	Vide.effect(function()
		if overflowAnchor() ~= nil and Vide.untrack(open) then
			open(false)
		end
	end)

	local toggle = IconView(entry, "Cell", side, overflowAnchor, {
		open = open,
		transition = transition,
		spring = spring,
	})

	local toggleWidth = Vide.source(toggle.AbsoluteSize.X)
	Vide.cleanup(toggle:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		toggleWidth(toggle.AbsoluteSize.X)
	end))
	local stripWidth = Vide.source(0)

	local function isRight(): boolean
		return side() == "Right"
	end

	local function endPadding(): number
		return tokens().Padding.XSmall
	end

	--- How much of the icons' strip shows.
	local function shown(): number
		return stripWidth() * transition()
	end

	local strip = VideFoundation.View({
		tag = "auto-x row align-y-center",
		AnchorPoint = function()
			return Vector2.new(if isRight() then 1 else 0, 0)
		end,
		Position = function()
			local behind = stripWidth() * (1 - transition())
			return if isRight() then UDim2.new(1, behind, 0, 0) else UDim2.fromOffset(-behind, 0)
		end,
		Size = UDim2.fromScale(0, 1),
		onAbsoluteSizeChanged = function(view: GuiObject)
			stripWidth(view.AbsoluteSize.X)
		end,
		children = Vide.indexes(registry.entriesOf(items), function(item: () -> registry.Entry): GuiObject?
			local child = item()
			if child.kind == "Icon" then
				return IconView(child, "Cell", side, overflowAnchor)
			elseif child.kind == "Divider" then
				return DividerView(child.props)
			end
			return nil
		end),
	})

	--- The strip's window, from the icon's edge outwards; closed, it is empty and keeps the icons out of reach.
	local reveal = VideFoundation.View({
		Position = function()
			return UDim2.fromOffset(endPadding() + (if isRight() then 0 else toggleWidth()), 0)
		end,
		Size = function()
			return UDim2.new(0, shown(), 1, 0)
		end,
		ClipsDescendants = true,
		Visible = function()
			return transition() > 0
		end,
		children = { strip },
	})

	Vide.effect(function()
		toggle.Position = UDim2.fromOffset(endPadding() + (if isRight() then shown() else 0), 0)
	end)

	local pill = VideFoundation.View({
		tag = "radius-circle",
		Size = function()
			return UDim2.fromOffset(endPadding() * 2 + toggleWidth() + shown(), tokens().Size.Size_1100)
		end,
		LayoutOrder = props.order,
		backgroundStyle = backplate,
		children = { reveal, toggle },
	})

	--* The overflow plan reads the width the pill is heading for, so it reshuffles once per opening and closing
	--* rather than on every frame of it.
	local toggleResting = Vide.source(0)
	local function readToggleResting()
		local resting = toggle:GetAttribute(overflow.RESTING_WIDTH_ATTRIBUTE)
		toggleResting(if type(resting) == "number" then resting else toggle.AbsoluteSize.X)
	end
	Vide.cleanup(toggle:GetAttributeChangedSignal(overflow.RESTING_WIDTH_ATTRIBUTE):Connect(readToggleResting))
	readToggleResting()
	Vide.effect(function()
		local width = endPadding() * 2 + toggleResting() + (if open() then stripWidth() else 0)
		pill:SetAttribute(overflow.RESTING_WIDTH_ATTRIBUTE, width)
	end)

	--* With a gamepad, B leaves an open row for its icon, as it leaves a list.
	Vide.effect(function()
		if open() then
			gamepad.openMenus[reveal] = { close = close, trigger = toggle }
		else
			gamepad.openMenus[reveal] = nil
			if gamepad.isInside(GuiService.SelectedObject, reveal) then
				GuiService.SelectedObject = toggle
			end
		end
	end)
	Vide.cleanup(function()
		gamepad.openMenus[reveal] = nil
	end)

	--* Kaan's choice: a row stays open until its x is pressed, unless `closeOnOutsideClick` asks for it. Then a click
	--* off the pill and off the lists its icons open closes it, armed a frame after opening as a list's is.
	local function closesOnOutsideClick(): boolean
		local value = props.closeOnOutsideClick
		return (if type(value) == "function" then value() else value) == true
	end

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
		if open() then
			disarm()
			armed = false
			arming = task.delay(0, function()
				arming = nil
				armed = true
			end)
		end
	end)

	local function closeFromOutside(point: Vector2)
		if not armed or not Vide.untrack(open) or not closesOnOutsideClick() or isPointOn(pill, point) then
			return
		end
		for frame in gamepad.openMenus do
			if frame ~= reveal and frame.Visible and isPointOn(frame, point) then
				return
			end
		end
		task.defer(close)
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
		if positions[1] == lastTouch then
			closeFromOutside(lastTouch)
		end
	end))

	return pill
end

return RowMenuView
