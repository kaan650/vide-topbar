local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local BadgeView = require("@game/ReplicatedStorage/Packages/VideTopbar/BadgeView")
local stage = require("../stage")

local function dot(): boolean
	return true
end

local function holder(badge: any): GuiObject
	return VideFoundation.View({ tag = "auto-xy", children = { badge } })
end

return stage.part({
	summary = "The badges on their own: a count (hidden at 0, capped at 99), a dot, the ringed dot on a round icon's "
		.. "corner, and text.",
	controls = {
		count = UILabs.Slider(5, 0, 150, 1),
		text = "NEW",
	},
	build = function(controls)
		return stage.row({
			stage.sample("Count", 1, holder(BadgeView.BadgeView({ value = controls.count }))),
			stage.sample("Dot", 2, holder(BadgeView.BadgeView({ value = dot }))),
			stage.sample("Ringed dot", 3, holder(BadgeView.BadgeView({ value = dot, ringed = true }))),
			stage.sample("Text", 4, holder(BadgeView.BadgeView({ value = controls.text }))),
		})
	end,
})
