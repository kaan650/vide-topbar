local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)
local VideTopbar = require(ReplicatedStorage.Packages.VideTopbar)

VideTopbar.mount()

local shopOpen = Vide.source(false)

Vide.root(function()
	VideTopbar.Icon({
		icon = "shopping-cart",
		label = "Shop",
		selected = shopOpen,
		order = 1,
	})
	VideTopbar.Icon({
		icon = "gear",
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
	})

	Vide.effect(function()
		print("[Demo] shop open:", shopOpen())
	end)
end)
