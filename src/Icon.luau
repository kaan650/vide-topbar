local Vide = require("./Packages/Vide")
local registry = require("./registry")
local types = require("./types")

--- Adds an icon to the topbar for as long as the calling scope lives. Call it inside a Vide scope (a component,
--- `Vide.root`, `Vide.show`...); the topbar draws it, so it returns nothing to parent.
local function Icon(props: types.IconProps)
	local remove: (() -> ())? = nil
	--* Registered first so a call outside a scope errors before the icon is added, instead of leaking it.
	Vide.cleanup(function()
		if remove then
			remove()
		end
	end)
	remove = registry.add(props)
end

return Icon
