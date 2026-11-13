local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local Vide = require("./Packages/Vide")

--* Roblox's updated health bar (TopBar/Components/Presentation/HealthBar.lua) sits at the topbar's right end while
--* health is below max. With Chrome on it registers no keep-out area, so TopbarInset ignores it and icons must make
--* room themselves. Widths by viewport width, from that file.
local WIDTH = 125
local WIDTH_SMALL = 80
local WIDTH_XSMALL = 50
local WIDTH_TENFOOT = 220
local BREAKPOINT_SMALL = 393
local BREAKPOINT_XSMALL = 320
--! StarterGui.CoreGuiChangedSignal is RobloxScript-only, so whether the game hid the health bar is polled.
local CORE_GUI_POLL = 1

local function widthFor(viewportWidth: number): number
	if GuiService:IsTenFootInterface() then
		return WIDTH_TENFOOT
	elseif viewportWidth <= BREAKPOINT_XSMALL then
		return WIDTH_XSMALL
	elseif viewportWidth <= BREAKPOINT_SMALL then
		return WIDTH_SMALL
	end
	return WIDTH
end

--- How wide Roblox's health bar is right now, 0 while it is hidden, for a screen `viewportWidth` wide.
local function useHealthBarWidth(viewportWidth: () -> number): () -> number
	local player = Players.LocalPlayer
	local enabled = Vide.source(StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Health))
	local hurt = Vide.source(false)

	local poll = task.spawn(function()
		while true do
			task.wait(CORE_GUI_POLL)
			enabled(StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Health))
		end
	end)
	Vide.cleanup(poll)

	local humanoidConnections: { RBXScriptConnection } = {}
	local watching: thread? = nil

	local function unwatch()
		for _, connection in humanoidConnections do
			connection:Disconnect()
		end
		table.clear(humanoidConnections)
		if watching then
			task.cancel(watching)
			watching = nil
		end
	end
	Vide.cleanup(unwatch)

	local function watch(character: Model?)
		unwatch()
		hurt(false)
		if character == nil then
			return
		end
		watching = task.spawn(function()
			local humanoid = character:WaitForChild("Humanoid", math.huge)
			watching = nil
			if humanoid == nil or not humanoid:IsA("Humanoid") then
				return
			end
			local function update()
				--* HealthBar.lua shows it whenever health is below max, dead included, whatever HealthDisplayType says.
				hurt(humanoid.Health < humanoid.MaxHealth)
			end
			table.insert(humanoidConnections, humanoid.HealthChanged:Connect(update))
			table.insert(humanoidConnections, humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(update))
			update()
		end)
	end

	if player then
		Vide.cleanup(player.CharacterAdded:Connect(watch))
		watch(player.Character)
	end

	return function()
		return if enabled() and hurt() then widthFor(viewportWidth()) else 0
	end
end

return useHealthBarWidth
