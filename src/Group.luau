local registry = require("./registry")
local types = require("./types")

--- Puts the icons added inside `content` into one pill, like Roblox's Unibar, for as long as the calling scope lives.
local function Group(props: types.GroupProps, content: () -> ())
	assert(registry.current().kind == "Topbar", "VideTopbar: a group can't be inside a group or a menu")
	local items = registry.newContainer("Group")
	registry.within(items, content)
	registry.add(registry.topbar, { kind = "Group", props = props, items = items })
end

return Group
