local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
local VideTopbar = require("@game/ReplicatedStorage/Packages/VideTopbar")
local stage = require("./stage")

local SHORTCUTS: { [string]: VideTopbar.Shortcut } = {
	["M"] = Enum.KeyCode.M,
	["Ctrl+M"] = { Enum.KeyCode.LeftControl, Enum.KeyCode.M },
	["Ctrl+Alt+M"] = { Enum.KeyCode.LeftControl, Enum.KeyCode.LeftAlt, Enum.KeyCode.M },
	["Esc"] = Enum.KeyCode.Escape,
}

return stage.topbar({
	summary = "Rest the pointer on an icon: its tooltip opens after 0.65 s, and moving to the next one opens it at "
		.. "once. Shortcuts show as keycaps; they bind only in a live game. Parts/Tooltip shows one held open.",
	controls = {
		title = "Settings",
		shortcut = UILabs.Choose({ "none", "M", "Ctrl+M", "Ctrl+Alt+M", "Esc" }),
	},
	build = function(controls)
		VideTopbar.Icon({
			order = 1,
			icon = "gear",
			tooltip = controls.title,
			shortcut = function()
				return SHORTCUTS[controls.shortcut()]
			end,
		})
		VideTopbar.Icon({ order = 2, icon = "bell", tooltip = "Notifications", shortcut = Enum.KeyCode.N })
		VideTopbar.Icon({
			order = 3,
			icon = "shopping-cart",
			tooltip = "Shop",
			shortcut = { Enum.KeyCode.LeftControl, Enum.KeyCode.B },
		})
		VideTopbar.Icon({
			order = 4,
			icon = "person",
			label = "Profile",
			tooltip = "`shortcutHint` only shows the key, for one the game handles",
			shortcutHint = Enum.KeyCode.P,
		})
		VideTopbar.Icon({
			order = 5,
			icon = "trophy",
			tooltip = "A long tooltip wraps once it is wider than 240 px and is cut after its second line, like "
				.. "Roblox's own, so this sentence never shows in full",
		})

		VideTopbar.Group({ side = "Center", order = 1 }, function()
			VideTopbar.Icon({ order = 1, icon = "heart", tooltip = "In a group the caret points at the circle" })
			VideTopbar.Icon({ order = 2, icon = "backpack", tooltip = "Inventory", shortcut = Enum.KeyCode.I })
		end)

		VideTopbar.Icon({
			side = "Right",
			order = 1,
			icon = "bell",
			tooltip = "Near the screen's edge the box moves in and the caret stays on the icon",
		})
	end,
})
