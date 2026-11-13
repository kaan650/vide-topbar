local UserInputService = game:GetService("UserInputService")

local VideFoundation = require("./Packages/VideFoundation")
local create = require("./Utility/create")
local measureText = require("./Utility/measureText")

--* UIBlox's KeyLabel (App/Menu/KeyLabel in the Studio install's LuaPackages), which Roblox's topbar tooltips draw
--* their hotkeys with. Foundation has its own KeyLabel, but it is drawn differently.
local HEIGHT = 36
local PREFERRED_WIDTH = HEIGHT
local MIN_SIDE_PADDING = 8
local SIDE_PADDING = 10
local TEXT_CENTER_OFFSET = -1
local SLICE_CENTER = Rect.new(10, 9, 25, 25)

local KEY_NAMES: { [Enum.KeyCode]: string } = {
	[Enum.KeyCode.Escape] = "Esc",
	[Enum.KeyCode.Print] = "Prt Sc",
	[Enum.KeyCode.ScrollLock] = "Sc Lock",
	[Enum.KeyCode.Pause] = "Pause",
	[Enum.KeyCode.Insert] = "Ins",
	[Enum.KeyCode.PageUp] = "PgUp",
	[Enum.KeyCode.NumLock] = "Num Lock",
	[Enum.KeyCode.Delete] = "Del",
	[Enum.KeyCode.End] = "End",
	[Enum.KeyCode.PageDown] = "PgDn",
	[Enum.KeyCode.CapsLock] = "Caps",
	[Enum.KeyCode.Return] = "Enter",
	[Enum.KeyCode.LeftShift] = "Shift",
	[Enum.KeyCode.LeftControl] = "Ctrl",
	[Enum.KeyCode.LeftAlt] = "Alt",
	[Enum.KeyCode.Space] = "Space",
	[Enum.KeyCode.LeftMeta] = "Fn",
	[Enum.KeyCode.LeftSuper] = "Cmd",
	[Enum.KeyCode.Tilde] = "~",
}

local function keyText(keyCode: Enum.KeyCode): string
	local name = KEY_NAMES[keyCode]
	if name then
		return name
	end
	local text = UserInputService:GetStringForKeyCode(keyCode)
	return if text ~= "" then text else keyCode.Name
end

--- How wide UIBlox draws a key: square, unless its name needs more room. It measures with the body font.
local function width(keyCode: Enum.KeyCode, body: measureText.Typography): number
	local inner = measureText(keyText(keyCode), body).X
	return if inner + 2 * MIN_SIDE_PADDING > PREFERRED_WIDTH then inner + 2 * SIDE_PADDING else PREFERRED_WIDTH
end

--- A keyboard key as Roblox's topbar tooltips draw it.
local function KeyCap(keyCode: Enum.KeyCode, layoutOrder: number): GuiObject
	local tokens = VideFoundation.Hooks.useTokens()

	return VideFoundation.Image({
		Image = "icons/controls/keys/key_single",
		imageStyle = function()
			local border = tokens().Color.Shift.Shift_400
			return { Color3 = border.Color3, Transparency = border.Transparency }
		end,
		slice = { center = SLICE_CENTER },
		Size = function()
			return UDim2.fromOffset(width(keyCode, tokens().Typography.BodySmall), HEIGHT)
		end,
		LayoutOrder = layoutOrder,
		children = {
			create("TextLabel")({
				Name = "Key",
				BackgroundTransparency = 1,
				Text = keyText(keyCode),
				FontFace = function()
					return tokens().Typography.CaptionMedium.Font
				end,
				TextSize = function()
					return tokens().Typography.CaptionMedium.FontSize
				end,
				TextColor3 = function()
					return tokens().Color.Content.Default.Color3
				end,
				TextTransparency = function()
					return tokens().Color.Content.Default.Transparency
				end,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				Position = UDim2.fromOffset(0, TEXT_CENTER_OFFSET),
				Size = UDim2.fromScale(1, 1),
			}),
		},
	})
end

return {
	HEIGHT = HEIGHT,
	width = width,
	KeyCap = KeyCap,
}
