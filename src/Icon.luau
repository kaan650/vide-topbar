local registry = require("./registry")
local types = require("./types")

--- Adds an icon to the topbar for as long as the calling scope lives. Call it inside a Vide scope (a component,
--- `Vide.root`, `Vide.show`...); the topbar draws it, so it returns nothing to parent. Inside `Group` it joins the
--- group's pill, and inside another icon's `menu` it becomes a row of that menu, or an icon of its row.
local function Icon(props: types.IconProps)
	local container = registry.current()
	local rows: registry.Container? = nil
	local menu = props.menu
	if menu then
		local style: types.MenuStyle = props.menuStyle or "List"
		if style == "Row" then
			assert(container.kind ~= "Group", "VideTopbar: a row menu can't be inside a group")
			assert(container.style ~= "Row", "VideTopbar: a row menu can't be inside another row menu")
		end
		local menuRows = registry.newContainer("Menu", style)
		registry.within(menuRows, menu)
		rows = menuRows
	end
	--* A field opens and closes like a row menu with nothing in it, so the icon, the overflow menu and a list's pages
	--* treat it as one; RowMenuView and MenuView draw the field in place of the icons.
	if props.input then
		assert(menu == nil, "VideTopbar: an icon takes `menu` or `input`, not both")
		assert(container.kind ~= "Group", "VideTopbar: an icon with `input` can't be inside a group")
		assert(container.style ~= "Row", "VideTopbar: an icon with `input` can't be inside a row menu")
		rows = registry.newContainer("Menu", "Row")
	end
	registry.add(container, { kind = "Icon", props = props, menu = rows })
end

return Icon
