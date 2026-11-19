local Vide = require("@game/ReplicatedStorage/Packages/Vide")
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VideTopbar = require("@game/ReplicatedStorage/Packages/VideTopbar")
local create = require("@game/ReplicatedStorage/Packages/VideTopbar/Utility/create")

--- A source per UI Labs control, by name.
export type Controls = { [string]: any }

type Props = { controls: Controls }

local FULL = UDim2.fromScale(1, 1)
--* The topbar's backplates are see-through, so they are shown over a stand-in for the game view.
local SCENE_COLOR = Color3.fromRGB(86, 120, 150)
local BACKDROP_COLOR = Color3.fromRGB(24, 24, 27)

local SCREENS = { "Fill", "Desktop 1280", "Tablet 768", "Phone 390", "Small phone 320" }
local SCREEN_WIDTHS: { [string]: number } = {
	["Desktop 1280"] = 1280,
	["Tablet 768"] = 768,
	["Phone 390"] = 390,
	["Small phone 320"] = 320,
}

local images: { [string]: Content } = {
	example = Content.fromAssetId(16086868244),
	exampleSelected = Content.fromAssetId(16086868447),
	shop = Content.fromAssetId(4882429582),
	premium = Content.fromAssetId(6071020687),
	mute = Content.fromAssetId(7248002480),
	unmute = Content.fromAssetId(7248002631),
}

local function merge(base: Controls, extra: Controls?): Controls
	local all = table.clone(base)
	for key, value in extra or {} do
		all[key] = value
	end
	return all
end

local function colorModeControl()
	return UILabs.Choose({ "Dark", "Light" })
end

--- A story with the topbar mounted along the top of a stand-in game view; `build` adds the icons. Its `screen` control
--- narrows the view to a device's width, starting at `screen`. `options` adds to `mount`'s options, and can put
--- things in the game view first.
local function topbar(spec: {
	summary: string,
	controls: Controls?,
	screen: string?,
	options: ((controls: Controls, scene: GuiObject) -> VideTopbar.MountOptions)?,
	build: (controls: Controls) -> (),
})
	return {
		summary = spec.summary,
		vide = Vide,
		controls = merge({
			colorMode = colorModeControl(),
			screen = UILabs.Choose(SCREENS, table.find(SCREENS, spec.screen or "Fill")),
		}, spec.controls),
		story = function(props: Props)
			local controls = props.controls
			local scene = create("Frame")({
				Name = "Scene",
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0),
				Size = function()
					local width = SCREEN_WIDTHS[controls.screen()]
					return if width then UDim2.new(0, width, 1, 0) else FULL
				end,
				BackgroundColor3 = SCENE_COLOR,
				ClipsDescendants = true,
			})
			local backdrop = create("Frame")({
				Name = "Backdrop",
				Size = FULL,
				BackgroundColor3 = BACKDROP_COLOR,
				scene,
			})
			Vide.cleanup(backdrop)
			local options: VideTopbar.MountOptions = if spec.options
				then table.clone(spec.options(controls, scene))
				else {}
			options.target = scene
			options.colorMode = controls.colorMode
			Vide.cleanup(VideTopbar.mount(options))
			spec.build(controls)
			return backdrop
		end,
	}
end

--- A story for one of the topbar's parts on its own, drawn inside a FoundationProvider as the topbar draws it.
local function part(spec: {
	summary: string,
	controls: Controls?,
	build: (controls: Controls) -> any,
})
	return {
		summary = spec.summary,
		vide = Vide,
		controls = merge({ colorMode = colorModeControl() }, spec.controls),
		story = function(props: Props)
			--* Foundation's overlays open here: UI Labs doesn't show the ScreenGui they use otherwise.
			local overlay = create("Frame")({
				Name = "Overlay",
				Size = FULL,
				BackgroundTransparency = 1,
				ZIndex = 2,
			})
			local scene = create("Frame")({
				Name = "Scene",
				Size = FULL,
				BackgroundColor3 = SCENE_COLOR,
				VideFoundation.FoundationProvider({
					colorMode = props.controls.colorMode,
					overlayGui = overlay,
					children = function()
						return spec.build(props.controls)
					end,
				}),
				overlay,
			})
			Vide.cleanup(scene)
			return scene
		end,
	}
end

--- Variants side by side, centred in the story.
local function row(children: { any }): GuiObject
	return VideFoundation.View({
		tag = "size-full row wrap gap-xlarge align-x-center align-y-center padding-xlarge",
		children = children,
	})
end

--- One variant in a `row`, captioned.
local function sample(caption: string, layoutOrder: number, content: GuiObject): GuiObject
	content.LayoutOrder = 1
	return VideFoundation.View({
		tag = "auto-xy col gap-small align-x-center",
		LayoutOrder = layoutOrder,
		children = {
			content,
			VideFoundation.Text({
				Text = caption,
				tag = "auto-xy text-caption-medium content-emphasis",
				LayoutOrder = 2,
			}),
		},
	})
end

--- A local copy of a boolean control, so an icon can flip it while the control still sets it.
local function mirror(control: () -> boolean): Vide.Source<boolean>
	local value = Vide.source(Vide.untrack(control))
	Vide.effect(function()
		value(control())
	end)
	return value
end

--- 1 to `count()`, for adding as many icons as a slider says.
local function upTo(count: () -> number): () -> { number }
	return Vide.derive(function()
		local list = {}
		for index = 1, count() do
			list[index] = index
		end
		return list
	end)
end

--- A callback that prints that it ran, for icons and rows in stories.
local function action(name: string): () -> ()
	return function()
		print(`[Story] {name}`)
	end
end

return {
	images = images,
	topbar = topbar,
	part = part,
	row = row,
	sample = sample,
	mirror = mirror,
	upTo = upTo,
	action = action,
}
