local Vide = require("./Packages/Vide")
local VideFoundation = require("./Packages/VideFoundation")
local types = require("./types")

local show = Vide.show

--- An icon as the topbar draws it, inside the topbar's FoundationProvider.
local function IconView(props: types.IconProps): GuiObject
	local tokens = VideFoundation.Hooks.useTokens()
	local preferences = VideFoundation.Hooks.usePreferences()
	local cursor = VideFoundation.Hooks.useCursor(VideFoundation.Enums.CursorType.SkinToneCircle)

	--! Vide.read infers the whole `T | () -> T` union under the new solver, so each prop is read with its own refinement.
	local function iconName(): string?
		local value = props.icon
		return if type(value) == "function" then value() else value
	end

	local function image(): Content?
		local value = props.image
		return if type(value) == "function" then value() else value
	end

	local function label(): string?
		local value = props.label
		local text = if type(value) == "function" then value() else value
		return if text == "" then nil else text
	end

	local function buttonSize(): number
		return tokens().Size.Size_1100
	end

	local function glyphSize(): number
		return tokens().Size.Size_600
	end

	local function hasGlyph(): boolean
		return iconName() ~= nil or image() ~= nil
	end

	--* Roblox's menu and Unibar glyphs measured rgb(247, 247, 248), the emphasis color, not the Icon default.
	local function glyphStyle(): { Color3: Color3?, Transparency: number? }
		local emphasis = tokens().Color.Content.Emphasis
		return { Color3 = emphasis.Color3, Transparency = emphasis.Transparency }
	end

	--* The glyph sits where it sits in a round icon, so a label grows the pill to the right only.
	local function glyphInset(): UDim
		return UDim.new(0, (buttonSize() - glyphSize()) / 2)
	end

	local function isSelected(): boolean
		local selected = props.selected
		return selected ~= nil and selected()
	end

	local function onActivated()
		local selected = props.selected
		if selected then
			selected(not selected())
		end
		if props.onActivated then
			props.onActivated()
		end
	end

	return VideFoundation.View({
		tag = "radius-circle auto-x",
		Size = function()
			return UDim2.fromOffset(buttonSize(), buttonSize())
		end,
		LayoutOrder = props.order,
		backgroundStyle = function()
			local backplate = tokens().Color.OverMedia.OverMedia_0
			return {
				Color3 = backplate.Color3,
				--* Roblox's own topbar buttons scale the backplate by the player's transparency setting.
				Transparency = backplate.Transparency * preferences().preferredTransparency,
			}
		end,
		selection = {
			Selectable = true,
			SelectionImageObject = cursor,
		},
		isDisabled = props.isDisabled,
		onActivated = onActivated,
		children = {
			--* The same 36 px circle Roblox's Unibar draws behind an icon whose menu is open.
			VideFoundation.View({
				tag = "radius-circle",
				Position = function()
					local inset = (buttonSize() - tokens().Size.Size_900) / 2
					return UDim2.fromOffset(inset, inset)
				end,
				Size = function()
					local inset = buttonSize() - tokens().Size.Size_900
					return UDim2.new(1, -inset, 1, -inset)
				end,
				backgroundStyle = function()
					local hover = tokens().Color.State.Hover
					return { Color3 = hover.Color3, Transparency = hover.Transparency }
				end,
				Visible = isSelected,
				ZIndex = 0,
			}),
			VideFoundation.View({
				tag = "auto-x row align-y-center gap-xsmall",
				Size = UDim2.fromScale(0, 1),
				padding = {
					left = function()
						return if hasGlyph() then glyphInset() else UDim.new(0, tokens().Padding.Medium)
					end,
					right = function()
						return if label() then UDim.new(0, tokens().Padding.Medium) else glyphInset()
					end,
				},
				children = {
					show(iconName, function(name)
						return VideFoundation.Icon({
							name = name,
							style = glyphStyle,
							size = glyphSize,
							LayoutOrder = 1,
						})
					end),
					show(function()
						return if iconName() == nil then image() else nil
					end, function(content)
						return VideFoundation.Image({
							ImageContent = content,
							Size = function()
								return UDim2.fromOffset(glyphSize(), glyphSize())
							end,
							LayoutOrder = 1,
						})
					end),
					show(label, function(text)
						return VideFoundation.Text({
							Text = text,
							tag = "auto-xy text-title-medium content-emphasis",
							LayoutOrder = 2,
						})
					end),
				},
			}),
		},
	})
end

return IconView
