local Vide = require("@game/ReplicatedStorage/Packages/Vide")
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
local VideTopbar = require("@game/ReplicatedStorage/Packages/VideTopbar")
local create = require("@game/ReplicatedStorage/Packages/VideTopbar/Utility/create")

return {
	summary = "Icons on each side of the topbar, over a stand-in for the game view.",
	vide = Vide,
	controls = {
		label = "Shop",
		icon = UILabs.Choose({ "shopping-cart", "gear", "bell" }),
		disabled = false,
	},
	story = function(props: { controls: { [string]: any } })
		local scene = create("Frame")({
			Name = "Scene",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(86, 120, 150),
		})
		Vide.cleanup(VideTopbar.mount({ target = scene }))

		local selected = Vide.source(false)
		VideTopbar.Icon({
			icon = props.controls.icon,
			label = props.controls.label,
			selected = selected,
			isDisabled = props.controls.disabled,
			order = 1,
		})
		VideTopbar.Icon({ icon = "gear", order = 2 })
		VideTopbar.Icon({ side = "Center", label = "Round 1" })
		VideTopbar.Icon({ side = "Right", icon = "bell" })

		return scene
	end,
}
