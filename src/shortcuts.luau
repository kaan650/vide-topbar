local Vide = require("./Packages/Vide")
local types = require("./types")

--- The InputContext that icons bind their shortcuts into: one per mounted topbar, none in a story.
local inputContext = Vide.context(nil :: InputContext?)

--- The keys of `shortcut` in order: modifiers, then the key.
local function keysOf(shortcut: types.Shortcut?): { Enum.KeyCode }
	if shortcut == nil then
		return {}
	elseif type(shortcut) == "table" then
		return shortcut
	end
	return { shortcut }
end

--- Calls `onPressed` whenever `shortcut` is pressed, for as long as the calling scope lives.
local function useShortcut(shortcut: () -> types.Shortcut?, onPressed: () -> ())
	local context = inputContext()
	if context == nil then
		return
	end

	local function keys(): { Enum.KeyCode }
		return keysOf(shortcut())
	end

	--* The action exists only while there is a shortcut, so icons without one add nothing to the context.
	Vide.show(function()
		return if #keys() > 0 then true else nil
	end, function()
		local action = Instance.new("InputAction")
		action.Name = "VideTopbarShortcut"
		Vide.cleanup(action)
		Vide.cleanup(action.Pressed:Connect(onPressed))

		Vide.effect(function()
			local current = keys()
			for _, binding in action:GetChildren() do
				binding:Destroy()
			end
			if #current == 0 then
				return
			end
			assert(#current <= 3, "VideTopbar: a shortcut is at most two modifiers and a key")

			local binding = Instance.new("InputBinding")
			binding.KeyCode = current[#current]
			if #current >= 2 then
				binding.PrimaryModifier = current[1]
			end
			if #current == 3 then
				binding.SecondaryModifier = current[2]
			end
			binding.Parent = action
		end)

		action.Parent = context
		return nil
	end)
end

return {
	inputContext = inputContext,
	keysOf = keysOf,
	useShortcut = useShortcut,
}
