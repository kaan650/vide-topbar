local Vide = require("@game/ReplicatedStorage/Packages/Vide")
local VideTopbar = require("@game/ReplicatedStorage/Packages/VideTopbar")
local stage = require("./stage")

return stage.topbar({
	summary = '`menuStyle = "Row"` opens a menu sideways: its icons slide out onto the pill, as Roblox\'s Unibar was '
		.. "built to expand, and a glyph turns into an x while a label stays. It stays open until the icon is pressed "
		.. "again, unless `closeOnOutsideClick` is on.",
	controls = {
		open = false,
		closeOnOutsideClick = false,
	},
	build = function(controls)
		local liked = Vide.source(false)

		VideTopbar.Icon({
			order = 1,
			icon = "star",
			tooltip = "`open` opens this one from code",
			menuStyle = "Row",
			menuOpen = stage.mirror(controls.open),
			closeOnOutsideClick = controls.closeOnOutsideClick,
			menu = function()
				VideTopbar.Icon({ order = 1, icon = "bell", tooltip = "Notifications", badge = 2 })
				VideTopbar.Icon({ order = 2, icon = "heart", tooltip = "A toggle", selected = liked })
				VideTopbar.Divider({ order = 3 })
				VideTopbar.Icon({
					order = 4,
					icon = "trophy",
					tooltip = "Its own list opens under it",
					menu = function()
						VideTopbar.Icon({
							order = 1,
							icon = "star",
							label = "Daily",
							onActivated = stage.action("daily"),
						})
						VideTopbar.Icon({
							order = 2,
							icon = "crown",
							label = "Season",
							onActivated = stage.action("season"),
						})
					end,
				})
				VideTopbar.Icon({ order = 5, image = stage.images.shop, tooltip = "An image" })
			end,
		})
		VideTopbar.Icon({ order = 2, icon = "house", tooltip = "A neighbour, pushed along as the row opens" })

		VideTopbar.Icon({
			side = "Center",
			label = "Emotes",
			menuStyle = "Row",
			menu = function()
				for index, icon in { "heart", "star", "music-note" } do
					VideTopbar.Icon({ order = index, icon = icon, onActivated = stage.action(icon) })
				end
			end,
		})

		VideTopbar.Icon({
			side = "Right",
			order = 1,
			icon = "three-bars-horizontal",
			tooltip = "On the right the pill grows leftwards",
			menuStyle = "Row",
			menu = function()
				VideTopbar.Icon({ order = 1, icon = "flag", tooltip = "Report", badge = "NEW" })
				VideTopbar.Icon({ order = 2, icon = "magnifying-glass", tooltip = "Search" })
				VideTopbar.Icon({ order = 3, icon = "bell", tooltip = "Inbox", badge = 5 })
			end,
		})
	end,
})
