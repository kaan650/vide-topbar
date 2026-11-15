local GamepadService = game:GetService("GamepadService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local Vide = require("./Packages/Vide")
local shortcuts = require("./shortcuts")

--- Set on every icon's button, so the topbar can find its icons among GuiService selections.
local ICON_ATTRIBUTE = "VideTopbarIcon"

export type OpenMenu = {
	close: () -> (),
	--- The icon the menu belongs to, where selection returns when the menu closes.
	trigger: GuiObject,
	--- Leaves a list opened in place of another, which B does before closing; false when there is none.
	back: (() -> boolean)?,
}

--- Every open menu's list frame, so B can close the one holding the selection.
local openMenus = setmetatable({}, { __mode = "k" }) :: { [GuiObject]: OpenMenu }

local function isInside(object: Instance?, ancestor: Instance): boolean
	return object ~= nil and (object == ancestor or object:IsDescendantOf(ancestor))
end

--- Whether `object` and every ancestor up to `root` are visible: what GuiService could select.
local function isShown(object: GuiObject, root: Instance): boolean
	local current: Instance? = object
	while current and current ~= root do
		if current:IsA("GuiObject") and not current.Visible then
			return false
		end
		current = current.Parent
	end
	return current == root
end

--- The menu whose list holds `object`, if any.
local function menuHolding(object: Instance): OpenMenu?
	for frame, menu in openMenus do
		if object:IsDescendantOf(frame) then
			return menu
		end
	end
	return nil
end

export type Gamepad = {
	--- Whether the highlight key and B have been used, for the hints shown until they have.
	usedHighlight: () -> boolean,
	usedBack: () -> boolean,
	--- The icon the highlight key would select.
	iconToSelect: () -> GuiObject?,
}

--- Gamepad support for a mounted topbar: `highlightKey` selects the icon last selected (or the left-most), B steps
--- back out of a menu and then off the topbar, and a mouse click lets go of the selection.
--- `getRoot` returns the topbar's ScreenGui once it exists.
local function useGamepad(getRoot: () -> Instance?, highlightKey: Enum.KeyCode?): Gamepad
	local used = Vide.source(false)
	local usedBack = Vide.source(false)
	local lastSelected: GuiObject? = nil

	local function topbarIcons(root: Instance): { GuiObject }
		local icons = {}
		for _, descendant in root:GetDescendants() do
			if
				descendant:IsA("GuiObject")
				and descendant:GetAttribute(ICON_ATTRIBUTE)
				and menuHolding(descendant) == nil
				and isShown(descendant, root)
			then
				table.insert(icons, descendant)
			end
		end
		return icons
	end

	--- The icon the highlight key selects: the last one selected while it is still shown, else the left-most.
	local function iconToSelect(): GuiObject?
		local root = getRoot()
		if root == nil then
			return nil
		end
		local last = lastSelected
		if last and last.Parent and isShown(last, root) then
			return last
		end
		local leftMost: GuiObject? = nil
		for _, icon in topbarIcons(root) do
			if leftMost == nil or icon.AbsolutePosition.X < leftMost.AbsolutePosition.X then
				leftMost = icon
			end
		end
		return leftMost
	end

	--- Whether the gamepad selection is on the topbar, menus included.
	local function selectionInside(): boolean
		local root = getRoot()
		return root ~= nil and isInside(GuiService.SelectedObject, root)
	end

	Vide.cleanup(GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(function()
		local selected = GuiService.SelectedObject
		if selected and selected:GetAttribute(ICON_ATTRIBUTE) and selectionInside() then
			lastSelected = selected
		end
	end))

	if highlightKey then
		shortcuts.useShortcut(function()
			return highlightKey
		end, function()
			if selectionInside() then
				return
			end
			local icon = iconToSelect()
			if icon then
				used(true)
				if GamepadService.GamepadCursorEnabled then
					GamepadService:DisableGamepadCursor()
				end
				GuiService.SelectedObject = icon
			end
		end)
	end

	shortcuts.useShortcut(function()
		return Enum.KeyCode.ButtonB
	end, function()
		local selected = GuiService.SelectedObject
		if not selectionInside() then
			return
		end
		local menu = if selected then menuHolding(selected) else nil
		if menu and menu.back and menu.back() then
			return
		elseif menu then
			menu.close()
			GuiService.SelectedObject = menu.trigger
		else
			usedBack(true)
			GuiService.SelectedObject = nil
		end
	end)

	--* A gamepad selection left on the topbar fights the mouse cursor.
	Vide.cleanup(UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and selectionInside() then
			GuiService.SelectedObject = nil
		end
	end))

	return {
		usedHighlight = used,
		usedBack = usedBack,
		iconToSelect = iconToSelect,
	}
end

return {
	ICON_ATTRIBUTE = ICON_ATTRIBUTE,
	isInside = isInside,
	openMenus = openMenus,
	useGamepad = useGamepad,
}
