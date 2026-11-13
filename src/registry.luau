local RunService = game:GetService("RunService")

local Vide = require("./Packages/Vide")
local types = require("./types")

export type ContainerKind = "Topbar" | "Group" | "Menu"

export type IconEntry = {
	kind: "Icon",
	props: types.IconProps,
	menu: Container?,
	--- Set on the overflow icon a side shows when its icons don't fit.
	isOverflow: boolean?,
	--- Set on a row of that overflow icon's menu: the icon the row stands for, and where the row goes.
	overflowOf: IconEntry?,
	rowOrder: number?,
}
export type GroupEntry = { kind: "Group", props: types.GroupProps, items: Container }
export type DividerEntry = { kind: "Divider", props: types.DividerProps }
export type Entry = IconEntry | GroupEntry | DividerEntry

--- Where icons go: the topbar itself, a group's pill, or a menu's list.
export type Container = {
	kind: ContainerKind,
	entries: Vide.Source<{ [number]: Entry }>,
}

local function newContainer(kind: ContainerKind): Container
	return { kind = kind, entries = Vide.source({} :: { [number]: Entry }) }
end

local topbar = newContainer("Topbar")
--- The container that `Icon`, `Group` and `Divider` add to: the topbar, unless called inside a group or a menu.
local current = Vide.context(topbar)

local mounted = false
local warnedNotMounted = false
local nextId = 0

local function warnIfNotMounted()
	if mounted or warnedNotMounted or not RunService:IsStudio() then
		return
	end
	warnedNotMounted = true
	warn("VideTopbar: an icon was added but VideTopbar.mount() has not been called")
end

local registry = {}

registry.topbar = topbar
registry.newContainer = newContainer
--- What pressing each drawn icon does, so an overflow menu's row can press the icon it stands for.
registry.activators = setmetatable({}, { __mode = "k" }) :: { [IconEntry]: () -> () }
--- The icon most recently selected or opened, which icons with `autoDeselect` give way to.
registry.latestSelection = Vide.source(nil :: IconEntry?)

function registry.current(): Container
	return current()
end

--- Runs `content` so that what it adds goes into `container`.
function registry.within(container: Container, content: () -> ())
	current(container, function()
		content()
		return nil
	end)
end

--- The container's entries, read through a plain getter: Vide.indexes rejects a source's setter half.
function registry.entriesOf(container: Container): () -> { [number]: Entry }
	return function()
		return container.entries()
	end
end

--- Adds `entry` to `container` for as long as the calling scope lives.
function registry.add(container: Container, entry: Entry)
	nextId += 1
	local id = nextId

	--* Registered first so a call outside a scope errors before the entry is added, instead of leaking it.
	Vide.cleanup(function()
		local remaining = table.clone(Vide.untrack(container.entries))
		remaining[id] = nil
		container.entries(remaining)
	end)

	local added = table.clone(Vide.untrack(container.entries))
	added[id] = entry
	container.entries(added)
	if container.kind == "Topbar" then
		task.defer(warnIfNotMounted)
	end
end

function registry.isMounted(): boolean
	return mounted
end

function registry.setMounted(value: boolean)
	mounted = value
end

return registry
