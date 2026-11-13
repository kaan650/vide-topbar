local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)
local VideTopbar = require(ReplicatedStorage.Packages.VideTopbar)

VideTopbar.mount()

local shopOpen = Vide.source(false)
local unread = Vide.source(3)

Vide.root(function()
	VideTopbar.Icon({
		icon = "shopping-cart",
		label = "Shop",
		selected = shopOpen,
		badge = unread,
		tooltip = "Open the shop",
		order = 1,
		onActivated = function()
			unread(0)
		end,
	})
	VideTopbar.Icon({
		icon = "gear",
		tooltip = "Settings",
		order = 2,
		onActivated = function()
			print("[Demo] settings")
		end,
	})
	VideTopbar.Icon({
		side = "Center",
		label = "Round 1",
	})
	VideTopbar.Icon({
		side = "Right",
		icon = "bell",
		badge = true,
		tooltip = "Notifications",
	})

	Vide.effect(function()
		print("[Demo] shop open:", shopOpen())
	end)
end)
