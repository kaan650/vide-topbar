local registry = require("./registry")
local types = require("./types")

--- A thin line between the icons of a group, like the ones in Roblox's Unibar.
local function Divider(props: types.DividerProps?)
	local container = registry.current()
	assert(container.kind == "Group", "VideTopbar: a divider goes inside a group")
	registry.add(container, { kind = "Divider", props = props or {} })
end

return Divider
