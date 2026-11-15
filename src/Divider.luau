local registry = require("./registry")
local types = require("./types")

--- A thin line between the icons of a group or a row menu, like the ones in Roblox's Unibar.
local function Divider(props: types.DividerProps?)
	local container = registry.current()
	assert(
		container.kind == "Group" or container.style == "Row",
		"VideTopbar: a divider goes inside a group or a row menu"
	)
	registry.add(container, { kind = "Divider", props = props or {} })
end

return Divider
