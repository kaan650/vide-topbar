local Vide = require("./Packages/Vide")

--- Set on what a game passes as `leading` or `trailing`, which keeps its own AutoLocalize.
local CUSTOM_ATTRIBUTE = "VideTopbarCustom"

local function markCustom(object: GuiObject): GuiObject
	object:SetAttribute(CUSTOM_ATTRIBUTE, true)
	return object
end

local function isCustom(object: Instance, root: Instance): boolean
	local current: Instance? = object
	while current and current ~= root do
		if current:GetAttribute(CUSTOM_ATTRIBUTE) then
			return true
		end
		current = current.Parent
	end
	return false
end

--! A Builder Icons glyph's text is the icon's name, so translating it would break the icon.
local function isGlyph(object: Instance): boolean
	return (object:IsA("TextLabel") or object:IsA("TextButton"))
		and string.find(object.FontFace.Family, "BuilderIcons", 1, true) ~= nil
end

--* Foundation turns AutoLocalize off on all it draws, as Roblox's own UI translates its strings itself, and a text is
--* only translated when it and every ancestor have it on. The topbar shows the game's strings, so they are translated
--* like the rest of the game's UI, as TopbarPlus's are.

--- Turns automatic translation on for everything the topbar draws under `root`.
local function useAutoLocalize(root: Instance)
	local function localize(object: Instance)
		if object:IsA("GuiBase2d") and not isGlyph(object) and not isCustom(object, root) then
			object.AutoLocalize = true
		end
	end

	for _, descendant in root:GetDescendants() do
		localize(descendant)
	end
	Vide.cleanup(root.DescendantAdded:Connect(localize))
end

return {
	markCustom = markCustom,
	useAutoLocalize = useAutoLocalize,
}
