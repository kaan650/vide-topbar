local Vide = require("../Packages/Vide")

--! AbsolutePosition changes without its changed signal when an ancestor is parented (the tooltip layer read (0, 0)
--! while it sat at (0, -58)), so these subscribe to the signals but always return the live value.
local function trackAbsolute(instance: GuiObject): (() -> Vector2, () -> Vector2)
	local version = Vide.source(0)
	local function bump()
		version(version() + 1)
	end
	Vide.cleanup(instance:GetPropertyChangedSignal("AbsolutePosition"):Connect(bump))
	Vide.cleanup(instance:GetPropertyChangedSignal("AbsoluteSize"):Connect(bump))

	return function()
		version()
		return instance.AbsolutePosition
	end, function()
		version()
		return instance.AbsoluteSize
	end
end

return trackAbsolute
