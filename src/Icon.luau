local registry = require("./registry")
local types = require("./types")

--- Adds an icon to the topbar for as long as the calling scope lives. Call it inside a Vide scope (a component,
--- `Vide.root`, `Vide.show`...); the topbar draws it, so it returns nothing to parent. Inside `Group` it joins the
--- group's pill, and inside another icon's `menu` it becomes a row of that menu.
local function Icon(props: types.IconProps)
	local container = registry.current()
	local rows: registry.Container? = nil
	local menu = props.menu
	if menu then
		assert(container.kind ~= "Menu", "VideTopbar: a menu row can't open a menu of its own")
		local menuRows = registry.newContainer("Menu")
		registry.within(menuRows, menu)
		rows = menuRows
	end
	registry.add(container, { kind = "Icon", props = props, menu = rows })
end

return Icon
