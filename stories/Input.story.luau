local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
local Vide = require("@game/ReplicatedStorage/Packages/Vide")
local VideTopbar = require("@game/ReplicatedStorage/Packages/VideTopbar")
local stage = require("./stage")

local FILLERS = { "gear", "bell", "star", "flag", "crown", "music-note", "house", "trophy" }

--- A submit callback that prints what was entered.
local function submitted(name: string): (text: string) -> ()
	return function(text)
		print(`[Story] {name}: {text}`)
	end
end

return stage.topbar({
	summary = "`input` gives an icon a text field. On the topbar it slides out of the icon like a row menu and takes "
		.. "focus; Enter submits it, empties it and closes it, and the icon's x closes it too. As a menu row, or once "
		.. "the icon has moved into the ⋯ menu, it opens a page with the field.",
	controls = {
		fillers = UILabs.Slider(0, 0, 12, 1),
		closeOnOutsideClick = false,
	},
	build = function(controls)
		local closeOnOutsideClick: () -> boolean = controls.closeOnOutsideClick

		VideTopbar.Icon({
			order = 1,
			icon = "gift-box",
			tooltip = "Redeem a code",
			closeOnOutsideClick = closeOnOutsideClick,
			input = { placeholder = "Enter a code", onSubmit = submitted("redeem") },
		})

		VideTopbar.Icon({
			order = 2,
			icon = "three-bars-horizontal",
			tooltip = "Menu",
			menu = function()
				VideTopbar.Icon({ order = 1, icon = "gear", label = "Settings", onActivated = stage.action("settings") })
				VideTopbar.Icon({
					order = 2,
					icon = "globe-simplified",
					label = "Join a server",
					input = { placeholder = "Server code", onSubmit = submitted("join") },
				})
			end,
		})

		Vide.indexes(stage.upTo(controls.fillers), function(_, index: number)
			VideTopbar.Icon({
				order = 2 + index,
				icon = FILLERS[(index - 1) % #FILLERS + 1],
				tooltip = `Filler {index}`,
			})
			return nil
		end)

		VideTopbar.Icon({
			side = "Right",
			icon = "magnifying-glass",
			tooltip = "Search players",
			closeOnOutsideClick = closeOnOutsideClick,
			input = { width = 160, onSubmit = submitted("search") },
		})
	end,
})
