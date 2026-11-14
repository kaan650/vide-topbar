local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
local Vide = require("@game/ReplicatedStorage/Packages/Vide")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VideTopbar = require("@game/ReplicatedStorage/Packages/VideTopbar")
local stage = require("./stage")

--* Roblox's own account, so the headshot loads in edit mode, where there is no LocalPlayer.
local SAMPLE_USER_ID = 1

local function Avatar(isOnline: () -> boolean): GuiObject
	return VideFoundation.View({
		Size = UDim2.fromOffset(28, 28),
		children = {
			VideFoundation.Image({
				tag = "size-full radius-circle bg-shift-200",
				ImageContent = Content.fromUri(`rbxthumb://type=AvatarHeadShot&id={SAMPLE_USER_ID}&w=150&h=150`),
			}),
			VideFoundation.View({
				tag = function()
					return if isOnline() then "radius-circle bg-system-success" else "radius-circle bg-shift-400"
				end,
				AnchorPoint = Vector2.new(1, 1),
				Position = UDim2.fromScale(1, 1),
				Size = UDim2.fromOffset(9, 9),
				ZIndex = 2,
			}),
		},
	})
end

local function Tag(text: string): GuiObject
	return VideFoundation.View({
		tag = "auto-xy radius-small bg-system-emphasis padding-x-xsmall",
		children = {
			VideFoundation.Text({ Text = text, tag = "auto-xy text-caption-small content-emphasis" }),
		},
	})
end

return stage.topbar({
	summary = "What an icon can hold: a glyph, an image sized by `imageScale` and `imageRatio`, a label, and your own "
		.. "`leading` and `trailing` instances. `minWidth` keeps a changing label from moving its neighbours.",
	controls = {
		imageScale = UILabs.Slider(1, 0.5, 1.5, 0.05),
		imageRatio = UILabs.Slider(1, 0.5, 3, 0.1),
		minWidth = UILabs.Slider(88, 0, 160, 4),
	},
	build = function(controls)
		VideTopbar.Icon({ order = 1, icon = "gear", tooltip = "A glyph" })
		VideTopbar.Icon({
			order = 2,
			image = stage.images.example,
			imageScale = controls.imageScale,
			imageRatio = controls.imageRatio,
			tooltip = "An image",
		})
		VideTopbar.Icon({ order = 3, label = "A label" })
		VideTopbar.Icon({ order = 4, icon = "shopping-cart", label = "Glyph and label" })
		VideTopbar.Icon({
			order = 5,
			image = stage.images.shop,
			imageScale = controls.imageScale,
			imageRatio = controls.imageRatio,
			label = "Image and label",
		})

		local online = Vide.source(true)
		VideTopbar.Icon({
			side = "Center",
			order = 1,
			label = "Roblox",
			leading = function()
				return Avatar(online)
			end,
			trailing = function()
				return Tag("VIP")
			end,
			selected = online,
			tooltip = "`leading` and `trailing`: press to toggle the dot",
		})

		local points = Vide.source(0)
		local ticker = task.spawn(function()
			while true do
				task.wait(0.4)
				points(math.random(1, 100000))
			end
		end)
		Vide.cleanup(ticker)
		local function pointsLabel(): string
			return `${points()}`
		end

		--* The right holder grows leftwards, so each bell sits left of the label it is pushed by.
		VideTopbar.Icon({ side = "Right", order = 1, icon = "bell", tooltip = "Moves with the label beside it" })
		VideTopbar.Icon({ side = "Right", order = 2, label = pointsLabel, tooltip = "No `minWidth`" })
		VideTopbar.Icon({ side = "Right", order = 3, icon = "bell", tooltip = "Stays put" })
		VideTopbar.Icon({
			side = "Right",
			order = 4,
			label = pointsLabel,
			minWidth = controls.minWidth,
			tooltip = "`minWidth`",
		})
	end,
})
