local Vide = require("@game/ReplicatedStorage/Packages/Vide")
local VideTopbar = require("@game/ReplicatedStorage/Packages/VideTopbar")
local stage = require("./stage")

local ROUND_SECONDS = 150

return stage.topbar({
	summary = "Groups put icons on one pill like Roblox's Unibar, with dividers between them. A cell lights a circle "
		.. "when hovered or selected instead of its own backplate.",
	controls = {
		dividers = true,
	},
	build = function(controls)
		local dividers: () -> boolean = controls.dividers
		local function Divider(order: number)
			Vide.show(function()
				return if dividers() then true else nil
			end, function()
				VideTopbar.Divider({ order = order })
				return nil
			end)
		end

		local leaderboard = Vide.source(false)
		local emotes = Vide.source(false)
		local inventory = Vide.source(false)
		VideTopbar.Group({ order = 1 }, function()
			VideTopbar.Icon({ order = 1, icon = "trophy", tooltip = "Leaderboard", selected = leaderboard })
			VideTopbar.Icon({ order = 2, icon = "heart", tooltip = "Emotes", selected = emotes })
			VideTopbar.Icon({ order = 3, icon = "backpack", tooltip = "Inventory", selected = inventory, badge = 2 })
			Divider(4)
			VideTopbar.Icon({ order = 5, icon = "speech-bubble-round", tooltip = "Chat" })
		end)

		local remaining = Vide.source(ROUND_SECONDS)
		local countdown = task.spawn(function()
			while true do
				task.wait(1)
				remaining(if remaining() > 0 then remaining() - 1 else ROUND_SECONDS)
			end
		end)
		Vide.cleanup(countdown)

		VideTopbar.Group({ side = "Center", order = 1 }, function()
			VideTopbar.Icon({ order = 1, label = "Round 3" })
			Divider(2)
			VideTopbar.Icon({
				order = 3,
				label = function()
					local seconds = remaining()
					return string.format("%d:%02d", seconds // 60, seconds % 60)
				end,
				minWidth = 64,
			})
		end)

		local muted = Vide.source(false)
		VideTopbar.Group({ side = "Right", order = 1 }, function()
			VideTopbar.Icon({
				order = 1,
				image = function()
					return if muted() then stage.images.unmute else stage.images.mute
				end,
				tooltip = function()
					return if muted() then "Unmute" else "Mute"
				end,
				selected = muted,
			})
			Divider(2)
			VideTopbar.Icon({
				order = 3,
				image = stage.images.premium,
				badge = 1,
				tooltip = "Premium",
				onActivated = stage.action("premium"),
			})
			VideTopbar.Icon({
				order = 4,
				icon = "three-bars-horizontal",
				tooltip = "A menu inside a group",
				menu = function()
					VideTopbar.Icon({ order = 1, icon = "gear", label = "Settings" })
					VideTopbar.Icon({ order = 2, icon = "house", label = "Leave" })
				end,
			})
		end)
	end,
})
