local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
local VideTopbar = require("@game/ReplicatedStorage/Packages/VideTopbar")
local stage = require("./stage")

local NONE = "none"

local function orNil(control: () -> string): () -> string?
	return function()
		local value = control()
		return if value == NONE then nil else value
	end
end

return stage.topbar({
	summary = "One icon and its props, between a few neighbours. Clear `icon` to see `image`; a label makes it a pill.",
	controls = {
		side = UILabs.Choose({ "Left", "Center", "Right" }),
		icon = UILabs.Choose({ "shopping-cart", "gear", "bell", "trophy", "backpack", NONE }),
		image = UILabs.Choose({ "shop", "premium", "example", NONE }),
		label = "Shop",
		tooltip = "Open the shop",
		badge = UILabs.Choose({ NONE, "3", "120", "dot", "NEW" }),
		minWidth = UILabs.Slider(0, 0, 240, 4),
		selected = false,
		disabled = false,
		locked = false,
	},
	build = function(controls)
		VideTopbar.Icon({
			side = controls.side,
			order = 1,
			icon = orNil(controls.icon),
			image = function()
				local name = controls.image()
				return if name == NONE then nil else stage.images[name]
			end,
			label = controls.label,
			tooltip = controls.tooltip,
			badge = function()
				local value = controls.badge()
				return if value == NONE then nil elseif value == "dot" then true else tonumber(value) or value
			end,
			minWidth = controls.minWidth,
			selected = stage.mirror(controls.selected),
			isDisabled = controls.disabled,
			isLocked = controls.locked,
			onActivated = stage.action("icon"),
		})

		VideTopbar.Icon({ order = 2, icon = "gear", tooltip = "Settings" })
		VideTopbar.Icon({ side = "Center", order = 2, label = "Round 1" })
		VideTopbar.Icon({ side = "Right", order = 2, icon = "bell", tooltip = "Notifications" })
	end,
})
