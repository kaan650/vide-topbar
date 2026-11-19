local VideFoundation = require("./Packages/VideFoundation")
local registry = require("./registry")

--- A top-level entry as the overflow plan sees it.
export type Item = { id: number, order: number, width: number }

export type Hidden = { [number]: true }

export type Plan = {
	Left: Hidden,
	Right: Hidden,
	--- Set when both sides overflow into one ⋯, on this side, as the bar has no room for one on each.
	shared: ("Left" | "Right")?,
}

--- A side's hidden entries, for the rows of the ⋯ that holds them.
export type HiddenSide = { hidden: Hidden, entries: { [number]: registry.Entry } }

export type PlanInput = {
	left: { Item },
	center: { Item },
	right: { Item },
	--- Where the left holder starts and the right holder ends, in screen pixels.
	leftStart: number,
	rightEnd: number,
	--- Where the centre icons are centred.
	screenMiddle: number,
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

local function hideAll(items: { Item }): Hidden
	local hidden: Hidden = {}
	for _, item in items do
		hidden[item.id] = true
	end
	return hidden
end

--- Which entries each side hides in its overflow menu, as Roblox's Unibar moves what doesn't fit into its ⋯ menu. A
--- side reaches up to the centre icons when there are any; otherwise a side needing less than half the bar keeps all
--- it needs and the other gets the rest. When both sides overflow and either has no room for its ⋯, every icon of
--- both moves into one ⋯ on the side with more room.
local function plan(input: PlanInput): Plan
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
		local centerLeft = input.screenMiddle - centerWidth / 2
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

	local leftHidden = fit(left, leftRoom, gap, input.overflowWidth)
	local rightHidden = fit(right, rightRoom, gap, input.overflowWidth)
	if next(leftHidden) and next(rightHidden) and math.min(leftRoom, rightRoom) < input.overflowWidth then
		return {
			Left = hideAll(left),
			Right = hideAll(right),
			shared = if leftRoom >= rightRoom then "Left" else "Right",
		}
	end
	return { Left = leftHidden, Right = rightHidden }
end

--- The overflow menu's rows: each hidden icon, and each icon of a hidden group, in bar order, one side after another.
local function rowsFor(sides: { HiddenSide }): { [number]: registry.Entry }
	local rows: { [number]: registry.Entry } = {}
	local index = 0
	local function add(id: number, icon: registry.IconEntry)
		index += 1
		rows[id] = { kind = "Icon", props = icon.props, menu = icon.menu, overflowOf = icon, rowOrder = index }
	end

	for _, side in sides do
		local entries = side.entries
		local hiddenItems: { Item } = {}
		for id in side.hidden do
			local entry = entries[id]
			if entry then
				table.insert(hiddenItems, { id = id, order = orderOf(entry), width = 0 })
			end
		end
		table.sort(hiddenItems, byOrder)

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
