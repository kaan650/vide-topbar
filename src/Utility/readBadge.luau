local types = require("../types")

--- An icon's `badge`, read once.
local function readBadge(props: types.IconProps): number | boolean | string | nil
	local value = props.badge
	return if type(value) == "function" then value() else value
end

return readBadge
