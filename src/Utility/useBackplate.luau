local VideFoundation = require("../Packages/VideFoundation")

--* Foundation's ColorStyleValue. Optional fields, since table fields are invariant under the new solver.
export type ColorStyle = { Color3: Color3?, Transparency: number? }

--- The fill behind Roblox's own topbar buttons, its Unibar and its menus: OverMedia_0, scaled by the player's
--- transparency setting as they do.
local function useBackplate(): () -> ColorStyle
	local tokens = VideFoundation.Hooks.useTokens()
	local preferences = VideFoundation.Hooks.usePreferences()
	return function()
		local backplate = tokens().Color.OverMedia.OverMedia_0
		return {
			Color3 = backplate.Color3,
			Transparency = backplate.Transparency * preferences().preferredTransparency,
		}
	end
end

return useBackplate
