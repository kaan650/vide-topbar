local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
local Vide = require("@game/ReplicatedStorage/Packages/Vide")
local VideTopbar = require("@game/ReplicatedStorage/Packages/VideTopbar")
local stage = require("./stage")

local ICONS = { "gear", "bell", "star", "flag", "crown", "music-note", "house", "trophy" }

local function upTo(count: () -> number): () -> { number }
	return Vide.derive(function()
		local list = {}
		for index = 1, count() do
			list[index] = index
		end
		return list
	end)
end

return stage.topbar({
	summary = "Add icons until a side runs out of room: what doesn't fit moves, furthest from the edge first, into a "
		.. "⋯ menu at that side's edge. Its rows press the hidden icons, so a hidden menu opens under the ⋯.",
	screen = "Phone 390",
	controls = {
		left = UILabs.Slider(5, 0, 16, 1),
		right = UILabs.Slider(1, 0, 16, 1),
		rightGroup = true,
		center = false,
	},
	build = function(controls)
		local center: () -> boolean = controls.center
		local rightGroup: () -> boolean = controls.rightGroup

		Vide.indexes(upTo(controls.left), function(_, index: number)
			VideTopbar.Icon({
				order = index,
				icon = ICONS[(index - 1) % #ICONS + 1],
				label = if index % 2 == 0 then `Left {index}` else nil,
				tooltip = `Left {index}`,
				badge = if index % 3 == 0 then index else nil,
				onActivated = stage.action(`left {index}`),
				menu = if index % 4 == 1
					then function()
						VideTopbar.Icon({ order = 1, icon = "gear", label = `Left {index} A` })
						VideTopbar.Icon({ order = 2, icon = "bell", label = `Left {index} B` })
					end
					else nil,
			})
			return nil
		end)

		Vide.show(function()
			return if center() then true else nil
		end, function()
			VideTopbar.Icon({ side = "Center", label = "Round 1" })
			return nil
		end)

		Vide.indexes(upTo(controls.right), function(_, index: number)
			VideTopbar.Icon({
				side = "Right",
				order = -index,
				icon = ICONS[(index + 3) % #ICONS + 1],
				tooltip = `Right {index}`,
				onActivated = stage.action(`right {index}`),
			})
			return nil
		end)

		Vide.show(function()
			return if rightGroup() then true else nil
		end, function()
			VideTopbar.Group({ side = "Right", order = 0 }, function()
				VideTopbar.Icon({ order = 1, icon = "heart", tooltip = "Group A" })
				VideTopbar.Divider({ order = 2 })
				VideTopbar.Icon({ order = 3, icon = "backpack", tooltip = "Group B", badge = 2 })
			end)
			return nil
		end)
	end,
})
