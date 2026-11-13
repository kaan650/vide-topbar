local VideFoundation = require("./Packages/VideFoundation")
local registry = require("./registry")

--- A top-level entry as the overflow plan sees it.
export type Item = { id: number, order: number, width: number }

export type Hidden = { [number]: true }

export type PlanInput = {
	left: { Item },
	center: { Item },
	right: { Item },
	--- Where the left holder starts and the right holder ends, in screen pixels.
	leftStart: number,
	rightEnd: number,
	screenWidth: number,
	gap: number,
	overflowWidth: number,
}

local function readOrder(props: { order: VideFoundation.Value<number>? }): number
	local value = props.order
	return (if type(value) == "function" then value() else value) or 0
end

local function orderOf(entry: registry.Entry): number
	return readOrder(entry.props)
end

local function byOrder(a: Item, b: Item): boolean
	if a.order ~= b.order then
		return a.order < b.order
	end
	return a.id < b.id
end

local function need(items: { Item }, gap: number): number
	local total = 0
	for index, item in items do
		total += item.width + (if index > 1 then gap else 0)
	end
	return total
end

--- Hides the items furthest from the screen edge once they don't all fit in `room`, keeping room for the overflow
--- icon. `items` are ordered from the edge inwards; once one doesn't fit, every item further in is hidden too, so
--- the bar keeps its order.
local function fit(items: { Item }, room: number, gap: number, overflowWidth: number): Hidden
	local hidden: Hidden = {}
	if need(items, gap) <= room then
		return hidden
	end
	local available = room - overflowWidth - gap
	local used = 0
	local full = false
	for _, item in items do
		local after = used + (if used > 0 then gap else 0) + item.width
		if not full and after <= available then
			used = after
		else
			full = true
			hidden[item.id] = true
		end
	end
	return hidden
end

--- Which entries each side hides in its overflow menu. Roblox's Unibar moves what doesn't fit into its ⋯ menu;
--- TopbarPlus decides when by where the sides meet, which this follows: up to the centre icons when there are any,
--- otherwise a side needing less than half the bar keeps all it needs and the other gets the rest.
local function plan(input: PlanInput): { Left: Hidden, Right: Hidden }
	local gap = input.gap
	local left = table.clone(input.left)
	table.sort(left, byOrder)
	local right = table.clone(input.right)
	table.sort(right, function(a, b)
		return byOrder(b, a)
	end)
	local center = table.clone(input.center)

	local leftRoom: number
	local rightRoom: number
	local centerWidth = need(center, gap)
	if centerWidth > 0 then
		local centerLeft = input.screenWidth / 2 - centerWidth / 2
		leftRoom = centerLeft - gap - input.leftStart
		rightRoom = input.rightEnd - (centerLeft + centerWidth + gap)
	else
		local total = input.rightEnd - input.leftStart - gap
		local leftNeed = need(left, gap)
		local rightNeed = need(right, gap)
		if leftNeed + rightNeed <= total then
			leftRoom, rightRoom = leftNeed, rightNeed
		elseif leftNeed <= total / 2 then
			leftRoom, rightRoom = leftNeed, total - leftNeed
		elseif rightNeed <= total / 2 then
			leftRoom, rightRoom = total - rightNeed, rightNeed
		else
			leftRoom, rightRoom = total / 2, total / 2
		end
	end

	return {
		Left = fit(left, leftRoom, gap, input.overflowWidth),
		Right = fit(right, rightRoom, gap, input.overflowWidth),
	}
end

--- The overflow menu's rows: each hidden icon, and each icon of a hidden group, in bar order.
local function rowsFor(hidden: Hidden, entries: { [number]: registry.Entry }): { [number]: registry.Entry }
	local hiddenItems: { Item } = {}
	for id in hidden do
		local entry = entries[id]
		if entry then
			table.insert(hiddenItems, { id = id, order = orderOf(entry), width = 0 })
		end
	end
	table.sort(hiddenItems, byOrder)

	local rows: { [number]: registry.Entry } = {}
	local index = 0
	local function add(id: number, icon: registry.IconEntry)
		index += 1
		rows[id] = { kind = "Icon", props = icon.props, menu = icon.menu, overflowOf = icon, rowOrder = index }
	end

	for _, item in hiddenItems do
		local entry = entries[item.id]
		if entry.kind == "Icon" then
			add(item.id, entry)
		elseif entry.kind == "Group" then
			local members: { Item } = {}
			local groupEntries = entry.items.entries()
			for id, member in groupEntries do
				if member.kind == "Icon" then
					table.insert(members, { id = id, order = orderOf(member), width = 0 })
				end
			end
			table.sort(members, byOrder)
			for _, member in members do
				local icon = groupEntries[member.id]
				if icon.kind == "Icon" then
					add(member.id, icon)
				end
			end
		end
	end
	return rows
end

return {
	--- Set on an icon's button to the width it rests at, which the overflow plan uses instead of its current width.
	RESTING_WIDTH_ATTRIBUTE = "VideTopbarRestingWidth",
	orderOf = orderOf,
	readOrder = readOrder,
	plan = plan,
	rowsFor = rowsFor,
}
