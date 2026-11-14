local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
local Vide = require("@game/ReplicatedStorage/Packages/Vide")
local VideTopbar = require("@game/ReplicatedStorage/Packages/VideTopbar")
local stage = require("./stage")

local FILLER_ICONS = { "gear", "bell", "star", "flag", "crown", "music-note", "house", "magnifying-glass" }

return stage.topbar({
	summary = "Menus open Roblox's ⋯ list under their icon. A labelled icon narrows into an x, and `rows` adds rows "
		.. "until the list cuts its last one in half to show it scrolls.",
	controls = {
		open = false,
		closeOnOutsideClick = true,
		rows = UILabs.Slider(6, 1, 24, 1),
	},
	build = function(controls)
		local rows: () -> number = controls.rows
		local shopSelected = Vide.source(false)
		local extraRows = Vide.derive(function()
			local list = {}
			for index = 7, rows() do
				list[index] = index
			end
			return list
		end)

		VideTopbar.Icon({
			order = 1,
			icon = "three-bars-horizontal",
			label = "Menu",
			tooltip = "`open` opens this one from code",
			menuOpen = stage.mirror(controls.open),
			closeOnOutsideClick = controls.closeOnOutsideClick,
			menu = function()
				VideTopbar.Icon({
					order = 1,
					icon = "shopping-cart",
					label = "Toggle",
					selected = shopSelected,
					badge = "NEW",
				})
				VideTopbar.Icon({ order = 2, icon = "bell", label = "Notifications", badge = 4 })
				VideTopbar.Icon({ order = 3, image = stage.images.premium, label = "An image row" })
				VideTopbar.Icon({ order = 4, label = "A row with no glyph", onActivated = stage.action("no glyph") })
				VideTopbar.Icon({ order = 5, icon = "lock-closed", label = "Disabled", isDisabled = true })
				VideTopbar.Icon({ order = 6, icon = "trophy", label = "Locked", isLocked = true })
				Vide.indexes(extraRows, function(_, index: number)
					local icon = FILLER_ICONS[(index - 7) % #FILLER_ICONS + 1]
					VideTopbar.Icon({
						order = index,
						icon = icon,
						label = `Row {index}`,
						onActivated = stage.action(icon),
					})
					return nil
				end)
			end,
		})
		VideTopbar.Icon({
			order = 2,
			icon = "gear",
			tooltip = "A menu without a label: the glyph turns into the x",
			menu = function()
				VideTopbar.Icon({ order = 1, icon = "gear", label = "Settings", onActivated = stage.action("settings") })
				VideTopbar.Icon({ order = 2, icon = "flag", label = "Report", onActivated = stage.action("report") })
			end,
		})

		VideTopbar.Icon({
			side = "Center",
			order = 1,
			label = "Mode",
			menu = function()
				VideTopbar.Icon({ order = 1, label = "Classic", onActivated = stage.action("classic") })
				VideTopbar.Icon({ order = 2, label = "Ranked", onActivated = stage.action("ranked") })
			end,
		})

		VideTopbar.Group({ side = "Right", order = 1 }, function()
			VideTopbar.Icon({ order = 1, icon = "bell", tooltip = "Notifications" })
			VideTopbar.Icon({
				order = 2,
				icon = "three-bars-horizontal",
				tooltip = "More",
				menu = function()
					VideTopbar.Icon({ order = 1, icon = "gear", label = "Settings" })
					VideTopbar.Icon({ order = 2, icon = "house", label = "Leave" })
				end,
			})
		end)
		VideTopbar.Icon({
			side = "Right",
			order = 2,
			label = "Edge",
			tooltip = "The list stays inside the screen's margin",
			menu = function()
				VideTopbar.Icon({ order = 1, icon = "star", label = "Near the right edge" })
				VideTopbar.Icon({ order = 2, icon = "crown", label = "The list moves in" })
			end,
		})
	end,
})
