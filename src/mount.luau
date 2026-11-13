local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

local IconView = require("./IconView")
local Vide = require("./Packages/Vide")
local VideFoundation = require("./Packages/VideFoundation")
local create = require("./Utility/create")
local layers = require("./layers")
local registry = require("./registry")
local types = require("./types")

type Value<T> = VideFoundation.Value<T>
type IconProps = types.IconProps
type Side = types.Side

export type MountOptions = {
	--- PlayerGui by default. In a story, pass a frame: the topbar runs along its top edge.
	target: Instance?,
	displayOrder: number?,
	enabled: Value<boolean>?,
	colorMode: Value<VideFoundation.ColorMode>?,
}

local DEFAULT_DISPLAY_ORDER = 10

local function iconsOn(side: Side): () -> { [number]: IconProps }
	return Vide.derive(function()
		local onSide = {}
		for id, props in registry.icons() do
			local value = props.side
			local iconSide = if type(value) == "function" then value() else value
			if (iconSide or "Left") == side then
				onSide[id] = props
			end
		end
		return onSide
	end)
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

--- The three holders. Without an inset (a story) the free area is the whole target.
--? TopbarInset may not account for a phone's notch; check in the device emulator.
local function Holders(inset: (() -> Rect)?): { GuiObject }
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

	local function holder(side: Side, anchorPoint: Vector2, position: () -> UDim2): GuiObject
		return VideFoundation.View({
			tag = "auto-x row align-y-center gap-small",
			AnchorPoint = anchorPoint,
			Position = position,
			Size = function()
				return UDim2.fromOffset(0, tokens().Size.Size_1100)
			end,
			Visible = isReady,
			children = Vide.indexes(iconsOn(side), function(props)
				return IconView(props())
			end),
		})
	end

	local tooltips = VideFoundation.View({
		tag = "size-full",
		ZIndex = 10,
	})
	tooltips.Name = "Tooltips"

	return layers.tooltipLayer(tooltips, function()
		return {
			tooltips,
			holder("Left", Vector2.zero, function()
				local left = if inset then inset().Min.X else 0
				return UDim2.fromOffset(left + tokens().Padding.Small, top())
			end),
			holder("Center", Vector2.new(0.5, 0), function()
				return UDim2.new(0.5, 0, 0, top())
			end),
			holder("Right", Vector2.new(1, 0), function()
				local edge = if inset then UDim2.fromOffset(inset().Max.X, 0) else UDim2.fromScale(1, 0)
				return edge + UDim2.fromOffset(-tokens().Gap.Large, top())
			end),
		}
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
		local provider = VideFoundation.FoundationProvider({
			colorMode = resolved.colorMode or "Dark",
			device = device,
			preferences = if isLive then livePreferences() else nil,
			children = function()
				return Holders(inset)
			end,
		})

		local root: GuiBase2d = if isLive
			then create("ScreenGui")({
				Name = "VideTopbar",
				DisplayOrder = resolved.displayOrder or DEFAULT_DISPLAY_ORDER,
				IgnoreGuiInset = true,
				ScreenInsets = Enum.ScreenInsets.None,
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
		root.Parent = target
		Vide.cleanup(root)
	end)

	return destroy
end

return mount
