local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
local Vide = require("@game/ReplicatedStorage/Packages/Vide")
local VideTopbar = require("@game/ReplicatedStorage/Packages/VideTopbar")
local stage = require("./stage")

return stage.topbar({
	summary = "Each badge on each kind of icon: a count (capped at 99), a dot and text. Round icons show text as the "
		.. "dot; a menu icon adds up its rows' badges.",
	controls = {
		count = UILabs.Slider(3, 0, 150, 1),
		text = "NEW",
	},
	build = function(controls)
		local count: () -> number = controls.count
		local text: () -> string = controls.text

		VideTopbar.Icon({ order = 1, icon = "bell", badge = count, tooltip = "Count" })
		VideTopbar.Icon({ order = 2, icon = "gear", badge = true, tooltip = "Dot" })
		VideTopbar.Icon({ order = 3, icon = "shopping-cart", badge = text, tooltip = "Text, as a dot" })
		VideTopbar.Icon({ order = 4, icon = "speech-bubble-round", label = "Inbox", badge = count })
		VideTopbar.Icon({ order = 5, label = "Quests", badge = true })
		VideTopbar.Icon({ order = 6, icon = "shopping-cart", label = "Shop", badge = text })

		VideTopbar.Group({ side = "Right", order = 1 }, function()
			VideTopbar.Icon({ order = 1, icon = "bell", badge = count, tooltip = "Count" })
			VideTopbar.Icon({ order = 2, icon = "gear", badge = true, tooltip = "Dot" })
			VideTopbar.Icon({ order = 3, icon = "shopping-cart", badge = text, tooltip = "Text, as a dot" })
		end)

		local inventory = Vide.source(2)
		VideTopbar.Icon({
			side = "Right",
			order = 2,
			label = "Menu",
			badge = count,
			menu = function()
				VideTopbar.Icon({
					order = 1,
					icon = "backpack",
					label = "Inventory (press to clear)",
					badge = inventory,
					onActivated = function()
						inventory(0)
					end,
				})
				VideTopbar.Icon({ order = 2, icon = "trophy", label = "Quests", badge = true })
				VideTopbar.Icon({ order = 3, icon = "shopping-cart", label = "Shop", badge = text })
			end,
		})
	end,
})
