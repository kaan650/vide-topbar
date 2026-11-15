local BadgeView = require("../BadgeView")
local readBadge = require("./readBadge")
local registry = require("../registry")
local types = require("../types")

--- An icon's badge with its menu's added up: counts add, and a row's dot or text shows as a dot, as Roblox shows one on
--- its ⋯ icon for activity inside. The icon's own text wins. Rows with menus of their own count theirs too.
local function menuBadge(props: types.IconProps, rows: registry.Container?): BadgeView.Badge
	local own = readBadge(props)
	if rows == nil or type(own) == "string" then
		return own
	end
	local count = if type(own) == "number" then math.max(own, 0) else 0
	local dot = own == true
	for _, row in rows.entries() do
		if row.kind == "Icon" then
			local rowBadge = menuBadge(row.props, row.menu)
			if type(rowBadge) == "number" then
				count += math.max(rowBadge, 0)
			elseif BadgeView.kindOf(rowBadge) ~= nil then
				dot = true
			end
		end
	end
	return if count > 0 then count elseif dot then true else nil
end

return menuBadge
