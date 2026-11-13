local TextService = game:GetService("TextService")

--* UIBlox's GetTextSize pads every measurement by this.
local TEXT_SIZE_PADDING = Vector2.new(2, 2)

export type Typography = { Font: Font, FontSize: number }

local legacyFonts: { [string]: Enum.Font } = {}
for _, legacyFont in Enum.Font:GetEnumItems() do
	local ok, font = pcall(Font.fromEnum, legacyFont)
	if ok then
		legacyFonts[`{font.Family}|{font.Weight.Name}|{font.Style.Name}`] = legacyFont
	end
end

--- The Enum.Font that draws `font`, so TextService:GetTextSize can measure it without yielding, as UIBlox's
--- GetLegacyFont does. Builder Sans weights without their own enum fall back to the nearest one.
local function legacyFont(font: Font): Enum.Font
	local exact = legacyFonts[`{font.Family}|{font.Weight.Name}|{font.Style.Name}`]
	if exact then
		return exact
	end
	local weight = font.Weight.Value
	return if weight >= Enum.FontWeight.ExtraBold.Value
		then Enum.Font.BuilderSansExtraBold
		elseif weight >= Enum.FontWeight.SemiBold.Value then Enum.Font.BuilderSansBold
		elseif weight >= Enum.FontWeight.Medium.Value then Enum.Font.BuilderSansMedium
		else Enum.Font.BuilderSans
end

--- The size UIBlox's GetTextSize gives `text`, wrapped at `maxWidth` when there is one.
local function measureText(text: string, typography: Typography, maxWidth: number?): Vector2
	local bounds = Vector2.new(maxWidth or math.huge, math.huge)
	return TextService:GetTextSize(text, typography.FontSize, legacyFont(typography.Font), bounds) + TEXT_SIZE_PADDING
end

return measureText
